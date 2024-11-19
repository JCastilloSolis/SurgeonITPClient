//
//  ProcedureType.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//

import Foundation

enum ProcedureType: String, CaseIterable, Identifiable {
    case cholecystectomy
    case inguinalHernia
    case prostatectomy
    case lobectomy
    case hysterectomy
    case lowAnteriorResection
    case TR100
    case notSet
    
    static var userDefaultsKey: String {
        return "ProcedureType"
    }
    
    var id: String { self.rawValue }

    var rawValue: String {
        switch self {
        case .cholecystectomy:
            return "cholecystectomy"
        case .inguinalHernia:
            return "inguinalHernia"
        case .prostatectomy:
            return "prostatectomy"
        case .lobectomy:
            return "lobectomy"
        case .hysterectomy:
            return "hysterectomy"
        case .lowAnteriorResection:
            return "lowAnteriorResection"
        case .TR100:
            return "TR100 - Training"
        default:
            return "not set"
        }
    }
    
    init(fromRawValue: String) {
        switch fromRawValue {
        case ProcedureType.cholecystectomy.rawValue :
            self = .cholecystectomy
        case ProcedureType.inguinalHernia.rawValue :
            self = .inguinalHernia
        case ProcedureType.prostatectomy.rawValue :
            self = .prostatectomy
        case ProcedureType.lobectomy.rawValue :
            self = .lobectomy
        case ProcedureType.hysterectomy.rawValue :
            self = .hysterectomy
        case ProcedureType.lowAnteriorResection.rawValue :
            self = .lowAnteriorResection
        case ProcedureType.TR100.rawValue:
            self = .TR100
        default:
            self = .notSet
        }
    }
}
