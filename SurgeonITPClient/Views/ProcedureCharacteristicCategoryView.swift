//
//  ProcedureCharacteristicCategoryView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/20/24.
//


import SwiftUI

struct ProcedureCharacteristicCategoryView: View {
    let tags: [String]
    let categoryName: String
    let horizontalPadding: CGFloat = 8
    let verticalPadding: CGFloat = 8
    @State var selectedTags: Set<String>
    
    var body: some View {
        VStack {
            HStack () {
                
                VStack {
                    Text(categoryName)
                        .font(.headline)
                        .padding(.leading, horizontalPadding)
                    
                    HStack {
                        DottedLine()
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: getTextWidth(text: categoryName), height: 1, alignment: .center)
                            .padding(.top, -5)
                            .padding(.leading, horizontalPadding)
                    }
                }
                .padding(.horizontal, 35)
                
                Spacer()
                
            }
            
            
            ScrollView {
                VStack(alignment: .leading, spacing: verticalPadding) {
                    ForEach(computeRows(), id: \.id) { row in
                        HStack(spacing: horizontalPadding) {
                            ForEach(row.tags, id: \.self) { tag in
                                ProcedureCharacteristicTagView(tag: tag, categoryName: categoryName, selectedTags: $selectedTags)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                        
                    }
                }
                .padding(5)
            }
            .padding(.horizontal, 10)
        }
        .padding()
        
        
        
    }
    
    private func getTextWidth(text: String) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
        return (text as NSString).size(withAttributes: attributes).width
    }
    
    func computeRows() -> [TagRow] {
        var rows: [TagRow] = []
        var currentRow = TagRow(id: UUID(), tags: [])
        var currentRowWidth: CGFloat = 0
        
        let screenWidth = UIScreen.main.bounds.width - horizontalPadding * 2
        
        for tag in tags {
            let tagWidth = (tag as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width + 24
            
            if currentRowWidth + tagWidth + horizontalPadding <= screenWidth {
                currentRow.tags.append(tag)
                currentRowWidth += tagWidth + horizontalPadding
            } else {
                rows.append(currentRow)
                currentRow = TagRow(id: UUID(), tags: [tag])
                currentRowWidth = tagWidth
            }
        }
        
        if !currentRow.tags.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

struct TagRow: Identifiable {
    let id: UUID
    var tags: [String]
}

import SwiftUI

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dashWidth: CGFloat = 1
        let dashSpacing: CGFloat = 3.5
        var x: CGFloat = rect.minX
        var y: CGFloat = rect.minY
        while x < rect.maxX {
            let endX = x + dashWidth
            path.addEllipse(in: CGRect(x: x, y: y - 1, width: 2, height: 2))
            path.move(to: CGPoint(x: endX + dashSpacing, y: y))
            x = endX + dashSpacing
        }
        return path
    }
}

struct ProcedureCharacteristicCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        ProcedureCharacteristicCategoryView(tags: Malignancy.allCases.map{$0.rawValue}, categoryName: "Malignancy", selectedTags: [])
    }
}

