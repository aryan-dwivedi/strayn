//
//  DeviceUsageTracker.swift
//  strayn
//
//  Tracks device usage during bedtime window and provides warnings.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Device Usage Configuration

struct BedtimeConfiguration: Codable {
    var bedtimeHour: Int = 22  // 10 PM
    var bedtimeMinute: Int = 0
    var wakeHour: Int = 7      // 7 AM
    var wakeMinute: Int = 0
    var warningThresholdMinutes: Int = 15
    var isEnabled: Bool = true
    var showInAppWarnings: Bool = true
    var sendNotifications: Bool = true

    var bedtimeDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = bedtimeHour
        components.minute = bedtimeMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var wakeDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = wakeHour
        components.minute = wakeMinute

        // If wake time is earlier than bedtime, it's the next day
        if wakeHour < bedtimeHour || (wakeHour == bedtimeHour && wakeMinute <= bedtimeMinute) {
            components.day! += 1
        }

        return Calendar.current.date(from: components) ?? Date()
    }

    var bedtimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedtimeDate)
    }

    var wakeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeDate)
    }
}

// MARK: - Usage Session

struct UsageSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var wasInBedtimeWindow: Bool

    init(startTime: Date, wasInBedtimeWindow: Bool) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: startTime)
        self.startTime = startTime
        self.endTime = nil
        self.durationMinutes = 0
        self.wasInBedtimeWindow = wasInBedtimeWindow
    }

    mutating func end() {
        endTime = Date()
        if let end = endTime {
            durationMinutes = Int(end.timeIntervalSince(startTime) / 60)
        }
    }
}

// MARK: - Daily Usage Summary

struct DailyUsageSummary: Codable {
    let date: Date
    var totalBedtimeMinutes: Int
    var sessions: [UsageSession]
    var warningsTriggered: Int

    var impactLevel: UsageImpactLevel {
        if totalBedtimeMinutes == 0 {
            return .none
        } else if totalBedtimeMinutes < 15 {
            return .minimal
        } else if totalBedtimeMinutes < 30 {
            return .moderate
        } else {
            return .significant
        }
    }
}

enum UsageImpactLevel: String, Codable {
    case none = "None"
    case minimal = "Minimal"
    case moderate = "Moderate"
    case significant = "Significant"

    var color: Color {
        switch self {
        case .none: return StraynColors.zoneGreen
        case .minimal: return StraynColors.zoneYellow
        case .moderate: return StraynColors.zoneRed.opacity(0.7)
        case .significant: return StraynColors.zoneRed
        }
    }

    var icon: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .minimal: return "exclamationmark.circle"
        case .moderate: return "exclamationmark.triangle"
        case .significant: return "exclamationmark.triangle.fill"
        }
    }

    var message: String {
        switch self {
        case .none: return "Great job! No screen time during your bedtime window."
        case .minimal: return "A little screen time detected. Try to reduce it for better sleep."
        case .moderate: return "Moderate screen usage before bed may impact your sleep quality."
        case .significant: return "Significant screen time detected. This likely affected your sleep."
        }
    }
}

// MARK: - Device Usage Tracker

@MainActor
class DeviceUsageTracker: ObservableObject {
    static let shared = DeviceUsageTracker()

    // MARK: - Published Properties

    @Published var configuration: BedtimeConfiguration {
        didSet { saveConfiguration() }
    }

    @Published var isInBedtimeWindow: Bool = false
    @Published var currentSessionMinutes: Int = 0
    @Published var showWarningBanner: Bool = false
    @Published var warningMessage: String = ""
    @Published var todaysSummary: DailyUsageSummary?
    @Published var usageHistory: [DailyUsageSummary] = []

    // MARK: - Private Properties

    private var currentSession: UsageSession?
    private var sessionTimer: Timer?
    private var bedtimeCheckTimer: Timer?
    private let calendar = Calendar.current
    private var hasShownWarningThisSession = false

    // MARK: - Initialization

