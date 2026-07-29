//
//  WHOOPStyleOnboardingView.swift
//  strayn
//
//  Created for the WHOOP-style 38-screen onboarding flow.
//

import SwiftUI

struct WHOOPStyleOnboardingView: View {
    @StateObject private var viewModel = WHOOPOnboardingViewModel()
    
    var body: some View {
        ZStack {
            // Global Background
            Color.black.ignoresSafeArea()
            
            // Screen Content
            switch viewModel.currentScreen {
            
            // MARK: - Phase 1: Identity & Core Profile
            case .welcome, .ageInput, .sexSelection, .heightInput, .weightInput:
                WHOOPIdentityPhaseView(viewModel: viewModel)
                    .transition(.opacity)
            
            // MARK: - Phase 2: Body Appearance
            case .bodyTypeIntro, .bodyTypeSelection:
                WHOOPBodyPhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 3: Skin Tone
            case .skinToneIntro, .skinCaptureForearm, .skinProcessingForearm,
                 .skinCaptureLeg, .skinProcessingLeg, .skinCaptureAbdomen, .skinResult:
                WHOOPSkinTonePhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 4: Face
            case .faceIntro, .faceCaptureFull, .faceProcessing, .faceCaptureUnderEye, .faceResult:
                WHOOPFacePhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 5: Hair
            case .hairIntro, .hairCaptureFrontal, .hairCaptureCrown, .hairProcessing, .hairResult:
                WHOOPHairPhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 6: Body Composition
            case .compositionProcessing, .compositionResult:
                WHOOPCompositionPhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 7: Lifestyle
            case .activityLevel, .sleepDuration, .sleepQuality, .stressLevel, .hydration:
                WHOOPLifestylePhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 8: Nutrition
            case .dietType, .nutritionGoal, .calorieReveal:
                WHOOPNutritionPhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 9: Goals
            case .goalSelection:
                WHOOPGoalsPhaseView(viewModel: viewModel)
                    .transition(.opacity)
                
            // MARK: - Phase 10: Consent & Privacy
            case .privacySummary, .consentToggles, .completion:
                WHOOPConsentPhaseView(viewModel: viewModel)
                    .transition(.opacity)
            }
            
            // Global Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StraynColors.accentPrimary))
                                .scaleEffect(1.5)
                            
                            Text("Setting up your profile...")
                                .font(StraynTypography.bodyLarge)
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreenIndex)
        .statusBar(hidden: true)
    }
}
