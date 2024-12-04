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
    @Published var sortedBeacons: [CLBeacon] = []
    @Published var nearestBeacon: CLBeacon?
    //TODO: Create a published var that represents if the device is inside a beacon region.
    private var locationManager: CLLocationManager?
    private let beaconUUID: UUID
    private let beaconIdentifier = "com.example.myBeacon"
    private var beaconConstraint: CLBeaconIdentityConstraint?
    private var notificationCenter: UNUserNotificationCenter


    override init() {
        guard let uuid = UUID(uuidString: Constants.iBeaconUUID) else {
            fatalError("Invalid Beacon UUID")
        }
        self.beaconUUID = uuid
        //TODO: Move notification code somewhere else
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        requestNotificationAuthorization()
        Logger.shared.log("BeaconManager initialized.")
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
    func startRangingBeacons() {
        Logger.shared.log("Starting to range and monitor beacons.")
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
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
//        let minimumTimeGap: TimeInterval = 5 * 60  // 5 minutes for testing
//        let lastNotificationDate = UserDefaults.standard.object(forKey: "LastNotificationDate") as? Date ?? Date.distantPast
//        let timeSinceLastNotification = Date().timeIntervalSince(lastNotificationDate)
//
//        guard timeSinceLastNotification >= minimumTimeGap else {
//            Logger.shared.log("Notification suppressed to prevent spamming.")
//            return
//        }

        Logger.shared.log("Creating notification: \(title) - \(body)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                Logger.shared.log("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                Logger.shared.log("Notification scheduled successfully.")
                UserDefaults.standard.set(Date(), forKey: "LastNotificationDate")
            }
        }
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

        guard !beacons.isEmpty else {
            sortedBeacons = []
            nearestBeacon = nil
            proximity = .unknown
            return
        }

        let sorted = sortBeacons(byProximity: beacons)
        sortedBeacons = sorted

        // Retrieve the nearest beacon
        if let nearest = sorted.first {
            nearestBeacon = nearest
            proximity = nearest.proximity

//            Logger.shared.log("""
//            Nearest Beacon - UUID: \(nearest.uuid),
//            Major: \(nearest.major),
//            Minor: \(nearest.minor),
//            Proximity: \(nearest.proximity.rawValue),
//            Accuracy: \(nearest.accuracy),
//            RSSI: \(nearest.rssi),
//            \(nearest.timestamp)
//            """)
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


    /// Assigns a numerical priority to a CLProximity value.
    /// Higher numbers represent higher priority.
    func proximityPriority(_ proximity: CLProximity) -> Int {
        switch proximity {
            case .immediate:
                return 4
            case .near:
                return 3
            case .far:
                return 2
            case .unknown:
                return 1
            @unknown default:
                return 0 // Handles any future cases gracefully
        }
    }

    /// Sorts an array of CLBeacon objects first by proximity priority, then by accuracy.
    /// - Parameter beacons: The array of beacons to sort.
    /// - Returns: A sorted array of beacons.
    func sortBeacons(byProximity beacons: [CLBeacon]) -> [CLBeacon] {
        return beacons.sorted { (beacon1, beacon2) -> Bool in
            let priority1 = proximityPriority(beacon1.proximity)
            let priority2 = proximityPriority(beacon2.proximity)

            if priority1 != priority2 {
                return priority1 > priority2 // Higher priority first
            } else {
                return beacon1.accuracy < beacon2.accuracy // Lower accuracy first
            }
        }
    }
}
