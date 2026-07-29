//
//  HealthspanViewModel.swift
//  strayn
//
//  View model for Healthspan feature managing state and data flow.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Healthspan View Model

@MainActor
final class HealthspanViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var healthspan: Healthspan?
    @Published var previousHealthspan: Healthspan?
    @Published var insights: [HealthspanInsight] = []
    @Published var weeklySummary: HealthspanWeeklySummary?
    @Published var history: [HealthspanHistoryEntry] = []
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedDetailTab: DetailTab = .overview
    @Published var isHealthspanHidden = false
    
    // MARK: - Week Navigation State
    
    @Published var selectedWeekOffset: Int = 0  // 0 = current week, -1 = last week, etc.
    @Published var weeklyHistory: [WeeklyHealthspanRecord] = []
    
    var canGoToPreviousWeek: Bool {
        selectedWeekOffset > -(weeklyHistory.count - 1)
    }
    
    var canGoToNextWeek: Bool {
        selectedWeekOffset < 0
    }
    
    var currentWeekRangeText: String {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: now) else {
            return ""
        }
        
        let startOfWeek = calendar.startOfWeek(for: weekStart)
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    var currentWeekHealthspan: WeeklyHealthspanRecord? {
        let index = -selectedWeekOffset
        guard index >= 0 && index < weeklyHistory.count else { return nil }
        return weeklyHistory[index]
    }
    
    var displayedStraynAge: Double {
        currentWeekHealthspan?.straynAge ?? healthspan?.straynAge.age ?? 0
    }
    
    var displayedAgeDelta: Double {
        currentWeekHealthspan?.ageDelta ?? healthspan?.straynAge.ageDelta ?? 0
    }
    
    var displayedPace: Double {
        currentWeekHealthspan?.paceOfAging ?? healthspan?.paceOfAging.pace ?? 1.0
    }
    
    var isSlowPace: Bool {
        displayedPace < 1.0
    }
    
    var isFastPace: Bool {
        displayedPace > 1.5
    }
    
    // MARK: - Display State
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case straynAge = "Strayn Age"
        case pace = "Pace"
        case insights = "Insights"
    }
    
    // MARK: - Dependencies
    
    private let healthspanEngine: HealthspanEngine
    private let insightEngine: HealthspanInsightEngine
    
    // MARK: - Initialization
    
    init(
        healthspanEngine: HealthspanEngine = .shared,
        insightEngine: HealthspanInsightEngine = .shared
    ) {
        self.healthspanEngine = healthspanEngine
        self.insightEngine = insightEngine
    }
    
    // MARK: - Computed Properties
    
    var displayState: DisplayState {
        guard let healthspan = healthspan else {
            return isLoading ? .loading : .noData
        }
        
        if isHealthspanHidden {
            return .hidden
        }
        
        switch healthspan.state {
        case .locked(let reason):
            return .locked(reason: reason.rawValue)
        case .calibrating(let phase):
            return .calibrating(progress: phase.progress, description: phase.displayText)
        case .active:
            return .active
        case .insufficientRecentData:
            return .needsMoreData
        case .userHidden:
            return .hidden
        }
    }
    
    enum DisplayState {
        case loading
        case noData
        case locked(reason: String)
        case calibrating(progress: Double, description: String)
        case active
        case needsMoreData
        case hidden
    }
    
    var formattedStraynAge: String {
        guard let age = healthspan?.straynAge.age else { return "--" }
        return String(format: "%.1f", age)
    }
    
    var formattedAgeDelta: String {
        guard let delta = healthspan?.straynAge.ageDelta else { return "" }
        let rounded = abs(delta).rounded(toPlaces: 1)
        if delta < -0.1 {
            return "\(rounded) years younger"
        } else if delta > 0.1 {
            return "\(rounded) years older"
        } else {
            return "At your age"
        }
    }
    
    var ageDeltaColor: Color {
        guard let delta = healthspan?.straynAge.ageDelta else { return .gray }
        if delta <= -1.0 {
            return StraynColors.recovery
        } else if delta < 1.0 {
            return StraynColors.zoneYellow
        } else {
            return StraynColors.zoneRed
        }
    }
    
    var formattedPaceOfAging: String {
        guard let pace = healthspan?.paceOfAging.pace else { return "--" }
        return String(format: "%.1fx", pace)
    }
    
    var paceZoneColor: Color {
        guard let zone = healthspan?.paceOfAging.zone else { return .gray }
        switch zone {
        case .optimal, .slow:
            return StraynColors.recovery
        case .steady:
            return StraynColors.zoneYellow
        case .elevated, .accelerated:
            return StraynColors.zoneRed
        }
    }
    
    var daysUntilUpdate: Int {
        healthspan?.daysUntilUpdate ?? 7
    }
    
    var dateRangeText: String {
        guard let healthspan = healthspan else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: healthspan.lastUpdated) ?? healthspan.lastUpdated
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: healthspan.lastUpdated))"
    }
    
    // MARK: - Actions
    
    func loadHealthspan(for user: User, recoveries: [DailyRecovery], strains: [DailyStrain], sleepSessions: [SleepSession], baselines: [Baseline]) async {
        isLoading = true
        error = nil
        
        do {
            let calculated = try await healthspanEngine.calculateHealthspan(
                for: user,
                recoveries: recoveries,
                strains: strains,
                sleepSessions: sleepSessions,
                baselines: baselines
            )
            
            healthspan = calculated
            
            // Generate insights
            insights = insightEngine.generateInsights(
                healthspan: calculated,
                previousHealthspan: previousHealthspan,
                inputData: nil  // Would pass actual input data in production
            )
            
            // Generate weekly summary
            weeklySummary = insightEngine.generateWeeklySummary(
                healthspan: calculated,
                previous: previousHealthspan,
                insights: insights
            )
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func loadMockData() {
        isLoading = true
        
        // Simulate network delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            healthspan = HealthspanEngine.createMockHealthspan(
                chronologicalAge: 35,
                straynAgeDelta: -1.2,
                paceOfAging: 0.3,
                state: .active
            )
            
            if let healthspan = healthspan {
                insights = insightEngine.generateInsights(
                    healthspan: healthspan,
                    previousHealthspan: nil,
                    inputData: nil
                )
                
                weeklySummary = insightEngine.generateWeeklySummary(
                    healthspan: healthspan,
                    previous: nil,
                    insights: insights
                )
            }
            
            // Generate mock history
            history = generateMockHistory()
            
            // Generate weekly history for navigation
            generateWeeklyHistory()
            
            isLoading = false
        }
    }
    
    func toggleHealthspanVisibility() {
        isHealthspanHidden.toggle()
    }
    
    func markInsightAsRead(_ insight: HealthspanInsight) {
        if let index = insights.firstIndex(where: { $0.id == insight.id }) {
            insights[index].isRead = true
        }
    }
    
    func dismissInsight(_ insight: HealthspanInsight) {
        if let index = insights.firstIndex(where: { $0.id == insight.id }) {
            insights[index].isDismissed = true
        }
    }
    
    // MARK: - Week Navigation
    
    func goToPreviousWeek() {
        guard canGoToPreviousWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekOffset -= 1
        }
    }
    
    func goToNextWeek() {
        guard canGoToNextWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekOffset += 1
        }
    }
    
    func goToCurrentWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekOffset = 0
        }
    }
    
    private func generateWeeklyHistory() {
        let calendar = Calendar.current
        let now = Date()
        var records: [WeeklyHealthspanRecord] = []
        
        let chronoAge = 35.0
        var runningAge = 33.8
        
        // Generate 12 weeks of history
        for weekOffset in 0..<12 {
            let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let startOfWeek = calendar.startOfWeek(for: weekDate)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            
            // Add realistic variation
            let weeklyVariation = Double.random(in: -0.2...0.2)
            runningAge += weeklyVariation
            
            // Keep within reasonable bounds
            runningAge = max(chronoAge - 5, min(chronoAge + 5, runningAge))
            
            let pace = Double.random(in: -0.3...1.8)
            
            records.append(WeeklyHealthspanRecord(
                id: UUID(),
                weekStartDate: startOfWeek,
                weekEndDate: endOfWeek,
                straynAge: runningAge,
                chronologicalAge: chronoAge,
                ageDelta: runningAge - chronoAge,
                paceOfAging: pace,
                isCurrentWeek: weekOffset == 0
            ))
        }
        
        weeklyHistory = records
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockHistory() -> [HealthspanHistoryEntry] {
        let calendar = Calendar.current
        let now = Date()
        var entries: [HealthspanHistoryEntry] = []
        
        var currentAge = 33.8
        let chronoAge = 35.0
        
        for weekOffset in 0..<26 {
            let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            
            // Add some variation
            let variation = Double.random(in: -0.3...0.3)
            currentAge += variation
            
            // Gradually trend toward current age
            if weekOffset < 10 {
                currentAge = 33.8 + (Double(weekOffset) * 0.05)
            }
            
            entries.append(HealthspanHistoryEntry(
                date: date,
                straynAge: currentAge,
                paceOfAging: Double.random(in: 0.2...0.8),
                chronologicalAge: chronoAge - (Double(weekOffset) / 52.0)
            ))
        }
        
        return entries.reversed()
    }
}

