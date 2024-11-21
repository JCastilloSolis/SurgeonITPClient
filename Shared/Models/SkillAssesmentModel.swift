//
//  AilLength.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//


import Foundation

enum AilLength: String, Codable, SkillAssesment {
    case appropriate
    case long
    case short

    static let promptText: String = "Describe the condition of the \(SurgeonSkills.ailLenght.rawValue)"

    var textForUI: String {
        "\(SurgeonSkills.ailLenght.rawValue): \(rawValue)"
    }
}

enum KnotFormation: String, Codable, CaseIterable, SkillAssesment {
    case appropriate
    case nonSquare = "Non-square"
    case air
    
    static let promptText: String = "Describe the condition of the \(SurgeonSkills.knotFormation.rawValue)"

    var textForUI: String {
        "\(SurgeonSkills.knotFormation.rawValue) : \(rawValue)"
    }
}

enum SutureCondition: String, Codable, CaseIterable, SkillAssesment {
    case appropriate
    case frayed
    case broken
    
    static let promptText: String = "Describe the \(SurgeonSkills.sutureCondition.rawValue)"

    var textForUI : String {
        "\(SurgeonSkills.sutureCondition.rawValue): \(rawValue)"
    }
}


enum SurgeonSkills: String, Codable, CaseIterable, SkillAssesment {
    case ailLenght = "Ail Length"
    case knotFormation = "Knot Formation"
    case sutureCondition = "Suture Condition"
    
    static let promptText: String = "Which Surgeon skill would you like to Asses?"

    var textForUI: String {
        ""
    }

    var userDefaultsKey: String {
        "\(rawValue).characteristic"
    }
}
