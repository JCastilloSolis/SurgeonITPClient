//
//  ZoomSessionCoordinator.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import ZMVideoSDK


/// The `ZoomSessionCoordinator` acts as the delegate for `ZMVideoSDK` events and communicates with the `SessionViewModel` to update the UI.
class ZoomSessionCoordinator: NSObject, ZMVideoSDKDelegate {
    /// The associated view model that manages session state and UI updates.
    var viewModel: SessionViewModel
    
    /// Initializes the coordinator with the given view model.
    /// - Parameter viewModel: The `SessionViewModel` to communicate with.
    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
    }
    
    /// Called when the session is successfully joined.
    func onSessionJoin() {
        Logger.shared.log("ZoomSessionCoordinator - Session joined successfully")
        if let myUser = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas() {
            DispatchQueue.main.async {
                self.viewModel.sessionIsActive = true
                self.viewModel.sessionStartedPublisher.send(self.viewModel.sessionName)
            }
        } else {
            Logger.shared.log("ZoomSessionCoordinator - Failed to get user or video canvas")
        }
    }
    
    /// Called when the session is terminated
    func onSessionLeave() {
        Logger.shared.log("ZoomSessionCoordinator - Session left")
        DispatchQueue.main.async {
            self.viewModel.sessionIsActive = false
            self.viewModel.sessionEndedPublisher.send()
        }
    }
    
    /// Called when a user's video status changes.
    func onUserVideoStatusChanged(_ helper: ZMVideoSDKVideoHelper?, user: ZMVideoSDKUser?, videoStatus: ZMVideoSDKVideoStatus?) {
        guard let isVideoOn = videoStatus?.isOn else { return }
        DispatchQueue.main.async {
            self.viewModel.isVideoOn = isVideoOn
            if let userName = user?.getName() {
                Logger.shared.log("ZoomSessionCoordinator - \(userName)'s video status changed: \(isVideoOn ? "On" : "Off")")
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Video status changed: \(isVideoOn ? "On" : "Off")")
            }
        }
    }
    
    /// Called when a user's audio status changes.
    func onUserAudioStatusChanged(_ helper: ZMVideoSDKAudioHelper?, user: ZMVideoSDKUser?, audioStatus: ZMVideoSDKAudioStatus?) {
        guard let isAudioMuted = audioStatus?.isMuted else { return }
        DispatchQueue.main.async {
            self.viewModel.isAudioMuted = isAudioMuted
            if let userName = user?.getName() {
                Logger.shared.log("ZoomSessionCoordinator - \(userName)'s audio status changed: \(isAudioMuted ? "Muted" : "Unmuted")")
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Audio status changed: \(isAudioMuted ? "Muted" : "Unmuted")")
            }
        }
    }
    
    /// Called when users join the session.
    func onUserJoin(_ userHelper: ZMVideoSDKUserHelper, userList users: [ZMVideoSDKUser]?) {
        if let users = users {
            let userNames = users.compactMap { $0.getName() }
            Logger.shared.log("ZoomSessionCoordinator - Users joined: \(userNames.joined(separator: ", "))")
        } else {
            Logger.shared.log("ZoomSessionCoordinator - Users joined: 0")
        }
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }
    
    /// Called when users leave the session.
    func onUserLeave(_ userHelper: ZMVideoSDKUserHelper, userList users: [ZMVideoSDKUser]?) {
        if let users = users {
            let userNames = users.compactMap { $0.getName() }
            Logger.shared.log("ZoomSessionCoordinator - Users left: \(userNames.joined(separator: ", "))")
        } else {
            Logger.shared.log("ZoomSessionCoordinator - Users left")
        }
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }
    
    /// Called when the command channel connection result is received.
    func onCommandChannelConnectResult(_ isSuccess: Bool) {
        DispatchQueue.main.async {
            if isSuccess {
                Logger.shared.log("ZoomSessionCoordinator - Command channel is ready to be used")
                self.viewModel.commandsActive = true
                self.viewModel.sendCameraList(to: nil)
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Command channel failed to connect")
                self.viewModel.commandsActive = false
                // Optionally, handle reconnection or notify the user
            }
        }
    }
    
    /// Called when a command is received over the command channel.
    func onCommandReceived(_ commandContent: String?, senderUser user: ZMVideoSDKUser?) {
        guard let commandContent = commandContent,
              let jsonData = commandContent.data(using: .utf8) else {
            Logger.shared.log("ZoomSessionCoordinator - onCommandReceived - Invalid command content")
            return
        }
        
        do {
            let command = try JSONDecoder().decode(Command.self, from: jsonData)
            switch command.type {
            case .requestCameraList:
                Logger.shared.log("ZoomSessionCoordinator - Request Camera List command received")
                viewModel.sendCameraList(to: user)
            case .requestSwitchCamera:
                if case .selectedCameraID(let cameraID) = command.payload {
                    Logger.shared.log("ZoomSessionCoordinator - Request Switch Camera command received for camera ID: \(cameraID)")
                    viewModel.switchCamera(to: cameraID)
                }
            default:
                Logger.shared.log("ZoomSessionCoordinator - Received unsupported command type")
            }
        } catch {
            Logger.shared.log("ZoomSessionCoordinator - Error decoding command: \(error.localizedDescription)")
        }
    }
    
    /// Called when the camera list changes.
    func onCameraListChanged() {
        Logger.shared.log("ZoomSessionCoordinator - Camera list has changed")
        DispatchQueue.main.async {
            self.viewModel.fetchAndUpdateCameraList()
            self.viewModel.sendCameraList(to: nil)
        }
    }
    
    /// Called when a camera control request is received from another user.
    func onCameraControlRequestReceived(_ user: ZMVideoSDKUser?, cameraControlRequestType requestType: ZMVideoSDKCameraControlRequestType, requestHandler cameraControlRequestHandler: ZMVideoSDKCameraControlRequestHandler?) {
        
        guard let handler = cameraControlRequestHandler else {
            Logger.shared.log("ZoomSessionCoordinator - Camera control request handler is nil")
            return
        }
        
        switch requestType {
        case ZMVideoSDKCameraControlRequestType_RequestControl:
            let userName = user?.getName() ?? "Unknown User"
            Logger.shared.log("ZoomSessionCoordinator - Camera control request received from \(userName)")
            handler.approve()
        case ZMVideoSDKCameraControlRequestType_GiveUpControl:
            let userName = user?.getName() ?? "Unknown User"
            Logger.shared.log("ZoomSessionCoordinator - Give up camera control request received from \(userName)")
            handler.approve()
        default:
            Logger.shared.log("ZoomSessionCoordinator - Unknown camera control request type")
        }
    }
    
    func onError(_ errorType: ZMVideoSDKErrors, detail details: Int32) {
        Logger.shared.log("ZoomSessionCoordinator macOS received error   \(details)  error type \(errorType)")
    }
    
    func onCameraControlRequestResult(_ user: ZMVideoSDKUser?, approved isApproved: Bool) {
        Logger.shared.log("onCameraControlRequestResult isApproved: \(isApproved) for \(user?.getName())")
    }
    
}
