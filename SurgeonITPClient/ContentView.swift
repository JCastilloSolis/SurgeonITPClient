//
//  ContentView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 10/28/24.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        ClientView(viewModel: PeerViewModel(), beaconManager: BeaconManagerService())
    }

}

#Preview {
    ContentView()
}
