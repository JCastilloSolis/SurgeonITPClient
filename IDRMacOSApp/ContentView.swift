//
//  ContentView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/7/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            ServerView(viewModel: PeerViewModel())
        }

    }
}

#Preview {
    ContentView()
}
