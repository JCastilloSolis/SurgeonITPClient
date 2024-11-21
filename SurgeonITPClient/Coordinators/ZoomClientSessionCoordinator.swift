//
//  ZoomClientSessionCoordinator.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import ZoomVideoSDK

class ZoomClientSessionCoordinator: NSObject, ZoomVideoSDKDelegate {
    var viewModel: SessionViewModel

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
    }

    func onSessionJoin() {
        Logger.shared.log("Session joined successfully")
        if let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas(),
           let myVideoIsOn = myUserVideoCanvas.videoStatus()?.on {
            DispatchQueue.main.async {
                self.viewModel.sessionIsActive = true
                self.viewModel.isVideoOn = myVideoIsOn
            }
        } else {
            Logger.shared.log("Failed to retrieve user's video status")
        }
    }

    func onSessionLeave() {
        Logger.shared.log("Session left")
        DispatchQueue.main.async {
            self.viewModel.sessionIsActive = false
        }
    }

    func onSessionLeave(_ reason: ZoomVideoSDKSessionLeaveReason) {
        Logger.shared.log("Session left: \(reason)")
    }

    func onUserVideoStatusChanged(_ helper: ZoomVideoSDKVideoHelper?, user userArray: [ZoomVideoSDKUser]?) {
        DispatchQueue.main.async {

            Logger.shared.log("video status changed: onUserVideoStatusChanged")

            self.viewModel.updateParticipants()
        }
    }

    func onUserAudioStatusChanged(_ helper: ZoomVideoSDKAudioHelper?, user userArray: [ZoomVideoSDKUser]?) {
        Logger.shared.log("Audio status changed: onUserAudioStatusChanged")

        self.viewModel.updateParticipants()
    }

    func onVideoCanvasSubscribeFail(_ failReason: ZoomVideoSDKSubscribeFailReason, user: ZoomVideoSDKUser?, view: UIView?) {
        Logger.shared.log("Video canvas subscribe failed: \(failReason) for \(user?.getName() ?? "unknown user")")
    }

    func onError(_ ErrorType: ZoomVideoSDKError, detail details: Int) {
        Logger.shared.log("ZoomCoordinator Error: \(ErrorType)")
    }

    func onUserJoin(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
        if let users = users {
            let userNames = users.compactMap { $0.getName() }
            Logger.shared.log("Users joined: \(userNames.joined(separator: ", "))")
        } else {
            Logger.shared.log("Users joined: 0")
        }
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onUserLeave(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
        if let users = users {
            let userNames = users.compactMap { $0.getName() }
            Logger.shared.log("Users left: \(userNames.joined(separator: ", "))")
        } else {
            Logger.shared.log("Users left")
        }
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onCmdChannelConnectResult(_ isSuccess: Bool) {
        DispatchQueue.main.async {
            if isSuccess {
                Logger.shared.log("Command channel is ready to be used")
                self.viewModel.commandsActive = true
                do {
                    try self.viewModel.requestCameraList()
                } catch {
                    Logger.shared.log("Failed to request camera list: \(error.localizedDescription)")
                }
            } else {
                Logger.shared.log("Command channel failed to connect")
                self.viewModel.commandsActive = false
            }
        }
    }

    func onCommandReceived(_ commandContent: String?, send sendUser: ZoomVideoSDKUser?) {
        Logger.shared.log("Command received")

        guard let commandContent = commandContent,
              let jsonData = commandContent.data(using: .utf8) else {
            Logger.shared.log("Invalid command content")
            return
        }

        do {
            let command = try JSONDecoder().decode(Command.self, from: jsonData)
            switch command.type {
                case .responseCameraList:
                    if case .cameraList(let cameras) = command.payload {
                        Logger.shared.log("Received camera list")
                        DispatchQueue.main.async {
                            self.viewModel.cameraList = cameras
                        }
                    }
                case .responseSwitchCamera:
                    if case .switchCameraResponse(let response) = command.payload {
                        Logger.shared.log("Switch camera response: Success=\(response.success), Message=\(response.message)")
                    }
                default:
                    Logger.shared.log("Received unsupported command type")
            }
        } catch {
            Logger.shared.log("Error decoding command: \(error.localizedDescription)")
        }
    }

    func onCameraControlRequestResult(_ user: ZoomVideoSDKUser?, approved isApproved: Bool) {
        DispatchQueue.main.async {
            if isApproved {
                Logger.shared.log("User is approved to control camera")
                self.viewModel.canControlCamera = true
            } else {
                Logger.shared.log("Camera control request was denied")
                self.viewModel.canControlCamera = false
            }
        }
    }

}
