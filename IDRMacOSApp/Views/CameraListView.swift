//
//  CameraListView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import SwiftUI
import ZMVideoSDK
import Combine

struct CameraListView: View {
    @ObservedObject var viewModel: CameraListViewModel

    var body: some View {

        VStack {

            HStack {
                List(viewModel.cameraDevices, id: \.deviceID) { device in
                    HStack {
                        Text(device.deviceName)
                        Spacer()
                        if device.deviceID == viewModel.selectedCameraID {
                            Image(systemName: "checkmark")
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedCameraID = device.deviceID
                        viewModel.selectCamera(deviceID: device.deviceID)
                    }
                }
                .listStyle(.bordered)
                .frame(width: 200,height: 100)

                Text("Camera Control Available: \(viewModel.userCanControlCamera ? "Yes" : "No")")

                HStack {
                    if viewModel.userCanControlCamera {
                        Button(action: {
                            viewModel.moveCameraLeft()
                        }) {
                            Text("<")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            viewModel.moveCameraRight()
                        }) {
                            Text(">")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            viewModel.moveCameraUp()
                        }) {
                            Text("^")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            viewModel.moveCameraDown()
                        }) {
                            Text("v")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }

        }
    }
}

#Preview {
    CameraListView(viewModel: CameraListViewModel())
}
