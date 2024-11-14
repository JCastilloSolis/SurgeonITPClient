//
//  MessageType.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//

/// Represents the type of message in the MPC communication protocol.
enum MPCMessageType: String, Codable {
    case command
    case response
    case heartbeat
    // Add other message types as needed
}

// MARK: Commands
/// Represents the command types that can be sent from the iOS client to the macOS server.
enum MPCCommandType: String, Codable {
    case startZoomCall
    case endZoomCall
    // Add other command types as needed
}

/// Protocol that all MPC command data structures conform to.
protocol MPCCommandData: Codable {}

/// Payload for the Start Zoom Call command.
struct MPCStartZoomCallCommand: MPCCommandData {
    // No additional data required
}

/// Payload for the End Zoom Call command.
struct MPCEndZoomCallCommand: MPCCommandData {
    // No additional data required
}

//MARK: Responses

/// Represents the status of a response from the macOS server.
enum MPCResponseStatus: String, Codable {
    case success
    case failure
}

/// Protocol that all MPC response data structures conform to.
protocol MPCResponseData: Codable {}

/// Response payload for the Start Zoom Call command.
struct MPCStartZoomCallResponse: MPCResponseData {
    let sessionName: String
}

/// Response payload for the End Zoom Call command.
struct MPCEndZoomCallResponse: MPCResponseData {
    let message: String?
}

/// Response payload for error responses.
struct MPCErrorResponse: MPCResponseData {
    let errorCode: Int
    let errorMessage: String
}

//MARK: Payloads

/// Represents the payload of an MPC message.
enum MPCPayload: Codable {
    case command(MPCCommandType, MPCCommandData)
    case response(MPCCommandType, MPCResponseStatus, MPCResponseData?)

    enum CodingKeys: String, CodingKey {
        case type
        case commandType
        case status
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let messageType = try container.decode(String.self, forKey: .type)

        switch messageType {
            case MPCMessageType.command.rawValue:
                let commandType = try container.decode(MPCCommandType.self, forKey: .commandType)
                let data = try MPCPayload.decodeCommandData(commandType: commandType, decoder: decoder)
                self = .command(commandType, data)
            case MPCMessageType.response.rawValue:
                let commandType = try container.decode(MPCCommandType.self, forKey: .commandType)
                let status = try container.decode(MPCResponseStatus.self, forKey: .status)
                let data = try MPCPayload.decodeResponseData(commandType: commandType, decoder: decoder)
                self = .response(commandType, status, data)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type,
                                                       in: container,
                                                       debugDescription: "Unknown message type: \(messageType)")
        }
    }

    // Helper methods for decoding command and response data
    static func decodeCommandData(commandType: MPCCommandType, decoder: Decoder) throws -> MPCCommandData {
        switch commandType {
            case .startZoomCall:
                return try MPCStartZoomCallCommand(from: decoder)
            case .endZoomCall:
                return try MPCEndZoomCallCommand(from: decoder)
        }
    }

    static func decodeResponseData(commandType: MPCCommandType, decoder: Decoder) throws -> MPCResponseData? {
        switch commandType {
            case .startZoomCall:
                return try MPCStartZoomCallResponse(from: decoder)
            case .endZoomCall:
                return try MPCEndZoomCallResponse(from: decoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .command(let commandType, let data):
                try container.encode(MPCMessageType.command.rawValue, forKey: .type)
                try container.encode(commandType, forKey: .commandType)
                try data.encode(to: encoder)
            case .response(let commandType, let status, let data):
                try container.encode(MPCMessageType.response.rawValue, forKey: .type)
                try container.encode(commandType, forKey: .commandType)
                try container.encode(status, forKey: .status)
                if let data = data {
                    try data.encode(to: encoder)
                }
        }
    }
}


// MARK: Message

/// Represents an MPC message containing the message type and payload.
struct MPCMessage: Codable {
    let messageType: MPCMessageType
    let payload: MPCPayload
}
