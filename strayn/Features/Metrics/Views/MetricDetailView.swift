//
//  MetricDetailView.swift
//  strayn
//
//  Enhanced metric detail view with historical comparison and AI insights.
//

import SwiftUI
import Charts

struct MetricDetailView: View {
    let title: String
    let value: String
    let unit: String
    let trend: [Double]
    let description: String
    let color: Color

    @State private var showContent = false
    @State private var selectedTimeRange: TimeRangeOption = .week

    enum TimeRangeOption: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
    }

    // Generate chart data based on time range
    private var chartData: [ChartDataPoint] {
        let days = selectedTimeRange == .week ? 7 : (selectedTimeRange == .month ? 30 : 90)
        return (0..<days).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -(days - 1 - i), to: Date())!
            let baseValue = trend.last ?? 50
            let variation = Double.random(in: -15...15)
            let trendFactor = Double(i) / Double(days) * 10
            return ChartDataPoint(date: date, value: max(0, baseValue + variation - 5 + trendFactor))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StraynSpacing.xxl) {
                // Hero Value Section
                heroSection

                // Time Range Picker
                timeRangePicker

                // Chart Section
                chartSection

                // Statistics Grid
                statisticsSection

                // Explanation Section
                explanationSection

                // Factors Section
                factorsSection

                // AI Insight
                aiInsightSection
            }
            .padding(.vertical)
            .padding(.bottom, 40)
        }
        .background(StraynColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(StraynAnimations.springMedium.delay(0.2)) {
                showContent = true
            }
            HapticsManager.shared.playCardTap()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(value)
                    .font(StraynTypography.displayLarge())
                    .foregroundColor(color)

                Text(unit)
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(StraynColors.textTertiary)
            }

            // Trend badge
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                Text("+8% vs last week")
                    .font(StraynTypography.labelMedium(.semibold))
            }
            .foregroundColor(StraynColors.zoneGreen)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRangeOption.allCases, id: \.self) { option in
                Button(action: {
                    HapticsManager.shared.playSelection()
                    withAnimation(.spring()) {
                        selectedTimeRange = option
                    }
                }) {
                    Text(option.rawValue)
                        .font(StraynTypography.labelMedium(.semibold))
                        .foregroundColor(selectedTimeRange == option ? .black : StraynColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTimeRange == option ?
                            Color.white : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(StraynColors.surfacePrimary)
        )
        .padding(.horizontal)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Chart {
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

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
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(StraynColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { value in
                    if selectedTimeRange == .week {
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(StraynColors.textTertiary)
                    } else {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(StraynColors.textTertiary)
                    }
                }
            }
            .frame(height: 200)
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
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("STATISTICS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(title: "Average", value: calculateAverage(), subtitle: "This period")
                statCard(title: "High", value: String(format: "%.0f", chartData.map { $0.value }.max() ?? 0), subtitle: "Peak value")
                statCard(title: "Low", value: String(format: "%.0f", chartData.map { $0.value }.min() ?? 0), subtitle: "Minimum")
                statCard(title: "Trend", value: "+12%", subtitle: "vs previous", isPositive: true)
            }
            .padding(.horizontal)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func statCard(title: String, value: String, subtitle: String, isPositive: Bool? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(StraynTypography.labelMedium())
                .foregroundColor(StraynColors.textTertiary)

            Text(value)
                .font(StraynTypography.headlineMedium())
                .foregroundColor(isPositive == true ? StraynColors.zoneGreen : (isPositive == false ? StraynColors.zoneRed : .white))

            Text(subtitle)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(StraynSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.lg)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.lg)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
    }

    private func calculateAverage() -> String {
        let avg = chartData.map { $0.value }.reduce(0, +) / Double(chartData.count)
        return String(format: "%.0f", avg)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(color)
                Text("WHAT THIS MEANS")
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
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Factors Section

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("INFLUENCING FACTORS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)

            VStack(spacing: 12) {
                factorRow(icon: "moon.fill", title: "Sleep Quality", impact: "High Impact", color: StraynColors.sleep)
                factorRow(icon: "figure.run", title: "Physical Activity", impact: "Medium Impact", color: StraynColors.strain)
                factorRow(icon: "drop.fill", title: "Hydration", impact: "Low Impact", color: StraynColors.accentPrimary)
            }
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
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func factorRow(icon: String, title: String, impact: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Text(title)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            Text(impact)
                .font(StraynTypography.labelSmall(.semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - AI Insight Section

    private var aiInsightSection: some View {
        InsightCard(
            type: .recommendation,
            title: "Optimization Tip",
            message: "Based on your \(title.lowercased()) trends, consider focusing on consistent sleep schedules. Your best readings correlate with nights where you slept before 11 PM."
        )
        .padding(.horizontal)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }
}

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Preview

#Preview {
    NavigationView {
        MetricDetailView(
            title: "Recovery",
            value: "85",
            unit: "%",
            trend: [65, 70, 72, 78, 82, 80, 85],
            description: "Your comprehensive recovery status based on HRV, RHR, and Sleep quality.",
            color: StraynColors.recovery
        )
    }
}
