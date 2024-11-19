//
//  CustomTextField.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//



import SwiftUI

struct CustomTextField: View {
    let imageName: String
    let placeholder: String
    let isSecure: Bool
    let iconBackgroundColor: Color
    let textColor: Color
    @Binding var text: String
    
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .stroke(textColor, lineWidth: 1)
                .frame(height: 40) // Set the height here
            
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(textColor)
            }
            
            HStack(spacing: 0) {
                if isSecure {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text)
                            .foregroundColor(textColor)
                    } else {
                        SecureField(placeholder, text: $text)
                            .foregroundColor(textColor)
                    }
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(textColor)
                }
            }
            .offset(x: 50, y: 0)
            .frame(width: UIScreen.main.bounds.width - 50, height: 40)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

struct CustomTextField_Previews: PreviewProvider {
    @State static var username: String = ""
    static var previews: some View {
        CustomTextField(imageName: "envelope", placeholder: "Username or email", isSecure: false, iconBackgroundColor: Color("gray-light"), textColor: Color("gray-darker"), text: $username)
    }
}
