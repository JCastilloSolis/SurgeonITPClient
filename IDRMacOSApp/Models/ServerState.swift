//
//  ServerState.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//

import SwiftUI

struct ServerState: Codable {
    var isInZoomCall: Bool
    var zoomSessionID: String?
    var participantCount: Int
    //var selectedProcedure: ProcedureType
    var serverStatus: ServerStatus
}

enum ServerStatus: String, Codable {
    case idle
    case discovering
    case connecting
    case connected
    case inZoomCall
    // Add other relevant states as needed
}