    init() {
        self.configuration = BedtimeConfiguration()
        loadConfiguration()
        loadUsageHistory()
        startMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        // Check bedtime status every minute
        bedtimeCheckTimer?.invalidate()
        bedtimeCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBedtimeStatus()
            }
        }

        // Initial check
        checkBedtimeStatus()

        // Listen for app lifecycle
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appBecameActive()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appWillResignActive()
            }
        }
    }

    func stopMonitoring() {
        bedtimeCheckTimer?.invalidate()
        sessionTimer?.invalidate()
        endCurrentSession()
    }

    func dismissWarning() {
        withAnimation {
            showWarningBanner = false
        }
    }

    func getSummary(for date: Date) -> DailyUsageSummary? {
        let targetDay = calendar.startOfDay(for: date)
        return usageHistory.first { calendar.isDate($0.date, inSameDayAs: targetDay) }
    }

    func getWeeklySummary() -> (totalMinutes: Int, avgMinutes: Double, daysWithUsage: Int) {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recentHistory = usageHistory.filter { $0.date >= weekAgo }

        let totalMinutes = recentHistory.reduce(0) { $0 + $1.totalBedtimeMinutes }
        let avgMinutes = recentHistory.isEmpty ? 0 : Double(totalMinutes) / Double(recentHistory.count)
        let daysWithUsage = recentHistory.filter { $0.totalBedtimeMinutes > 0 }.count

        return (totalMinutes, avgMinutes, daysWithUsage)
    }

    // MARK: - Private Methods

    private func checkBedtimeStatus() {
        guard configuration.isEnabled else {
            isInBedtimeWindow = false
            return
        }

        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute

        let bedtimeTotalMinutes = configuration.bedtimeHour * 60 + configuration.bedtimeMinute
        let wakeTotalMinutes = configuration.wakeHour * 60 + configuration.wakeMinute

        // Handle overnight bedtime window (e.g., 10 PM to 7 AM)
        if bedtimeTotalMinutes > wakeTotalMinutes {
            // Bedtime window crosses midnight
            isInBedtimeWindow = currentTotalMinutes >= bedtimeTotalMinutes || currentTotalMinutes < wakeTotalMinutes
        } else {
            // Bedtime window is within same day
            isInBedtimeWindow = currentTotalMinutes >= bedtimeTotalMinutes && currentTotalMinutes < wakeTotalMinutes
        }
    }

    private func appBecameActive() {
        checkBedtimeStatus()

        if isInBedtimeWindow && configuration.isEnabled {
            startSession()
        }
    }

    private func appWillResignActive() {
        if currentSession != nil {
            endCurrentSession()
        }
    }

    private func startSession() {
        guard currentSession == nil else { return }

        currentSession = UsageSession(startTime: Date(), wasInBedtimeWindow: true)
        hasShownWarningThisSession = false
        currentSessionMinutes = 0

        // Start session timer
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSession()
            }
        }
    }

    private func updateSession() {
        guard currentSession != nil else { return }

        currentSessionMinutes += 1

        // Check if we should show warning
        if currentSessionMinutes >= configuration.warningThresholdMinutes && !hasShownWarningThisSession {
            triggerWarning()
        }

        // Update every 5 minutes after initial warning
        if currentSessionMinutes > configuration.warningThresholdMinutes &&
           currentSessionMinutes % 5 == 0 {
            updateWarningMessage()
        }
    }

    private func endCurrentSession() {
        guard var session = currentSession else { return }

        session.end()
        sessionTimer?.invalidate()
        sessionTimer = nil

        // Save to today's summary
        saveTodaySession(session)

        currentSession = nil
        currentSessionMinutes = 0

        withAnimation {
            showWarningBanner = false
        }
    }

    private func triggerWarning() {
        hasShownWarningThisSession = true

        // Haptic feedback
        HapticsManager.shared.playBedtimeWarning()

        // Update warning message
        updateWarningMessage()

        // Show in-app banner
        if configuration.showInAppWarnings {
            withAnimation(.spring()) {
                showWarningBanner = true
            }
        }

        // Send notification if app is in background
        if configuration.sendNotifications {
            sendBedtimeNotification()
        }

        // Increment warning count for today
        incrementWarningCount()
    }

    private func updateWarningMessage() {
        let minutes = currentSessionMinutes

        if minutes < 30 {
            warningMessage = "You've been using your device for \(minutes) minutes during your bedtime window. Screen light can suppress melatonin and delay sleep."
        } else if minutes < 60 {
            warningMessage = "\(minutes) minutes of screen time detected. This level of exposure may significantly impact your sleep quality tonight."
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            warningMessage = "Extended device usage (\(hours)h \(remainingMins)m) during bedtime. Consider putting your device away to protect your sleep."
        }
    }

    private func sendBedtimeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "You've been using your device for \(currentSessionMinutes) minutes. Screen time before bed can impact your sleep quality."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "bedtime-warning-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Data Management

    private func saveTodaySession(_ session: UsageSession) {
        let today = calendar.startOfDay(for: Date())

        if var summary = todaysSummary, calendar.isDate(summary.date, inSameDayAs: today) {
            summary.sessions.append(session)
            summary.totalBedtimeMinutes += session.durationMinutes
            todaysSummary = summary

            // Update in history
            if let index = usageHistory.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                usageHistory[index] = summary
            }
        } else {
            let newSummary = DailyUsageSummary(
                date: today,
                totalBedtimeMinutes: session.durationMinutes,
                sessions: [session],
                warningsTriggered: 0
            )
            todaysSummary = newSummary
            usageHistory.append(newSummary)
        }

        saveUsageHistory()
    }

    private func incrementWarningCount() {
        let today = calendar.startOfDay(for: Date())

        if var summary = todaysSummary, calendar.isDate(summary.date, inSameDayAs: today) {
            summary.warningsTriggered += 1
            todaysSummary = summary

            if let index = usageHistory.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                usageHistory[index] = summary
            }
            saveUsageHistory()
        }
    }

    // MARK: - Persistence

    private func saveConfiguration() {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: "bedtimeConfiguration")
        }
    }

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "bedtimeConfiguration"),
           let decoded = try? JSONDecoder().decode(BedtimeConfiguration.self, from: data) {
            configuration = decoded
        }
    }

    private func saveUsageHistory() {
        // Keep last 30 days only
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        usageHistory = usageHistory.filter { $0.date >= thirtyDaysAgo }

        if let encoded = try? JSONEncoder().encode(usageHistory) {
            UserDefaults.standard.set(encoded, forKey: "deviceUsageHistory")
        }
    }

    private func loadUsageHistory() {
        if let data = UserDefaults.standard.data(forKey: "deviceUsageHistory"),
           let decoded = try? JSONDecoder().decode([DailyUsageSummary].self, from: data) {
            usageHistory = decoded

            // Set today's summary if available
            let today = calendar.startOfDay(for: Date())
            todaysSummary = usageHistory.first { calendar.isDate($0.date, inSameDayAs: today) }
        }
    }
}

