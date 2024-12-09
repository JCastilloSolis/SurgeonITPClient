//
//  Constants.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/17/24.
//


class Constants {

    // TODO: should be in a DB at some point, maybe firebase 
    //ZOOM
    static let zoomAPIKey = "vWORwGngSfyZ4PIio6bqCg"
    static let zoomAPISecret = "i3II29cNHHnL98vc0qGtVbp3SrVC3yYv2vIT"
    static let zoomAPIDomain = "https://zoom.us"

    // TODO: should be in a DB at some point, maybe firebase
    // iBeacon
    static let iBeaconUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096F9"
    static let beaconToPeerDisplayNameMap: [BeaconData: String] = [
        BeaconData(major: 1, minor: 1): "YN4Y736WLT",
        BeaconData(major: 1, minor: 2): "T9RX65X75K",
        BeaconData(major: 1, minor: 6): "H2WHW0RZQ6NY",
        //BeaconData(major: 1, minor: 6): "TLFQLV75MJ",
        // Add more mappings as needed
    ]


    // MPC
    static let mpcServiceType = "idr-itp-service"


}
