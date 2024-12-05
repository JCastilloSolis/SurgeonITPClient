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
                //TODO: Figure out what to controls to put here 
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
