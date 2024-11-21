//
//  SetClinicalProcedureCharacteristicsView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//


import SwiftUI

struct SetClinicalProcedureCharacteristicsView: View {
    var body: some View {
        //ScrollView {
            VStack {

                ProcedureCharacteristicCategoryView(tags: PrimarySurgeon.allCases.map{$0.rawValue}, categoryName: PreopCaseCharacteristics.primarySurgeon.rawValue, selectedTags: [] )

                ProcedureCharacteristicCategoryView(tags: PatientHistory.allCases.map{$0.rawValue}, categoryName: PreopCaseCharacteristics.patientHistory.rawValue , selectedTags: [] )

                ProcedureCharacteristicCategoryView(tags: Emergent.allCases.map{$0.rawValue}, categoryName: PreopCaseCharacteristics.emergent.rawValue, selectedTags: [] )
                
                //ProcedureCharacteristicCategoryView(tags: BMI.allCases.map{$0.rawValue}, categoryName: PreopCaseCharacteristics.bmi.rawValue, selectedTags: [] )
                
                ProcedureCharacteristicCategoryView(tags: Malignancy.allCases.map{$0.rawValue}, categoryName: PreopCaseCharacteristics.malignancy.rawValue, selectedTags: [] )
            }
      //  }
    }
}

struct SetProcedureCharacteristicsView_Previews: PreviewProvider {
    static var previews: some View {
        SetClinicalProcedureCharacteristicsView()
    }
}
