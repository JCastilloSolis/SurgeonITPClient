//
//  ZoomSessionCoordinator.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import ZoomVideoSDK

class ZoomSessionCoordinator: NSObject, ZoomVideoSDKDelegate {
    var viewModel: SessionViewModel

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
    }

    func onSessionJoin() {
        Logger.shared.log("ZoomSessionCoordinator - Session joined successfully")
        if let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas(),
           let myVideoIsOn = myUserVideoCanvas.videoStatus()?.on {
            DispatchQueue.main.async {
                self.viewModel.sessionIsActive = true
                self.viewModel.isVideoOn = myVideoIsOn
            }
        } else {
            Logger.shared.log("ZoomSessionCoordinator - Failed to retrieve user's video status")
        }
    }

    func onSessionLeave() {
        Logger.shared.log("ZoomSessionCoordinator - Session left")
        DispatchQueue.main.async {
            self.viewModel.sessionIsActive = false
        }
    }

    func onUserVideoStatusChanged(_ helper: ZoomVideoSDKVideoHelper?, user: ZoomVideoSDKUser?, videoStatus: ZoomVideoSDKVideoStatus?) {
        guard let isVideoOn = videoStatus?.on else { return }
        DispatchQueue.main.async {
            self.viewModel.isVideoOn = isVideoOn
            if let userName = user?.getName() {
                Logger.shared.log("ZoomSessionCoordinator - \(userName)'s video status changed: \(isVideoOn)")
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Video status changed: \(isVideoOn)")
            }
        }
    }

    func onUserAudioStatusChanged(_ helper: ZoomVideoSDKAudioHelper?, user: ZoomVideoSDKUser?, audioStatus: ZoomVideoSDKAudioStatus?) {
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

    func onUserJoin(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
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

    func onUserLeave(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
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

    func onCmdChannelConnectResult(_ isSuccess: Bool) {
        DispatchQueue.main.async {
            if isSuccess {
                Logger.shared.log("ZoomSessionCoordinator - Command channel is ready to be used")
                self.viewModel.commandsActive = true
                do {
                    try self.viewModel.requestCameraList()
                } catch {
                    Logger.shared.log("ZoomSessionCoordinator - Failed to request camera list: \(error.localizedDescription)")
                }
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Command channel failed to connect")
                self.viewModel.commandsActive = false
            }
        }
    }

    func onCommandReceived(_ commandContent: String?, send sendUser: ZoomVideoSDKUser?) {
        Logger.shared.log("ZoomSessionCoordinator - Command received")

        guard let commandContent = commandContent,
              let jsonData = commandContent.data(using: .utf8) else {
            Logger.shared.log("ZoomSessionCoordinator - Invalid command content")
            return
        }

        do {
            let command = try JSONDecoder().decode(Command.self, from: jsonData)
            switch command.type {
                case .responseCameraList:
                    if case .cameraList(let cameras) = command.payload {
                        Logger.shared.log("ZoomSessionCoordinator - Received camera list")
                        DispatchQueue.main.async {
                            self.viewModel.cameraList = cameras
                        }
                    }
                case .responseSwitchCamera:
                    if case .switchCameraResponse(let response) = command.payload {
                        Logger.shared.log("ZoomSessionCoordinator - Switch camera response: Success=\(response.success), Message=\(response.message)")
                    }
                default:
                    Logger.shared.log("ZoomSessionCoordinator - Received unsupported command type")
            }
        } catch {
            Logger.shared.log("ZoomSessionCoordinator - Error decoding command: \(error.localizedDescription)")
        }
    }

    func onCameraControlRequestResult(_ user: ZoomVideoSDKUser?, approved isApproved: Bool) {
        DispatchQueue.main.async {
            if isApproved {
                Logger.shared.log("ZoomSessionCoordinator - User is approved to control camera")
                self.viewModel.canControlCamera = true
            } else {
                Logger.shared.log("ZoomSessionCoordinator - Camera control request was denied")
                self.viewModel.canControlCamera = false
            }
        }
    }

}
