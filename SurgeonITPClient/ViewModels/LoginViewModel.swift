//
//  LoginViewModel.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//

import Foundation
import LocalAuthentication

final class LoginViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var username: String = ""
    @Published var password: String = ""
    
    init () {
        // This is just to fake an easy login
        UserDefaults.standard.set("user", forKey: "username")
        UserDefaults.standard.set("password", forKey: "password")
    }
    
    func authenticateUser() {
        AppState.shared.authenticate(username: username, password: password) { [weak self] success in
            guard let self else { return }
            if !success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.errorMessage = "Invalid username or password."
                }
            }
        }
    }
}
