//
//  AppDelegate.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/4/24.
//


import UIKit
import UserNotifications
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    var notificationCenter: UNUserNotificationCenter!
    private var monitor: CLMonitor?
    private var authSession: CLServiceSession?
    private let beacons: [BeaconData] = [
        .init(major: 1, minor: 1),
        .init(major: 1, minor: 2),
        .init(major: 1, minor: 6)
    ]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.shared.log("AppDelegate: Application did finish launching.")


        self.notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound, .criticalAlert]

        notificationCenter.requestAuthorization(options: options) { _, error in
            if let error = error {
                print("Error: \(error)")
            }
        }

        //TODO: Initialize geofencing here
        Task {
            await setupGeofence()
        }

        return true
    }

    func setupGeofence() async {
        Logger.shared.log("Setting up beacon background tracking")

        authSession = CLServiceSession(authorization: .always, fullAccuracyPurposeKey: "monitor")

        if monitor == nil {
            monitor = await CLMonitor("MonitorID")
        }

        for beacon in beacons {
            Logger.shared.log("monitoring \(beacon.description)")
            let beaconCondition =  CLMonitor.BeaconIdentityCondition(uuid: beacon.uuid, major: beacon.major, minor: beacon.minor)
            await monitor?.add(beaconCondition, identifier: "IDR_Device_\(beacon.uuid.uuidString)_\(beacon.major)_\(beacon.minor)", assuming: .unknown)
        }


        Task {
            guard let monitor else { return }

            for try await event in await monitor.events {
                Logger.shared.log("New event received: \(event.identifier)  \(event.state)   \(event.date)")
                switch event.state {
                    case .satisfied:
                        if event.identifier.contains("IDR_Device") {
                            Logger.shared.log(" \(event.identifier) found")
                            createNotificationWith(title: "Great news!", body: "You found \(event.identifier)")
                        } else {
                            Logger.shared.log("User satisfied event \(event.identifier)")
                        }
                    case .unsatisfied:
                        if event.identifier.contains("IDR_Device") {
                            Logger.shared.log(" \(event.identifier) lost")
                            createNotificationWith(title: "Connection lost", body: "Get closer to \(event.identifier)")
                        } else {
                            Logger.shared.log("User unsatisfied event \(event.identifier)")
                        }
                    case .unknown: // here you will receive the callback when user leaves in the region
                        Logger.shared.log("unkown state for monitored event \(event.identifier)")
                    case  .unmonitored:
                        Logger.shared.log("unmonitored state for monitored event \(event.identifier)")
                    default:
                        Logger.shared.log("No Location Registered \(event.identifier)")

                }
            }
        }

    }

    func createNotificationWith(title: String, body: String) {

        //        let minimumTimeGap: TimeInterval = 60  // 60 seconds for testing
        //        let lastNotificationDate = UserDefaults.standard.object(forKey: "LastNotificationDate") as? Date ?? Date.distantPast
        //        let timeSinceLastNotification = Date().timeIntervalSince(lastNotificationDate)
        //
        //        guard timeSinceLastNotification >= minimumTimeGap else {
        //            Logger.shared.log("Notification suppressed to prevent spamming.")
        //            return
        //        }

        Logger.shared.log("createNotificationWith title: \(title). Body: \(body)")
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.log("Failed to schedule notification: \(error)")
            }
        }

        UserDefaults.standard.set(Date(), forKey: "LastNotificationDate")
    }
}





extension AppDelegate: UNUserNotificationCenterDelegate {

    // Handle notification when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Logger.shared.log("Notification will present: \(notification.request.content.title)")
        completionHandler([.banner, .sound, .list])
    }

    // Handle user's response to notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // get the notification identifier to respond accordingly
        let identifier = response.notification.request.identifier

        Logger.shared.log("Notification did receive response: \(response.notification.request.content.title) for \(identifier)")

        completionHandler()
    }
}
