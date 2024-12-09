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
    @State private var serialNumber = Host.current().localizedName ?? "Mac"
    @State private var beaconInfo = ""

    var body: some View {
        VStack {
            if  viewModel.serverState.serverStatus == .inZoomCall {
                SessionView(viewModel: viewModel.sessionViewModel)
            }
            serverContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            for beaconData in Constants.beaconToPeerDisplayNameMap {
                if beaconData.value == serialNumber {
                    let data = beaconData.key as BeaconData
                    beaconInfo = data.description
                }
            }
        }
    }
    
    var serverContent: some View {
        VStack {
            
            VStack {
                Text(serialNumber)
                    .font(.headline)
                    .padding()
                
                Text("iBeacon: \(beaconInfo)")
                    .font(.subheadline)
                    .padding()
            }
            
            HStack {
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
