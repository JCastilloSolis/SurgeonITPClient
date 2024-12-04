//
//  ServerState.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//

import SwiftUI

struct ServerState: Codable {
    var zoomSessionID: String?
    //var selectedProcedure: ProcedureType
    var serverStatus: ServerStatus
}

enum ServerStatus: String, Codable {
    case idle
    case inZoomCall
    // Add other relevant states as needed
}
