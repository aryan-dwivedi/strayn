//
//  WHOOPSelectionCard.swift
//  strayn
//
//  WHOOP-style selection card with glow effects and spring animations.
//

import SwiftUI

struct WHOOPSelectionCard<T: Hashable>: View {
    let item: T
    let isSelected: Bool
    let icon: String
    let title: String
    let subtitle: String?
    let accentColor: Color
    let onSelect: () -> Void

    init(
        item: T,
        isSelected: Bool,
        icon: String,
        title: String,
        subtitle: String? = nil,
        accentColor: Color = StraynColors.accentPrimary,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            onSelect()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.2) : StraynColors.surfacePrimary)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? accentColor : StraynColors.textSecondary)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(StraynColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : StraynColors.borderMedium, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(StraynColors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? accentColor : StraynColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 15, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Compact Card Variant

struct WHOOPCompactCard<T: Hashable>: View {
    let item: T
    let isSelected: Bool
    let icon: String
    let title: String
    let accentColor: Color
    let onSelect: () -> Void

    init(
        item: T,
        isSelected: Bool,
        icon: String,
        title: String,
        accentColor: Color = StraynColors.accentPrimary,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.accentColor = accentColor
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            onSelect()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.2) : StraynColors.surfacePrimary)
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isSelected ? accentColor : StraynColors.textSecondary)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(StraynColors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : StraynColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: isSelected ? accentColor.opacity(0.25) : .clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Grid Card for Body Type Selection

struct WHOOPGridCard<T: Hashable>: View {
    let item: T
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let onSelect: () -> Void

    init(
        item: T,
        isSelected: Bool,
        icon: String,
        title: String,
        description: String,
        accentColor: Color = StraynColors.accentPrimary,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            onSelect()
        }) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? accentColor.opacity(0.15) : StraynColors.surfaceSecondary)
                        .frame(height: 80)

                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(isSelected ? accentColor : StraynColors.textSecondary)
                }

                // Title
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Description
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(StraynColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(StraynColors.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? accentColor : StraynColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: isSelected ? accentColor.opacity(0.2) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            WHOOPSelectionCard(
                item: "male",
                isSelected: true,
                icon: "person.fill",
                title: "Male",
                subtitle: "Biological male",
                onSelect: {}
            )

            WHOOPSelectionCard(
                item: "female",
                isSelected: false,
                icon: "person.fill",
                title: "Female",
                subtitle: "Biological female",
                onSelect: {}
            )

            HStack(spacing: 16) {
                WHOOPCompactCard(
                    item: 1,
                    isSelected: true,
                    icon: "figure.walk",
                    title: "Active",
                    onSelect: {}
                )

                WHOOPCompactCard(
                    item: 2,
                    isSelected: false,
                    icon: "figure.run",
                    title: "Athletic",
                    onSelect: {}
                )
            }
        }
        .padding()
    }
}
