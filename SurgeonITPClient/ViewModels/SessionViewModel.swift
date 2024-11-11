//
//  SessionViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import SwiftUI
import ZoomVideoSDK

struct Camera: Identifiable, Codable {
    let id: String
    let name: String
}

class SessionViewModel: ObservableObject {
    @Published var isVideoOn = true
    @Published var isAudioMuted = false
    @Published var sessionIsActive = false
    @Published var commandsActive = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var participants = [Participant]()
    @Published var pinnedParticipantID: String?
    @Published var cameraList: [Camera] = []
    @Published var canControlCamera = false

    let sessionName = "demoSession2"
    let userName = "Ipad"

    private var coordinator: ZoomSessionCoordinator?
    private var commandChannel: ZoomVideoSDKCmdChannel?
    private var remoteControlHelper: ZoomVideoSDKRemoteCameraControlHelper?

    init() {
        coordinator = ZoomSessionCoordinator(viewModel: self)
        setupSession()
    }

    func setupSession() {
        let sessionContext = ZoomVideoSDKSessionContext()
        
        sessionContext.token = getJWTToken()
        sessionContext.sessionName = sessionName
        sessionContext.userName = userName

        ZoomVideoSDK.shareInstance()?.delegate = coordinator

        if let _ = ZoomVideoSDK.shareInstance()?.joinSession(sessionContext) {
            // Session joined successfully
            print("-SessionViewModel- Session joined successfully")
            commandChannel = ZoomVideoSDK.shareInstance()?.getCmdChannel()
        } else {
            // Handle failure to join session
            //showError = true
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to join session."
            }
            print("-SessionViewModel- Failed to join session")
        }
    }

    func getJWTToken() -> String {
        // Instantiate ZoomAPIJWT with your Zoom API credentials
        let zoomJWT = ZoomAPIJWT(apiKey: "vWORwGngSfyZ4PIio6bqCg", apiSecret: "i3II29cNHHnL98vc0qGtVbp3SrVC3yYv2vIT")

        // Generate the JWT token for the session
        let roleType = 1  // 1 for host, 0 for participant
        let jwtToken = zoomJWT.generateToken(sessionName: sessionName, roleType: roleType)

        // Output the generated JWT token
        print("Generated JWT Token: \(jwtToken)")
        return jwtToken
    }

    func pinParticipant(_ participantID: String?) {
        pinnedParticipantID = participantID
    }

    func toggleVideo() {
        guard let videoHelper = ZoomVideoSDK.shareInstance()?.getVideoHelper(),
              let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let videoCanvas = myUser.getVideoCanvas(),
              let isVideoOn = videoCanvas.videoStatus()?.on else {
            print("- SessionViewModel- Failed to access video components")
            return
        }

            if isVideoOn {
                _ = videoHelper.stopVideo()
                DispatchQueue.main.async {
                    self.isVideoOn = false
                }
                print("- SessionViewModel - Video stopped")
            } else {
                _ = videoHelper.startVideo()
                DispatchQueue.main.async {
                    self.isVideoOn = true
                }
                print("- SessionViewModel - Video started")
            }

    }

    func toggleAudio() {
        guard let audioHelper = ZoomVideoSDK.shareInstance()?.getAudioHelper(),
              let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let audioStatus = myUser.audioStatus() else {
            print("- SessionViewModel - Failed to access audio components")
            return
        }

        if audioStatus.audioType == .none {
            audioHelper.startAudio()
        } else {
            if audioStatus.isMuted {
                _ = audioHelper.unmuteAudio(myUser)
                DispatchQueue.main.async {
                    self.isAudioMuted = false
                }
                print("- SessionViewModel - Audio unmuted")
            } else {
                _ = audioHelper.muteAudio(myUser)
                DispatchQueue.main.async {
                    self.isAudioMuted = true
                }
                print("- SessionViewModel - Audio muted")
            }
        }
    }

    func leaveSession() {
        ZoomVideoSDK.shareInstance()?.leaveSession(true)
        print("- SessionViewModel - Session left")
    }


    private func errorMessage(for error: ZoomVideoSDKError) -> String {
        switch error {
            case .Errors_Success:
                return "Success"
            case .Errors_Wrong_Usage:
                return "Error: Wrong usage of the SDK"
            case .Errors_Internal_Error:
                return "Error: Internal SDK error"
            case .Errors_Uninitialize:
                return "Error: SDK not initialized"
            case .Errors_Memory_Error:
                return "Error: Memory issues encountered"
            case .Errors_Load_Module_Error:
                return "Error: Failed to load a module"
            case .Errors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
                // Add additional cases for other specific errors...
            case .Errors_Auth_Error:
                return "Error: Authentication failed"
            case .Errors_JoinSession_NoSessionName:
                return "Error: No session name provided for joining session"
            case .Errors_Invalid_Parameter:
                return "Error: Invalid Parameter"
            case .Errors_Call_Too_Frequently:
                return "Error: Call too frequently"
            case .Errors_No_Impl :
                return "Error: No impl"
            case .Errors_Dont_Support_Feature:
                return "Error: Dont support feature"
            case .Errors_Unknown:
                return "Error: Unkown"
            case .Errors_Remove_Folder_Fail:
                return "Remove Folder Fail"
            default:
                return "Unknown error occurred with code: \(error.rawValue)"
        }
    }

    func updateParticipants() {
        guard let session = ZoomVideoSDK.shareInstance()?.getSession() else { return }
        let allUsers = session.getRemoteUsers() ?? []
        participants = allUsers.map { user in
            let name = user.getName() ?? "Unknown"
            let id = user.getID().description
            let canvas = user.getVideoCanvas()
            return Participant(id: id, name: name, videoCanvas: canvas)
        }
    }

    func updateCameraList(cameras: [[String: String]]) {
        DispatchQueue.main.async {
            self.cameraList = cameras.compactMap { dict -> Camera? in
                guard let id = dict["id"], let name = dict["name"] else {
                    return nil
                }
                return Camera(id: id, name: name)
            }
        }
    }

    func requestCameraList() throws {
        let command = Command(type: .requestCameraList, payload: .empty)
        let jsonData = try JSONEncoder().encode(command)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw NSError() }
        commandChannel?.sendCommand(jsonString, receive: nil)
        print("Request camera list command sent")
        //session?.sendCommand(jsonString)
    }

    func requestSwitchCamera(toDeviceID deviceID: String) {
        let payload = Payload.selectedCameraID(deviceID)
        let command = Command(type: .requestSwitchCamera, payload: payload)

        do {
            let jsonData = try JSONEncoder().encode(command)
            guard let commandString = String(data: jsonData, encoding: .utf8) else {
                print("Error: Unable to encode command to string")
                return
            }

            // Assuming `commandChannel` and `sendCommand` are properly implemented
            if let result = commandChannel?.sendCommand(commandString, receive: nil) { // Define how to specify the macOS client if needed
                print("Requested to switch camera. Result: \(errorMessage(for: result))")

                if result == .Errors_Success {
                    requestCameraControl()
                }

            } else {
                print("Failed to send camera switch request")
            }
        } catch {
            print("Error sending camera switch request: \(error)")
        }
    }

    func requestCameraControl() {
        let session = ZoomVideoSDK.shareInstance()?.getSession()
        let users = session?.getRemoteUsers()?.compactMap { $0 as ZoomVideoSDKUser } ?? []

        // Determine the user to subscribe to
        let user: ZoomVideoSDKUser? = {
            if let participantID = pinnedParticipantID,
               let intValue: Int = Int(participantID),
               let foundUser = users.first(where: { $0.getID() == intValue }) {
                return foundUser
            }
            return nil // Default to no user, if no pinned participant
        }()



        guard let selectedUser =  user,
              let remoteControlHelper = selectedUser.getRemoteCameraControlHelper() else {
            print("error retrieving pinned user remote control helper")
            return
        }

        self.remoteControlHelper = remoteControlHelper

        if canControlCamera {
            let result = remoteControlHelper.giveUpControlRemoteCamera()
            print("giveUpControlRemoteCamera \(errorMessage(for: result))")
            if result == .Errors_Success {
                DispatchQueue.main.async {
                    self.canControlCamera = false
                }
            }
        } else {
            let result = remoteControlHelper.requestControlRemoteCamera()
            print("requestControlRemoteCamera \(errorMessage(for: result))")

        }
    }

    func requestMoveCameraLeft() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.turnLeft(range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Move camera left:  \(errorMessage(for: result))")
    }

    func requestMoveCameraRight() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.turnRight(range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Move camera right:  \(errorMessage(for: result))")
    }

    func requestMoveCameraUp() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.turnUp(range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Move camera up:  \(errorMessage(for: result))")
    }

    func requestMoveCameraDown() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.turnDown(range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Move camera down:  \(errorMessage(for: result))")
    }

    func requestZoomCamera() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.zoom(in: range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Zoom camera:  \(errorMessage(for: result))")
    }

    func requestZoomCameraOut() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            print("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.zoomOut(range)

        //TODO: Get current camera name
        //print("Move \(cameraName) left:  \(errorMessage(for: result))")
        print("Zoom camera out:  \(errorMessage(for: result))")
    }
}
