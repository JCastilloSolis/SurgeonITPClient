//
//  BeaconManagerService.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/4/24.
//

import SwiftUI
import CoreLocation
import UserNotifications

/// Manages beacon detection, ranging, and push notifications.
@MainActor
class BeaconManagerService: NSObject, ObservableObject {
    @Published var proximity: CLProximity = .unknown
    @Published var mpcService: ClientManagerService?
    private var locationManager: CLLocationManager?
    private let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096F9")!
    private let beaconIdentifier = "com.example.myBeacon"
    private var beaconConstraint: CLBeaconIdentityConstraint?
    private var notificationCenter: UNUserNotificationCenter


    override init() {
        Logger.shared.log("BeaconManager initialized.")
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        requestNotificationAuthorization()
    }

    /// Requests user authorization for notifications.
    private func requestNotificationAuthorization() {
        Logger.shared.log("Requesting notification authorization.")
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                Logger.shared.log("Notification authorization error: \(error.localizedDescription)")
            } else {
                Logger.shared.log("Notification authorization granted: \(granted)")
            }
        }
    }

    /// Starts scanning and monitoring for beacons.
    func startScanning() {
        Logger.shared.log("Starting beacon scanning.")
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.requestAlwaysAuthorization()
    }

    /// Initiates beacon ranging and monitoring.
    private func startRangingBeacons() {
        Logger.shared.log("Starting to range and monitor beacons.")
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
        beaconConstraint = constraint
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconIdentifier)
        beaconRegion.notifyEntryStateOnDisplay = true
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: constraint)
    }

    /// Stops ranging beacons.
    func stopRangingBeacons() {
        Logger.shared.log("Stopping beacon ranging.")
        if let constraint = beaconConstraint {
            locationManager?.stopRangingBeacons(satisfying: constraint)
        }
    }

    /// Creates and schedules a local notification.
    private func createNotification(title: String, body: String) {
        //TODO: Keep track of the last time a notification was created
        /// Have a time gap between each local push notification to be at least x amounts of minutes
        /// For Testing 5 minutes, For demos 20 minutes
        ///
        ///
        // TODO: Save data into user defauls or coreData along with the beaconId
        Logger.shared.log("Creating notification: \(title) - \(body)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.log("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                Logger.shared.log("Notification scheduled successfully.")
            }
        }
    }

    /// Starts MultipeerConnectivity browsing.
    private func startMPCBrowsing() {
        Logger.shared.log("Starting MPC browsing.")
        if mpcService == nil {
            mpcService = ClientManagerService()
        }
        mpcService?.startBrowsing()
    }

    /// Stops MultipeerConnectivity browsing.
    private func stopMPCBrowsing() {
        Logger.shared.log("Stopping MPC browsing.")
        mpcService?.stopBrowsing()
        mpcService = nil
    }

}

extension BeaconManagerService: CLLocationManagerDelegate {
    /// Called when the location manager's authorization status changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Logger.shared.log("Location authorization status changed: \(status.rawValue).")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startRangingBeacons()
        } else {
            Logger.shared.log("Location authorization not granted.")
        }
    }

    /// Called when beacons are ranged in the specified region.
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
        guard let nearestBeacon = beacons.first else {
            // No beacons detected; stop browsing if necessary
            if proximity != .unknown {
                Logger.shared.log("Beacon lost. Stopping MPC browsing.")
                proximity = .unknown
                stopMPCBrowsing()
            }
            return
        }

        let previousProximity = proximity
        proximity = nearestBeacon.proximity
        Logger.shared.log("Beacon detected with proximity: \(proximityDescription(proximity)).")

        if proximity != .unknown && previousProximity == .unknown {
            // Just started detecting the beacon; start MPC browsing
            createNotification(title: "Beacon Detected", body: "You are near the beacon.")
            startMPCBrowsing()
        } else if proximity == .unknown && previousProximity != .unknown {
            // Beacon was lost; stop MPC browsing
            Logger.shared.log("Beacon lost. Stopping MPC browsing.")
            stopMPCBrowsing()
        }
    }


    /// Called when entering a beacon region.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.shared.log("Entered region: \(region.identifier)")
        createNotification(title: "Entered Region", body: "You have entered the beacon region.")
    }

    /// Called when exiting a beacon region.
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.shared.log("Exited region: \(region.identifier)")
        createNotification(title: "Exited Region", body: "You have exited the beacon region.")
    }

    /// Helper method to convert CLProximity to a string description.
    private func proximityDescription(_ proximity: CLProximity) -> String {
        switch proximity {
            case .immediate:
                return "Immediate"
            case .near:
                return "Near"
            case .far:
                return "Far"
            default:
                return "Unknown"
        }
    }
}
