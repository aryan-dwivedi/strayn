//
//  SexSelectionScreen.swift
//  strayn
//
//  Biological sex selection screen with card selection.
//

import SwiftUI

struct SexSelectionScreen: View {
    @Binding var selection: BiologicalSexOption
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Biological sex",
            subtitle: "Used to calculate accurate metabolic baselines",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                // Selection cards
                VStack(spacing: 16) {
                    ForEach(BiologicalSexOption.allCases) { option in
                        WHOOPSelectionCard(
                            item: option,
                            isSelected: selection == option,
                            icon: option.icon,
                            title: option.rawValue,
                            subtitle: subtitleFor(option),
                            onSelect: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selection = option
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private func subtitleFor(_ option: BiologicalSexOption) -> String {
        switch option {
        case .male:
            return "Biological male physiology"
        case .female:
            return "Biological female physiology"
        case .preferNotToSay:
            return "We'll use averaged calculations"
        }
    }
}

// MARK: - Preview

#Preview {
    SexSelectionScreen(
        selection: .constant(.male),
        onContinue: {},
        onBack: {}
    )
}
