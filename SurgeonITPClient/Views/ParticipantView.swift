//
//  ParticipantView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//


import Foundation
import ZoomVideoSDK
import SwiftUI

struct ParticipantView: UIViewRepresentable {
    var participant: Participant

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .gray  // Default background if no video
        if let canvas = participant.videoCanvas {
            canvas.subscribe(with: view, aspectMode: .original, andResolution: ._180)
            Logger.shared.log("subscribing to \(participant.id) video canvas")
        } else {
            Logger.shared.log("Not able to render video for \(participant.id)")
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Subscription might need to be refreshed if video settings change
    }
}
