//
//  VideoCanvasView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//
import SwiftUI
import ZoomVideoSDK

struct VideoCanvasView: UIViewRepresentable {
    @EnvironmentObject var viewModel: SessionViewModel
    var participantID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateVideoCanvas(for: uiView, participantID: participantID)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.unsubscribeVideoCanvas(from: uiView)
    }

    class Coordinator {
        var lastVideoCanvas: ZoomVideoSDKVideoCanvas?

        func updateVideoCanvas(for view: UIView, participantID: String?) {
            // Unsubscribe from previous video canvas
            if let lastCanvas = lastVideoCanvas {
                lastCanvas.unSubscribe(with: view)
                Logger.shared.log("- VideoCanvasView - Unsubscribed from previous video canvas")
            }

            // Subscribe to the new participant's video canvas
            guard let participantID = participantID,
                  let intParticipantID = Int(participantID),
                  let session = ZoomVideoSDK.shareInstance()?.getSession(),
                  let user = session.getRemoteUsers()?.compactMap({ $0 as? ZoomVideoSDKUser }).first(where: { $0.getID() == intParticipantID }),
                  let videoCanvas = user.getVideoCanvas(),
                  ZoomVideoSDK.shareInstance()?.isInSession() == true
            else {
                Logger.shared.log("- VideoCanvasView - Participant not found or not in session")
                lastVideoCanvas = nil
                return
            }

            let sdkReturnStatus = videoCanvas.subscribe(
                with: view,
                aspectMode: .letterBox,
                andResolution: ._360
            )

            if sdkReturnStatus == ZoomVideoSDKError.Errors_Success {
                Logger.shared.log("- VideoCanvasView - Subscribed to video canvas for user \(user.getName())")
                lastVideoCanvas = videoCanvas
            } else {
                Logger.shared.log("- VideoCanvasView - Subscription failed: \(sdkReturnStatus.rawValue)")
            }
        }

        func unsubscribeVideoCanvas(from view: UIView) {
            if let lastCanvas = lastVideoCanvas {
                lastCanvas.unSubscribe(with: view)
                Logger.shared.log("- VideoCanvasView - Unsubscribed in dismantleUIView")
            }
        }
    }
}
