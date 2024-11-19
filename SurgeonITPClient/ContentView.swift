//
//  ContentView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 10/28/24.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var clientViewModel = ClientViewModel()

    var body: some View {
        Group {
            switch appState.navigation {
                case .login:
                    LoginView()
                case .main:
                    ClientView(viewModel: clientViewModel)
            }
        }
        .animation(.easeInOut, value: appState.navigation)
        .transition(.slide)
    }
}

#Preview {
    ContentView()
}
