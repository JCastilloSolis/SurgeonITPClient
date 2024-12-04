//
//  BeaconData.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 12/3/24.
//


import CoreLocation
struct BeaconData : Hashable {
    let uuid: UUID = UUID(uuidString: Constants.iBeaconUUID)!
    let major: UInt16
    let minor: UInt16
    var description: String {
        return "uuid:\(uuid), major:\(major), minor:\(minor)"
    }
}
