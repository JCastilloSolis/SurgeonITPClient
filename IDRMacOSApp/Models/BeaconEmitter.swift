//
//  BeaconEmitter.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/17/24.
//


import CoreBluetooth

// Ensure your class conforms to CBPeripheralManagerDelegate
class BeaconEmitter: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    var beaconRegion: BeaconRegion!

    override init() {
        super.init()
        
        // Initialize the BeaconRegion with desired UUID, major, and minor
        let uuid = UUID(uuidString: Constants.iBeaconUUID)!
        beaconRegion = BeaconRegion(proximityUUID: uuid, major: 1, minor: 1)
        Logger.shared.log("Beacon region created using \(Constants.iBeaconUUID)")

        // Initialize the Peripheral Manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // CBPeripheralManagerDelegate method
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            // Start advertising as an iBeacon
            let advertisementData = beaconRegion.peripheralData(withMeasuredPower: -59)
            peripheralManager.startAdvertising(advertisementData)
            Logger.shared.log("Started advertising as iBeacon")
        } else {
            Logger.shared.log("Peripheral Manager is not powered on")
        }
    }
}
