//
//  MessageType.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//


enum MessageType: String {
    case command = "COMMAND:"
    case response = "RESPONSE:"
    case heartbeat = "HEARTBEAT:"

    var prefix: String {
        self.rawValue
    }

    static func determineType(from message: String) -> MessageType? {
        if message.starts(with: MessageType.command.prefix) {
            return .command
        } else if message.starts(with: MessageType.response.prefix) {
            return .response
        } else if message.starts(with: MessageType.heartbeat.prefix) {
            return .heartbeat
        }
        return nil
    }
}
