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
    var body: some View {
        VStack {
            if viewModel.proximity != .unknown {
                VStack {
                    HStack {
                        Text(viewModel.connectionStatus)
                            .foregroundColor(viewModel.connectionColor)
                        if viewModel.showProgressView {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
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


                    if !viewModel.previouslyPaired {
                        List(viewModel.discoveredPeers, id: \.self) { peer in
                            Button(peer.displayName) {
                                viewModel.selectServer(peerID: peer)
                            }
                        }
                        .padding()
                    }


                }
                .padding()

            }

            SelectProcedureView(viewModel: viewModel)
        }


    }
}

struct SelectProcedureView: View {
    @StateObject var viewModel: ClientViewModel
    @State var selection: ProcedureType = .notSet

    var body: some View {

        VStack {
            Picker("Procedure Type", selection: $selection) {
                ForEach(ProcedureType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value.rawValue)
                }
            }
            .onChange(of: selection) { procedureType in
                UserDefaults.standard.set(procedureType.rawValue, forKey: ProcedureType.userDefaultsKey)
            }
            .frame(maxHeight: 100)
            .padding(.top, -5)

            Spacer()

            if selection != .notSet && selection !=  .TR100 {

                SetClinicalProcedureCharacteristicsView()


                HStack {
                    Button("Start Zoom Call") {
                        viewModel.startZoomCall()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                .disabled(viewModel.peerManager.sessionState != .connected)
                .isHidden(viewModel.peerManager.sessionState != .connected)
            }
            Spacer()
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
