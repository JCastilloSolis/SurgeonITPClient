//
//  SkillAssesment.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//



import Foundation

protocol SkillAssesment: CaseIterable, Equatable {
    static var promptText: String { get }
    
    var voiceCommandNumber: Int { get }
    var voiceCommandText: String { get }
    var textForUI: String { get }
}

extension SkillAssesment {
    var voiceCommandNumber: Int {
        let idxs = Self.allCases.enumerated()
        return idxs.first { $0.element == self }.map { $0.offset + 1 } ?? -1
    }
    
    var voiceCommandText: String {
        guard (1...9).contains(voiceCommandNumber) else {
            Logger.shared.log("Trying to get SpokenString for number greater than 9")
            return ""
        }
        return ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"][voiceCommandNumber - 1]
    }
}
