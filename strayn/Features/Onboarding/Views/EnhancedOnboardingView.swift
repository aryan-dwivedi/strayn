//
//  EnhancedOnboardingView.swift
//  strayn
//
//  Simple enhanced onboarding placeholder
//

import SwiftUI

struct EnhancedOnboardingView: View {
    @Binding var isFirstRun: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Enhanced Onboarding")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Welcome to Strayn")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("Continue to Main App") {
                    isFirstRun = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
        }
    }
}