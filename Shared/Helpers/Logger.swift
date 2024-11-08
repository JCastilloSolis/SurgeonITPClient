//
//  Logger.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/4/24.
//


//
//  Logger.swift
//  geofencingDemo
//
//  Created by Jorge Castillo on 9/9/24.
//


import Foundation

class Logger {
    static let shared = Logger() // Singleton instance for global access
    private var logs: [String] = []
    
    // Function to log a message with a timestamp
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        let logMessage = "[\(timestamp)] \(message)"
        logs.append(logMessage)
        print(logMessage) // You can also save this to a file if needed
    }
    
    // Optional: Function to get all logs (for UI or file output)
    func getLogs() -> [String] {
        return logs
    }
}
