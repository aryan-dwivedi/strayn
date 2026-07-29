//
//  AppState.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI
import Combine

/// Centralized application state.
/// Manages global state that needs to be accessible throughout the app:
/// - Authentication status
/// - App locking (FaceID)
/// - Tab selection
/// - User Preferences
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Navigation State
    @Published var selectedTab: TabIdentifier = .dashboard
    
    // MARK: - App Cycle State
    @Published var isAppLocked: Bool = true
    @Published var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete")
        }
    }
    
    // MARK: - Dependencies
    // We can hold references to major services here if needed for global access,
    // though EnvironmentObjects or Dependency Injection is preferred for views.
    
    private init() {
        // Force onboarding to show for testing
        self.isOnboardingComplete = false
        // Don't lock during onboarding
        self.isAppLocked = false
        
        // Setup observers if needed
    }
    
    func appDidBecomeActive() {
        // Trigger FaceID check if enabled
        if SecurityManager.shared.useBiometrics {
            self.isAppLocked = true
            SecurityManager.shared.authenticate { success in
                DispatchQueue.main.async {
                    self.isAppLocked = !success
                }
            }
        } else {
            self.isAppLocked = false
        }
    }
    
    func appWillResignActive() {
        if SecurityManager.shared.useBiometrics {
            self.isAppLocked = true
        }
    }
}

enum TabIdentifier: String, CaseIterable {
    case dashboard
    case history
    case achievements
    case profile
}
