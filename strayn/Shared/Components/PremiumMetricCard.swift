//
//  PremiumMetricCard.swift
//  strayn
//
//  Premium metric cards with glassmorphism for dashboard and detail views.
//

import SwiftUI

// MARK: - Premium Metric Card

struct PremiumMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?
    let trendValue: String?
    let onTap: (() -> Void)?

    enum TrendDirection {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }

    @State private var isPressed = false
    @State private var hasAppeared = false

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
        self.trendValue = trendValue
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StraynColors.textSecondary)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(value)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StraynColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Trend & Chevron
                HStack(spacing: 8) {
                    if let trend = trend, let trendValue = trendValue {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(trendValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(trendColor(for: trend))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StraynColors.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .stroke(StraynColors.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(StraynAnimations.springMedium) {
                hasAppeared = true
            }
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

    private func trendColor(for direction: TrendDirection) -> Color {
        switch direction {
        case .up: return StraynColors.zoneGreen
        case .down: return StraynColors.zoneRed
        case .neutral: return StraynColors.textMuted
        }
    }
}

// MARK: - Compact Metric Card (2-column grid)

struct CompactMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let onTap: (() -> Void)?

    @State private var isPressed = false

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)

                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(StraynColors.textTertiary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(StraynColors.textTertiary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .stroke(StraynColors.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
}

// MARK: - Biological Engine Card (Horizontal Scroll)

struct BiologicalEngineCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let subtitle: String
    let onTap: (() -> Void)?

    @State private var isPressed = false
    @State private var hasAppeared = false

    init(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color,
        subtitle: String,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(StraynColors.textTertiary)
                    Spacer()
                }

                // Value
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StraynColors.textTertiary)
                }

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.8))
            }
            .padding(20)
            .frame(width: 150)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .fill(StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .stroke(StraynColors.borderSubtle, lineWidth: 1)
            )
            .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(StraynAnimations.springMedium.delay(0.1)) {
                hasAppeared = true
            }
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
}

// MARK: - Insight Card (AI Analysis)

struct InsightCard: View {
    let type: InsightType
    let title: String
    let message: String
    let onTap: (() -> Void)?

    enum InsightType {
        case trend, correlation, recommendation, warning, celebration

        var icon: String {
            switch self {
            case .trend: return "chart.line.uptrend.xyaxis"
            case .correlation: return "link"
            case .recommendation: return "lightbulb.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .celebration: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .trend: return StraynColors.strain
            case .correlation: return StraynColors.sleep
            case .recommendation: return StraynColors.accentPrimary
            case .warning: return StraynColors.zoneYellow
            case .celebration: return StraynColors.biologicalAge
            }
        }

        var label: String {
            switch self {
            case .trend: return "TREND"
            case .correlation: return "CORRELATION"
            case .recommendation: return "RECOMMENDATION"
            case .warning: return "ATTENTION"
            case .celebration: return "ACHIEVEMENT"
            }
        }
    }

    @State private var isPressed = false

    init(
        type: InsightType,
        title: String,
        message: String,
        onTap: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticsManager.shared.playCardTap()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                    Text(type.label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(type.color)
                    Spacer()
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(StraynColors.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(3)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .fill(type.color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .stroke(type.color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let actionLabel: String
    let icon: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            onTap()
        }) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(StraynColors.accentPrimary)

                    Text(title.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(actionLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StraynColors.accentPrimary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StraynColors.accentPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.md)
                    .fill(StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.md)
                    .stroke(StraynColors.borderMedium, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                PremiumMetricCard(
                    title: "Heart Rate Variability",
                    value: "62",
                    subtitle: "ms",
                    icon: "waveform.path.ecg",
                    color: StraynColors.recovery,
                    trend: .up,
                    trendValue: "8%"
                )

                HStack(spacing: 12) {
                    CompactMetricCard(
                        title: "Steps",
                        value: "12,450",
                        subtitle: "8,000 goal",
                        icon: "figure.walk",
                        color: StraynColors.strain
                    )

                    CompactMetricCard(
                        title: "Heart Rate",
                        value: "68",
                        subtitle: "bpm",
                        icon: "heart.fill",
                        color: StraynColors.zoneRed
                    )
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        BiologicalEngineCard(
                            title: "Strayn Age",
                            value: "24.5",
                            unit: "YEARS",
                            icon: "sparkles",
                            color: StraynColors.biologicalAge,
                            subtitle: "3.5 years younger"
                        )

                        BiologicalEngineCard(
                            title: "Autonomic",
                            value: "Rest",
                            unit: "MODE",
                            icon: "scale.3d",
                            color: StraynColors.recovery,
                            subtitle: "Parasympathetic"
                        )
                    }
                }

                InsightCard(
                    type: .recommendation,
                    title: "Optimize Your Recovery",
                    message: "Your HRV dropped 15% this week. Consider reducing training load and improving sleep consistency."
                )

                QuickActionCard(
                    title: "Morning Journal",
                    actionLabel: "Log habits",
                    icon: "pencil.circle.fill"
                ) { }
            }
            .padding()
        }
    }
}
