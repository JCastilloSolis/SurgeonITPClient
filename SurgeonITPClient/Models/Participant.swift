//
//  Participant.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//


import Foundation
import ZoomVideoSDK

struct Participant : Identifiable {
    let id: String
    let name: String
    let isVideoOn: Bool
    let isAudioOn: Bool
    var videoCanvas: ZoomVideoSDKVideoCanvas?
}
