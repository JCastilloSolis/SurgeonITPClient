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

    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    /// Logs a message with a timestamp, log level, thread info, and the calling class name.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level (default is `.info`).
    ///   - file: The file from which the log is called (automatically provided).
    ///   - function: The function from which the log is called (automatically provided).
    ///   - line: The line number from which the log is called (automatically provided).
    func log(_ message: String,
             level: LogLevel = .info,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.components(separatedBy: ".").first ?? fileName

        // Determine the thread info
        let threadName: String
        if Thread.isMainThread {
            threadName = "Main Thread"
        } else if let name = Thread.current.name, !name.isEmpty {
            threadName = "Thread \(name)"
        } else {
            threadName = "Thread \(Thread.current)"
        }

        print("[\(timestamp)] [\(level.rawValue)] [\(threadName)] [\(className).\(function):\(line)] \(message)")
    }
}
