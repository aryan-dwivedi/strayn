//
//  WHOOPPhaseViews.swift
//  strayn
//
//  Created to consolidate the missing phase views for the WHOOP-style onboarding.
//

import SwiftUI

// MARK: - Phase 1: Identity & Core Profile

struct WHOOPIdentityPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .welcome:
            WelcomeScreen(onContinue: { viewModel.nextScreen() })
        case .ageInput:
            AgeInputScreen(
                age: $viewModel.selectedAge,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .sexSelection:
            SexSelectionScreen(
                selection: $viewModel.biologicalSex,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .heightInput:
            HeightInputScreen(
                heightCm: $viewModel.selectedHeight,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .weightInput:
            WeightInputScreen(
                weightKg: $viewModel.selectedWeight,
                heightCm: viewModel.selectedHeight,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 2: Body Appearance

struct WHOOPBodyPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .bodyTypeIntro:
            BodyTypeIntroScreen(
                onContinue: { viewModel.nextScreen() },
                onSkip: { 
                    // Skip the intro, go to selection
                    viewModel.nextScreen() 
                }
            )
        case .bodyTypeSelection:
            BodyTypeSelectionScreen(
                selection: $viewModel.bodyType,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 3: Skin Tone

struct WHOOPSkinTonePhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .skinToneIntro:
            SkinToneIntroScreen(
                onContinue: { viewModel.nextScreen() },
                onSkip: { 
                    // Skip entire skin phase if needed, or just intro? 
                    // Usually skips to next logical block. Let's assume skips capture.
                    // For now, next screen.
                    viewModel.nextScreen()
                }
            )
        case .skinCaptureForearm:
            SkinCaptureScreen(
                region: .innerForearm,
                onCapture: { data in
                    viewModel.handleSkinCapture(data, region: .innerForearm)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .skinProcessingForearm:
            SkinProcessingScreen(
                progress: viewModel.skinAnalysisProgress,
                regionName: "Inner Forearm"
            )
        case .skinCaptureLeg:
            SkinCaptureScreen(
                region: .lowerLeg,
                onCapture: { data in
                    viewModel.handleSkinCapture(data, region: .lowerLeg)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .skinProcessingLeg:
            SkinProcessingScreen(
                progress: viewModel.skinAnalysisProgress,
                regionName: "Lower Leg"
            )
        case .skinCaptureAbdomen:
            SkinCaptureScreen(
                region: .abdomen,
                onCapture: { data in
                    viewModel.handleSkinCapture(data, region: .abdomen)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .skinResult:
            SkinResultScreen(
                skinType: viewModel.determinedSkinType,
                onContinue: { viewModel.nextScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 4: Face

struct WHOOPFacePhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .faceIntro:
            FaceIntroScreen(
                onContinue: { viewModel.nextScreen() },
                onSkip: { viewModel.skipToScreen(OnboardingScreenIndex.faceResult.rawValue + 1) } // Skip to next phase
            )
        case .faceCaptureFull:
            FaceCaptureScreen(
                captureType: .fullFace,
                onCapture: { data in
                    viewModel.handleFaceCapture(data, type: .fullFace)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .faceProcessing:
            FaceProcessingScreen(progress: viewModel.faceAnalysisProgress)
        case .faceCaptureUnderEye:
            FaceCaptureScreen(
                captureType: .underEye,
                onCapture: { data in
                    viewModel.handleFaceCapture(data, type: .underEye)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .faceResult:
            FaceResultScreen(onContinue: { viewModel.nextScreen() })
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 5: Hair

struct WHOOPHairPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .hairIntro:
            HairIntroScreen(
                onContinue: { viewModel.nextScreen() },
                onSkip: { viewModel.skipToScreen(OnboardingScreenIndex.hairResult.rawValue + 1) }
            )
        case .hairCaptureFrontal:
            HairCaptureScreen(
                captureType: .frontalHairline,
                onCapture: { data in
                    viewModel.handleHairCapture(data, type: .frontalHairline)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .hairCaptureCrown:
            HairCaptureScreen(
                captureType: .crownScalp,
                onCapture: { data in
                    viewModel.handleHairCapture(data, type: .crownScalp)
                    viewModel.nextScreen()
                },
                onBack: { viewModel.previousScreen() }
            )
        case .hairProcessing:
            HairProcessingScreen(progress: viewModel.hairAnalysisProgress)
        case .hairResult:
            HairResultScreen(
                densityScore: viewModel.hairDensityScore,
                thinningIndicator: viewModel.thinningIndicator,
                onContinue: { viewModel.nextScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 6: Body Composition

struct WHOOPCompositionPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .compositionProcessing:
            CompositionProcessingScreen(progress: viewModel.compositionProgress)
        case .compositionResult:
            CompositionResultScreen(
                bodyFatCategory: viewModel.bodyFatCategory,
                muscleSignal: viewModel.muscleSignal,
                waterRetention: viewModel.waterRetention,
                confidence: viewModel.compositionConfidence,
                onContinue: { viewModel.nextScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 7: Lifestyle

struct WHOOPLifestylePhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .activityLevel:
            ActivityLevelScreen(
                selection: $viewModel.activityLevel,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .sleepDuration:
            SleepDurationScreen(
                hours: $viewModel.sleepDuration,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .sleepQuality:
            SleepQualityScreen(
                quality: $viewModel.sleepQuality,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .stressLevel:
            StressLevelScreen(
                level: $viewModel.stressLevel,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .hydration:
            HydrationScreen(
                level: $viewModel.hydration,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        default:
            EmptyView()
        }
    }
}

// MARK: - Phase 8: Nutrition

struct WHOOPNutritionPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        switch viewModel.currentScreen {
        case .dietType:
            DietTypeScreen(
                selection: $viewModel.dietType,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .nutritionGoal:
            NutritionGoalScreen(
                selection: $viewModel.nutritionGoal,
                onContinue: { viewModel.nextScreen() },
                onBack: { viewModel.previousScreen() }
            )
        case .calorieReveal:
            CalorieRevealScreen(
                bmr: viewModel.calculatedBMR,
                tdee: viewModel.calculatedTDEE,
                targetCalories: viewModel.targetCalories,
                nutritionGoal: viewModel.nutritionGoal,
                onContinue: { viewModel.nextScreen() }
            )
        default:
            EmptyView()
        }
    }
}
