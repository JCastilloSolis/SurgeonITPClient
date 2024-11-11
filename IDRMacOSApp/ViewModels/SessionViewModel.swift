//
//  SessionViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//

import Foundation
import ZMVideoSDK
import SwiftUI


struct Camera: Identifiable, Codable {
    let id: String
    let name: String
}

struct Participant {
    let id: String
    let name: String
    var videoCanvas: ZMVideoSDKVideoCanvas?
}


class SessionViewModel : NSObject, ObservableObject, ZMVideoSDKDelegate {
    @Published var sessionName: String = "demoSession2"
    @Published var userDisplayName: String = "Mac2"
    @Published var isAudioMuted: Bool = false
    @Published var isVideoOn: Bool = false
    @Published var showError: Bool = false
    @Published var participants = [Participant]()
    @Published var sessionIsActive = false
    @Published var commandsActive = false

    private var coordinator: ZoomSessionCoordinator?
    private var commandChannel: ZMVideoSDKCmdChannel?

    override init() {
        super.init()
        initializeSDK()
        let token = getJWTToken()
        createAndJoinSession(token: token)
        commandChannel = ZMVideoSDK.shared().getCmdChannel()

    }

    func initializeSDK() {
        let initParams = ZMVideoSDKInitParams()
        initParams.domain = "https://zoom.us"
        initParams.enableLog = true
        initParams.logFilePrefix = "ZoomSDK"
        initParams.videoRawDataMemoryMode = ZMVideoSDKRawDataMemoryMode_Heap
        initParams.shareRawDataMemoryMode = ZMVideoSDKRawDataMemoryMode_Heap
        coordinator = ZoomSessionCoordinator(viewModel: self)
        ZMVideoSDK.shared().addListener(coordinator!)
        let sdkInitReturnStatus = ZMVideoSDK.shared().initialize(initParams)
        print("\(errorMessage(for: sdkInitReturnStatus)) ")
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

    func createAndJoinSession(token: String) {
        let audioOption = ZMVideoSDKAudioOption()
        audioOption.connect = true
        audioOption.mute = isAudioMuted

        let videoOption = ZMVideoSDKVideoOption()
        videoOption.localVideoOn = !isVideoOn

        let sessionContext = ZMVideoSDKSessionContext()
        sessionContext.sessionName = sessionName
        sessionContext.userName = userDisplayName
        sessionContext.token = token
        sessionContext.videoOption = videoOption
        sessionContext.audioOption = audioOption

        // Attempt to join the session with the given context
        if ZMVideoSDK.shared().joinSession(sessionContext) != nil {
            // If the session is created and joined successfully
            print("Session joined successfully")

        } else {
            // If there is an issue in joining the session
            print("Failed to join the session")
            showError = true
        }
    }

    func toggleAudio() {
        if let myself = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let audioStatus = myself.getAudioStatus() {
            let audioHelper = ZMVideoSDK.shared().getAudioHelper()

            var result: ZMVideoSDKErrors

            if audioStatus.audioType == ZMVideoSDKAudioType_None {
                audioHelper.startAudio()
            } else {
                if audioStatus.isMuted {
                    result = audioHelper.unMuteAudio(myself)
                    DispatchQueue.main.async {
                        self.isAudioMuted = false
                    }
                    print("Mute audio \(errorMessage(for: result))")
                } else {
                    result = audioHelper.muteAudio(myself)
                    DispatchQueue.main.async {
                        self.isAudioMuted = true
                    }
                    print("Unmute audio \(errorMessage(for: result))")
                }
            }
        }
    }

    func toggleVideo() {

        if let myself = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let isVideoOn = myself.getVideoPipe()?.getVideoStatus()?.isOn {
            let videoHelper = ZMVideoSDK.shared().getVideoHelper()
            var result: ZMVideoSDKErrors

            if isVideoOn {
                result = videoHelper.stopVideo()
                DispatchQueue.main.async {
                    self.isVideoOn = false
                }
                print("Toggle Video off \(errorMessage(for: result))")
            } else {
                result = videoHelper.startVideo()
                DispatchQueue.main.async {
                    self.isVideoOn = true
                }
                print("Toggle Video on \(errorMessage(for: result))")
            }
        }
    }

    func leaveSession() {
        let result = ZMVideoSDK.shared().leaveSession(true)
        print("Leave session \(errorMessage(for: result))")
    }

    func sendCameraList(to user: ZMVideoSDKUser?) {
        let cameras = fetchCameras()
        let cameraData = cameras.map { Camera(id: $0.deviceID, name: $0.deviceName) }

        let payload = Payload.cameraList(cameras.map { Camera(id: $0.deviceID, name: $0.deviceName) })
        let command = Command(type: .responseCameraList, payload: payload)
        print("sendCameraList will send \(cameras.count) cameras")

        do {
            let jsonData = try JSONEncoder().encode(command)
            guard let commandString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "CameraViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode command to string"])
            }

