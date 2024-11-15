//
//  SessionViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//

import Foundation
import ZMVideoSDK
import SwiftUI
import Combine

/// Represents a participant in the Zoom session.
struct Participant {
    let id: String
    let name: String
    var videoCanvas: ZMVideoSDKVideoCanvas?
}

// Manages the Zoom session, handling user interactions and ZoomVideoSDK communications.
class SessionViewModel : NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var sessionName: String = "demoSession2"
    @Published var userDisplayName: String = "Mac2"
    @Published var isAudioMuted: Bool = false
    @Published var isVideoOn: Bool = false
    @Published var showError: Bool = false
    @Published var participants = [Participant]()
    @Published var sessionIsActive = true
    @Published var commandsActive = false
    @Published var cameraList: [Camera] = []

    // MARK: - Private Properties
    private var coordinator: ZoomSessionCoordinator?
    private var commandChannel: ZMVideoSDKCmdChannel?

    //MARK: Publishers
    let sessionStartedPublisher = PassthroughSubject<String, Never>() // Publishes the session name
    let sessionEndedPublisher = PassthroughSubject<Void, Never>() // Publishes when the session ends



    // MARK: - Initialization and Setup

    /// Initializes the SessionViewModel by setting up the ZoomVideoSDK and joining a session.
    override init() {
        super.init()
        initializeSDK()
    }

    /// Initializes the ZoomVideoSDK with the required parameters.
    func initializeSDK() {
        let initParams = ZMVideoSDKInitParams()
        initParams.domain = "https://zoom.us"
        initParams.enableLog = true
        initParams.logFilePrefix = "ZoomSDK"
        initParams.videoRawDataMemoryMode = ZMVideoSDKRawDataMemoryMode_Heap
        initParams.shareRawDataMemoryMode = ZMVideoSDKRawDataMemoryMode_Heap

        // Initialize the coordinator and set it as the delegate
        coordinator = ZoomSessionCoordinator(viewModel: self)
        if let coordinator = coordinator {
            ZMVideoSDK.shared().addListener(coordinator)
        } else {
            Logger.shared.log("Failed to initialize ZoomSessionCoordinator")
        }

        // Initialize the ZoomVideoSDK and log the status
        let sdkInitReturnStatus = ZMVideoSDK.shared().initialize(initParams)
        Logger.shared.log("ZoomVideoSDK Initialization: \(errorMessage(for: sdkInitReturnStatus))")

        if sdkInitReturnStatus != ZMVideoSDKErrors_Success {
            Logger.shared.log("ZoomVideoSDK failed to initialize with error: \(errorMessage(for: sdkInitReturnStatus))")
            DispatchQueue.main.async {
                self.showError = true
            }
        }

        commandChannel = ZMVideoSDK.shared().getCmdChannel()
    }


    /// Generates a JWT token required for joining the Zoom session.
    /// - Returns: A JWT token string if successful; otherwise, an empty string.
    func getJWTToken() -> String {
        // Instantiate ZoomAPIJWT with your Zoom API credentials
        let zoomJWT = ZoomAPIJWT(apiKey: "vWORwGngSfyZ4PIio6bqCg", apiSecret: "i3II29cNHHnL98vc0qGtVbp3SrVC3yYv2vIT")  // Replace with secure storage

        // Generate the JWT token for the session
        let roleType = 1  // 1 for host, 0 for participant
        let jwtToken = zoomJWT.generateToken(sessionName: sessionName, roleType: roleType)

        if jwtToken.isEmpty {
            Logger.shared.log("Failed to generate JWT Token")
            DispatchQueue.main.async {
                self.showError = true
            }
        } else {
            Logger.shared.log("Generated JWT Token successfully")
        }

        return jwtToken
    }

    func startSession() {
        let token = getJWTToken()
        createAndJoinSession(token: token)
    }

    /// Creates and attempts to join a Zoom session with the provided token.
    /// - Parameter token: The JWT token for authentication.
    func createAndJoinSession(token: String) {
        // Configure audio options
        let audioOption = ZMVideoSDKAudioOption()
        audioOption.connect = true
        audioOption.mute = isAudioMuted

        // Configure video options
        let videoOption = ZMVideoSDKVideoOption()
        videoOption.localVideoOn = !isVideoOn

        // Set up the session context
        let sessionContext = ZMVideoSDKSessionContext()
        sessionContext.sessionName = sessionName
        sessionContext.userName = userDisplayName
        sessionContext.token = token
        sessionContext.videoOption = videoOption
        sessionContext.audioOption = audioOption

        // Attempt to join the session with the given context
        if ZMVideoSDK.shared().joinSession(sessionContext) != nil {
            // Session joined successfully
            Logger.shared.log("Session joined successfully")
            DispatchQueue.main.async {
                self.sessionIsActive = true
                self.sessionStartedPublisher.send(self.sessionName)
            }
        } else {
            // Failed to join the session
            Logger.shared.log("Failed to join the session")
            DispatchQueue.main.async {
                self.showError = true
                self.sessionIsActive = false
            }
        }
    }

    /// Toggles the local audio on/off.
    func toggleAudio() {
        let sessionInfo = ZMVideoSDK.shared().getSessionInfo()
        let audioHelper = ZMVideoSDK.shared().getAudioHelper()

        guard
              let myself = sessionInfo.getMySelf(),
              let audioStatus = myself.getAudioStatus()
              else {
            Logger.shared.log("Failed to access audio components")
            return
        }


        var result: ZMVideoSDKErrors

        if audioStatus.audioType == ZMVideoSDKAudioType_None {
            // Start audio if it's not connected
            result = audioHelper.startAudio()
            if result == ZMVideoSDKErrors_Success {
                DispatchQueue.main.async {
                    self.isAudioMuted = false
                }
                Logger.shared.log("Audio started successfully")
            } else {
                Logger.shared.log("Failed to start audio: \(errorMessage(for: result))")
            }
        } else {
            if audioStatus.isMuted {
                // Unmute audio
                result = audioHelper.unMuteAudio(myself)
                if result == ZMVideoSDKErrors_Success {
                    DispatchQueue.main.async {
                        self.isAudioMuted = false
                    }
                    Logger.shared.log("Audio unmuted successfully")
                } else {
                    Logger.shared.log("Failed to unmute audio: \(errorMessage(for: result))")
                }
            } else {
                // Mute audio
                result = audioHelper.muteAudio(myself)
                if result == ZMVideoSDKErrors_Success {
                    DispatchQueue.main.async {
                        self.isAudioMuted = true
                    }
                    Logger.shared.log("Audio muted successfully")
                } else {
                    Logger.shared.log("Failed to mute audio: \(errorMessage(for: result))")
                }
            }
        }
    }

    /// Toggles the local video on or off.
    func toggleVideo() {
        let sessionInfo = ZMVideoSDK.shared().getSessionInfo()
        let videoHelper = ZMVideoSDK.shared().getVideoHelper()

        guard
              let myself = sessionInfo.getMySelf(),
              let isVideoOn = myself.getVideoPipe()?.getVideoStatus()?.isOn else {
            Logger.shared.log("Failed to access video components")
            return
        }

        var result: ZMVideoSDKErrors

        if isVideoOn {
            // Stop video
            result = videoHelper.stopVideo()
            if result == ZMVideoSDKErrors_Success {
                DispatchQueue.main.async {
                    self.isVideoOn = false
                }
                Logger.shared.log("Video stopped successfully")
            } else {
                Logger.shared.log("Failed to stop video: \(errorMessage(for: result))")
            }
        } else {
            // Start video
            result = videoHelper.startVideo()
            if result == ZMVideoSDKErrors_Success {
                DispatchQueue.main.async {
                    self.isVideoOn = true
                }
                Logger.shared.log("Video started successfully")
            } else {
                Logger.shared.log("Failed to start video: \(errorMessage(for: result))")
            }
        }
    }

    /// Leaves the current Zoom session and updates the session state.
    func leaveSession() {
        let result = ZMVideoSDK.shared().leaveSession(true)
        if result == ZMVideoSDKErrors_Success {
            Logger.shared.log("Left session successfully")
            DispatchQueue.main.async {
                self.sessionIsActive = false
            }
        } else {
            Logger.shared.log("Failed to leave session: \(errorMessage(for: result))")
            DispatchQueue.main.async {
                self.showError = true
            }
        }
    }


    /// Sends the list of available cameras to a specified user.
    /// - Parameter user: The user to send the camera list to; if `nil`, broadcasts to all users.
    func sendCameraList(to user: ZMVideoSDKUser?) {
        let cameras = fetchCameras()
        let cameraData = cameras.map { Camera(id: $0.deviceID, name: $0.deviceName) }

        let payload = Payload.cameraList(cameraData)
        let command = Command(type: .responseCameraList, payload: payload)
        Logger.shared.log("sendCameraList will send \(cameras.count) cameras")

        do {
            let jsonData = try JSONEncoder().encode(command)
            guard let commandString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "SessionViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode command to string"])
            }

            // Ensure command channel is available
            guard let commandChannel = commandChannel else {
                Logger.shared.log("Command channel is not available")
                return
            }

            // Send the command string
            let result = commandChannel.sendCommand(commandString, receive: user)
            if result == ZMVideoSDKErrors_Success {
                let recipient = user?.getName() ?? "All Users"
                Logger.shared.log("Sent camera list to: \(recipient)")
            } else {
                Logger.shared.log("Failed to send camera list: \(errorMessage(for: result))")
            }
        } catch {
            Logger.shared.log("Error processing camera list: \(error.localizedDescription)")
        }
    }

    /// Fetches the list of available camera devices.
    /// - Returns: An array of `ZMVideoSDKCameraDevice`.
    func fetchCameras() -> [ZMVideoSDKCameraDevice] {
        Logger.shared.log("-SessionViewModel- fetch camera list")
      let videoHelper = ZMVideoSDK.shared().getVideoHelper()
        return videoHelper.getCameraList() ?? []
    }

    /// Fetches the list of available cameras and updates the `cameraList` property.
    func fetchAndUpdateCameraList() {
        let cameras = fetchCameras()
        let cameraData = cameras.map { Camera(id: $0.deviceID, name: $0.deviceName) }

        DispatchQueue.main.async {
            self.cameraList = cameraData
            Logger.shared.log("SessionViewModel - Updated camera list. Count: \(self.cameraList.count)")
        }
    }


    /// Switches the camera to the specified device ID.
    /// - Parameter deviceID: The identifier of the camera device to switch to.
    func switchCamera(to deviceID: String?) {
        let videoHelper = ZMVideoSDK.shared().getVideoHelper()

        if let cameraDeviceID = deviceID {
            let result = videoHelper.selectCamera(cameraDeviceID)

            if result {
                Logger.shared.log("Camera switched successfully to device ID: \(cameraDeviceID)")
            } else {
                Logger.shared.log("Failed to switch to camera: \(cameraDeviceID) ")
            }

        } else {
            Logger.shared.log("Invalid Device ID provided")
        }
    }

    /// Provides a human-readable error message for a given `ZMVideoSDKErrors` code.
    /// - Parameter error: The error code.
    /// - Returns: A string describing the error.
    private func errorMessage(for error: ZMVideoSDKErrors) -> String {
        switch error {
            case ZMVideoSDKErrors_Success:
                return "Success"
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong usage of the SDK"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal ZoomVideoSDK error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: ZoomVideoSDK not initialized"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory issues encountered"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Failed to load a module"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
            case ZMVideoSDKErrors_Auth_Error:
                return "Error: Authentication failed"
            case ZMVideoSDKErrors_JoinSession_NoSessionName:
                return "Error: No session name provided for joining session"
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

    /// Updates the list of participants in the session.
    func updateParticipants() {
        let session = ZMVideoSDK.shared().getSessionInfo()
        let allUsers = session.getRemoteUsers() ?? []

        DispatchQueue.main.async {
            self.participants = allUsers.map { user in
                let name = user.getName() ?? "Unknown"
                let id = user.getID()?.description ?? UUID().uuidString
                let canvas = user.getVideoCanvas()
                return Participant(id: id, name: name, videoCanvas: canvas)
            }
            Logger.shared.log("SessionViewModel - Update participants. Count: \(self.participants.count)")
        }
    }
}
