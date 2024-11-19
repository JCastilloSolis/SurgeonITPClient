//
//  AppState.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/18/24.
//


import Foundation
import Combine
import LocalAuthentication

enum AppNavigation {
    case login
    case main
}

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var navigation: AppNavigation = .login
    
    // Singleton instance for global access
    static let shared = AppState()
    
    private init() {}
    
    // Method to authenticate the user
    func authenticate(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // check if device has biometric authentication capability
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            Logger.shared.log(error?.localizedDescription ?? "Unknown error")
            return
        }

        // authenticate user using biometric authentication
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to unlock") { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.navigation = .main
                } else {
                    Logger.shared.log(error?.localizedDescription ?? "Unknown error")
                }
            }
        }
    }
    
    // Method to handle logout
    func logout() {
        isAuthenticated = false
        navigation = .login
    }
}