// MARK: - Bedtime Warning Banner View

struct BedtimeWarningBanner: View {
    @ObservedObject var tracker = DeviceUsageTracker.shared
    @State private var isExpanded = false

    var body: some View {
        if tracker.showWarningBanner && tracker.configuration.showInAppWarnings {
            VStack(spacing: 0) {
                HStack(spacing: StraynSpacing.md) {
                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(StraynColors.zoneRed.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 20))
                            .foregroundColor(StraynColors.zoneRed)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Bedtime Mode Active")
                                .font(StraynTypography.labelLarge(.bold))
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(tracker.currentSessionMinutes) min")
                                .font(StraynTypography.labelMedium(.bold))
                                .foregroundColor(StraynColors.zoneRed)
                        }

                        if isExpanded {
                            Text(tracker.warningMessage)
                                .font(StraynTypography.bodySmall)
                                .foregroundColor(StraynColors.textSecondary)
                                .lineSpacing(4)
                                .padding(.top, 4)
                        }
                    }

                    if !isExpanded {
                        Button(action: { tracker.dismissWarning() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(StraynColors.textSecondary)
                                .padding(8)
                                .background(Circle().fill(StraynColors.surfaceSecondary))
                        }
                    }
                }
                .padding(StraynSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: StraynRadius.lg)
                        .fill(StraynColors.surfacePrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: StraynRadius.lg)
                                .stroke(StraynColors.zoneRed.opacity(0.3), lineWidth: 1)
                        )
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Sleep Hygiene Card

struct SleepHygieneCard: View {
    @ObservedObject var tracker = DeviceUsageTracker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: StraynSpacing.md) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(StraynColors.sleep)
                Text("SLEEP HYGIENE")
                    .font(StraynTypography.metricLabel)
                    .tracking(StraynTypography.metricLabelTracking)
                    .foregroundColor(StraynColors.sleep)

                Spacer()

                if let summary = tracker.todaysSummary {
                    Image(systemName: summary.impactLevel.icon)
                        .foregroundColor(summary.impactLevel.color)
                }
            }

            if let summary = tracker.todaysSummary {
                VStack(alignment: .leading, spacing: StraynSpacing.sm) {
                    HStack {
                        Text("Screen time before bed")
                            .font(StraynTypography.bodyMedium)
                            .foregroundColor(StraynColors.textSecondary)

                        Spacer()

                        Text("\(summary.totalBedtimeMinutes) min")
                            .font(StraynTypography.headlineSmall())
                            .foregroundColor(summary.impactLevel.color)
                    }

                    Text(summary.impactLevel.message)
                        .font(StraynTypography.labelSmall())
                        .foregroundColor(StraynColors.textMuted)
                }
            } else {
                Text("No bedtime screen usage tracked today")
                    .font(StraynTypography.bodySmall)
                    .foregroundColor(StraynColors.textSecondary)
            }

            // Weekly summary
            let weekly = tracker.getWeeklySummary()
            if weekly.totalMinutes > 0 {
                Divider()
                    .background(StraynColors.borderSubtle)

                HStack {
                    VStack(alignment: .leading) {
                        Text("7-Day Average")
                            .font(StraynTypography.labelSmall())
                            .foregroundColor(StraynColors.textMuted)
                        Text("\(Int(weekly.avgMinutes)) min/night")
                            .font(StraynTypography.labelMedium(.semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Days Affected")
                            .font(StraynTypography.labelSmall())
                            .foregroundColor(StraynColors.textMuted)
                        Text("\(weekly.daysWithUsage)/7")
                            .font(StraynTypography.labelMedium(.semibold))
                            .foregroundColor(weekly.daysWithUsage > 4 ? StraynColors.zoneRed : .white)
                    }
                }
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
    }
}
