//
//  WHOOPStarRating.swift
//  strayn
//
//  WHOOP-style 5-star rating component with glow animations.
//

import SwiftUI

struct WHOOPStarRating: View {
    @Binding var rating: Int
    let maxRating: Int
    let label: String?
    let accentColor: Color

    init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        label: String? = nil,
        accentColor: Color = StraynColors.accentPrimary
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.label = label
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            if let label = label {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
            }

            HStack(spacing: 16) {
                ForEach(1...maxRating, id: \.self) { index in
                    StarView(
                        isFilled: index <= rating,
                        accentColor: accentColor,
                        index: index
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = index
                        }
                        HapticsManager.shared.playSelection()
                    }
                }
            }

            // Rating description
            Text(ratingDescription)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 0.2), value: rating)
        }
    }

    private var ratingDescription: String {
        switch rating {
        case 1: return "Very Poor"
        case 2: return "Poor"
        case 3: return "Average"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Not Rated"
        }
    }
}

// MARK: - Star View

private struct StarView: View {
    let isFilled: Bool
    let accentColor: Color
    let index: Int

    var body: some View {
        ZStack {
            // Glow effect
            if isFilled {
                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundColor(accentColor.opacity(0.5))
                    .blur(radius: 8)
            }

            // Star
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(isFilled ? accentColor : StraynColors.textMuted)
                .scaleEffect(isFilled ? 1.1 : 1.0)
        }
        .animation(
            .spring(response: 0.3, dampingFraction: 0.6).delay(Double(index) * 0.05),
            value: isFilled
        )
    }
}

// MARK: - Quality Level Rating (Alternative with labels)

struct WHOOPLevelRating: View {
    @Binding var level: Int
    let levels: [LevelOption]
    let accentColor: Color

    struct LevelOption: Identifiable {
        let id: Int
        let label: String
        let color: Color
    }

    init(
        level: Binding<Int>,
        levels: [LevelOption],
        accentColor: Color = StraynColors.accentPrimary
    ) {
        self._level = level
        self.levels = levels
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(levels) { option in
                    LevelButton(
                        option: option,
                        isSelected: option.id == level,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                level = option.id
                            }
                            HapticsManager.shared.playSelection()
                        }
                    )
                }
            }
        }
    }
}

private struct LevelButton: View {
    let option: WHOOPLevelRating.LevelOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? option.color : StraynColors.surfacePrimary)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? option.color : StraynColors.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )

                Text(option.label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            WHOOPStarRating(
                rating: .constant(4),
                label: "How would you rate your sleep quality?"
            )

            WHOOPLevelRating(
                level: .constant(3),
                levels: [
                    .init(id: 1, label: "Low", color: StraynColors.zoneGreen),
                    .init(id: 2, label: "Medium", color: StraynColors.zoneYellow),
                    .init(id: 3, label: "High", color: StraynColors.zoneYellow),
                    .init(id: 4, label: "Very High", color: StraynColors.zoneRed),
                    .init(id: 5, label: "Extreme", color: StraynColors.zoneRed)
                ]
            )
        }
        .padding()
    }
}
