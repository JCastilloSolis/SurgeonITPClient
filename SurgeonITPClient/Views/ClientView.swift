//
//  ClientView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI
import CoreLocation

struct ClientView: View {
    @ObservedObject var viewModel: ClientViewModel

    var body: some View {
        VStack {
            VStack {
                Text("Beacon Proximity: \(proximityDescription(viewModel.proximity))")
                    .padding()
            }
            .onAppear {
                Logger.shared.log("ContentView appeared. Starting beacon scanning.")
                viewModel.startBeaconScanning()
            }

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


                if !viewModel.previouslyPaired {
                    List(viewModel.discoveredPeers, id: \.self) { peer in
                        Button(peer.displayName) {
                            viewModel.selectServer(peerID: peer)
                        }
                    }
                    .padding()
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

            // Embed SessionView conditionally
            if viewModel.sessionViewModel.sessionIsActive {
                SessionView(viewModel: viewModel.sessionViewModel)
                //.transition(.slide)
            }

            HStack {
                Button("Start Zoom Call") {
                    viewModel.startZoomCall()
                }

                Button("Stop Zoom Call") {
                    viewModel.stopZoomCall()
                }
            }
            .buttonStyle(.bordered)
            .padding()
            .disabled(viewModel.peerManager.sessionState != .connected)
        }
    }
    
}

private func proximityDescription(_ proximity: CLProximity) -> String {
    switch proximity {
        case .immediate: return "Immediate"
        case .near: return "Near"
        case .far: return "Far"
        default: return "Unknown"
    }
}

#Preview {
    ClientView(viewModel: ClientViewModel())
}
