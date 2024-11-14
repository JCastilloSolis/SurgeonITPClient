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
                isZoomSessionActive = true
                sessionViewModel.startSession()  // Start the session here
                viewModel.shouldStartZoomCall = false
            }
        }
        .onReceive(viewModel.$shouldEndZoomCall) { shouldEnd in
            if shouldEnd {
                // Tell SessionViewModel to leave the session
                sessionViewModel.leaveSession()
                viewModel.shouldEndZoomCall = false
            }
        }
        .onReceive(sessionViewModel.$sessionIsActive) { isActive in
            if !isActive {
                isZoomSessionActive = false
            }
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
