//
//  AchievementService.swift
//  strayn
//
//  Analyzes health data to unlock achievements and track streaks.
//

import Foundation

class AchievementService {
    static let shared = AchievementService()

    private let recoveryRepo = CoreDataRecoveryRepository.shared
    private let sleepRepo = CoreDataSleepRepository.shared

    private init() {}

    func getAllAchievements() async -> [Achievement] {
        // Return sample achievements using the new model with requirements
        return [
            Achievement(
                id: "recovery_streak_3",
                title: "Consistency King",
                description: "Maintain a Green recovery for 3 consecutive days.",
                icon: "crown.fill",
                category: .recovery,
                tier: .bronze,
                requirement: AchievementRequirement(
                    metric: .consecutiveGreenDays,
                    comparison: .greaterThanOrEqual,
                    threshold: 3,
                    duration: nil
                ),
                isUnlocked: true,
                progress: 1.0,
                dateUnlocked: Date()
            ),
            Achievement(
                id: "sleep_pro",
                title: "Deep Sleeper",
                description: "Achieve >90% sleep efficiency 5 times.",
                icon: "moon.stars.fill",
                category: .sleep,
                tier: .silver,
                requirement: AchievementRequirement(
                    metric: .sleepEfficiency,
                    comparison: .greaterThanOrEqual,
                    threshold: 90,
                    duration: 5
                ),
                isUnlocked: true,
                progress: 1.0,
                dateUnlocked: Date().addingTimeInterval(-86400 * 2)
            ),
            Achievement(
                id: "strain_hero",
                title: "Pushing Limits",
                description: "Reach a Strain of 18.0 or higher.",
                icon: "flame.fill",
                category: .strain,
                tier: .gold,
                requirement: AchievementRequirement(
                    metric: .strainScore,
                    comparison: .greaterThanOrEqual,
                    threshold: 18.0,
                    duration: nil
                ),
                isUnlocked: false,
                progress: 0.6,
                dateUnlocked: nil
            ),
            Achievement(
                id: "habit_master",
                title: "Journalist",
                description: "Complete your Morning Journal for 7 days straight.",
                icon: "book.fill",
                category: .habits,
                tier: .silver,
                requirement: AchievementRequirement(
                    metric: .journalStreak,
                    comparison: .greaterThanOrEqual,
                    threshold: 7,
                    duration: nil
                ),
                isUnlocked: false,
                progress: 0.85,
                dateUnlocked: nil
            )
        ]
    }

    func getStreakInfo() async -> AchievementProgress {
        // Return default progress struct
        var progress = AchievementProgress()
        progress.currentStreak = 5
        progress.bestStreak = 12
        progress.totalDays = 45
        return progress
    }
}
