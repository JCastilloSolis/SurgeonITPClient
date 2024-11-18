//
//  BeaconRegion.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/17/24.
//


import Foundation
import CoreBluetooth

/// A structure representing an iBeacon region.
struct BeaconRegion {
    
    // MARK: - Properties
    let proximityUUID: UUID
    let major: UInt16
    let minor: UInt16
    
    // MARK: - Initializer
    
    /**
     Initializes a new `BeaconRegion` with the specified UUID, major, and minor values.
     
     - Parameters:
       - proximityUUID: The UUID that uniquely identifies the beacon.
       - major: The major value for the beacon region.
       - minor: The minor value for the beacon region.
     */
    init(proximityUUID: UUID, major: UInt16, minor: UInt16) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
    }
    
    // MARK: - Methods
    
    /**
     Generates the peripheral data dictionary required to advertise as an iBeacon.
     
     - Parameter measuredPower: The measured power value (RSSI) at 1 meter from the beacon. Defaults to -59.
     
     - Returns: A dictionary containing the advertising data key and the corresponding beacon data.
     */
    func peripheralData(withMeasuredPower measuredPower: Int8 = -59) -> [String: Any] {
        let beaconKey = "kCBAdvDataAppleBeaconKey"
        var beaconBytes = [UInt8](repeating: 0, count: 21)
        
        // Extract UUID bytes
        let uuidBytes = withUnsafeBytes(of: proximityUUID.uuid) { Array($0) }
        for (index, byte) in uuidBytes.enumerated() {
            beaconBytes[index] = byte
        }
        
        // Insert major value (big endian)
        beaconBytes[16] = UInt8((major >> 8) & 0xFF)
        beaconBytes[17] = UInt8(major & 0xFF)
        
        // Insert minor value (big endian)
        beaconBytes[18] = UInt8((minor >> 8) & 0xFF)
        beaconBytes[19] = UInt8(minor & 0xFF)
        
        // Insert measured power
        beaconBytes[20] = UInt8(bitPattern: measuredPower)
        
        let beaconData = Data(beaconBytes)
        return [beaconKey: beaconData]
    }
}
