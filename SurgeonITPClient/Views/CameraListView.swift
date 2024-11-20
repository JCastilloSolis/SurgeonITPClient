//
//  CameraListView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import SwiftUI
import ZoomVideoSDK


struct CameraListView: View {
    @StateObject var viewModel: SessionViewModel

    var body: some View {
        HStack {

            //TODO: Expand check to only show this when a macOS server is part of the call
            if (viewModel.firstRemoteParticipant != nil) {
                Menu {
                    ForEach(viewModel.cameraList, id: \.id) { camera in
                        Button(camera.name) {
                            Logger.shared.log("Select Camera \(camera.name)")
                            viewModel.requestSwitchCamera(toDeviceID: camera.id)
                        }
                    }
                } label: {
                    Label("Available Cameras", systemImage: "camera")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(8)
                }

                Button(action: viewModel.requestCameraControl) {
                    Image(systemName: "web.camera.fill")
                        .iconStyle(viewModel.canControlCamera ? .red : .purple)
                }

                if viewModel.canControlCamera {
                    cameraControlView
                        .frame(height: 100)

                }
            }

        }
        //.background(BlurView(style: .systemThinMaterialDark))
        .cornerRadius(10)
        .padding()

    }

    var cameraControlView: some View {
        HStack {
            Button(action: {
                viewModel.requestMoveCameraUp()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }

            Button(action: {
                viewModel.requestMoveCameraDown()
            }) {
                Image(systemName: "arrow.down.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }


            Button(action: {
                viewModel.requestMoveCameraLeft()
            }) {
                Image(systemName: "arrow.left.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }


            Button(action: {
                viewModel.requestMoveCameraRight()
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }



            Button(action: {
                viewModel.requestZoomCameraOut()
            }) {
                Image(systemName: "minus.magnifyingglass")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }


            Button(action: {
                viewModel.requestZoomCameraIn()
            }) {
                Image(systemName: "plus.magnifyingglass")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding()
            }


        }

        
    }

}


#Preview {
    CameraListView(viewModel: SessionViewModel())
}
