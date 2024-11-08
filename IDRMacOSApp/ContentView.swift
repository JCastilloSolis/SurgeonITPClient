//
//  ContentView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/7/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mpcService = ServerManagerService()

    var body: some View {
        VStack {
            Text("Server Running")
                .font(.largeTitle)
                .padding()

            Text("Connected Peers:")
                .font(.headline)

            List(mpcService.connectedPeers, id: \.self) { peer in
                Text(peer.displayName)
            }

            HStack {
                Button(action: {
                    mpcService.startAdvertising()
                }) {
                    Text("Start Advertising")
                }
                .padding()

                Button(action: {
                    mpcService.stopAdvertising()
                }) {
                    Text("Stop Advertising")
                }
                .padding()

                Button(action: {
                    mpcService.disconnect()
                }) {
                    Text("Disconnect")
                }
                .padding()
            }
        }
        .onAppear {
            Logger.shared.log("Server ContentView appeared.")
            mpcService.startAdvertising()
        }
    }
}

#Preview {
    ContentView()
}
