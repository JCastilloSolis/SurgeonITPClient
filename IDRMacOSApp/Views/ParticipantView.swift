//
//  ParticipantView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import ZMVideoSDK
import SwiftUI

struct ParticipantView: NSViewRepresentable {
    var participant: Participant

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.needsDisplay = true
        view.needsLayout = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.gray.cgColor
        if let canvas = participant.videoCanvas {
            canvas.subscribe(with: view, aspectMode: ZMVideoSDKVideoAspect_LetterBox, resolution: ZMVideoSDKResolution_360P)
        }
        return view
    }

    func updateNSView(_ uiView: NSView, context: Context) {
        // Subscription might need to be refreshed if video settings change
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        // Properly unsubscribe when the view is not longer used
        if let myUser = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas() {
            myUserVideoCanvas.unSubscribe(with: nsView)
        }
    }
}