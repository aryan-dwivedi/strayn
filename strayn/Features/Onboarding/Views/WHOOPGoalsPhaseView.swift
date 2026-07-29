//
//  WHOOPGoalsPhaseView.swift
//  strayn
//
//  Created for the WHOOP-style onboarding flow.
//

import SwiftUI

struct WHOOPGoalsPhaseView: View {
    @ObservedObject var viewModel: WHOOPOnboardingViewModel
    
    var body: some View {
        // Since there is only one screen in this phase (goalSelection), we don't need a switch statement
        goalSelection
    }
    
    // MARK: - Goal Selection Screen
    
    private var goalSelection: some View {
        OnboardingScreenContainer(
            title: "What are your primary goals?",
            subtitle: "Select all that apply to personalize your insights",
            showBackButton: true,
            onBack: { viewModel.previousScreen() }
        ) {
            VStack(spacing: 32) {
                // Multi-select grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                        GoalSelectionCard(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer().frame(height: 20)
                
                WHOOPContinueButton(
                    title: "Continue",
                    isEnabled: !viewModel.selectedGoals.isEmpty
                ) {
                    viewModel.nextScreen()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Helper Components

struct GoalSelectionCard: View {
    let goal: PrimaryGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color.opacity(0.2) : StraynColors.surfaceSecondary.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(isSelected ? goal.color : StraynColors.textSecondary)
                }
                
                Text(goal.rawValue)
                    .font(StraynTypography.labelMedium(.medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.4)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? goal.color : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
