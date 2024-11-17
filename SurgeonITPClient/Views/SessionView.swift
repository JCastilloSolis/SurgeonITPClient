//
//  SessionView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//



import SwiftUI
import ZoomVideoSDK

struct SessionView: View {
    @StateObject var viewModel: SessionViewModel

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 3) // Adjust the count based on your UI needs

    var body: some View {
        ZStack {
            VideoCanvasView(participantID: viewModel.pinnedParticipantID)
                .environmentObject(viewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                topBar
                Spacer()
                participantsGrid
                Spacer()

                HStack {
                    controlBar
                    CameraListView(viewModel: viewModel)
                }
                .padding()
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Alert"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    var topBar: some View {
        HStack {
            Text("Session: \(viewModel.sessionName)")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Button("Leave") {
                viewModel.leaveSession()
            }
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }

    var participantsGrid: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: columns, spacing: 10) {
                ForEach(viewModel.participants, id: \.id) { participant in
                    ParticipantView(participant: participant)
                        .onTapGesture {
                            viewModel.pinParticipant(viewModel.pinnedParticipantID == participant.id ? nil : participant.id)
                        }
                        .frame(width: 80, height: 80)
                        .border(Color.blue, width: viewModel.pinnedParticipantID == participant.id ? 3 : 0)
                }
            }
            .padding(.horizontal)
        }
    }

    var controlBar: some View {
        HStack {
            Button(action: viewModel.toggleVideo) {
                Image(systemName: viewModel.isVideoOn ? "video.fill" : "video.slash.fill")
                    .iconStyle(.blue)
            }

            Button(action: viewModel.toggleAudio) {
                Image(systemName: viewModel.isAudioMuted ? "mic.slash.fill" : "mic.fill")
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
    SessionView(viewModel: SessionViewModel())
}
