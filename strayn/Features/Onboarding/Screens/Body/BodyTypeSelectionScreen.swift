//
//  BodyTypeSelectionScreen.swift
//  strayn
//
//  Body type selection screen with grid cards.
//

import SwiftUI

struct BodyTypeSelectionScreen: View {
    @Binding var selection: BodyTypeAssessment
    let onContinue: () -> Void
    let onBack: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        OnboardingScreenContainer(
            title: "Which best describes you?",
            subtitle: "Select your current body type",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                // Grid of body type options
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(BodyTypeAssessment.allCases) { bodyType in
                            WHOOPGridCard(
                                item: bodyType,
                                isSelected: selection == bodyType,
                                icon: bodyType.icon,
                                title: bodyType.rawValue,
                                description: bodyType.description,
                                accentColor: StraynColors.strain,
                                onSelect: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selection = bodyType
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Continue button
                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyTypeSelectionScreen(
        selection: .constant(.average),
        onContinue: {},
        onBack: {}
    )
}
