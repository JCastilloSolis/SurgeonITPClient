//
//  MainView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//


import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ClientViewModel
    @ObservedObject var appState = AppState.shared

    var body: some View {
        VStack {
            // Your main application UI goes here
            Text("Welcome to SurgeonITPClient")
                .font(.title)
                .padding()
        }
        .onAppear {
            // Initialize MPC and Zoom if needed
        }
    }
}