// MARK: - Orb Animation State

enum OrbColorScheme: String, CaseIterable {
    case positive      // Green/teal for younger age
    case neutral       // Blue for at-age
    case negative      // Gold/amber for older age
    
    static func scheme(for ageDelta: Double) -> OrbColorScheme {
        if ageDelta <= -0.5 {
            return .positive
        } else if ageDelta >= 0.5 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .positive: return Color(red: 0.0, green: 0.8, blue: 0.6)     // Teal green
        case .neutral: return Color(red: 0.2, green: 0.6, blue: 0.9)      // Blue
        case .negative: return Color(red: 0.85, green: 0.65, blue: 0.2)   // Golden amber
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .positive: return Color(red: 0.0, green: 0.6, blue: 0.5)
        case .neutral: return Color(red: 0.15, green: 0.4, blue: 0.7)
        case .negative: return Color(red: 0.7, green: 0.5, blue: 0.15)
        }
    }
    
    var glowColor: Color {
        switch self {
        case .positive: return Color(red: 0.0, green: 0.9, blue: 0.7).opacity(0.4)
        case .neutral: return Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.4)
        case .negative: return Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.4)
        }
    }
    
    var particleColor: Color {
        switch self {
        case .positive: return .white.opacity(0.9)
        case .neutral: return .white.opacity(0.8)
        case .negative: return Color(red: 1.0, green: 0.95, blue: 0.8)
        }
    }
}

// MARK: - Weekly Healthspan Record

struct WeeklyHealthspanRecord: Identifiable, Equatable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    let straynAge: Double
    let chronologicalAge: Double
    let ageDelta: Double
    let paceOfAging: Double
    let isCurrentWeek: Bool
    
    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
