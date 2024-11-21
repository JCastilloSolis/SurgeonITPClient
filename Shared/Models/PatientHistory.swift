//
//  PatientHistory.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//



import Foundation

enum PatientHistory: String, Codable, CaseIterable {
    case priorSurgery = "Prior surgery"
    case reOP = "Re-op"
    case none = "None"
    
    var textForUI : String {
        return "\(PreopCaseCharacteristics.patientHistory.rawValue) : \(rawValue)"
    }
    
}

enum Emergent: String, Codable, CaseIterable  {
    case urgent = "Emergent/Urgent"
    case elective = "Elective"
    
    var textForUI : String {
        return rawValue
    }
}

enum BMI: String, Codable, CaseIterable  {
    case lessThan18 = "BMI < 18.5"
    case between18and25 = "18.5 ≤ BMI < 25"
    case between25and30 = "25 ≤ BMI < 30"
    case between30and40 = "30 ≤ BMI < 40"
    case moreThan40OrEqual = "BMI ≥ 40"
    
    var textForUI : String {
        return rawValue
    }
}

enum Malignancy: String, Codable, CaseIterable {
    case malignant = "Malignant"
    case benign = "Benign"
    
    var textForUI : String {
        return rawValue
    }
}

enum Teaching: String, Codable, CaseIterable {
    case yes = "Yes"
    case no = "No"
    
    var textForUI : String {
        return "\(PreopCaseCharacteristics.teaching.rawValue) : \(rawValue)"
    }
}

enum PrimarySurgeon: String, Codable, CaseIterable {
    case yes = "Yes"
    case no = "No"

    var textForUI : String {
        return "\(PreopCaseCharacteristics.primarySurgeon.rawValue) : \(rawValue)"
    }
}


enum PreopCaseCharacteristics: String, Codable, CaseIterable {
    case teaching = "Teaching"
    case primarySurgeon = "Primary Surgeon"
    case patientHistory = "Patient History"
    case emergent = "Emergent"
    case bmi = "BMI"
    case malignancy = "Malignancy"
    
    var userDefaultsKey: String {
        return "\(rawValue).characteristic"
    }
}

// These are set once
struct SurgicalProcedureCharacteristicsModel: Codable {
    let teaching: Teaching
    let patientHistory: PatientHistory
    let emergent: Emergent
    let bmi: BMI
    let malignancy: Malignancy
}

// These can be
struct TrainingProcedureCharacteristicsModel: Codable {
    let sutureCondition: SutureCondition
    let ailLenght: AilLength
    let knotFormation: KnotFormation
}

struct ProcedureConfigurationModel: Codable{
    let surgeonName: String
    let surgeonLastName: String
    let procedureType: String
    var surgicalCharacteristics: SurgicalProcedureCharacteristicsModel? = nil
    var trainingCharacteristics: TrainingProcedureCharacteristicsModel? = nil
    let timeStamp: Date
}

// MARK: - internal
extension ProcedureConfigurationModel {
    init(data: Data) throws {
        self = try PropertyListDecoder().decode(Self.self, from: data)
    }
}

extension Data {
    init(procedureConfiguration: ProcedureConfigurationModel) throws {
        self = try PropertyListEncoder().encode(procedureConfiguration)
    }
}
