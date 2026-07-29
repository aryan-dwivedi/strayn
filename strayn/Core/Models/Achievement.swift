//
//  Achievement.swift
//  strayn
//
//  Enhanced achievement model with tiers, requirements, and rich metadata.
//

import Foundation
import SwiftUI

// MARK: - Achievement Tier

enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .diamond: return Color(red: 0.7, green: 0.9, blue: 1.0)
        }
    }

    var glowColor: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.5)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.5)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 1.0).opacity(0.6)
        case .diamond: return Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.7)
        }
    }

    var points: Int {
        switch self {
        case .bronze: return 10
        case .silver: return 25
        case .gold: return 50
        case .platinum: return 100
        case .diamond: return 250
        }
    }

    var order: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        case .diamond: return 4
        }
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case recovery = "Recovery"
    case strain = "Strain"
    case sleep = "Sleep"
    case habits = "Habits"
    case longevity = "Longevity"
    case consistency = "Consistency"
    case milestones = "Milestones"
    case special = "Special"

    var icon: String {
        switch self {
        case .recovery: return "heart.fill"
        case .strain: return "flame.fill"
        case .sleep: return "moon.fill"
        case .habits: return "checkmark.circle.fill"
        case .longevity: return "sparkles"
        case .consistency: return "calendar.badge.checkmark"
        case .milestones: return "flag.fill"
        case .special: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return StraynColors.recovery
        case .strain: return StraynColors.strain
        case .sleep: return StraynColors.sleep
        case .habits: return StraynColors.zoneGreen
        case .longevity: return StraynColors.biologicalAge
        case .consistency: return StraynColors.accentPrimary
        case .milestones: return StraynColors.zoneYellow
        case .special: return StraynColors.accentSecondary
        }
    }
}

// MARK: - Achievement Requirement

struct AchievementRequirement: Codable, Equatable {
    let metric: AchievementMetric
    let comparison: ComparisonType
    let threshold: Double
    let duration: Int? // Number of consecutive days required, nil for one-time

    enum AchievementMetric: String, Codable {
        case recoveryScore
        case recoveryZone
        case strainScore
        case sleepDuration
        case sleepEfficiency
        case hrvValue
        case restingHR
        case vo2Max
        case straynAge
        case journalStreak
        case journalCount
        case totalActivities
        case consecutiveGreenDays
        case consecutiveRedDays
        case daysTracked
    }

    enum ComparisonType: String, Codable {
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
        case equal
        case streak
    }
}

// MARK: - Achievement

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let tier: AchievementTier
    let requirement: AchievementRequirement
    var isUnlocked: Bool
    var progress: Double
    var dateUnlocked: Date?
    let secret: Bool
    let shareMessage: String?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        tier: AchievementTier = .bronze,
        requirement: AchievementRequirement,
        isUnlocked: Bool = false,
        progress: Double = 0.0,
        dateUnlocked: Date? = nil,
        secret: Bool = false,
        shareMessage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.tier = tier
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.dateUnlocked = dateUnlocked
        self.secret = secret
        self.shareMessage = shareMessage
    }

    var displayTitle: String {
        if secret && !isUnlocked {
            return "???"
        }
        return title
    }

    var displayDescription: String {
        if secret && !isUnlocked {
            return "Complete secret requirements to unlock"
        }
        return description
    }

    var points: Int {
        tier.points
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Achievement Progress Tracking

struct AchievementProgress: Codable {
    var currentStreak: Int
    var bestStreak: Int
    var totalDays: Int
    var currentValue: Double
    var lastUpdated: Date

    init() {
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalDays = 0
        self.currentValue = 0
        self.lastUpdated = Date()
    }
}

// MARK: - User Achievement Stats

struct UserAchievementStats: Codable {
    var totalPoints: Int
    var totalUnlocked: Int
    var bronzeCount: Int
    var silverCount: Int
    var goldCount: Int
    var platinumCount: Int
    var diamondCount: Int
    var longestStreak: Int
    var currentLevel: Int
    var levelProgress: Double

    init() {
        totalPoints = 0
        totalUnlocked = 0
        bronzeCount = 0
        silverCount = 0
        goldCount = 0
        platinumCount = 0
        diamondCount = 0
        longestStreak = 0
        currentLevel = 1
        levelProgress = 0.0
    }

    var levelTitle: String {
        switch currentLevel {
        case 1...5: return "Novice"
        case 6...10: return "Explorer"
        case 11...20: return "Enthusiast"
        case 21...35: return "Dedicated"
        case 36...50: return "Master"
        case 51...75: return "Elite"
        case 76...100: return "Legend"
        default: return "Transcendent"
        }
    }

    var nextLevelPoints: Int {
        // Points needed to reach next level
        return currentLevel * 100
    }

    mutating func recalculate(from achievements: [Achievement]) {
        let unlocked = achievements.filter { $0.isUnlocked }
        totalPoints = unlocked.reduce(0) { $0 + $1.points }
        totalUnlocked = unlocked.count
        bronzeCount = unlocked.filter { $0.tier == .bronze }.count
        silverCount = unlocked.filter { $0.tier == .silver }.count
        goldCount = unlocked.filter { $0.tier == .gold }.count
        platinumCount = unlocked.filter { $0.tier == .platinum }.count
        diamondCount = unlocked.filter { $0.tier == .diamond }.count

        // Calculate level
        var pointsRemaining = totalPoints
        var level = 1
        while pointsRemaining >= level * 100 {
            pointsRemaining -= level * 100
            level += 1
        }
        currentLevel = level
        levelProgress = Double(pointsRemaining) / Double(level * 100)
    }
}

// MARK: - Achievement Unlock Event

struct AchievementUnlockEvent {
    let achievement: Achievement
    let timestamp: Date
    let celebrationType: CelebrationType

    enum CelebrationType {
        case standard
        case milestone
        case epic
    }
}
