//
//  MainTabView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var clientViewModel = ClientViewModel()
    @State private var isShowingSettings: Bool = false
    
    var body: some View {
        TabView(selection: $clientViewModel.selectedTab) {

            if clientViewModel.mpcSessionState == .connected {
                CaseCreationView(viewModel: clientViewModel)
                    .tabItem {
                        Image(systemName: "waveform.path.ecg.text.clipboard.fill")
                        Text("Case")
                    }
                    .tag(0)
            } else {
                VStack {
                    
                    
                    if let nearestBeaconDisplayName = clientViewModel.currentNearestBeaconDisplayName {
                        Image("console")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding()
                        
                        Text(nearestBeaconDisplayName)
                            .font(.subheadline)
                            .padding()
                        
                        if clientViewModel.showProgressView {
                            ProgressView("Connecting")
                                .frame(width: 100, height: 100, alignment: .center)
                        }
                    }
                    
                    Text("Please remain close to the system and ensure you are on the same network")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(.secondary)
                }
                .tag(0)
            }


            // Embed SessionView conditionally
            if clientViewModel.sessionViewModel.sessionIsActive {
                SessionView(viewModel: clientViewModel)
                    .tabItem {
                        Image(systemName: "person.crop.square.badge.video.fill")
                        Text("ITP Session")
                    }
                    .tag(1)
            }
            
        }
        .onAppear {
            Logger.shared.log("main tab view appeared. Starting beacon scanning.")
            clientViewModel.startBeaconScanning()
        }
        .tint(.black)
        .navigationBarTitle("My Intuitive", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(viewModel: clientViewModel)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainTabView()
        }
    }
}
