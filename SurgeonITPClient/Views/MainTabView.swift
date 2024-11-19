//
//  MainTabView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var viewModel = MainTabViewModel()
    @State private var isShowingSettings: Bool = false
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            
            SelectProcedureView(viewModel: viewModel.tab1ViewModel)
                .tabItem {
                    Image(systemName: "house.circle.fill")
                    Text("Home")
                }
                .tag(0)


            Tab2View(viewModel: viewModel.tab2ViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Reports")
                }
                .tag(1)
            Tab3View(viewModel: viewModel.tab3ViewModel)
                .tabItem {
                    Image(systemName: "graduationcap.circle.fill")
                    Text("Learn")
                }
                .tag(2)
        }
        .tint(.black)
        .navigationBarTitle("My Intuitive", displayMode: .inline)
        .toolbar {
            //            ToolbarItem(placement: .navigationBarLeading) {
            //                Button("Leave") {
            //
            //                }
            //            }
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
//        .sheet(isPresented: $isShowingSettings) {
//            SettingsView(viewModel: SettingsViewModel())
//        }
    }
}

struct SelectProcedureView: View {
    @StateObject var viewModel: Tab1ViewModel
    @State var selection: ProcedureType = .notSet
    
    var body: some View {
        
        VStack {
            Spacer()
            Form {
                Picker("Procedure Type", selection: $selection) {
                    ForEach(ProcedureType.allCases, id: \.self) { value in
                        Text(value.rawValue)
                            .tag(value.rawValue)
                    }
                }
                .onChange(of: selection) { procedureType in
                    UserDefaults.standard.set(procedureType.rawValue, forKey: ProcedureType.userDefaultsKey)
                }
                
            }
            .frame(maxHeight: 100)
            .padding(.top, -5)
            
            Spacer()
            
//            if selection != .notSet && selection !=  .TR100 {
//                SetClinicalProcedureCharacteristicsView()
//            } else if selection == .TR100 {
//                SetTrainingAssesmentCharacteristicsView()
//            }
//            
//            
//            Spacer()
        }
        
    }
}

struct Tab2View: View {
    @ObservedObject var viewModel: Tab2ViewModel
    
    var body: some View {
        Text(viewModel.tabName)
    }
}

struct Tab3View: View {
    @ObservedObject var viewModel: Tab3ViewModel
    
    var body: some View {
        Text(viewModel.tabName)
    }
}

class MainTabViewModel: ObservableObject {
    @Published var selectedTab = 0
    
    let tab1ViewModel = Tab1ViewModel(tabName: "Tab 1")
    let tab2ViewModel = Tab2ViewModel(tabName: "Tab 2")
    let tab3ViewModel = Tab3ViewModel(tabName: "Tab 3")
}

class Tab1ViewModel: ObservableObject {
    @Published var tabName: String
    
    init(tabName: String) {
        self.tabName = tabName
    }
}

class Tab2ViewModel: ObservableObject {
    @Published var tabName: String
    
    init(tabName: String) {
        self.tabName = tabName
    }
}

class Tab3ViewModel: ObservableObject {
    @Published var tabName: String
    
    init(tabName: String) {
        self.tabName = tabName
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
