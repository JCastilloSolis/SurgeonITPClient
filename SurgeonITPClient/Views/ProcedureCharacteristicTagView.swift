//
//  ProcedureCharacteristicTagView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//


import SwiftUI

struct ProcedureCharacteristicTagView: View {
    let tag: String
    let categoryName: String
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        Button(action: {
            if selectedTags.contains(tag) {
                selectedTags = []
            } else {
                selectedTags = [tag]
                //UserDefaults.standard.set(tag, forKey: "\(categoryName).characteristic")
            }
        }) {
            Text(tag)
                .font(.system(size: 14))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTags.contains(tag) ? Color.black : Color.white)
                .foregroundColor(selectedTags.contains(tag) ? Color.white : Color.black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                        .opacity(selectedTags.contains(tag) ? 0 : 1)
                )
        }
    }
}

struct ProcedureCharacteristicTagView_Previews: PreviewProvider {
    @State static var selectedTags: Set<String> = [BMI.between30and40.rawValue]
    static var previews: some View {
        ProcedureCharacteristicTagView(tag: BMI.between30and40.rawValue, categoryName: "BMI", selectedTags: $selectedTags)
    }
}

