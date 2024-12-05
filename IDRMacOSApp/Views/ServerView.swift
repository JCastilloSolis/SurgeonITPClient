//
//  ServerView.swift
//  IDRMacOSApp
//
//  Created by Jorge Castillo on 11/8/24.
//

import SwiftUI

struct ServerView: View {
    @ObservedObject var viewModel: ServerViewModel
    @State private var sessionName: String = UserDefaults.standard.string(forKey: "sessionName") ?? ""

    var body: some View {
        VStack {
            if  viewModel.serverState.serverStatus == .inZoomCall {
                SessionView(viewModel: viewModel.sessionViewModel)
            }
            serverContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var serverContent: some View {
        VStack {
            HStack {
                Text(Host.current().localizedName ?? "Mac")
                    .font(.headline)
                    .padding()
                
                Text(viewModel.connectionStatus)
                    .foregroundColor(viewModel.connectionColor)
                    .padding()
                
                if viewModel.showProgressView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            
            // Add the TextField for sessionName
            TextField("Enter session name", text: $sessionName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: sessionName) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "sessionName")
                }
            
            
            VStack {
                Text("App Version: \(getAppVersion())")
                Text("Build Number: \(getBuildNumber())")
            }
        }
    }
    
    func getAppVersion() -> String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return "Unknown"
    }
    
    func getBuildNumber() -> String {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return buildNumber
        }
        return "Unknown"
    }
}






#Preview {
    ServerView(viewModel: ServerViewModel())
}
