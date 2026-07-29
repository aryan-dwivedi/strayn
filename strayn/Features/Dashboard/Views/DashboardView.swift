//
//  DashboardView.swift
//  strayn
//
//  Premium Dashboard with WHOOP-inspired design, glassmorphism, and haptic feedback.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingJournal = false
    @State private var selectedBioMetric: String?
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showHealthspan = false

    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                StraynColors.premiumBackgroundGradient
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.recovery == nil {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: StraynSpacing.xxl) {
                            // Header with date navigation
                            headerSection

                            // Sleep Detection Banner
                            if viewModel.sleepDetection.showSleepPrompt {
                                sleepDetectionBanner
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            // Morning Journal Prompt
                            if let recovery = viewModel.recovery, recovery.journalData == nil {
                                journalPromptCard
                            }

                            // Main Metrics (WHOOP Style Rings)
                            mainMetricsSection

                            // Biological Engines Grid
                            biologicalEnginesSection

                            // AI Insight Card
                            if let brief = viewModel.healthBrief {
                                aiInsightSection(brief)
                            }

                            // Core Metrics List
                            coreMetricsSection

                            // Quick Actions
                            quickActionsSection
                        }
                        .padding(.vertical)
                        .padding(.bottom, 60)
                    }
                    .refreshable {
                        HapticsManager.shared.playPullToRefresh()
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingJournal, onDismiss: {
                Task { await viewModel.refreshData() }
            }) {
                MorningJournalView()
            }
            .sheet(item: Binding(
                get: { selectedBioMetric.map { BioMetricItem(name: $0) } },
                set: { selectedBioMetric = $0?.name }
            )) { item in
                biologicalDetail(for: item.name)
            }
            .fullScreenCover(isPresented: $showHealthspan) {
                HealthspanMainView()
            }
        }
        .task {
            await viewModel.requestPermissions()
            if Calendar.current.component(.hour, from: Date()) < 5 {
                viewModel.sleepDetection.simulateSleepDetection()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)

            Text("Syncing your biology...")
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textSecondary)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textTertiary)

                Text("Biology")
                    .font(StraynTypography.headlineLarge())
                    .foregroundColor(.white)
            }

            Spacer()

            // Date Navigation
            HStack(spacing: 16) {
                Button(action: { navigateDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StraynColors.textSecondary)
                }

                Button(action: { showDatePicker.toggle() }) {
                    Text("Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(StraynColors.surfaceSecondary)
                        )
                }

                Button(action: { navigateDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isToday ? StraynColors.textMuted : StraynColors.textSecondary)
                }
                .disabled(isToday)
            }

            // Profile Button
            Button(action: { HapticsManager.shared.playCardTap() }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(StraynColors.textSecondary)
            }
        }
        .padding(.horizontal)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private func navigateDate(by days: Int) {
        HapticsManager.shared.playSelection()
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
    }

    // MARK: - Sleep Detection Banner

    private var sleepDetectionBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(StraynColors.sleep)
                    .symbolEffect(.pulse)

                Text("Sleep Detected")
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    HapticsManager.shared.playSelection()
                    viewModel.sleepDetection.showSleepPrompt = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(StraynColors.textMuted)
                }
            }

            Text("We detected a sleep session from 11:30 PM to 7:00 AM. Is this correct?")
                .font(StraynTypography.bodySmall)
                .foregroundColor(StraynColors.textSecondary)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                Button(action: {
                    HapticsManager.shared.playSuccess()
                    Task { await viewModel.sleepDetection.confirmSleep() }
                }) {
                    Text("Confirm")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(StraynRadius.sm)
                }

                Button(action: {
                    HapticsManager.shared.playSelection()
                    viewModel.sleepDetection.showSleepPrompt = false
                }) {
                    Text("Edit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(StraynColors.surfaceSecondary)
                        .cornerRadius(StraynRadius.sm)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.sleep.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.sleep.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Journal Prompt Card

    private var journalPromptCard: some View {
        QuickActionCard(
            title: "Morning Journal",
            actionLabel: "Log habits",
            icon: "pencil.circle.fill"
        ) {
            showingJournal = true
        }
        .padding(.horizontal)
    }

    // MARK: - Main Metrics Section (WHOOP Style)

    private var mainMetricsSection: some View {
        HStack(spacing: 16) {
            // Sleep Ring (Compact)
            NavigationLink(destination: MetricDetailView(
                title: "Sleep",
                value: "\(Int(viewModel.recovery?.sleepScore ?? 0))%",
                unit: "EFFICIENCY",
                trend: generateTrend(base: viewModel.recovery?.sleepScore ?? 80),
                description: "Your sleep efficiency measures how much of your time in bed was spent actually sleeping.",
                color: StraynColors.sleep
            )) {
                CompactMetricRing(
                    type: .sleep,
                    value: viewModel.recovery?.sleepScore ?? 0,
                    size: 90
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Recovery Ring (Main)
            NavigationLink(destination: MetricDetailView(
                title: "Recovery",
                value: "\(Int(viewModel.recovery?.recoveryScore ?? 0))%",
                unit: "SCORE",
                trend: generateTrend(base: viewModel.recovery?.recoveryScore ?? 75),
                description: "Your comprehensive recovery status based on HRV, RHR, and Sleep quality.",
                color: Color.forRecoveryScore(viewModel.recovery?.recoveryScore ?? 0)
            )) {
                WHOOPStyleRing(
                    type: .recovery,
                    value: viewModel.recovery?.recoveryScore ?? 0,
                    size: 160,
                    lineWidth: 14,
                    showLabel: true
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Strain Ring (Compact)
            NavigationLink(destination: MetricDetailView(
                title: "Strain",
                value: String(format: "%.1f", viewModel.strain?.strainScore ?? 0),
                unit: "SCORE",
                trend: generateTrend(base: viewModel.strain?.strainScore ?? 10, range: 0...21),
                description: "Total cardiovascular load accumulated today through all activities.",
                color: StraynColors.strain
            )) {
                CompactMetricRing(
                    type: .strain,
                    value: viewModel.strain?.strainScore ?? 0,
                    size: 90
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }

    // MARK: - Biological Engines Section

    private var biologicalEnginesSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("BIOLOGICAL ENGINES")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Strayn Age - Opens new WHOOP-style Healthspan view
                    BiologicalEngineCard(
                        title: "Strayn Age",
                        value: String(format: "%.1f", viewModel.recovery?.straynAge ?? 30.0),
                        unit: "YEARS",
                        icon: "sparkles",
                        color: StraynColors.biologicalAge,
                        subtitle: "Tap for Healthspan"
                    ) {
                        showHealthspan = true
                    }

                    // Autonomic Balance
                    BiologicalEngineCard(
                        title: "Autonomic",
                        value: (viewModel.recovery?.autonomicBalance ?? 0) > 0.5 ? "Rest" : "Fight",
                        unit: "MODE",
                        icon: "scale.3d",
                        color: StraynColors.recovery,
                        subtitle: autonomicSubtitle
                    ) {
                        selectedBioMetric = "Autonomic Balance"
                    }

                    // Stress Load
                    BiologicalEngineCard(
                        title: "Stress Load",
                        value: String(format: "%.0f", viewModel.recovery?.stressLoad ?? 0),
                        unit: "INDEX",
                        icon: "bolt.fill",
                        color: StraynColors.stress,
                        subtitle: "Recovery debt"
                    ) {
                        selectedBioMetric = "Stress Load"
                    }

                    // VO2 Max
                    BiologicalEngineCard(
                        title: "VO2 Max",
                        value: String(format: "%.1f", viewModel.recovery?.rawVO2Max ?? 42.0),
                        unit: "ML/KG/MIN",
                        icon: "lungs.fill",
                        color: StraynColors.vo2Max,
                        subtitle: "Aerobic capacity"
                    ) {
                        selectedBioMetric = "VO2 Max"
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var autonomicSubtitle: String {
        (viewModel.recovery?.autonomicBalance ?? 0) > 0.5 ? "Parasympathetic" : "Sympathetic"
    }

    // MARK: - AI Insight Section

    private func aiInsightSection(_ brief: HealthBrief) -> some View {
        InsightCard(
            type: .recommendation,
            title: brief.title,
            message: brief.summary
        )
        .padding(.horizontal)
    }

    // MARK: - Core Metrics Section

    private var coreMetricsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("CORE METRICS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                NavigationLink(destination: MetricDetailView(
                    title: "HRV",
                    value: "\(Int(viewModel.recovery?.rawHRV ?? 0))",
                    unit: "MS",
                    trend: generateTrend(base: viewModel.recovery?.rawHRV ?? 50, range: 20...120),
                    description: "Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better recovery and stress resilience.",
                    color: StraynColors.hrv
                )) {
                    PremiumMetricCard(
                        title: "Heart Rate Variability",
                        value: "\(Int(viewModel.recovery?.rawHRV ?? 0))",
                        subtitle: "ms",
                        icon: "waveform.path.ecg",
                        color: StraynColors.hrv,
                        trend: .up,
                        trendValue: "+5%"
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: MetricDetailView(
                    title: "Resting Heart Rate",
                    value: "\(Int(viewModel.recovery?.rawRestingHR ?? 0))",
                    unit: "BPM",
                    trend: generateTrend(base: viewModel.recovery?.rawRestingHR ?? 60, range: 45...80),
                    description: "Your resting heart rate is a key indicator of cardiovascular fitness. Lower resting HR typically indicates better fitness.",
                    color: StraynColors.stress
                )) {
                    PremiumMetricCard(
                        title: "Resting Heart Rate",
                        value: "\(Int(viewModel.recovery?.rawRestingHR ?? 0))",
                        subtitle: "bpm",
                        icon: "heart.fill",
                        color: StraynColors.stress,
                        trend: .neutral,
                        trendValue: "0%"
                    )
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: MetricDetailView(
                    title: "VO2 Max",
                    value: String(format: "%.1f", viewModel.recovery?.rawVO2Max ?? 42.0),
                    unit: "ML/KG/MIN",
                    trend: generateTrend(base: viewModel.recovery?.rawVO2Max ?? 42, range: 30...60),
                    description: "VO2 Max measures your maximum oxygen uptake during exercise. It's the gold standard for aerobic fitness.",
                    color: StraynColors.vo2Max
                )) {
                    PremiumMetricCard(
                        title: "VO2 Max",
                        value: String(format: "%.1f", viewModel.recovery?.rawVO2Max ?? 42.0),
                        subtitle: "mL/kg/min",
                        icon: "lungs.fill",
                        color: StraynColors.vo2Max,
                        trend: .up,
                        trendValue: "+2%"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("RECOMMENDATIONS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                QuickActionCard(
                    title: "Track an Activity",
                    actionLabel: "Start",
                    icon: "figure.run"
                ) {
                    // TODO: Navigate to activity tracking
                }

                QuickActionCard(
                    title: "Talk to Sleep Coach",
                    actionLabel: "Plan Bedtime",
                    icon: "moon.zzz.fill"
                ) {
                    // TODO: Navigate to sleep coach
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func generateTrend(base: Double?, range: ClosedRange<Double> = 0...100) -> [Double] {
        let value = base ?? 50
        return (0..<7).map { i in
            let variation = Double.random(in: -10...10)
            return max(range.lowerBound, min(range.upperBound, value + variation - Double(6 - i) * 2))
        }
    }

    private func biologicalDetail(for name: String) -> some View {
        Group {
            switch name {
            case "Strayn Age":
                BiologicalDetailView(
                    title: "Strayn Age",
                    value: String(format: "%.1f", viewModel.recovery?.straynAge ?? 30.0),
                    subtitle: "Your Biological Age",
                    description: "Strayn Age is a composite calculation of your cardiovascular, autonomic, and respiratory performance relative to your chronological peers. A lower Strayn Age indicates high longevity potential and efficient physiological systems.",
                    color: StraynColors.biologicalAge,
                    icon: "sparkles"
                )
            case "Autonomic Balance":
                BiologicalDetailView(
                    title: "Autonomic Balance",
                    value: (viewModel.recovery?.autonomicBalance ?? 0) > 0.5 ? "Rest" : "Fight",
                    subtitle: "Nervous System State",
                    description: "This reflects the balance between your sympathetic (Fight or Flight) and parasympathetic (Rest and Digest) branches. Currently, you are leaning towards high parasympathetic activity, meaning you are primed for recovery and mental clarity.",
                    color: StraynColors.recovery,
                    icon: "scale.3d"
                )
            case "Stress Load":
                BiologicalDetailView(
                    title: "Stress Load",
                    value: String(format: "%.0f", viewModel.recovery?.stressLoad ?? 0),
                    subtitle: "Cumulative Stress",
                    description: "Stress Load tracks the total physiological strain on your body over the last 24 hours. This includes physical training, emotional stress, and environmental factors. High loads require proactive recovery interventions.",
                    color: StraynColors.stress,
                    icon: "bolt.fill"
                )
            case "VO2 Max":
                BiologicalDetailView(
                    title: "VO2 Max",
                    value: String(format: "%.1f", viewModel.recovery?.rawVO2Max ?? 42.0),
                    subtitle: "Aerobic Capacity",
                    description: "VO2 Max represents your body's maximum capacity to transport and use oxygen during exercise. It's the gold standard measure of cardiovascular fitness and correlates strongly with longevity.",
                    color: StraynColors.vo2Max,
                    icon: "lungs.fill"
                )
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Supporting Types

struct BioMetricItem: Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
