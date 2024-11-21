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
        SelectProcedureView(viewModel: viewModel)
    }
}

struct SelectProcedureView: View {
    @StateObject var viewModel: ClientViewModel
    @State var selection: ProcedureType = .notSet
    
    var body: some View {
        VStack {
            Text("Hi Dr. Castillo")
                .font(.title)
                .padding()
            
            Text("Please select a procedure type: ")
            Picker("Procedure Type", selection: $selection) {
                ForEach(ProcedureType.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .tag(value.rawValue)
                }
            }
            .onChange(of: selection) { procedureType in
                UserDefaults.standard.set(procedureType.rawValue, forKey: ProcedureType.userDefaultsKey)
            }
            //.frame(maxHeight: 100)
            .padding()
            
            Spacer()
            
            if selection != .notSet && selection !=  .TR100 {
                
                SetClinicalProcedureCharacteristicsView()
                
                
                Button("Start Zoom Call") {
                    viewModel.startZoomCall()
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
