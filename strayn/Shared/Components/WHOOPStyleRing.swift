//
//  WHOOPStyleRing.swift
//  strayn
//
//  Premium circular progress ring with WHOOP-inspired design and animations.
//

import SwiftUI

// MARK: - Ring Type

enum MetricRingType: Equatable {
    case recovery
    case strain
    case sleep
    case biologicalAge
    case vo2Max
    case custom(color: Color, icon: String)

    static func == (lhs: MetricRingType, rhs: MetricRingType) -> Bool {
        switch (lhs, rhs) {
        case (.recovery, .recovery): return true
        case (.strain, .strain): return true
        case (.sleep, .sleep): return true
        case (.biologicalAge, .biologicalAge): return true
        case (.vo2Max, .vo2Max): return true
        case (.custom(let c1, let i1), .custom(let c2, let i2)):
            return c1 == c2 && i1 == i2
        default: return false
        }
    }

    var color: Color {
        switch self {
        case .recovery: return StraynColors.recovery
        case .strain: return StraynColors.strain
        case .sleep: return StraynColors.sleep
        case .biologicalAge: return StraynColors.biologicalAge
        case .vo2Max: return StraynColors.vo2Max
        case .custom(let color, _): return color
        }
    }

    var icon: String {
        switch self {
        case .recovery: return "heart.fill"
        case .strain: return "flame.fill"
        case .sleep: return "moon.fill"
        case .biologicalAge: return "sparkles"
        case .vo2Max: return "lungs.fill"
        case .custom(_, let icon): return icon
        }
    }

    var label: String {
        switch self {
        case .recovery: return "Recovery"
        case .strain: return "Strain"
        case .sleep: return "Sleep"
        case .biologicalAge: return "Bio Age"
        case .vo2Max: return "VO2 Max"
        case .custom: return ""
        }
    }

    var maxValue: Double {
        switch self {
        case .strain: return 21.0
        case .vo2Max: return 60.0
        case .biologicalAge: return 100.0
        default: return 100.0
        }
    }

    var unit: String {
        switch self {
        case .recovery, .sleep: return "%"
        case .strain: return ""
        case .biologicalAge: return "yrs"
        case .vo2Max: return ""
        case .custom: return ""
        }
    }
}

// MARK: - WHOOP Style Ring

struct WHOOPStyleRing: View {
    let type: MetricRingType
    let value: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    let showIcon: Bool
    let onTap: (() -> Void)?

    @State private var animatedProgress: CGFloat = 0
    @State private var animatedValue: Double = 0
    @State private var isPressed = false
    @State private var hasAppeared = false

    private var progress: CGFloat {
        CGFloat(min(value / type.maxValue, 1.0))
    }

    private var displayValue: String {
        switch type {
        case .strain, .vo2Max:
            return String(format: "%.1f", animatedValue)
        default:
            return "\(Int(animatedValue))"
        }
    }

    init(
        type: MetricRingType,
        value: Double,
        size: CGFloat = 140,
        lineWidth: CGFloat = 12,
        showLabel: Bool = true,
        showIcon: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.type = type
        self.value = value
        self.size = size
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.showIcon = showIcon
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            ZStack {
                // Glassmorphic background
                Circle()
                    .fill(StraynColors.surfacePrimary)
                    .frame(width: size, height: size)

                // Background track
                Circle()
                    .stroke(
                        type.color.opacity(0.15),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size - lineWidth, height: size - lineWidth)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                type.color.opacity(0.6),
                                type.color,
                                type.color.opacity(0.8)
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size - lineWidth, height: size - lineWidth)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: type.color.opacity(0.4), radius: 8, x: 0, y: 4)

                // Center content
                VStack(spacing: 4) {
                    if showIcon {
                        Image(systemName: type.icon)
                            .font(.system(size: size * 0.12))
                            .foregroundColor(type.color)
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(displayValue)
                            .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText(value: animatedValue))
                            .monospacedDigit()

                        if !type.unit.isEmpty {
                            Text(type.unit)
                                .font(.system(size: size * 0.12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    if showLabel {
                        Text(type.label)
                            .font(.system(size: size * 0.08, weight: .bold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                    }
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            animateRing()
        }
        .onChange(of: value) { newValue in
            animateToNewValue(newValue)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        isPressed = false
                    }
                }
        )
    }

    private func animateRing() {
        // Animate progress ring
        withAnimation(StraynAnimations.scoreReveal) {
            animatedProgress = progress
        }

        // Animate number counting
        withAnimation(.easeOut(duration: 1.2)) {
            animatedValue = value
        }

        // Haptic at end
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticsManager.shared.playScoreReveal()
        }
    }

    private func animateToNewValue(_ newValue: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animatedProgress = CGFloat(min(newValue / type.maxValue, 1.0))
            animatedValue = newValue
        }
    }
}

// MARK: - Compact Ring (for dashboard grid)

struct CompactMetricRing: View {
    let type: MetricRingType
    let value: Double
    let size: CGFloat
    let onTap: (() -> Void)?

