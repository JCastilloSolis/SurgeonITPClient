//
//  Logger.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/4/24.
//

import Foundation

class Logger {
    static let shared = Logger()

    private init() {}

    func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] \(message)")
    }
}
