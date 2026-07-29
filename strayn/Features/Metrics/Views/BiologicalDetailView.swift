//
//  BiologicalDetailView.swift
//  strayn
//
//  Enhanced biological metric detail view with staggered animations and haptics.
//

import SwiftUI
import Charts

struct BiologicalDetailView: View {
    let title: String
    let value: String
    let subtitle: String
    let description: String
    let color: Color
    let icon: String

    @Environment(\.dismiss) var dismiss
    @State private var revealPhase = 0
    @State private var animatedValue: Double = 0
    @State private var showContent = false

    // Mock historical data
    private var historicalData: [HistoricalPoint] {
        (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -6 + i, to: Date())!
            let baseValue = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) ?? 30
            let variation = Double.random(in: -3...3)
            return HistoricalPoint(date: date, value: baseValue + variation)
        }
    }

    var body: some View {
        ZStack {
            StraynColors.premiumBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: StraynSpacing.xxl) {
                    // Header with close button
                    headerSection

                    // Main Value Display
                    valueSection

                    // Historical Chart
                    chartSection

                    // What This Indicates
                    explanationSection

                    // Effects on Your Day
                    effectsSection

                    // Comparison Section
                    comparisonSection
                }
                .padding(.vertical)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startRevealSequence()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Button(action: {
                HapticsManager.shared.playSheetDismiss()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(StraynColors.surfaceSecondary)
                    )
            }

            Spacer()

            Text(title.uppercased())
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal)
    }

    // MARK: - Value Section

    private var valueSection: some View {
        VStack(spacing: StraynSpacing.lg) {
            // Animated ring/icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)

                // Animated progress ring
                Circle()
                    .trim(from: 0, to: revealPhase >= 1 ? 0.75 : 0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color.opacity(0.6), color, color.opacity(0.8)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(StraynAnimations.scoreReveal, value: revealPhase)
                    .shadow(color: color.opacity(0.4), radius: 10)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
                    .scaleEffect(revealPhase >= 1 ? 1.0 : 0.5)
                    .opacity(revealPhase >= 1 ? 1.0 : 0.0)
                    .animation(StraynAnimations.springMedium, value: revealPhase)
            }

            // Value display
            VStack(spacing: 8) {
                Text(value)
                    .font(StraynTypography.displayLarge())
                    .foregroundColor(.white)
                    .opacity(revealPhase >= 2 ? 1.0 : 0.0)
                    .offset(y: revealPhase >= 2 ? 0 : 20)
                    .animation(StraynAnimations.springMedium.delay(0.2), value: revealPhase)

                Text(subtitle)
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(StraynColors.textSecondary)
                    .opacity(revealPhase >= 2 ? 1.0 : 0.0)
                    .animation(StraynAnimations.springMedium.delay(0.3), value: revealPhase)
            }
        }
        .padding(.top, StraynSpacing.lg)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("7-DAY TREND")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            Chart {
                ForEach(historicalData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(30)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(StraynColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(StraynColors.textTertiary)
                }
            }
            .frame(height: 180)
        }
        .padding(StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
        .animation(StraynAnimations.springMedium.delay(0.4), value: showContent)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(color)
                Text("WHAT THIS INDICATES")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(color)
            }

            Text(description)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textSecondary)
                .lineSpacing(6)
        }
        .padding(StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
        .animation(StraynAnimations.springMedium.delay(0.5), value: showContent)
    }

    // MARK: - Effects Section

    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("EFFECTS ON YOUR DAY")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            HStack(spacing: StraynSpacing.md) {
                effectCard(
                    icon: "bolt.fill",
                    title: "Training",
                    subtitle: "Readiness",
                    status: getTrainingStatus()
                )

                effectCard(
                    icon: "brain.head.profile",
                    title: "Cognitive",
                    subtitle: "Performance",
                    status: getCognitiveStatus()
                )

                effectCard(
                    icon: "heart.fill",
                    title: "Cardiac",
                    subtitle: "Health",
                    status: getCardiacStatus()
                )
            }
        }
        .padding(.horizontal)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
        .animation(StraynAnimations.springMedium.delay(0.6), value: showContent)
    }

    private func effectCard(icon: String, title: String, subtitle: String, status: EffectStatus) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(status.color)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(StraynTypography.labelMedium(.semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textTertiary)
            }

            Text(status.label)
                .font(StraynTypography.labelSmall(.bold))
                .foregroundColor(status.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, StraynSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.lg)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.lg)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("COMPARISON")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            VStack(spacing: 12) {
                comparisonRow(
                    label: "vs. Your Baseline",
                    value: "+8%",
                    isPositive: true
                )

                Divider()
                    .background(StraynColors.borderSubtle)

                comparisonRow(
                    label: "vs. Last Week",
                    value: "+12%",
                    isPositive: true
                )

                Divider()
                    .background(StraynColors.borderSubtle)

                comparisonRow(
                    label: "vs. Age Group Average",
                    value: "+15%",
                    isPositive: true
                )
            }
            .padding(StraynSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .fill(StraynColors.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .stroke(StraynColors.borderSubtle, lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
        .animation(StraynAnimations.springMedium.delay(0.7), value: showContent)
    }

    private func comparisonRow(label: String, value: String, isPositive: Bool) -> some View {
        HStack {
            Text(label)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                Text(value)
                    .font(StraynTypography.labelLarge(.bold))
            }
            .foregroundColor(isPositive ? StraynColors.zoneGreen : StraynColors.zoneRed)
        }
    }

    // MARK: - Animation

    private func startRevealSequence() {
        // Phase 1: Ring and icon
        withAnimation {
            revealPhase = 1
        }

        // Phase 2: Value display
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                revealPhase = 2
            }
            HapticsManager.shared.playScoreReveal()
        }

        // Phase 3: Content sections
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showContent = true
        }
    }

    // MARK: - Status Helpers

    private func getTrainingStatus() -> EffectStatus {
        // Mock logic based on title
        switch title {
        case "Strayn Age": return .optimal
        case "Autonomic Balance": return value == "Rest" ? .optimal : .moderate
        case "Stress Load": return .moderate
        default: return .optimal
        }
    }

    private func getCognitiveStatus() -> EffectStatus {
        switch title {
        case "Strayn Age": return .optimal
        case "Autonomic Balance": return value == "Rest" ? .optimal : .suboptimal
        case "Stress Load": return .suboptimal
        default: return .moderate
        }
    }

    private func getCardiacStatus() -> EffectStatus {
        switch title {
        case "VO2 Max": return .optimal
        default: return .optimal
        }
    }
}

// MARK: - Supporting Types

struct HistoricalPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum EffectStatus {
    case optimal, moderate, suboptimal

    var label: String {
        switch self {
        case .optimal: return "Optimal"
        case .moderate: return "Moderate"
        case .suboptimal: return "Suboptimal"
        }
    }

    var color: Color {
        switch self {
        case .optimal: return StraynColors.zoneGreen
        case .moderate: return StraynColors.zoneYellow
        case .suboptimal: return StraynColors.zoneRed
        }
    }
}

// MARK: - Preview

#Preview {
    BiologicalDetailView(
        title: "Strayn Age",
        value: "24.5",
        subtitle: "Your Biological Age",
        description: "Strayn Age is a composite calculation of your cardiovascular, autonomic, and respiratory performance relative to your chronological peers.",
        color: StraynColors.biologicalAge,
        icon: "sparkles"
    )
}
