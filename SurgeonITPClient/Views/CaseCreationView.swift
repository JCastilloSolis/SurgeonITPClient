//
//  CaseCreationView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//

import SwiftUI
import CoreLocation

struct CaseCreationView: View {
    @ObservedObject var viewModel: ClientViewModel
    @StateObject var tabViewModel = MainTabViewModel()
    var body: some View {
        VStack {
            VStack {
                Text("Beacon Proximity: \(proximityDescription(viewModel.proximity))")
                    .padding()
            }
            

            if viewModel.proximity != .unknown {
                VStack {
                    HStack {
                        Text(viewModel.connectionStatus)
                            .foregroundColor(viewModel.connectionColor)
                        if viewModel.showProgressView {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    .padding()


                    if !viewModel.previouslyPaired {
                        List(viewModel.discoveredPeers, id: \.self) { peer in
                            Button(peer.displayName) {
                                viewModel.selectServer(peerID: peer)
                            }
                        }
                        .padding()
                    }

                    if viewModel.previouslyPaired {
                        Button("Clear Saved Server") {
                            viewModel.clearSavedServer()
                        }
                        .padding()
                        .foregroundColor(.red)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()

                HStack {
                    Button("Start Zoom Call") {
                        viewModel.startZoomCall()
                    }

                    Button("Stop Zoom Call") {
                        viewModel.stopZoomCall()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                .disabled(viewModel.peerManager.sessionState != .connected)
                .isHidden(viewModel.peerManager.sessionState != .connected)

            }

            SelectProcedureView(viewModel: tabViewModel.tab1ViewModel)
        }


    }
}

private func proximityDescription(_ proximity: CLProximity) -> String {
    switch proximity {
        case .immediate: return "Immediate"
        case .near: return "Near"
        case .far: return "Far"
        default: return "Unknown"
    }
}

#Preview {
    CaseCreationView(viewModel: ClientViewModel())
}
