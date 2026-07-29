//
//  DayDetailView.swift
//  strayn
//
//  Detailed view for a specific day showing all metrics, journal, and activities.
//

import SwiftUI
import Charts

struct DayDetailView: View {
    let date: Date

    @Environment(\.dismiss) var dismiss
    @State private var showContent = false

    // Mock data - in real app, fetch from repositories
    private var recovery: DailyRecovery {
        DailyRecovery(
            date: date,
            recoveryScore: Double.random(in: 50...95),
            recoveryZone: .green,
            hrvScore: Double.random(in: 60...90),
            restingHRScore: Double.random(in: 70...90),
            sleepScore: Double.random(in: 65...95),
            respiratoryRateScore: Double.random(in: 75...95),
            rawHRV: Double.random(in: 40...80),
            rawRestingHR: Double.random(in: 52...68),
            rawSleepDuration: Double.random(in: 6...9) * 3600,
            rawRespiratoryRate: Double.random(in: 12...16),
            autonomicBalance: Double.random(in: 0.4...0.8),
            stressLoad: Double.random(in: 20...60),
            straynAge: Double.random(in: 24...32),
            rawVO2Max: Double.random(in: 38...50)
        )
    }

    var body: some View {
        ZStack {
            StraynColors.premiumBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: StraynSpacing.xxl) {
                    // Header
                    headerSection

                    // Overview Cards
                    overviewSection

                    // Detailed Metrics
                    metricsSection

                    // Sleep Summary (if data available)
                    sleepSection

                    // Journal Summary (if data available)
                    journalSection

                    // Activities
                    activitiesSection
                }
                .padding(.vertical)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(StraynAnimations.springMedium.delay(0.1)) {
                showContent = true
            }
            HapticsManager.shared.playCardTap()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: {
                HapticsManager.shared.playNavigationPop()
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

            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(.white)
                Text(date.formatted(.dateTime.day().month(.wide).year()))
                    .font(StraynTypography.labelMedium())
                    .foregroundColor(StraynColors.textSecondary)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        HStack(spacing: 12) {
            overviewCard(
                title: "Recovery",
                value: "\(Int(recovery.recoveryScore))%",
                color: Color.forRecoveryScore(recovery.recoveryScore),
                icon: "heart.fill"
            )

            overviewCard(
                title: "Strain",
                value: String(format: "%.1f", Double.random(in: 8...18)),
                color: StraynColors.strain,
                icon: "flame.fill"
            )

            overviewCard(
                title: "Sleep",
                value: "\(Int(recovery.sleepScore))%",
                color: StraynColors.sleep,
                icon: "moon.fill"
            )
        }
        .padding(.horizontal)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func overviewCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(StraynTypography.headlineMedium())
                    .foregroundColor(.white)

                Text(title)
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, StraynSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .fill(StraynColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StraynRadius.xl)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("DETAILED METRICS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                metricRow(title: "HRV", value: "\(Int(recovery.rawHRV ?? 0)) ms", icon: "waveform.path.ecg", color: StraynColors.hrv)
                metricRow(title: "Resting HR", value: "\(Int(recovery.rawRestingHR ?? 0)) bpm", icon: "heart.fill", color: StraynColors.stress)
                metricRow(title: "Strayn Age", value: String(format: "%.1f yrs", recovery.straynAge ?? 0), icon: "sparkles", color: StraynColors.biologicalAge)
                metricRow(title: "VO2 Max", value: String(format: "%.1f", recovery.rawVO2Max ?? 0), icon: "lungs.fill", color: StraynColors.vo2Max)
                metricRow(title: "Stress Load", value: String(format: "%.0f", recovery.stressLoad ?? 0), icon: "bolt.fill", color: StraynColors.stress)
            }
            .padding(.horizontal)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func metricRow(title: String, value: String, icon: String, color: Color) -> some View {
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

            Text(value)
                .font(StraynTypography.headlineSmall())
                .foregroundColor(color)
        }
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

    // MARK: - Sleep Section

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("SLEEP SUMMARY")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Asleep")
                            .font(StraynTypography.labelMedium())
                            .foregroundColor(StraynColors.textTertiary)
                        Text("7h 23m")
                            .font(StraynTypography.headlineMedium())
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Efficiency")
                            .font(StraynTypography.labelMedium())
                            .foregroundColor(StraynColors.textTertiary)
                        Text("\(Int(recovery.sleepScore))%")
                            .font(StraynTypography.headlineMedium())
                            .foregroundColor(StraynColors.sleep)
                    }
                }

                // Sleep stages bar
                HStack(spacing: 2) {
                    sleepStageBar(stage: "Deep", percentage: 0.18, color: Color(red: 0.2, green: 0.3, blue: 0.6))
                    sleepStageBar(stage: "REM", percentage: 0.22, color: StraynColors.sleep)
                    sleepStageBar(stage: "Light", percentage: 0.52, color: StraynColors.sleep.opacity(0.5))
                    sleepStageBar(stage: "Awake", percentage: 0.08, color: StraynColors.textMuted)
                }
                .frame(height: 24)
                .cornerRadius(4)

                // Legend
                HStack(spacing: 16) {
                    sleepLegendItem(color: Color(red: 0.2, green: 0.3, blue: 0.6), label: "Deep 18%")
                    sleepLegendItem(color: StraynColors.sleep, label: "REM 22%")
                    sleepLegendItem(color: StraynColors.sleep.opacity(0.5), label: "Light 52%")
                    sleepLegendItem(color: StraynColors.textMuted, label: "Awake 8%")
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
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func sleepStageBar(stage: String, percentage: Double, color: Color) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(color)
                .frame(width: geometry.size.width * percentage)
        }
    }

    private func sleepLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textSecondary)
        }
    }

    // MARK: - Journal Section

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("MORNING JOURNAL")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                journalItem(habit: "Hydration", performed: true)
                journalItem(habit: "Morning Sunlight", performed: true)
                journalItem(habit: "Late Meal", performed: false)
                journalItem(habit: "Alcohol", performed: false)
                journalItem(habit: "Meditation", performed: true)
                journalItem(habit: "Caffeine after 2 PM", performed: true)
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
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func journalItem(habit: String, performed: Bool) -> some View {
        HStack {
            Image(systemName: performed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(performed ? StraynColors.zoneGreen : StraynColors.zoneRed)

            Text(habit)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            Text(performed ? "Yes" : "No")
                .font(StraynTypography.labelMedium(.semibold))
                .foregroundColor(performed ? StraynColors.zoneGreen : StraynColors.zoneRed)
        }
    }

    // MARK: - Activities Section

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("ACTIVITIES")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                activityCard(
                    type: "Running",
                    icon: "figure.run",
                    duration: "45 min",
                    strain: "12.4",
                    calories: "420"
                )

                activityCard(
                    type: "Strength",
                    icon: "dumbbell.fill",
                    duration: "30 min",
                    strain: "8.2",
                    calories: "180"
                )
            }
            .padding(.horizontal)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func activityCard(type: String, icon: String, duration: String, strain: String, calories: String) -> some View {
        HStack(spacing: StraynSpacing.md) {
            ZStack {
                Circle()
                    .fill(StraynColors.strain.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(StraynColors.strain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(.white)
                Text(duration)
                    .font(StraynTypography.labelMedium())
                    .foregroundColor(StraynColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(StraynColors.strain)
                    Text(strain)
                        .font(StraynTypography.labelLarge(.bold))
                        .foregroundColor(.white)
                }
                Text("\(calories) cal")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textTertiary)
            }
        }
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
}

// MARK: - Preview

#Preview {
    DayDetailView(date: Date())
}
