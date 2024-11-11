//
//  CameraListViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import Foundation
import Combine
import ZMVideoSDK


class CameraListViewModel: ObservableObject {
    @Published var cameraDevices: [ZMVideoSDKCameraDevice] = []
    @Published var userCanControlCamera: Bool = false
    @Published var selectedCameraID: String? {
        didSet {
            selectCamera(deviceID: selectedCameraID)
        }
    }

    init(){
        fetchCameras()
    }

    func selectCamera(deviceID: String?) {
        let videoHelper = ZMVideoSDK.shared().getVideoHelper()
        if let cameraDeviceID = deviceID {
            let result = videoHelper.selectCamera(cameraDeviceID)
            print("-CameraListViewModel- Camera switched successfully? : \(result)")
            canControlCamera()

        } else {
            print("selectCamera: Invalid Device ID")
        }
    }

    func fetchCameras() {
        print("Fetch cameras")
        let videoHelper = ZMVideoSDK.shared().getVideoHelper()
        cameraDevices = videoHelper.getCameraList() ?? []

        // Check which camera is currently selected
        if let selectedCamera = cameraDevices.first(where: { $0.isSelectedDevice }) {
            self.selectedCameraID = selectedCamera.deviceID
            print("Found selected camera. \(selectedCamera.deviceName)")
            canControlCamera()
        } else {
            // No camera is selected or there are no cameras
            self.selectedCameraID = nil
        }
    }

    //TODO: Add value of "canCameraBeControlled" to camera list sent to users
    func canControlCamera() {
        print("canControlCamera method")
        var canControl: ObjCBool = false
        
        let result  = ZMVideoSDK.shared().getVideoHelper().canControlCamera(&canControl, deviceID: selectedCameraID)


        DispatchQueue.main.async {
            // Update the observable property on the main thread
            self.userCanControlCamera = canControl.boolValue
            let cameraName = self.cameraDevices.first(where: { $0.deviceID == self.selectedCameraID })?.deviceName
            print("\(self.errorMessage(for: result)). Can app control camera \(cameraName)? : \(self.userCanControlCamera)")
        }
    }

    func moveCameraLeft() {
        print("Move camera left method")
        let range:UInt32 = 100
        let cameraName = self.cameraDevices.first(where: { $0.deviceID == self.selectedCameraID })?.deviceName

        let result = ZMVideoSDK.shared().getVideoHelper().turnCameraLeft(range, deviceID: selectedCameraID)



        print("Move \(cameraName) left:  \(errorMessage(for: result))")
    }

    func moveCameraRight() {
        print("Move camera Right method")
        let range:UInt32 = 100

        let result = ZMVideoSDK.shared().getVideoHelper().turnCameraRight(range, deviceID: selectedCameraID)
        print("Move Camera right:  \(errorMessage(for: result))")
    }

    func moveCameraUp() {
        print("Move camera up method")
        let range:UInt32 = 100

        let result = ZMVideoSDK.shared().getVideoHelper().turnCameraUp(range, deviceID: selectedCameraID)
        print("Move Camera up:  \(errorMessage(for: result))")
    }

    func moveCameraDown() {
        print("Move camera down method")
        let range:UInt32 = 100

        let result = ZMVideoSDK.shared().getVideoHelper().turnCameraDown(range, deviceID: selectedCameraID)
        print("Move Camera down:  \(errorMessage(for: result))")
    }

    func zoomCamera() {
        print("Move camera left method")
        let range:UInt32 = 100

        let result = ZMVideoSDK.shared().getVideoHelper().zoomCamera(in: range, deviceID: selectedCameraID)
        print("Move Camera left:  \(errorMessage(for: result))")
    }

    func zoomCameraOut() {
        print("Move camera left method")
        let range:UInt32 = 100

        let result = ZMVideoSDK.shared().getVideoHelper().zoomCameraOut(range, deviceID: selectedCameraID)
        print("Move Camera left:  \(errorMessage(for: result))")
    }


    private func errorMessage(for error: ZMVideoSDKErrors) -> String {
        switch error {
            case ZMVideoSDKErrors_Success:
                return "Success"
            case ZMVideoSDKErrors_Wrong_Usage:
                return "Error: Wrong usage of the SDK"
            case ZMVideoSDKErrors_Internal_Error:
                return "Error: Internal SDK error"
            case ZMVideoSDKErrors_Uninitialize:
                return "Error: SDK not initialized"
            case ZMVideoSDKErrors_Memory_Error:
                return "Error: Memory issues encountered"
            case ZMVideoSDKErrors_Load_Module_Error:
                return "Error: Failed to load a module"
            case ZMVideoSDKErrors_UnLoad_Module_Error:
                return "Error: Failed to unload a module"
                // Add additional cases for other specific errors...
            case ZMVideoSDKErrors_Auth_Error:
                return "Error: Authentication failed"
            case ZMVideoSDKErrors_JoinSession_NoSessionName:
                return "Error: No session name provided for joining session"
                // Ensure all specific errors are handled.
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
}
