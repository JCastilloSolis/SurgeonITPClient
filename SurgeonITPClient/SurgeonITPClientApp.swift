//
//  SurgeonITPClientApp.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 10/28/24.
//

import SwiftUI
import ZoomVideoSDK

@main
struct SurgeonITPClientApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    init() {
        setupSDK()
    }

    private func setupSDK() {
        let initParams = ZoomVideoSDKInitParams()
        initParams.domain = "zoom.us"
        let sdkInitReturnStatus = ZoomVideoSDK.shareInstance()?.initialize(initParams)
        switch sdkInitReturnStatus {
            case .Errors_Success:
                Logger.shared.log("- ITP_DemoApp - SDK initialized successfully")
            default:
                if let error = sdkInitReturnStatus {
                    Logger.shared.log("- ITP_DemoApp - SDK failed to initialize: \(error)")
                    return
                }
        }
    }

    var body: some Scene {
        WindowGroup {
            //ContentView()
            SessionView()
        }
    }
}
