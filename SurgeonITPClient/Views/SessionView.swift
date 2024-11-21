//
//  SessionView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import SwiftUI
import ZoomVideoSDK

struct SessionView: View {
    @StateObject var viewModel: ClientViewModel

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 5) {
            topBar

            HStack {
                controlBar
                
                if viewModel.sessionViewModel.cameraList.count > 1 {
                    CameraListView(viewModel: viewModel.sessionViewModel)
                }
            }
            
            if viewModel.sessionViewModel.participants.isEmpty {
                Text("Waiting for participants...")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Active participants : ")
                    .padding()
                participantList
            }

            if viewModel.peerManager.sessionState == .connected {
                Button("End Zoom Session") {
                    viewModel.stopZoomCall()
                    
                }
                .padding()
                .foregroundColor(.red)
                .buttonStyle(.bordered)
            }
        }
        .alert(isPresented: $viewModel.sessionViewModel.showAlert) {
            Alert(
                title: Text("Alert"),
                message: Text(viewModel.sessionViewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    var topBar: some View {
        HStack {
            Text("Session: \(viewModel.sessionViewModel.sessionName)")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Button("Leave Zoom Session") {
                viewModel.sessionViewModel.leaveSession()
            }
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }


    var participantList: some View {
        List(viewModel.sessionViewModel.participants) { participant in
            HStack {
                Text(participant.name)
                    .font(.body)
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: participant.isVideoOn ? "video.fill" : "video.slash.fill")
                        .foregroundColor(participant.isVideoOn ? .green : .red)
                    Image(systemName: participant.isAudioOn ? "mic.fill" : "mic.slash.fill")
                        .foregroundColor(participant.isAudioOn ? .green : .red)
                }

               // ParticipantView(participant: participant)
                 //   .frame(width: 80, height: 80)

            }
            .padding(.vertical, 8)
        }
        .listStyle(PlainListStyle())
    }

    var controlBar: some View {
        HStack {
            Button(action: viewModel.sessionViewModel.toggleVideo) {
                Image(systemName: viewModel.sessionViewModel.isVideoOn ? "video.fill" : "video.slash.fill")
                    .iconStyle(.blue)
            }

            Button(action: viewModel.sessionViewModel.toggleAudio) {
                Image(systemName: viewModel.sessionViewModel.isAudioMuted ? "mic.slash.fill" : "mic.fill")
                    .iconStyle(.blue)
            }
        }
        .background(BlurView(style: .systemThinMaterialDark))
        .cornerRadius(10)
        .padding()
    }
}

// Helper View Modifier for icon styles
extension Image {
    func iconStyle(_ color: Color) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(15)
    }
}

// To create a blur view
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}




#Preview {
    SessionView(viewModel: ClientViewModel())
}
