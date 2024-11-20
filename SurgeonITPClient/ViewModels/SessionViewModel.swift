//
//  SessionViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//

import Foundation
import SwiftUI
import ZoomVideoSDK

/// The `SessionViewModel` manages the Zoom session, handles user interactions,
/// and communicates with the `ZoomSessionCoordinator` to respond to ZoomVideoSDK events.
class SessionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isVideoOn = false
    @Published var isAudioMuted = true
    @Published var sessionIsActive = false
    @Published var commandsActive = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var participants = [Participant]()
    @Published var pinnedParticipantID: String?
    @Published var cameraList: [Camera] = []
    @Published var canControlCamera = false
    @Published var sessionName: String = ""

    // MARK: - Session Properties
    let userName = UIDevice.current.name

    // MARK: - Private Variables
    private var coordinator: ZoomClientSessionCoordinator?
    private var commandChannel: ZoomVideoSDKCmdChannel?
    private var remoteControlHelper: ZoomVideoSDKRemoteCameraControlHelper?

    // Computed property to get the first participant other than the local user
    var firstRemoteParticipant: Participant? {
        return participants.first { $0.id != selfUserID }
    }

    // Assuming you have a way to get the local user's ID
    private var selfUserID: String {
        guard let userID = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()?.getID() else {
            Logger.shared.log("Unable to retrieve local user ID.")
            return ""
        }
        return String(userID)
    }


    // MARK: - Initialization
    init() {
        coordinator = ZoomClientSessionCoordinator(viewModel: self)
    }

    /// Joins a Zoom session with the provided sessionName.
    /// - Parameter sessionName: The name of the Zoom session to join.
    func joinSession(sessionName: String) {
        self.sessionName = sessionName
        setupSession()
    }

    func setupSession() {

        guard !sessionName.isEmpty else {
            Logger.shared.log("sessionName is empty. Cannot join session.")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Session name is empty. Please provide a valid session name."
            }
            return
        }

        let sessionContext = ZoomVideoSDKSessionContext()

        sessionContext.token = getJWTToken()
        sessionContext.sessionName = sessionName
        sessionContext.userName = userName

        // Set video and audio options to disable video and audio upon joining
        let videoOptions = ZoomVideoSDKVideoOptions()
        videoOptions.localVideoOn = false
        sessionContext.videoOption = videoOptions

        let audioOptions = ZoomVideoSDKAudioOptions()
        audioOptions.connect = true
        audioOptions.mute = true
        sessionContext.audioOption = audioOptions

        ZoomVideoSDK.shareInstance()?.delegate = coordinator

        if let session = ZoomVideoSDK.shareInstance()?.joinSession(sessionContext) { // returns a ZoomVideoSDKSession
            // Session joined successfully
            Logger.shared.log("Session '\(sessionName)' joined successfully")
            commandChannel = ZoomVideoSDK.shareInstance()?.getCmdChannel()
        } else {
            // Handle failure to join session
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to join session '\(self.sessionName)'."
            }
            Logger.shared.log("Failed to join session '\(sessionName)'")
        }
    }

    /// Generates a JWT token required for joining the Zoom session.
    /// - Returns: A JWT token string if successful; otherwise, an empty string.
    func getJWTToken() -> String {
        //TODO: Save this into firebase or something and add some validation steps
        let zoomJWT = ZoomAPIJWT(apiKey: Constants.zoomAPIKey , apiSecret: Constants.zoomAPISecret)
        let roleType = 0  // 1 for host, 0 for participant

        let jwtToken = zoomJWT.generateToken(sessionName: sessionName, roleType: roleType)
        if jwtToken.isEmpty {
            Logger.shared.log("SessionViewModel - Failed to generate JWT Token")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to generate JWT Token."
            }
        } else {
            Logger.shared.log("SessionViewModel - JWT Token generated successfully")
        }
        return jwtToken
    }

    func pinParticipant(_ participantID: String?) {
        pinnedParticipantID = participantID
    }

    /// Toggles the local video on or off based on the current state.
    func toggleVideo() {
        guard let videoHelper = ZoomVideoSDK.shareInstance()?.getVideoHelper(),
              let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let videoCanvas = myUser.getVideoCanvas(),
              let isVideoOn = videoCanvas.videoStatus()?.on else {
            Logger.shared.log("SessionViewModel - Failed to access video components")
            return
        }

        if isVideoOn {
            let result = videoHelper.stopVideo()
            if result == .Errors_Success {
                DispatchQueue.main.async {
                    self.isVideoOn = false
                }
                Logger.shared.log("SessionViewModel - Video stopped successfully")
            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to stop video: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to stop video: \(errorMessage)"
                }
            }
        } else {
            DispatchQueue.global(qos: .background).async {


                let result = videoHelper.startVideo()
                if result == .Errors_Success {
                    DispatchQueue.main.async {
                        self.isVideoOn = true
                    }
                    Logger.shared.log("SessionViewModel - Video started successfully")
                } else {
                    let errorMessage = self.errorMessage(for: result)
                    Logger.shared.log("SessionViewModel - Failed to start video: \(errorMessage)")
                    DispatchQueue.main.async {
                        self.showAlert = true
                        self.alertMessage = "Failed to start video: \(errorMessage)"
                    }
                }
            }
        }
    }

    /// Toggles the local audio mute status based on the current state.
    func toggleAudio() {
        guard let audioHelper = ZoomVideoSDK.shareInstance()?.getAudioHelper(),
              let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let audioStatus = myUser.audioStatus() else {
            Logger.shared.log("SessionViewModel - Failed to access audio components")
            return
        }

        if audioStatus.audioType == .none {
            let result = audioHelper.startAudio()
            if result == .Errors_Success {
                Logger.shared.log("SessionViewModel - Audio started successfully")
            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to start audio: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to start audio: \(errorMessage)"
                }
            }
        } else {
            if audioStatus.isMuted {
                let result = audioHelper.unmuteAudio(myUser)
                if result == .Errors_Success {
                    DispatchQueue.main.async {
                        self.isAudioMuted = false
                    }
                    Logger.shared.log("SessionViewModel - Audio unmuted successfully")
                } else {
                    let errorMessage = self.errorMessage(for: result)
                    Logger.shared.log("SessionViewModel - Failed to unmute audio: \(errorMessage)")
                    DispatchQueue.main.async {
                        self.showAlert = true
                        self.alertMessage = "Failed to unmute audio: \(errorMessage)"
                    }
                }
            } else {
                let result = audioHelper.muteAudio(myUser)
                if result == .Errors_Success {
                    DispatchQueue.main.async {
                        self.isAudioMuted = true
                    }
                    Logger.shared.log("SessionViewModel - Audio muted successfully")
                } else {
                    let errorMessage = self.errorMessage(for: result)
                    Logger.shared.log("SessionViewModel - Failed to mute audio: \(errorMessage)")
                    DispatchQueue.main.async {
                        self.showAlert = true
                        self.alertMessage = "Failed to mute audio: \(errorMessage)"
                    }
                }
            }
        }
    }

    /// Leaves the current Zoom session and updates the session state.
    func leaveSession() {
        if let result = ZoomVideoSDK.shareInstance()?.leaveSession(true) {
            if result == .Errors_Success {
                Logger.shared.log("SessionViewModel - Session left successfully")
                DispatchQueue.main.async {
                    self.sessionIsActive = false
                }
            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to leave session: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to leave session: \(errorMessage)"
                }
            }
        } else {
            Logger.shared.log("SessionViewModel - leaveSession returned nil")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to leave session: Unknown error"
            }
        }
    }


    private func errorMessage(for error: ZoomVideoSDKError) -> String {
        switch error {
            case .Errors_Success:
                return "Success"
            case .Errors_Wrong_Usage:
                return "Error: Wrong usage of the SDK"
            case .Errors_Internal_Error:
                return "Error: Internal ZoomVideoSDK error"
            case .Errors_Uninitialize:
                return "Error: ZoomVideoSDK not initialized"
            case .Errors_Memory_Error:
                return "Error: Memory issues encountered"
            case .Errors_Load_Module_Error:
                return "Error: Failed to load a module"
            case .Errors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
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

    /// Updates the list of participants in the session.
    func updateParticipants() {
        guard let session = ZoomVideoSDK.shareInstance()?.getSession() else {
            Logger.shared.log("SessionViewModel - Failed to get session for updating participants")
            return
        }
        let allUsers = session.getRemoteUsers() ?? []
        let updatedParticipants = allUsers.compactMap { user -> Participant? in
            guard let name = user.getName() else {
                Logger.shared.log("SessionViewModel - Skipping user with missing name")
                return nil
            }
            let id = user.getID().description
            let canvas = user.getVideoCanvas()
            return Participant(id: id, name: name, videoCanvas: canvas)
        }
        DispatchQueue.main.async {
            self.participants = updatedParticipants
        }
        Logger.shared.log("SessionViewModel - Updated participants. Count: \(updatedParticipants.count)")
    }


    /// Updates the list of available cameras.
    func updateCameraList(cameras: [Camera]) {
        DispatchQueue.main.async {
            self.cameraList = cameras
        }
        Logger.shared.log("SessionViewModel - Updated camera list. Count: \(cameras.count)")
    }

    /// Sends a command to request the list of available cameras from the macOS server.
    func requestCameraList() {
        let command = Command(type: .requestCameraList, payload: .empty)
        do {
            let jsonData = try JSONEncoder().encode(command)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "SessionViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode Zoom Command to string"])
            }
            guard let commandChannel = commandChannel else {
                Logger.shared.log("SessionViewModel - Command channel is not active")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Cannot request camera list: Command channel is inactive."
                }
                return
            }
            let result = commandChannel.sendCommand(jsonString, receive: nil)
            if result == .Errors_Success {
                Logger.shared.log("SessionViewModel - Request camera list command sent successfully")

            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to send request camera list command: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to request camera list: \(errorMessage)"
                }
            }
        } catch {
            Logger.shared.log("SessionViewModel - Error sending request camera list command: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Error requesting camera list: \(error.localizedDescription)"
            }
        }
    }

    /// Sends a request to the zoom host to change its camera
    func requestSwitchCamera(toDeviceID deviceID: String) {
        let payload = Payload.selectedCameraID(deviceID)
        let command = Command(type: .requestSwitchCamera, payload: payload)

        do {
            let jsonData = try JSONEncoder().encode(command)
            guard let commandString = String(data: jsonData, encoding: .utf8) else {
                Logger.shared.log("Error: Unable to encode command to string")
                return
            }

            // Assuming `commandChannel` and `sendCommand` are properly implemented
            if let result = commandChannel?.sendCommand(commandString, receive: nil) { // Define how to specify the macOS client if needed
                Logger.shared.log("Requested to switch camera. Result: \(errorMessage(for: result))")

                if result == .Errors_Success {
                    requestCameraControl()
                }

            } else {
                Logger.shared.log("Failed to send camera switch request")
            }
        } catch {
            Logger.shared.log("Error sending camera switch request: \(error)")
        }
    }

    /// Requests the hosts for control of the remote PTZ  camera.
    func requestCameraControl() {
        guard let session: ZoomVideoSDKSession = ZoomVideoSDK.shareInstance()?.getSession(),
              let users: [ZoomVideoSDKUser] = session.getRemoteUsers() else {
            Logger.shared.log("SessionViewModel - No remote users available")
            return
        }

        // Determine the user to control
        let user: ZoomVideoSDKUser? = {
            if let remoteParticipantID = firstRemoteParticipant?.id,
               let intValue = Int(remoteParticipantID),
               let foundUser = users.first(where: { $0.getID() == intValue }) {
                return foundUser
            }
            return nil
        }()

        guard let selectedUser = user,
              let remoteControlHelper = selectedUser.getRemoteCameraControlHelper() else {
            Logger.shared.log("SessionViewModel - Error retrieving remote control helper for selected user")
            return
        }

        self.remoteControlHelper = remoteControlHelper


        //TODO: Add more comments around this and the related scenarios
        if canControlCamera {
            let result = remoteControlHelper.giveUpControlRemoteCamera()
            if result == .Errors_Success {
                Logger.shared.log("SessionViewModel - Successfully gave up control of remote camera")
                DispatchQueue.main.async {
                    self.canControlCamera = false
                }
            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to give up control of remote camera: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to give up camera control: \(errorMessage)"
                }
            }
        } else {
            let result = remoteControlHelper.requestControlRemoteCamera()
            if result == .Errors_Success {
                Logger.shared.log("SessionViewModel - Requested control of remote camera successfully")
                // The approval result will be handled in `onCameraControlRequestResult`
            } else {
                let errorMessage = self.errorMessage(for: result)
                Logger.shared.log("SessionViewModel - Failed to request control of remote camera: \(errorMessage)")
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Failed to request camera control: \(errorMessage)"
                }
            }
        }
    }

    /// Moves the remote camera to the left.
    func requestMoveCameraLeft() {
        let range: UInt32 = 100  // Adjust the range as needed
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("SessionViewModel - Remote control helper is not available")
            return
        }
        //TODO: try to get camera name
        let result = remoteControlHelper.turnLeft(range)
        if result == .Errors_Success {
            Logger.shared.log("SessionViewModel - Camera moved left successfully")
        } else {
            let errorMessage = self.errorMessage(for: result)
            Logger.shared.log("SessionViewModel - Failed to move camera left: \(errorMessage)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to move camera left: \(errorMessage)"
            }
        }
    }


    /// Moves the remote camera to the right.
    func requestMoveCameraRight() {
        let range: UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("SessionViewModel - Remote control helper is not available")
            return
        }

        let result = remoteControlHelper.turnRight(range)
        if result == .Errors_Success {
            Logger.shared.log("SessionViewModel - Camera moved right successfully")
        } else {
            let errorMessage = self.errorMessage(for: result)
            Logger.shared.log("SessionViewModel - Failed to move camera right: \(errorMessage)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to move camera right: \(errorMessage)"
            }
        }
    }

    /// Moves the remote camera upwards.
    func requestMoveCameraUp() {
        let range: UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("SessionViewModel - Remote control helper is not available")
            return
        }

        let result = remoteControlHelper.turnUp(range)
        if result == .Errors_Success {
            Logger.shared.log("SessionViewModel - Camera moved up successfully")
        } else {
            let errorMessage = self.errorMessage(for: result)
            Logger.shared.log("SessionViewModel - Failed to move camera up: \(errorMessage)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to move camera up: \(errorMessage)"
            }
        }
    }

    /// Moves the remote camera downwards.
    func requestMoveCameraDown() {
        let range: UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("SessionViewModel - Remote control helper is not available")
            return
        }

        let result = remoteControlHelper.turnDown(range)
        if result == .Errors_Success {
            Logger.shared.log("SessionViewModel - Camera moved down successfully")
        } else {
            let errorMessage = self.errorMessage(for: result)
            Logger.shared.log("SessionViewModel - Failed to move camera down: \(errorMessage)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to move camera down: \(errorMessage)"
            }
        }
    }

    /// Zooms the remote camera in.
    func requestZoomCameraIn() {
        let range: UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("SessionViewModel - Remote control helper is not available")
            return
        }

        let result = remoteControlHelper.zoom(in: range)
        if result == .Errors_Success {
            Logger.shared.log("SessionViewModel - Camera zoomed in successfully")
        } else {
            let errorMessage = self.errorMessage(for: result)
            Logger.shared.log("SessionViewModel - Failed to zoom camera in: \(errorMessage)")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Failed to zoom camera in: \(errorMessage)"
            }
        }
    }

    func requestZoomCameraOut() {
        let range:UInt32 = 100
        guard let remoteControlHelper = remoteControlHelper else {
            Logger.shared.log("Invalid remoteController helper")
            return
        }

        let result = remoteControlHelper.zoomOut(range)

        //TODO: Get current camera name
        Logger.shared.log("Zoom camera out:  \(errorMessage(for: result))")
    }

    
}
