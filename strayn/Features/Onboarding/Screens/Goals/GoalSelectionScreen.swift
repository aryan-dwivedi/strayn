//
//  GoalSelectionScreen.swift
//  strayn
//
//  Goal selection screen with multi-select cards.
//

import SwiftUI

struct GoalSelectionScreen: View {
    @Binding var selectedGoals: Set<PrimaryGoal>
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Your priorities",
            subtitle: "Select all that apply to personalize your experience",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(PrimaryGoal.allCases) { goal in
                            WHOOPMultiSelectCard(
                                item: goal,
                                isSelected: selectedGoals.contains(goal),
                                icon: goal.icon,
                                title: goal.rawValue,
                                description: goal.description,
                                accentColor: goal.color,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedGoals.contains(goal) {
                                            selectedGoals.remove(goal)
                                        } else {
                                            selectedGoals.insert(goal)
                                        }
                                    }
                                    HapticsManager.shared.playSelection()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // Selection count
                HStack {
                    Text("\(selectedGoals.count) selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StraynColors.textSecondary)

                    if selectedGoals.count == 0 {
                        Text("· Select at least one")
                            .font(.system(size: 14))
                            .foregroundColor(StraynColors.zoneYellow)
                    }
                }
                .padding(.bottom, 16)

                WHOOPContinueButton(
                    isEnabled: !selectedGoals.isEmpty,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GoalSelectionScreen(
        selectedGoals: .constant([.betterSleep, .higherRecovery]),
        onContinue: {},
        onBack: {}
    )
}
