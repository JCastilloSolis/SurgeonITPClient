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


    //TODO: Move somewhere else
    init() {
        setupSDK()
    }

    private func setupSDK() {
        let initParams = ZoomVideoSDKInitParams()
        initParams.domain = Constants.zoomAPIDomain
        
        // Set audio memory mode to heap.
        initParams.audioRawdataMemoryMode = .heap
        // Set video memory mode to heap.
        initParams.videoRawdataMemoryMode = .heap
        // Set share memory mode to heap.
        initParams.shareRawdataMemoryMode = .heap
        
        let sdkInitReturnStatus = ZoomVideoSDK.shareInstance()?.initialize(initParams)
        switch sdkInitReturnStatus {
            case .Errors_Success:
                Logger.shared.log("ZoomVideoSDK initialized successfully")
            default:
                if let error = sdkInitReturnStatus {
                    Logger.shared.log("ZoomVideoSDK failed to initialize: \(error)")
                    return
                }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
