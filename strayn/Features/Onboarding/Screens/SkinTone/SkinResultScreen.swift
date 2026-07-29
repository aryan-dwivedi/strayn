//
//  SkinResultScreen.swift
//  strayn
//
//  Skin type result reveal screen.
//

import SwiftUI

struct SkinResultScreen: View {
    let skinType: FitzpatrickSkinType?
    let onContinue: () -> Void

    @State private var showResult = false

    var body: some View {
        OnboardingResultScreen(
            title: "Your Skin Type",
            subtitle: "Based on your captured images",
            onContinue: onContinue
        ) {
            VStack(spacing: 32) {
                // Skin type display
                if let type = skinType {
                    VStack(spacing: 20) {
                        // Type circle
                        ZStack {
                            Circle()
                                .fill(type.color)
                                .frame(width: 120, height: 120)
                                .shadow(color: type.color.opacity(0.5), radius: 20)

                            Text("Type \(type.rawValue)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .scaleEffect(showResult ? 1 : 0.5)
                        .opacity(showResult ? 1 : 0)

                        // Type name
                        Text(type.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(showResult ? 1 : 0)

                        // Description
                        Text(type.description)
                            .font(.system(size: 15))
                            .foregroundColor(StraynColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(showResult ? 1 : 0)
                    }

                    // UV Sensitivity card
                    uvSensitivityCard(for: type)
                        .padding(.top, 16)
                        .opacity(showResult ? 1 : 0)

                    // Fitzpatrick scale
                    fitzpatrickScale(selected: type)
                        .padding(.top, 24)
                        .opacity(showResult ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showResult = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HapticsManager.shared.playScoreReveal()
            }
        }
    }

    private func uvSensitivityCard(for type: FitzpatrickSkinType) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 24))
                .foregroundColor(uvColor(for: type.uvSensitivity))

            VStack(alignment: .leading, spacing: 4) {
                Text("UV Sensitivity")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)

                Text(type.uvSensitivity.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(StraynColors.surfacePrimary)
        )
    }

    private func uvColor(for sensitivity: UVSensitivity) -> Color {
        switch sensitivity {
        case .high: return StraynColors.zoneRed
        case .moderate: return StraynColors.zoneYellow
        case .low: return StraynColors.zoneGreen
        }
    }

    private func fitzpatrickScale(selected: FitzpatrickSkinType) -> some View {
        VStack(spacing: 12) {
            Text("Fitzpatrick Scale".uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)

            HStack(spacing: 8) {
                ForEach(FitzpatrickSkinType.allCases) { type in
                    Circle()
                        .fill(type.color)
                        .frame(width: type == selected ? 40 : 28, height: type == selected ? 40 : 28)
                        .overlay(
                            Circle()
                                .stroke(type == selected ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SkinResultScreen(
        skinType: .typeIII,
        onContinue: {}
    )
}
