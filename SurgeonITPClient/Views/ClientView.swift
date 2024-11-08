//
//  ClientView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI
import CoreLocation

struct ClientView: View {
    @ObservedObject var viewModel: PeerViewModel
    @ObservedObject var beaconManager : BeaconManagerService

    var body: some View {
        VStack {

            VStack {
                Text("Beacon Proximity: \(proximityDescription(beaconManager.proximity))")
                    .padding()
            }
            .onAppear {
                Logger.shared.log("ContentView appeared. Starting beacon scanning.")
                beaconManager.startScanning()
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
                    List(viewModel.peerManager.discoveredPeers, id: \.self) { peer in
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


            List(viewModel.receivedMessages, id: \.self) { message in
                HStack {
                    Text(message).padding(10)
                    Spacer()
                }
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            HStack {
                Button("Start") {
                    viewModel.sendCommand("start")
                }
                Button("Stop") {
                    viewModel.sendCommand("stop")
                }
                Button("Status") {
                    viewModel.sendCommand("status")
                }
            }
            .buttonStyle(.bordered)
            .padding()
            .disabled(viewModel.peerManager.sessionState != .connected)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func proximityDescription(_ proximity: CLProximity) -> String {
        switch proximity {
            case .immediate: return "Immediate"
            case .near: return "Near"
            case .far: return "Far"
            default: return "Unknown"
        }
    }
}

#Preview {
    ClientView(viewModel: PeerViewModel(), beaconManager: BeaconManagerService())
}