    @State private var animatedProgress: CGFloat = 0
    @State private var animatedValue: Double = 0

    private var progress: CGFloat {
        CGFloat(min(value / type.maxValue, 1.0))
    }

    init(
        type: MetricRingType,
        value: Double,
        size: CGFloat = 100,
        onTap: (() -> Void)? = nil
    ) {
        self.type = type
        self.value = value
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Background track
                    Circle()
                        .stroke(
                            type.color.opacity(0.2),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: size, height: size)

                    // Progress
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            type.color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: type.color.opacity(0.3), radius: 4)

                    // Value
                    Text(type == .strain ? String(format: "%.1f", animatedValue) : "\(Int(animatedValue))\(type.unit)")
                        .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(value: animatedValue))
                }

                Text(type.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(StraynAnimations.scoreReveal) {
                animatedProgress = progress
                animatedValue = value
            }
        }
    }
}

// MARK: - Triple Ring Display (Recovery, Sleep, Strain)

struct TripleRingDisplay: View {
    let recovery: Double
    let sleep: Double
    let strain: Double
    let size: CGFloat
    let onRecoveryTap: (() -> Void)?
    let onSleepTap: (() -> Void)?
    let onStrainTap: (() -> Void)?

    init(
        recovery: Double,
        sleep: Double,
        strain: Double,
        size: CGFloat = 120,
        onRecoveryTap: (() -> Void)? = nil,
        onSleepTap: (() -> Void)? = nil,
        onStrainTap: (() -> Void)? = nil
    ) {
        self.recovery = recovery
        self.sleep = sleep
        self.strain = strain
        self.size = size
        self.onRecoveryTap = onRecoveryTap
        self.onSleepTap = onSleepTap
        self.onStrainTap = onStrainTap
    }

    var body: some View {
        HStack(spacing: 16) {
            CompactMetricRing(
                type: .sleep,
                value: sleep,
                size: size * 0.8,
                onTap: onSleepTap
            )

            WHOOPStyleRing(
                type: .recovery,
                value: recovery,
                size: size,
                lineWidth: 14,
                showLabel: true,
                onTap: onRecoveryTap
            )

            CompactMetricRing(
                type: .strain,
                value: strain,
                size: size * 0.8,
                onTap: onStrainTap
            )
        }
    }
}

// MARK: - Biological Age Ring (Special Style)

struct BiologicalAgeRing: View {
    let chronologicalAge: Int
    let biologicalAge: Double
    let size: CGFloat
    let onTap: (() -> Void)?

    @State private var animatedAge: Double = 0
    @State private var isRevealed = false

    private var ageDifference: Double {
        Double(chronologicalAge) - biologicalAge
    }

    private var isYounger: Bool {
        ageDifference > 0
    }

    init(
        chronologicalAge: Int,
        biologicalAge: Double,
        size: CGFloat = 140,
        onTap: (() -> Void)? = nil
    ) {
        self.chronologicalAge = chronologicalAge
        self.biologicalAge = biologicalAge
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            ZStack {
                // Gradient background ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                StraynColors.biologicalAge.opacity(0.3),
                                StraynColors.biologicalAge.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .frame(width: size - 12, height: size - 12)

                // Animated accent arc
                Circle()
                    .trim(from: 0, to: isRevealed ? 0.7 : 0)
                    .stroke(
                        StraynColors.biologicalAge,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: size - 12, height: size - 12)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: StraynColors.biologicalAge.opacity(0.4), radius: 8)

                // Content
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.12))
                        .foregroundColor(StraynColors.biologicalAge)
                        .opacity(isRevealed ? 1 : 0)
                        .scaleEffect(isRevealed ? 1 : 0.5)

                    Text(String(format: "%.1f", animatedAge))
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(value: animatedAge))

                    Text("BIO AGE")
                        .font(.system(size: size * 0.08, weight: .bold))
                        .foregroundColor(.gray)

                    // Difference badge
                    HStack(spacing: 2) {
                        Image(systemName: isYounger ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.1f yrs", abs(ageDifference)))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(isYounger ? StraynColors.zoneGreen : StraynColors.zoneRed)
                    .opacity(isRevealed ? 1 : 0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isRevealed = true
            }
            withAnimation(StraynAnimations.scoreReveal) {
                animatedAge = biologicalAge
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                HapticsManager.shared.playScoreReveal()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 40) {
                WHOOPStyleRing(
                    type: .recovery,
                    value: 85,
                    size: 160,
                    showLabel: true
                )

                TripleRingDisplay(
                    recovery: 78,
                    sleep: 85,
                    strain: 14.5
                )

                HStack(spacing: 20) {
                    CompactMetricRing(type: .sleep, value: 92)
                    CompactMetricRing(type: .strain, value: 12.5)
                    CompactMetricRing(type: .vo2Max, value: 45)
                }

                BiologicalAgeRing(
                    chronologicalAge: 28,
                    biologicalAge: 24.5
                )
            }
            .padding()
        }
    }
}
