//
//  WHOOPMetricReveal.swift
//  strayn
//
//  WHOOP-style metric reveal animation with counting and glow effects.
//

import SwiftUI

struct WHOOPMetricReveal: View {
    let value: Double
    let label: String
    let unit: String
    let accentColor: Color
    let decimals: Int

    @State private var displayedValue: Double = 0
    @State private var showLabel = false
    @State private var showGlow = false

    init(
        value: Double,
        label: String,
        unit: String = "",
        accentColor: Color = StraynColors.accentPrimary,
        decimals: Int = 0
    ) {
        self.value = value
        self.label = label
        self.unit = unit
        self.accentColor = accentColor
        self.decimals = decimals
    }

    var body: some View {
        VStack(spacing: 8) {
            // Value with glow
            ZStack {
                if showGlow {
                    Text(formattedValue)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor.opacity(0.5))
                        .blur(radius: 15)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedValue)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(StraynColors.textSecondary)
                    }
                }
            }

            // Label
            Text(label.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
                .opacity(showLabel ? 1 : 0)
                .offset(y: showLabel ? 0 : 10)
        }
        .onAppear {
            animateReveal()
        }
    }

    private var formattedValue: String {
        if decimals == 0 {
            return String(format: "%.0f", displayedValue)
        } else {
            return String(format: "%.\(decimals)f", displayedValue)
        }
    }

    private func animateReveal() {
        // Count up animation
        let duration: Double = 1.5
        let steps = 60
        let stepDuration = duration / Double(steps)
        let increment = value / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    displayedValue = min(increment * Double(i), value)
                }

                // Play tick haptic every 10 steps
                if i % 10 == 0 && i > 0 {
                    HapticsManager.shared.playCountingTick()
                }
            }
        }

        // Show glow
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            showGlow = true
        }

        // Show label
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.0)) {
            showLabel = true
        }

        // Final haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            HapticsManager.shared.playSuccess()
        }
    }
}

// MARK: - Metric Card Reveal

struct WHOOPMetricCardReveal: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color
    let delay: Double

    @State private var isVisible = false

    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String? = nil,
        accentColor: Color = StraynColors.accentPrimary,
        delay: Double = 0
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.delay = delay
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                if isVisible {
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                }

                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(StraynColors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(StraynColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isVisible ? accentColor.opacity(0.3) : StraynColors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(color: isVisible ? accentColor.opacity(0.2) : .clear, radius: 12, x: 0, y: 4)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
                HapticsManager.shared.playImpact(.light)
            }
        }
    }
}

// MARK: - Composition Result View

struct WHOOPCompositionResult: View {
    let bodyFatCategory: BodyFatCategory
    let muscleSignal: MuscleSignal
    let waterRetention: WaterRetentionLevel
    let confidence: Double

    var body: some View {
        VStack(spacing: 16) {
            WHOOPMetricCardReveal(
                icon: bodyFatCategory.icon,
                title: "Body Fat",
                value: bodyFatCategory.rawValue,
                subtitle: bodyFatCategory.description,
                accentColor: bodyFatCategory.color,
                delay: 0
            )

            WHOOPMetricCardReveal(
                icon: muscleSignal.icon,
                title: "Muscle Signal",
                value: muscleSignal.rawValue,
                subtitle: muscleSignal.description,
                accentColor: StraynColors.strain,
                delay: 0.2
            )

            WHOOPMetricCardReveal(
                icon: "drop.fill",
                title: "Water Retention",
                value: waterRetention.rawValue,
                subtitle: waterRetention.description,
                accentColor: StraynColors.hrv,
                delay: 0.4
            )

            // Confidence indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(StraynColors.zoneGreen)

                Text("Analysis confidence: \(Int(confidence * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 40) {
                WHOOPMetricReveal(
                    value: 1856,
                    label: "Daily Calories",
                    unit: "kcal",
                    accentColor: StraynColors.strain
                )

                WHOOPMetricCardReveal(
                    icon: "flame.fill",
                    title: "BMR",
                    value: "1,650 kcal",
                    subtitle: "Basal Metabolic Rate"
                )

                WHOOPCompositionResult(
                    bodyFatCategory: .moderate,
                    muscleSignal: .medium,
                    waterRetention: .moderate,
                    confidence: 0.85
                )
            }
            .padding()
        }
    }
}
