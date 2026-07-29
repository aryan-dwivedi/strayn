//
//  AnimatedNumberText.swift
//  strayn
//
//  Animated number display with counting effect and haptic feedback.
//

import SwiftUI

// MARK: - Animated Number Text

struct AnimatedNumberText: View {
    let value: Double
    let format: NumberFormat
    let font: Font
    let color: Color
    let animationDuration: Double
    let hapticOnComplete: Bool

    @State private var animatedValue: Double = 0
    @State private var hasAnimated = false

    enum NumberFormat {
        case integer           // "85"
        case oneDecimal        // "85.5"
        case twoDecimal        // "85.50"
        case percentage        // "85%"
        case percentageDecimal // "85.5%"

        func format(_ value: Double) -> String {
            switch self {
            case .integer:
                return "\(Int(value))"
            case .oneDecimal:
                return String(format: "%.1f", value)
            case .twoDecimal:
                return String(format: "%.2f", value)
            case .percentage:
                return "\(Int(value))%"
            case .percentageDecimal:
                return String(format: "%.1f%%", value)
            }
        }
    }

    init(
        value: Double,
        format: NumberFormat = .integer,
        font: Font = StraynTypography.displayMedium(),
        color: Color = StraynColors.textPrimary,
        animationDuration: Double = 1.2,
        hapticOnComplete: Bool = false
    ) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
        self.animationDuration = animationDuration
        self.hapticOnComplete = hapticOnComplete
    }

    var body: some View {
        Text(format.format(animatedValue))
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText(value: animatedValue))
            .monospacedDigit()
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { newValue in
                animateToNewValue(newValue)
            }
    }

    private func animateValue() {
        guard !hasAnimated else { return }
        hasAnimated = true

        withAnimation(.easeOut(duration: animationDuration)) {
            animatedValue = value
        }

        if hapticOnComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                HapticsManager.shared.playSuccess()
            }
        }
    }

    private func animateToNewValue(_ newValue: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animatedValue = newValue
        }
    }
}

// MARK: - Score Reveal Animation

struct ScoreRevealText: View {
    let score: Double
    let maxScore: Double
    let label: String
    let color: Color
    let size: ScoreSize

    @State private var isRevealed = false
    @State private var animatedScore: Double = 0

    enum ScoreSize {
        case small, medium, large, hero

        var fontSize: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 42
            case .large: return 56
            case .hero: return 72
            }
        }

        var labelSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            case .hero: return 16
            }
        }
    }

    init(
        score: Double,
        maxScore: Double = 100,
        label: String = "",
        color: Color = StraynColors.recovery,
        size: ScoreSize = .large
    ) {
        self.score = score
        self.maxScore = maxScore
        self.label = label
        self.color = color
        self.size = size
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(Int(animatedScore))")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText(value: animatedScore))
                    .monospacedDigit()

                if maxScore == 100 {
                    Text("%")
                        .font(.system(size: size.fontSize * 0.4, weight: .bold, design: .rounded))
                        .foregroundColor(color.opacity(0.7))
                }
            }
            .scaleEffect(isRevealed ? 1.0 : 0.8)
            .opacity(isRevealed ? 1.0 : 0.0)

            if !label.isEmpty {
                Text(label.uppercased())
                    .font(.system(size: size.labelSize, weight: .bold))
                    .tracking(2)
                    .foregroundColor(StraynColors.textTertiary)
                    .opacity(isRevealed ? 1.0 : 0.0)
            }
        }
        .onAppear {
            revealScore()
        }
    }

    private func revealScore() {
        // Phase 1: Fade in
        withAnimation(.easeOut(duration: 0.3)) {
            isRevealed = true
        }

        // Phase 2: Count up
        withAnimation(StraynAnimations.scoreReveal) {
            animatedScore = score
        }

        // Phase 3: Haptic at end
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            HapticsManager.shared.playScoreReveal()
        }
    }
}

// MARK: - Counting Number with Timer

struct CountingNumber: View {
    let targetValue: Double
    let duration: Double
    let format: String

    @State private var currentValue: Double = 0
    @State private var timer: Timer?

    init(targetValue: Double, duration: Double = 1.5, format: String = "%.0f") {
        self.targetValue = targetValue
        self.duration = duration
        self.format = format
    }

    var body: some View {
        Text(String(format: format, currentValue))
            .onAppear {
                startCounting()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onChange(of: targetValue) { newValue in
                startCounting(to: newValue)
            }
    }

    private func startCounting(to target: Double? = nil) {
        timer?.invalidate()

        let finalTarget = target ?? targetValue
        let startValue = currentValue
        let totalSteps = 60.0 * duration
        let increment = (finalTarget - startValue) / totalSteps
        var step = 0.0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            step += 1
            if step >= totalSteps {
                currentValue = finalTarget
                t.invalidate()
            } else {
                let progress = step / totalSteps
                // Ease out function
                let easeProgress = 1 - pow(1 - progress, 3)
                currentValue = startValue + (finalTarget - startValue) * easeProgress
            }
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let currentValue: Double
    let previousValue: Double
    let format: String
    let positiveIsGood: Bool

    init(
        currentValue: Double,
        previousValue: Double,
        format: String = "%.1f",
        positiveIsGood: Bool = true
    ) {
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.format = format
        self.positiveIsGood = positiveIsGood
    }

    private var difference: Double {
        currentValue - previousValue
    }

    private var percentChange: Double {
        guard previousValue != 0 else { return 0 }
        return (difference / previousValue) * 100
    }

    private var isPositive: Bool {
        difference > 0
    }

    private var trendColor: Color {
        if difference == 0 { return StraynColors.textMuted }

        let goodTrend = (isPositive && positiveIsGood) || (!isPositive && !positiveIsGood)
        return goodTrend ? StraynColors.zoneGreen : StraynColors.zoneRed
    }

    private var trendIcon: String {
        if difference == 0 { return "minus" }
        return isPositive ? "arrow.up" : "arrow.down"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.system(size: 10, weight: .bold))

            Text(String(format: format, abs(difference)))
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(trendColor)
    }
}

// MARK: - Value with Subtitle

struct ValueWithSubtitle: View {
    let value: String
    let subtitle: String
    let valueColor: Color
    let valueFont: Font
    let alignment: HorizontalAlignment

    init(
        value: String,
        subtitle: String,
        valueColor: Color = StraynColors.textPrimary,
        valueFont: Font = StraynTypography.headlineMedium(),
        alignment: HorizontalAlignment = .leading
    ) {
        self.value = value
        self.subtitle = subtitle
        self.valueColor = valueColor
        self.valueFont = valueFont
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(valueFont)
                .foregroundColor(valueColor)
                .monospacedDigit()

            Text(subtitle)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedNumberText(
                value: 85,
                format: .percentage,
                color: StraynColors.recovery
            )

            ScoreRevealText(
                score: 78,
                label: "Recovery",
                color: StraynColors.recovery,
                size: .hero
            )

            HStack(spacing: 20) {
                TrendIndicator(
                    currentValue: 85,
                    previousValue: 78,
                    positiveIsGood: true
                )

                TrendIndicator(
                    currentValue: 62,
                    previousValue: 68,
                    positiveIsGood: true
                )
            }

            ValueWithSubtitle(
                value: "42.5",
                subtitle: "VO2 MAX",
                valueColor: StraynColors.vo2Max
            )
        }
    }
}
