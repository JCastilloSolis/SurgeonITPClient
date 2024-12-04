//
//  ServerView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var viewModel: ServerViewModel
    @State private var sessionName: String = UserDefaults.standard.string(forKey: "sessionName") ?? ""

    var body: some View {
        VStack {
            if  viewModel.serverState.isInZoomCall {
                SessionView(viewModel: viewModel.sessionViewModel)
            }
            serverContent
        }
        .onReceive(viewModel.peerViewModel.$shouldStartZoomCall) { shouldStart in
            if shouldStart {
                viewModel.peerViewModel.shouldStartZoomCall = false
                viewModel.sessionViewModel.startSession(sessionName: sessionName)
            }
        }
        .onReceive(viewModel.peerViewModel.$shouldEndZoomCall) { shouldEnd in
            if shouldEnd {
                viewModel.peerViewModel.shouldEndZoomCall = false
                viewModel.sessionViewModel.leaveSession() 
            }
        }
        .onReceive(viewModel.sessionViewModel.sessionEndedPublisher) {
            // Inform PeerViewModel that session has ended
            viewModel.peerViewModel.sessionDidEnd()
            viewModel.serverState.isInZoomCall = false
            viewModel.serverState.serverStatus = .idle
        }
        .onReceive(viewModel.sessionViewModel.sessionStartedPublisher) { sessionName in
            // Inform PeerViewModel that session has started
            viewModel.peerViewModel.sessionDidStart(sessionName: sessionName)
            viewModel.serverState.isInZoomCall = true
            viewModel.serverState.serverStatus = .inZoomCall
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var serverContent: some View {
        VStack {
            HStack {
                Text(viewModel.peerViewModel.connectionStatus)
                    .foregroundColor(viewModel.peerViewModel.connectionColor)
                if viewModel.peerViewModel.showProgressView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            
            // Add the TextField for sessionName
            TextField("Enter session name", text: $sessionName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: sessionName) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "sessionName")
                }
            
            
            if viewModel.peerViewModel.previouslyPaired {
                Button("Forget Client Device") {
                    viewModel.peerViewModel.clearSavedClient()
                }
                .padding()
                .foregroundColor(.red)
                .buttonStyle(.bordered)
            }
        }
    }
}






#Preview {
    ServerView(viewModel: ServerViewModel())
}
