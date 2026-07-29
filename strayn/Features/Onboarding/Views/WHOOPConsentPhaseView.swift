//
//  WHOOPConsentPhaseView.swift
//  strayn
//
//  Created for the WHOOP-style onboarding flow.
//

import SwiftUI

struct WHOOPConsentPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        Group {
            switch viewModel.currentScreen {
            case .privacySummary:
                privacySummaryScreen
            case .consentToggles:
                consentTogglesScreen
            case .completion:
                completionScreen
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Privacy Summary
    
    private var privacySummaryScreen: some View {
        OnboardingInfoScreen(
            icon: "lock.shield",
            title: "Your Privacy",
            description: "Your health data is sensitive. We believe you should be in complete control of how it's used.",
            accentColor: StraynColors.zoneGreen
        ) {
            WHOOPContinueButton(title: "Review Consents") {
                viewModel.nextScreen()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Consent Toggles
    
    private var consentTogglesScreen: some View {
        OnboardingScreenContainer(
            title: "Data Permissions",
            subtitle: "Please review and accept our data processing policies.",
            showBackButton: true,
            onBack: { viewModel.previousScreen() }
        ) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ConsentToggleRow(
                            title: "Camera & Analysis",
                            description: "Allow temporary camera access to analyze skin, face, and hair features. Images are processed locally and deleted immediately.",
                            isAccepted: $viewModel.cameraConsent
                        )
                        
                        ConsentToggleRow(
                            title: "Health Database",
                            description: "Store your biometric profile securely on your device for generating recovery insights.",
                            isAccepted: $viewModel.healthDataConsent
                        )
                        
                        ConsentToggleRow(
                            title: "AI Processing",
                            description: "Use advanced algorithms to interpret your physiological signals and provide recommendations.",
                            isAccepted: $viewModel.aiInsightsConsent
                        )
                        
                        ConsentToggleRow(
                            title: "Secure Handling",
                            description: "I acknowledge that my data is encrypted and will not be sold to third parties.",
                            isAccepted: $viewModel.secureProcessingAck
                        )
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        ConsentToggleRow(
                            title: "Terms of Service",
                            description: "I agree to the Terms of Service.",
                            isAccepted: $viewModel.termsAccepted
                        )
                        
                        ConsentToggleRow(
                            title: "Privacy Policy",
                            description: "I have read and agree to the Privacy Policy.",
                            isAccepted: $viewModel.privacyAccepted
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                
                // Bottom Action Area
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            viewModel.grantAllConsents()
                        }
                    }) {
                        Text("Accept All")
                            .font(StraynTypography.labelMedium(.medium))
                            .foregroundColor(StraynColors.accentPrimary)
                    }
                    
                    WHOOPContinueButton(
                        title: "Complete Setup",
                        isEnabled: viewModel.allConsentsGranted
                    ) {
                        viewModel.nextScreen()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    // MARK: - Completion Screen
    
    private var completionScreen: some View {
        OnboardingInfoScreen(
            icon: "checkmark.seal.fill",
            title: "You're All Set!",
            description: "Your personalized recovery profile has been created. Let's start tracking your strain.",
            accentColor: StraynColors.accentPrimary
        ) {
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("Start Using Strayn")
                    .font(StraynTypography.headlineSmall(.bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(StraynRadius.xl)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Helper Components

struct ConsentToggleRow: View {
    let title: String
    let description: String
    @Binding var isAccepted: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isAccepted.toggle()
                if isAccepted {
                    HapticsManager.shared.playSelection()
                }
            }
        }) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: isAccepted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isAccepted ? StraynColors.accentPrimary : StraynColors.textSecondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(StraynTypography.labelLarge(.bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(StraynTypography.bodyMedium)
                        .foregroundColor(StraynColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isAccepted 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isAccepted ? StraynColors.accentPrimary.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}
