//
//  HabitTracker.swift
//  strayn
//
//  Enhanced habit tracking with streaks, intensity levels, and gamification.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Habit Impact Level

enum HabitImpact: String, Codable {
    case positive
    case negative
    case neutral

    var color: Color {
        switch self {
        case .positive: return StraynColors.zoneGreen
        case .negative: return StraynColors.zoneRed
        case .neutral: return StraynColors.textSecondary
        }
    }
}

// MARK: - Intensity Level for certain habits

enum IntensityLevel: String, Codable, CaseIterable {
    case none = "None"
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"

    var displayValue: String {
        rawValue
    }

    var impactMultiplier: Double {
        switch self {
        case .none: return 0
        case .light: return 0.3
        case .moderate: return 0.6
        case .heavy: return 1.0
        }
    }
}

// MARK: - Enhanced Logged Habit

struct LoggedHabit: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let category: String
    var wasPerformed: Bool
    var intensity: IntensityLevel?
    var notes: String?
    let impact: HabitImpact
    let supportsIntensity: Bool
    let description: String

    init(id: String, name: String, icon: String, category: String, wasPerformed: Bool = false, intensity: IntensityLevel? = nil, notes: String? = nil, impact: HabitImpact = .neutral, supportsIntensity: Bool = false, description: String = "") {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.wasPerformed = wasPerformed
        self.intensity = intensity
        self.notes = notes
        self.impact = impact
        self.supportsIntensity = supportsIntensity
        self.description = description
    }

    // Core habits with enhanced metadata
    static let defaults: [LoggedHabit] = [
        LoggedHabit(
            id: "hydration",
            name: "Hydrated properly",
            icon: "drop.fill",
            category: "Nutrition",
            impact: .positive,
            description: "Adequate hydration supports cellular function and recovery."
        ),
        LoggedHabit(
            id: "sunlight",
            name: "Morning Sunlight",
            icon: "sun.max.fill",
            category: "Circadian",
            impact: .positive,
            description: "10+ minutes of morning light helps regulate your circadian rhythm."
        ),
        LoggedHabit(
            id: "late_meal",
            name: "Late Meal",
            icon: "fork.knife",
            category: "Nutrition",
            impact: .negative,
            description: "Eating within 3 hours of bed can reduce deep sleep quality."
        ),
        LoggedHabit(
            id: "alcohol",
            name: "Alcohol Consumption",
            icon: "wineglass.fill",
            category: "Toxins",
            impact: .negative,
            supportsIntensity: true,
            description: "Alcohol significantly impacts HRV and sleep architecture."
        ),
        LoggedHabit(
            id: "meditation",
            name: "Meditation / Breathwork",
            icon: "lungs.fill",
            category: "Stress",
            impact: .positive,
            description: "Mindfulness practices improve HRV and stress resilience."
        ),
        LoggedHabit(
            id: "caffeine_cutoff",
            name: "Caffeine after 2 PM",
            icon: "cup.and.saucer.fill",
            category: "Sleep",
            impact: .negative,
            supportsIntensity: true,
            description: "Late caffeine has a half-life of 5-6 hours, disrupting sleep."
        )
    ]

    var categoryColor: Color {
        switch category.lowercased() {
        case "nutrition": return StraynColors.recovery
        case "circadian": return StraynColors.biologicalAge
        case "toxins": return StraynColors.zoneRed
        case "stress": return StraynColors.sleep
        case "sleep": return StraynColors.accentPrimary
        default: return StraynColors.textSecondary
        }
    }
}

// MARK: - Journal Entry

struct JournalEntry: Codable {
    let date: Date
    let habits: [LoggedHabit]
    let completedAt: Date

    var positiveHabitsCount: Int {
        habits.filter { $0.wasPerformed && $0.impact == .positive }.count
    }

    var negativeHabitsAvoided: Int {
        habits.filter { !$0.wasPerformed && $0.impact == .negative }.count
    }
}

// MARK: - Streak Info

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    let lastEntryDate: Date?

    var isOnFire: Bool {
        currentStreak >= 3
    }

    var nextMilestone: Int {
        let milestones = [3, 7, 14, 30, 60, 90, 180, 365]
        return milestones.first { $0 > currentStreak } ?? currentStreak + 30
    }

    var progressToNextMilestone: Double {
        let next = nextMilestone
        let prev = [0, 3, 7, 14, 30, 60, 90, 180].last { $0 < next } ?? 0
        return Double(currentStreak - prev) / Double(next - prev)
    }
}

// MARK: - Habit Tracker

class HabitTracker: ObservableObject {
    static let shared = HabitTracker()

