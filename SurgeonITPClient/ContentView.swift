//
//  ContentView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 10/28/24.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Group {
            switch appState.navigation {
                case .login:
                    LoginView()
                case .main:
                    MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.navigation)
        .transition(.slide)
    }
}

#Preview {
    ContentView()
}
