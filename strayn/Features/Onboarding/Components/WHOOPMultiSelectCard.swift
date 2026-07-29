//
//  WHOOPMultiSelectCard.swift
//  strayn
//
//  WHOOP-style multi-select card with glow effects for goal selection.
//

import SwiftUI

struct WHOOPMultiSelectCard<T: Hashable>: View {
    let item: T
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let onToggle: () -> Void

    init(
        item: T,
        isSelected: Bool,
        icon: String,
        title: String,
        description: String,
        accentColor: Color = StraynColors.accentPrimary,
        onToggle: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
        self.onToggle = onToggle
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Icon with glow
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(accentColor.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                    }

                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.2) : StraynColors.surfacePrimary)
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? accentColor : StraynColors.textSecondary)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(StraynColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? accentColor : StraynColors.borderMedium, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: 16, height: 16)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(StraynColors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? accentColor.opacity(0.5) : StraynColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: isSelected ? accentColor.opacity(0.25) : .clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            WHOOPMultiSelectCard(
                item: "sleep",
                isSelected: true,
                icon: "moon.fill",
                title: "Better Sleep",
                description: "Improve sleep quality and duration",
                accentColor: .purple,
                onToggle: {}
            )

            WHOOPMultiSelectCard(
                item: "recovery",
                isSelected: false,
                icon: "battery.100.bolt",
                title: "Higher Recovery",
                description: "Maximize daily recovery scores",
                accentColor: .green,
                onToggle: {}
            )

            WHOOPMultiSelectCard(
                item: "stress",
                isSelected: true,
                icon: "brain.head.profile",
                title: "Stress Reduction",
                description: "Lower stress and improve HRV",
                accentColor: .blue,
                onToggle: {}
            )
        }
        .padding()
    }
}
