//
//  ContentView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 10/28/24.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var beaconManager = BeaconManagerService()

    var body: some View {
        VStack {
            Text("Beacon Proximity: \(proximityDescription(beaconManager.proximity))")
                .padding()

            if let clientManager = beaconManager.mpcService {
                VStack {
                    if !clientManager.connectedPeers.isEmpty {
                        Text("Connected Peers:")
                            .font(.headline)
                        List(clientManager.connectedPeers, id: \.self) { peer in
                            Text(peer.displayName)
                        }
                    } else {
                        Text("No connected peers.")
                            .padding()
                    }

                    if !clientManager.discoveredPeers.isEmpty {
                        Text("Discovered Peers:")
                            .font(.headline)
                        List(clientManager.discoveredPeers, id: \.self) { peer in
                            Button(action: {
                                Logger.shared.log("User tapped on peer \(peer.displayName). Sending invitation.")
                                clientManager.invitePeer(peer)
                            }) {
                                Text(peer.displayName)
                            }
                        }
                    } else {
                        Text("No peers discovered.")
                            .padding()
                    }
                }
            } else {
                Text("Not browsing for peers.")
                    .padding()
            }
        }
        .onAppear {
            Logger.shared.log("ContentView appeared. Starting beacon scanning.")
            beaconManager.startScanning()
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
}

#Preview {
    ContentView()
}
