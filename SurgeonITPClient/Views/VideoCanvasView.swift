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

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        subscribeVideoCanvas(to: view, participantID: participantID)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        subscribeVideoCanvas(to: uiView, participantID: participantID)
    }

    private func subscribeVideoCanvas(to view: UIView, participantID: String?) {
        let session = ZoomVideoSDK.shareInstance()?.getSession()
        let users = session?.getRemoteUsers()?.compactMap { $0 as ZoomVideoSDKUser } ?? []

        // Determine the user to subscribe to
        let user: ZoomVideoSDKUser? = {
            if let participantID = participantID,
               let intValue: Int = Int(participantID),
               let foundUser = users.first(where: { $0.getID() == intValue }) {
                return foundUser
            }
            return session?.getMySelf() // Default to the local user if no participant is pinned
        }()

        if let videoCanvas = user?.getVideoCanvas() {
            videoCanvas.subscribe(with: view, aspectMode: .original, andResolution: ._Auto)
            print("- VideoCanvasView - Subscribe to video canvas for user \(user?.getName() ?? "unknown")")
        }
    }
}
