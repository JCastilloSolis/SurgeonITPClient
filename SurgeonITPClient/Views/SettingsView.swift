//
//  SettingsViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo Solis on 11/21/24.
//



import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                if viewModel.proximity != .unknown {
                    VStack {
                        HStack {
                            Text(viewModel.connectionStatus)
                                .foregroundColor(viewModel.connectionColor)
                            if viewModel.showProgressView {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            
                            if viewModel.previouslyPaired {
                                Button("Clear Saved Server") {
                                    viewModel.clearSavedServer()
                                }
                                .padding()
                                .foregroundColor(.red)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        
                        
                        if !viewModel.previouslyPaired {
                            List(viewModel.discoveredPeers, id: \.self) { peer in
                                Button(peer.displayName) {
                                    viewModel.selectServer(peerID: peer)
                                }
                            }
                            .padding()
                        }
                        
                        
                    }
                    .padding()
                    
                }
                
            }// Vstack
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }//: - ToolBar
        }// Navigation
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: ClientViewModel())
    }
}