            // Send the command string
            if let result = commandChannel?.sendCommand(commandString, receive: user) {
                print("Send camera list to: \(user?.getName()). \(errorMessage(for: result))")
            } else {
                print("Failed to send camera list to \(String(describing: user?.getName()))")
            }
        } catch {
            print("Error processing camera list: \(error)")
        }
    }

    func fetchCameras() -> [ZMVideoSDKCameraDevice] {
        print("-SessionViewModel- fetch camera list")
      let videoHelper = ZMVideoSDK.shared().getVideoHelper()
        return videoHelper.getCameraList() ?? []
    }

    func switchCamera(to deviceID: String?) {
        let videoHelper = ZMVideoSDK.shared().getVideoHelper()
        if let cameraDeviceID = deviceID {
            let result = videoHelper.selectCamera(cameraDeviceID)
            print(" -SessionViewModel- Camera switched successfully? : \(result)")

        } else {
            print("selectCamera: Invalid Device ID")
        }
    }

    private func errorMessage(for error: ZMVideoSDKErrors) -> String {
        switch error {
            case ZMVideoSDKErrors_Success:
                return "Success"
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong usage of the SDK"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal SDK error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: SDK not initialized"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory issues encountered"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Failed to load a module"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
                // Add additional cases for other specific errors...
            case ZMVideoSDKErrors_Auth_Error:
                return "Error: Authentication failed"
            case ZMVideoSDKErrors_JoinSession_NoSessionName:
                return "Error: No session name provided for joining session"
                // Ensure all specific errors are handled.
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong Usage"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal Error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: Uninitialize"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory Error"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Load Module Error"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Unload Module Error"
            case ZMVideoSDKErrors_Invalid_Parameter:
                return "Error: Invalid Parameter"
            case ZMVideoSDKErrors_Call_Too_Frequently:
                return "Error: Call too frequently"
            case ZMVideoSDKErrors_No_Impl :
                return "Error: No impl"
            case ZMVideoSDKErrors_Dont_Support_Feature:
                return "Error: Dont support feature"
            case ZMVideoSDKErrors_Unknown:
                return "Error: Unkown"
            case ZMVideoSDKErrors_Remove_Folder_Fail:
                return "Remove Folder Fail"
            default:
                return "Unknown error occurred with code: \(error.rawValue)"
        }
    }

    func updateParticipants() {

        let session = ZMVideoSDK.shared().getSessionInfo()
        let allUsers = session.getRemoteUsers() ?? []
        participants = allUsers.map { user in
            let name = user.getName() ?? "Unknown"
            let id = user.getID()?.description
            let canvas = user.getVideoCanvas()
            return Participant(id: id ?? UUID().uuidString, name: name, videoCanvas: canvas)
        }

        print("SessionViewModel - Update participants. Count: \(participants.count)")
    }
}
