//
//  ZoomSessionCoordinator.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import ZMVideoSDK

class ZoomSessionCoordinator: NSObject, ZMVideoSDKDelegate {
    var viewModel: SessionViewModel

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
    }

    func onSessionJoin() {
        print("- ZoomSessionCoordinator - Session joined successfully")
        if let myUser = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           // Get User's video canvas
           let myUserVideoCanvas = myUser.getVideoCanvas() {
                DispatchQueue.main.async {
                    self.viewModel.sessionIsActive = true
                    //                    myUserVideoCanvas.subscribe(with: self.canvasView, aspectMode: .panAndScan, andResolution: ._Auto)
                }
        }
    }

    func onSessionLeave() {
        print("-  ZoomSessionCoordinator - Session left")
        DispatchQueue.main.async {
            self.viewModel.sessionIsActive = false
        }
    }

    func onUserVideoStatusChanged(_ helper: ZMVideoSDKVideoHelper?, user: ZMVideoSDKUser?, videoStatus: ZMVideoSDKVideoStatus?) {
        guard let isVideoOn = videoStatus?.isOn else { return }
        DispatchQueue.main.async {
            self.viewModel.isVideoOn = !isVideoOn
            print("- ZoomSessionCoordinator - Video status changed: \(isVideoOn)")
        }
    }

    func onUserAudioStatusChanged(_ helper: ZMVideoSDKAudioHelper?, user: ZMVideoSDKUser?, audioStatus: ZMVideoSDKAudioStatus?) {
        guard let isAudioMuted = audioStatus?.isMuted else { return }
        DispatchQueue.main.async {
            self.viewModel.isAudioMuted = isAudioMuted
            print("- ZoomSessionCoordinatorAudio -  status changed: \(isAudioMuted)")
        }
    }

    func onUserJoin(_ userHelper: ZMVideoSDKUserHelper, userList users: [ZMVideoSDKUser]?) {
        print("- ZoomSessionCoordinator - Users joined: \(users?.count ?? 0)")
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onUserLeave(_ userHelper: ZMVideoSDKUserHelper, userList users: [ZMVideoSDKUser]?) {
        print("- ZoomSessionCoordinator - Users left")
        DispatchQueue.main.async {
            self.viewModel.updateParticipants()
        }
    }

    func onError(_ ErrorType: ZMVideoSDKErrors, detail details: Int32) {
        print("On Error method called")
        switch ErrorType {
            case ZMVideoSDKErrors_Success:
                // Your ZMVideoSDK operation was successful.
                print("ZMVideoSDKDelegate - onError - Success")
            default:
                // Your ZMVideoSDK operation raised an error.
                // Refer to error code documentation.
                print("-ZMVideoSDKDelegate - onError - Error \(ErrorType) \(details)")
                return
        }
    }

    func onCommandChannelConnectResult(_ isSuccess: Bool) {
        if (isSuccess) {
            DispatchQueue.main.async {
                print("Command channel is ready to be used")
                self.viewModel.commandsActive = true
                self.viewModel.sendCameraList(to: nil)
            }
        }
    }

    func onCommandReceived(_ commandContent: String?, senderUser user: ZMVideoSDKUser?) {
        guard let jsonData = commandContent?.data(using: .utf8),
              let command = try? JSONDecoder().decode(Command.self, from: jsonData) else {
            print("-onCommandReceived- Error decoding command")
            return
        }

        switch command.type {
            case .requestCameraList:
                print("Request Camera List command received")
                viewModel.sendCameraList(to: user)
            case .requestSwitchCamera:
                if case .selectedCameraID(let cameraID) = command.payload {
                    viewModel.switchCamera(to: cameraID)
                }
            default:
                print("Received unsupported command type")
        }
    }

    func onCameraListChanged() {
        //TODO: update list
    }

    func onCameraControlRequestReceived(_ user: ZMVideoSDKUser?, cameraControlRequestType requestType: ZMVideoSDKCameraControlRequestType, requestHandler cameraControlRequestHandler: ZMVideoSDKCameraControlRequestHandler?) {

        switch requestType {
            case ZMVideoSDKCameraControlRequestType_RequestControl :
                print("RequestControl onCameraControlRequestReceived from \(user?.getName())")
                cameraControlRequestHandler?.approve()
            case ZMVideoSDKCameraControlRequestType_GiveUpControl:
                print(" GiveUpControl onCameraControlRequestReceived from \(user?.getName())")
                cameraControlRequestHandler?.approve()
            default:
                break
        }
    }


    
}
