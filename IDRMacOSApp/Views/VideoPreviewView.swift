//
//  VideoPreviewView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import SwiftUI
import ZMVideoSDK

struct VideoPreviewView: NSViewRepresentable {
    @EnvironmentObject var viewModel: SessionViewModel

    func makeNSView(context: Context) -> NSView {
        // Create and configure your NSView object here
        let view = NSView()
        view.needsLayout = true
        view.wantsLayer = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.cgColor
        
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the view properties if necessary
        if let myUser = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas() {
           
            // Unsubscribe previous view if needed
            myUserVideoCanvas.unSubscribe(with: nsView)

            if  ZMVideoSDK.shared().isInSession() {
                let sdkReturnStatus = myUserVideoCanvas.subscribe(with: nsView, aspectMode: ZMVideoSDKVideoAspect_LetterBox, resolution: ZMVideoSDKResolution_360P)

                // Subscribe to the video canvas
                Logger.shared.log("- VideoCanvasView - Subscribe to the video canvas : \(errorMessage(for: sdkReturnStatus))")
            }

        }
    }

    private func errorMessage(for error: ZMVideoSDKErrors) -> String {
        switch error {
            case ZMVideoSDKErrors_Success:
                return "ZoomVideoSDK initialized successfully"
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong usage of the ZoomVideoSDK"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal ZoomVideoSDK error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: ZoomVideoSDK not initialized"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory issues encountered"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Failed to load a module"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
            case ZMVideoSDKErrors_Auth_Error:
                return "Error: Authentication failed"
            case ZMVideoSDKErrors_JoinSession_NoSessionName:
                return "Error: No session name provided for joining session"
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong Usage"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal Error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: Uninitialize"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory Error"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Load Module Error"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Unload Module Error"
            case ZMVideoSDKErrors_Invalid_Parameter:
                return "Error: Invalid Parameter"
            case ZMVideoSDKErrors_Call_Too_Frequently:
                return "Error: Call too frequently"
            case ZMVideoSDKErrors_No_Impl :
                return "Error: No impl"
            case ZMVideoSDKErrors_Dont_Support_Feature:
                return "Error: Dont support feature"
            case ZMVideoSDKErrors_Unknown:
                return "Error: Unkown"
            case ZMVideoSDKErrors_Remove_Folder_Fail:
                return "Remove Folder Fail"
            default:
                return "Unknown error occurred with code: \(error.rawValue)"
        }
    }



    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        // Properly unsubscribe when the view is not longer used
        if let myUser = ZMVideoSDK.shared().getSessionInfo().getMySelf(),
           let myUserVideoCanvas = myUser.getVideoCanvas() {
            myUserVideoCanvas.unSubscribe(with: nsView)
        }
    }
}

#Preview {
    VideoPreviewView()
}
