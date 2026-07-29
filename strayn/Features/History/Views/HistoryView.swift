//
//  HistoryView.swift
//  strayn
//
//  Enhanced History/Trends view with filtering, calendar, and AI analysis.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject private var viewModel = TrendsViewModel()
    @State private var timeRange: TimeRange = .week
    @State private var showFilters = false
    @State private var showCalendar = false
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedDate: Date?

    private var selectedDateBinding: Binding<SelectedDateItem?> {
        Binding<SelectedDateItem?>(
            get: { selectedDate.map { SelectedDateItem(date: $0) } },
            set: { selectedDate = $0?.date }
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                StraynColors.premiumBackgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: StraynSpacing.xxl) {
                        // Header
                        headerSection

                        // View Mode Toggle (Chart/Calendar)
                        viewModeToggle

                        // Time Range Picker
                        timeRangePicker

                        // Main Content
                        if showCalendar {
                            calendarSection
                        } else {
                            chartSection
                        }

                        // AI Analysis Cards
                        aiAnalysisSection

                        // Filter Chips
                        filterSection

                        // Daily Logs List
                        dailyLogsSection
                    }
                    .padding(.vertical)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilters) {
                FilterSheet(selectedFilter: $selectedFilter)
            }
            .sheet(item: selectedDateBinding) { item in
                DayDetailView(date: item.date)
            }
        }
        .task {
            await viewModel.fetchHistory(for: timeRange)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("INSIGHTS")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textTertiary)

                Text("Trends")
                    .font(StraynTypography.headlineLarge())
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: {
                HapticsManager.shared.playCardTap()
                showFilters = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(StraynColors.textSecondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "Chart", icon: "chart.line.uptrend.xyaxis", isSelected: !showCalendar) {
                showCalendar = false
            }

            toggleButton(title: "Calendar", icon: "calendar", isSelected: showCalendar) {
                showCalendar = true
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.md)
                .fill(StraynColors.surfacePrimary)
        )
        .padding(.horizontal)
    }

    private func toggleButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            withAnimation(.spring()) {
                action()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(StraynTypography.labelMedium(.semibold))
            }
            .foregroundColor(isSelected ? .black : StraynColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(StraynRadius.sm)
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    HapticsManager.shared.playSelection()
                    timeRange = range
                    Task { await viewModel.fetchHistory(for: range) }
                }) {
                    Text(range.rawValue)
                        .font(StraynTypography.labelMedium(.semibold))
                        .foregroundColor(timeRange == range ? .black : StraynColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(timeRange == range ? Color.white : Color.clear)
                        .cornerRadius(StraynRadius.sm)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: StraynRadius.md)
                .fill(StraynColors.surfacePrimary)
        )
        .padding(.horizontal)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("RECOVERY VS STRAIN")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            Chart {
                ForEach(viewModel.recoveryHistory) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Recovery", item.recoveryScore)
                    )
                    .foregroundStyle(StraynColors.recovery)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Recovery", item.recoveryScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [StraynColors.recovery.opacity(0.3), StraynColors.recovery.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                ForEach(viewModel.strainHistory) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Strain", item.strainScore * 5)
                    )
                    .foregroundStyle(StraynColors.strain)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
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
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(StraynColors.textTertiary)
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 20) {
                    legendItem(color: StraynColors.recovery, label: "Recovery")
                    legendItem(color: StraynColors.strain, label: "Strain")
                }
            }
            .frame(height: 220)
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
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textSecondary)
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("RECOVERY CALENDAR")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            // Calendar Heatmap
            CalendarHeatmapView(
                recoveryHistory: viewModel.recoveryHistory,
                onDateSelected: { date in
                    HapticsManager.shared.playCardTap()
                    selectedDate = date
                }
            )
            .padding(.horizontal)
        }
    }

    // MARK: - AI Analysis Section

    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            Text("AI ANALYSIS")
                .font(StraynTypography.metricLabel)
                .tracking(StraynTypography.metricLabelTracking)
                .foregroundColor(StraynColors.textTertiary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                InsightCard(
                    type: .trend,
                    title: "Recovery Trend",
                    message: viewModel.aiAnalysis
                )

                if viewModel.recoveryHistory.count >= 7 {
                    InsightCard(
                        type: .correlation,
                        title: "Pattern Detected",
                        message: "Your recovery tends to be highest on days following early bedtimes. Consider maintaining a consistent sleep schedule."
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(filter: .all)
                filterChip(filter: .greenDays)
                filterChip(filter: .yellowDays)
                filterChip(filter: .redDays)
                filterChip(filter: .highStrain)
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(filter: HistoryFilter) -> some View {
        Button(action: {
            HapticsManager.shared.playSelection()
            selectedFilter = filter
        }) {
            HStack(spacing: 6) {
                if filter != .all {
                    Circle()
                        .fill(filter.color)
                        .frame(width: 8, height: 8)
                }
                Text(filter.label)
                    .font(StraynTypography.labelSmall(.semibold))
            }
            .foregroundColor(selectedFilter == filter ? .black : StraynColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedFilter == filter ? Color.white : StraynColors.surfacePrimary)
            )
            .overlay(
                Capsule()
                    .stroke(selectedFilter == filter ? Color.clear : StraynColors.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Daily Logs Section

    private var dailyLogsSection: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            HStack {
                Text("HISTORY")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.textTertiary)

                Spacer()

                Text("\(filteredHistory.count) days")
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textMuted)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(filteredHistory.prefix(20)) { recovery in
                    NavigationLink(destination: DayDetailView(date: recovery.date)) {
                        HistoryRowView(recovery: recovery, strain: findStrain(for: recovery.date))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    private var filteredHistory: [DailyRecovery] {
        let history = viewModel.recoveryHistory.reversed()

        switch selectedFilter {
        case .all:
            return Array(history)
        case .greenDays:
            return history.filter { $0.recoveryZone == .green }
        case .yellowDays:
            return history.filter { $0.recoveryZone == .yellow }
        case .redDays:
            return history.filter { $0.recoveryZone == .red }
        case .highStrain:
            return history.filter { recovery in
                let strain = findStrain(for: recovery.date)
                return (strain?.strainScore ?? 0) >= 14
            }
        }
    }

    private func findStrain(for date: Date) -> DailyStrain? {
        viewModel.strainHistory.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - History Filter

enum HistoryFilter: CaseIterable {
    case all, greenDays, yellowDays, redDays, highStrain

    var label: String {
        switch self {
        case .all: return "All Days"
        case .greenDays: return "Green"
        case .yellowDays: return "Yellow"
        case .redDays: return "Red"
        case .highStrain: return "High Strain"
        }
    }

    var color: Color {
        switch self {
        case .all: return .white
        case .greenDays: return StraynColors.zoneGreen
        case .yellowDays: return StraynColors.zoneYellow
        case .redDays: return StraynColors.zoneRed
        case .highStrain: return StraynColors.strain
        }
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let recovery: DailyRecovery
    let strain: DailyStrain?

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: StraynSpacing.md) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(recovery.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(.white)
                Text(recovery.date.formatted(.dateTime.weekday(.wide)))
                    .font(StraynTypography.labelSmall())
                    .foregroundColor(StraynColors.textTertiary)
            }
            .frame(width: 70, alignment: .leading)

            Spacer()

            // Recovery
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(recovery.recoveryScore))%")
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(Color.forRecoveryScore(recovery.recoveryScore))
                Text("RECOVERY")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(StraynColors.textTertiary)
            }

            // Strain
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", strain?.strainScore ?? 0))
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(StraynColors.strain)
                Text("STRAIN")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(StraynColors.textTertiary)
            }
            .frame(width: 50)

            // Strayn Age
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", recovery.straynAge ?? 0))
                    .font(StraynTypography.headlineSmall())
                    .foregroundColor(StraynColors.biologicalAge)
                Text("AGE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(StraynColors.textTertiary)
            }
            .frame(width: 40)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(StraynColors.textMuted)
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
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

// MARK: - Calendar Heatmap View

struct CalendarHeatmapView: View {
    let recoveryHistory: [DailyRecovery]
    let onDateSelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: StraynSpacing.sm) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(last30Days(), id: \.self) { date in
                    let recovery = recoveryForDate(date)
                    Button(action: { onDateSelected(date) }) {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(StraynTypography.labelSmall(.semibold))
                                .foregroundColor(recovery != nil ? .white : StraynColors.textMuted)

                            if let recovery = recovery {
                                Circle()
                                    .fill(Color.forRecoveryScore(recovery.recoveryScore))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: StraynRadius.xs)
                                .fill(recovery != nil ? StraynColors.surfaceSecondary : StraynColors.surfacePrimary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Legend
            HStack(spacing: StraynSpacing.lg) {
                legendItem(color: StraynColors.zoneGreen, label: "Green")
                legendItem(color: StraynColors.zoneYellow, label: "Yellow")
                legendItem(color: StraynColors.zoneRed, label: "Red")
            }
            .padding(.top, StraynSpacing.sm)
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

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textSecondary)
        }
    }

    private func last30Days() -> [Date] {
        (0..<35).compactMap { i in
            Calendar.current.date(byAdding: .day, value: -34 + i, to: Date())
        }
    }

    private func recoveryForDate(_ date: Date) -> DailyRecovery? {
        recoveryHistory.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedFilter: HistoryFilter
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            if filter != .all {
                                Circle()
                                    .fill(filter.color)
                                    .frame(width: 12, height: 12)
                            }
                            Text(filter.label)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct SelectedDateItem: Identifiable {
    let id = UUID()
    let date: Date
}

extension Optional {
    func map<T>(_ transform: @escaping (Wrapped) -> T) -> Binding<T?> where T: Identifiable {
        Binding<T?>(
            get: { self.map { transform($0) } },
            set: { _ in }
        )
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}
