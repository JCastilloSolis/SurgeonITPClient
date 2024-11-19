//
//  LoginView.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//


import SwiftUI


struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()

    var body: some View {

        VStack {

            Image("isrg-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.top, 10)

            Spacer()


            CustomTextField(imageName: "envelope", placeholder: "Username or email", isSecure: false, iconBackgroundColor: Color("gray-light"), textColor: Color("gray-darker"), text: $viewModel.username)

            CustomTextField(imageName: "lock", placeholder: "Password", isSecure: true, iconBackgroundColor: Color("gray-light"), textColor: Color("gray-darker"), text: $viewModel.password)



            Image(systemName: "faceid")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(.top, 10)
                .foregroundColor(.gray)
                .onTapGesture {
                    viewModel.authenticateUser()
                }

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
            }

            Spacer()

            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                Button(action: {
                    viewModel.authenticateUser()
                }) {
                    Text("Log in > ")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(Color.black)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.top, 16)
        }
        .edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    LoginView()
}