    @Published private(set) var habitHistory: [Date: [LoggedHabit]] = [:]
    @Published private(set) var journalEntries: [JournalEntry] = []
    @Published private(set) var streakInfo: StreakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, totalEntries: 0, lastEntryDate: nil)

    private let calendar = Calendar.current

    init() {
        loadHabitHistory()
        loadJournalEntries()
        calculateStreaks()
    }

    // MARK: - Public Methods

    func logHabits(_ habits: [LoggedHabit]) {
        let today = calendar.startOfDay(for: Date())
        habitHistory[today] = habits

        // Create journal entry
        let entry = JournalEntry(date: today, habits: habits, completedAt: Date())
        journalEntries.removeAll { calendar.isDate($0.date, inSameDayAs: today) }
        journalEntries.append(entry)

        saveHabitHistory()
        saveJournalEntries()
        calculateStreaks()

        // Check for achievements
        checkForAchievements()
    }

    func hasCompletedJournalToday() -> Bool {
        let today = calendar.startOfDay(for: Date())
        return journalEntries.contains { calendar.isDate($0.date, inSameDayAs: today) }
    }

    func getJournalEntry(for date: Date) -> JournalEntry? {
        let targetDay = calendar.startOfDay(for: date)
        return journalEntries.first { calendar.isDate($0.date, inSameDayAs: targetDay) }
    }

    func getRecentEntries(limit: Int = 7) -> [JournalEntry] {
        Array(journalEntries.sorted { $0.date > $1.date }.prefix(limit))
    }

    // MARK: - Streak Calculation

    private func calculateStreaks() {
        let sortedDates = journalEntries.map { calendar.startOfDay(for: $0.date) }.sorted(by: >)

        guard !sortedDates.isEmpty else {
            streakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, totalEntries: 0, lastEntryDate: nil)
            return
        }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Calculate current streak
        var currentStreak = 0
        var checkDate = today

        // Check if today or yesterday has an entry (streak continues)
        let hasToday = sortedDates.contains { calendar.isDate($0, inSameDayAs: today) }
        let hasYesterday = sortedDates.contains { calendar.isDate($0, inSameDayAs: yesterday) }

        if hasToday || hasYesterday {
            checkDate = hasToday ? today : yesterday

            while sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
                currentStreak += 1
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDate
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?

        for date in sortedDates.sorted() {
            if let last = lastDate {
                let dayDiff = calendar.dateComponents([.day], from: last, to: date).day ?? 0
                if dayDiff == 1 {
                    tempStreak += 1
                } else if dayDiff > 1 {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            lastDate = date
        }
        longestStreak = max(longestStreak, tempStreak, currentStreak)

        streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalEntries: journalEntries.count,
            lastEntryDate: sortedDates.first
        )
    }

    // MARK: - Achievements

    private func checkForAchievements() {
        // Check streak milestones
        let milestones = [3, 7, 14, 30, 60, 90]

        for milestone in milestones {
            if streakInfo.currentStreak == milestone {
                HapticsManager.shared.playStreakCelebration()
                // Post notification for achievement system
                NotificationCenter.default.post(
                    name: .journalStreakMilestone,
                    object: nil,
                    userInfo: ["streak": milestone]
                )
            }
        }
    }

    // MARK: - Correlation Analysis

    func analyzeCorrelations(habitHistory: [Date: [LoggedHabit]], recoveryHistory: [Date: DailyRecovery]) -> [HabitCorrelation] {
        var correlations: [HabitCorrelation] = []

        // Analyze each habit's impact on recovery
        for habit in LoggedHabit.defaults {
            var withHabitRecovery: [Double] = []
            var withoutHabitRecovery: [Double] = []

            for (date, recovery) in recoveryHistory {
                if let prevDate = calendar.date(byAdding: .day, value: -1, to: date),
                   let habits = habitHistory[calendar.startOfDay(for: prevDate)] {
                    let hadHabit = habits.first { $0.id == habit.id }?.wasPerformed ?? false

                    if hadHabit {
                        withHabitRecovery.append(recovery.recoveryScore)
                    } else {
                        withoutHabitRecovery.append(recovery.recoveryScore)
                    }
                }
            }

            // Need enough data points
            if withHabitRecovery.count >= 3 && withoutHabitRecovery.count >= 3 {
                let avgWith = withHabitRecovery.reduce(0, +) / Double(withHabitRecovery.count)
                let avgWithout = withoutHabitRecovery.reduce(0, +) / Double(withoutHabitRecovery.count)
                let difference = avgWith - avgWithout

                if abs(difference) >= 5 {
                    correlations.append(HabitCorrelation(
                        habitId: habit.id,
                        habitName: habit.name,
                        icon: habit.icon,
                        impactPercentage: difference,
                        isPositive: (habit.impact == .positive && difference > 0) || (habit.impact == .negative && difference < 0),
                        sampleSize: withHabitRecovery.count + withoutHabitRecovery.count
                    ))
                }
            }
        }

        return correlations.sorted { abs($0.impactPercentage) > abs($1.impactPercentage) }
    }

    // MARK: - Persistence

    private func saveHabitHistory() {
        if let encoded = try? JSONEncoder().encode(habitHistory) {
            UserDefaults.standard.set(encoded, forKey: "habitHistory")
        }
    }

    private func loadHabitHistory() {
        if let data = UserDefaults.standard.data(forKey: "habitHistory"),
           let decoded = try? JSONDecoder().decode([Date: [LoggedHabit]].self, from: data) {
            habitHistory = decoded
        }
    }

    private func saveJournalEntries() {
        if let encoded = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(encoded, forKey: "journalEntries")
        }
    }

    private func loadJournalEntries() {
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            journalEntries = decoded
        }
    }
}

// MARK: - Correlation Result

struct HabitCorrelation: Identifiable {
    let id = UUID()
    let habitId: String
    let habitName: String
    let icon: String
    let impactPercentage: Double
    let isPositive: Bool
    let sampleSize: Int

    var formattedImpact: String {
        let sign = impactPercentage > 0 ? "+" : ""
        return "\(sign)\(Int(impactPercentage))%"
    }

    var message: String {
        if isPositive {
            return "\(habitName) improves your recovery by ~\(Int(abs(impactPercentage)))%"
        } else {
            return "\(habitName) reduces your recovery by ~\(Int(abs(impactPercentage)))%"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let journalStreakMilestone = Notification.Name("journalStreakMilestone")
    static let journalCompleted = Notification.Name("journalCompleted")
}
