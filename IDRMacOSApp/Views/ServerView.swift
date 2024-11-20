//
//  ServerView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var viewModel: PeerViewModel
    @State private var isZoomSessionActive = false
    @StateObject private var sessionViewModel = SessionViewModel()

    var body: some View {
        VStack {
            if isZoomSessionActive {
                SessionView(viewModel: sessionViewModel)
            } else {
                serverContent
            }
        }
        .onReceive(viewModel.$shouldStartZoomCall) { shouldStart in
            if shouldStart {
                viewModel.shouldStartZoomCall = false
                sessionViewModel.startSession()  // Start the session here
            }
        }
        .onReceive(viewModel.$shouldEndZoomCall) { shouldEnd in
            if shouldEnd {
                viewModel.shouldEndZoomCall = false
                sessionViewModel.leaveSession()  // End the session here
            }
        }
        .onReceive(sessionViewModel.sessionEndedPublisher) {
            // Inform PeerViewModel that session has ended
            viewModel.sessionDidEnd()
            isZoomSessionActive = false
        }
        .onReceive(sessionViewModel.sessionStartedPublisher) { sessionName in
            // Inform PeerViewModel that session has started
            viewModel.sessionDidStart(sessionName: sessionName)
            isZoomSessionActive = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var serverContent: some View {
        VStack {
            HStack {
                Text(viewModel.connectionStatus)
                    .foregroundColor(viewModel.connectionColor)
                if viewModel.showProgressView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()

            if viewModel.previouslyPaired {
                Button("Forget Client Device") {
                    viewModel.clearSavedClient()
                }
                .padding()
                .foregroundColor(.red)
                .buttonStyle(.bordered)
            }
            
            

        }
    }
}






#Preview {
    ServerView(viewModel: PeerViewModel())
}
