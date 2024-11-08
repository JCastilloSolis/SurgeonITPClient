//
//  AppDelegate.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/4/24.
//


import UIKit
import UserNotifications
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.shared.log("AppDelegate: Application did finish launching.")

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Handle notification when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, 
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Logger.shared.log("Notification will present: \(notification.request.content.title)")
        completionHandler([.banner, .sound, .badge])
    }

    // Handle user's response to notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, 
        withCompletionHandler completionHandler: @escaping () -> Void) {
        Logger.shared.log("Notification did receive response: \(response.notification.request.content.title)")
        completionHandler()
    }
}
