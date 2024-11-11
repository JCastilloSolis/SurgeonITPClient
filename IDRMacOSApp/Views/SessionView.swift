//
//  SessionView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/11/24.
//

import SwiftUI
import ZMVideoSDK

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack {

            HStack {
                Text("Session Connected: \(viewModel.sessionIsActive)")

                Spacer()

                Text("Session Name: \(viewModel.sessionName)")
            }

            CameraListView(viewModel: CameraListViewModel())


            HStack {
                VideoPreviewView()
                    .frame(width: 300,height: 300)
                    .environmentObject(viewModel)

                HStack(alignment: .center) {
                    // Toggle Video Button
                    Button {
                        viewModel.toggleVideo()
                    } label: {
                        Image(systemName: viewModel.isVideoOn ? "video.fill" : "video.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    // Toggle Audio Button
                    Button {
                        viewModel.toggleAudio()
                    } label: {
                        Image(systemName: viewModel.isAudioMuted ? "mic.slash.fill" : "mic.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    // Leave Session Button
                    Button {
                        viewModel.leaveSession()
                    } label: {
                        Image(systemName: "phone.down.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding()

            }



            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.participants, id: \.id) { participant in
                        VStack {
                            Text(participant.name)
                            ParticipantView(participant: participant)
                                .frame(width: 200, height: 200)
                                .border(Color.blue, width: 2)
                        }
                    }
                }
            }

            Spacer()
        }
    }
}

#Preview {
    SessionView(viewModel: SessionViewModel())
}

