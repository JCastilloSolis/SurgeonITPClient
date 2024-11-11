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
        print("- ZoomSessionCoordinator - Session joined successfully")
        if let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
           // Get User's video canvas
           let myUserVideoCanvas = myUser.getVideoCanvas() {
            if let myVideoIsOn = myUserVideoCanvas.videoStatus()?.on,
               myVideoIsOn == false {
                DispatchQueue.main.async {
                    self.viewModel.sessionIsActive = true
                }

            } else {
                print("No video status or it was on")
            }
        }
    }

    func onSessionLeave() {
        print("-  ZoomSessionCoordinator - Session left")
        DispatchQueue.main.async {
            self.viewModel.sessionIsActive = false
        }
    }

    func onUserVideoStatusChanged(_ helper: ZoomVideoSDKVideoHelper?, user: ZoomVideoSDKUser?, videoStatus: ZoomVideoSDKVideoStatus?) {
        guard let isVideoOn = videoStatus?.on else { return }
        DispatchQueue.main.async {
            self.viewModel.isVideoOn = isVideoOn
            print("- ZoomSessionCoordinator - Video status changed: \(isVideoOn)")
        }
    }

    func onUserAudioStatusChanged(_ helper: ZoomVideoSDKAudioHelper?, user: ZoomVideoSDKUser?, audioStatus: ZoomVideoSDKAudioStatus?) {
        guard let isAudioMuted = audioStatus?.isMuted else { return }
        DispatchQueue.main.async {
            self.viewModel.isAudioMuted = isAudioMuted
            print("- ZoomSessionCoordinatorAudio -  status changed: \(isAudioMuted)")
        }
    }

    func onUserJoin(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
        print("- Coordinator - Users joined: \(users?.count ?? 0)")
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onUserLeave(_ userHelper: ZoomVideoSDKUserHelper?, users: [ZoomVideoSDKUser]?) {
        print("- Coordinator - Users left")
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onCmdChannelConnectResult(_ isSuccess: Bool) {
        if (isSuccess) {
            // Command channel is ready for use.
            DispatchQueue.main.async {
                print("Command channel is ready to be used")
                self.viewModel.commandsActive = true

                try? self.viewModel.requestCameraList()

            }
        }
    }

    func onCommandReceived(_ commandContent: String?, send sendUser: ZoomVideoSDKUser?) {
        // Respond to the command here
        print("Command received -")

        guard let jsonData = commandContent?.data(using: .utf8),
              let command = try? JSONDecoder().decode(Command.self, from: jsonData) else {
            print("Error decoding command")
            return
        }

        switch command.type {
            case .responseCameraList:
                if case .cameraList(let cameras) = command.payload {
                    print("Received camera list:", cameras)
                    DispatchQueue.main.async {
                        self.viewModel.cameraList = cameras
                    }
                }
            case .responseSwitchCamera:
                print("response switch camera")
                if case .switchCameraResponse(let response) = command.payload {
                    print("Switch camera response: \(response.success). \(response.message)")
                }
            default:
                print("Received unsupported command type")
        }
    }

    func onCameraControlRequestResult(_ user: ZoomVideoSDKUser?, approved isApproved: Bool) {
        if isApproved {
            DispatchQueue.main.async {
                print("User is approved to control camera")
                self.viewModel.canControlCamera = true
            }

        }
    }

}
