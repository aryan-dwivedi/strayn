//
//  SecurityManager.swift
//  strayn
//
//  Handles biometric authentication and app locking.
//

import Foundation
import LocalAuthentication
import Combine

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    var useBiometrics: Bool {
        get {
            UserDefaults.standard.bool(forKey: "useBiometrics")
        }
        set {
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBiometrics")
        }
    }
    
    @Published var isAuthenticated: Bool
    
    private init() {
        // Initial state: locked if biometrics enabled
        let currentBiometricsEnabled = UserDefaults.standard.bool(forKey: "useBiometrics")
        self.isAuthenticated = !currentBiometricsEnabled
    }
    
    func authenticate(completion: @escaping (Bool) -> Void = { _ in }) {
        guard useBiometrics else {
            isAuthenticated = true
            completion(true)
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock Strayn to view your health data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                        completion(true)
                    } else {
                        // Handle failure (e.g., show error or fallback to passcode)
                        self.isAuthenticated = false
                        completion(false)
                    }
                }
            }
        } else {
            // Biometrics not available
            self.isAuthenticated = true
            completion(true)
        }
    }
    
    func lockout() {
        if useBiometrics {
            isAuthenticated = false
        }
    }
}
