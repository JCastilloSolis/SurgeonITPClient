//
//  Command.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//

import Foundation


/// Represents the response when attempting to switch cameras.
struct SwitchCameraResponse: Codable {
    var success: Bool
    var message: String?
}

/// Enum representing different payloads that can be sent in a zoom command.
enum Payload: Codable {
    case empty
    case cameraList([Camera])
    case selectedCameraID(String)
    case switchCameraResponse(SwitchCameraResponse)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .empty:
                try container.encode("empty")
            case .cameraList(let cameras):
                try container.encode(cameras)
            case .selectedCameraID(let cameraID):
                try container.encode(cameraID)
            case .switchCameraResponse(let response):
                try container.encode(response)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Attempt to decode each possible payload type
        if let str = try? container.decode(String.self), str == "empty" {
            self = .empty
        } else if let cameras = try? container.decode([Camera].self) {
            self = .cameraList(cameras)
        } else if let cameraID = try? container.decode(String.self) {
            self = .selectedCameraID(cameraID)
        } else if let response = try? container.decode(SwitchCameraResponse.self) {
            self = .switchCameraResponse(response)
        } else {
            Logger.shared.log("Payload - Failed to decode payload")
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Data cannot be decoded"))
        }
    }
}


//TODO: Rename to include zoom relationship 
/// Command struct for sending and receiving command data over the zoom command channel.
struct Command: Codable {
    enum CommandType: String, Codable {
        case requestCameraList
        case responseCameraList
        case requestSwitchCamera
        case responseSwitchCamera
    }

    var type: CommandType
    var payload: Payload

    init(type: CommandType, payload: Payload) {
        self.type = type
        self.payload = payload
    }
}
