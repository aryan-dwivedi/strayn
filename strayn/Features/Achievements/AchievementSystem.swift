//
//  AchievementSystem.swift
//  strayn
//
//  Enhanced achievement system with 30+ dynamic badges, tiers, and celebrations.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AchievementSystem: ObservableObject {
    static let shared = AchievementSystem()

    // MARK: - Published Properties

    @Published var achievements: [Achievement] = []
    @Published var stats: UserAchievementStats = UserAchievementStats()
    @Published var recentUnlocks: [Achievement] = []
    @Published var showCelebration: Bool = false
    @Published var celebratingAchievement: Achievement?

    // MARK: - Private Properties

    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        loadAchievements()
        setupNotificationListeners()
    }

    // MARK: - All Achievements Definition (30+)

    private static func createAllAchievements() -> [Achievement] {
        var allAchievements: [Achievement] = []

        // ===== RECOVERY ACHIEVEMENTS (7) =====

        allAchievements.append(contentsOf: [
            // Green Streak - Bronze
            Achievement(
                id: "green_streak_3",
                title: "Green Machine",
                description: "Achieve 3 consecutive days of Green recovery",
                icon: "leaf.fill",
                category: .recovery,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .consecutiveGreenDays, comparison: .greaterThanOrEqual, threshold: 3, duration: 3),
                shareMessage: "I just hit a 3-day green recovery streak on Strayn!"
            ),
            // Green Streak - Silver
            Achievement(
                id: "green_streak_7",
                title: "Week of Green",
                description: "Achieve 7 consecutive days of Green recovery",
                icon: "leaf.fill",
                category: .recovery,
                tier: .silver,
                requirement: AchievementRequirement(metric: .consecutiveGreenDays, comparison: .greaterThanOrEqual, threshold: 7, duration: 7),
                shareMessage: "One full week of optimal recovery!"
            ),
            // Green Streak - Gold
            Achievement(
                id: "green_streak_14",
                title: "Fortnight of Excellence",
                description: "Achieve 14 consecutive days of Green recovery",
                icon: "leaf.fill",
                category: .recovery,
                tier: .gold,
                requirement: AchievementRequirement(metric: .consecutiveGreenDays, comparison: .greaterThanOrEqual, threshold: 14, duration: 14)
            ),
            // Green Streak - Platinum
            Achievement(
                id: "green_streak_30",
                title: "Monthly Master",
                description: "Achieve 30 consecutive days of Green recovery",
                icon: "crown.fill",
                category: .recovery,
                tier: .platinum,
                requirement: AchievementRequirement(metric: .consecutiveGreenDays, comparison: .greaterThanOrEqual, threshold: 30, duration: 30)
            ),
            // Green Streak - Diamond
            Achievement(
                id: "green_streak_100",
                title: "Century Club",
                description: "Achieve 100 consecutive days of Green recovery",
                icon: "diamond.fill",
                category: .recovery,
                tier: .diamond,
                requirement: AchievementRequirement(metric: .consecutiveGreenDays, comparison: .greaterThanOrEqual, threshold: 100, duration: 100),
                secret: true
            ),
            // Perfect Recovery
            Achievement(
                id: "perfect_recovery",
                title: "Peak Performance",
                description: "Achieve a 95%+ recovery score",
                icon: "star.circle.fill",
                category: .recovery,
                tier: .silver,
                requirement: AchievementRequirement(metric: .recoveryScore, comparison: .greaterThanOrEqual, threshold: 95, duration: nil)
            ),
            // Recovery Comeback
            Achievement(
                id: "recovery_comeback",
                title: "Comeback King",
                description: "Go from Red to Green recovery in consecutive days",
                icon: "arrow.up.heart.fill",
                category: .recovery,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .recoveryScore, comparison: .greaterThanOrEqual, threshold: 67, duration: nil)
            )
        ])

        // ===== STRAIN ACHIEVEMENTS (6) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "strain_hunter_15",
                title: "Strain Seeker",
                description: "Hit a 15+ strain score in a single day",
                icon: "flame.fill",
                category: .strain,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .strainScore, comparison: .greaterThanOrEqual, threshold: 15, duration: nil)
            ),
            Achievement(
                id: "strain_hunter_18",
                title: "Strain Hunter",
                description: "Hit an 18+ strain score in a single day",
                icon: "flame.fill",
                category: .strain,
                tier: .silver,
                requirement: AchievementRequirement(metric: .strainScore, comparison: .greaterThanOrEqual, threshold: 18, duration: nil)
            ),
            Achievement(
                id: "strain_hunter_20",
                title: "Strain Beast",
                description: "Hit a 20+ strain score in a single day",
                icon: "flame.circle.fill",
                category: .strain,
                tier: .gold,
                requirement: AchievementRequirement(metric: .strainScore, comparison: .greaterThanOrEqual, threshold: 20, duration: nil)
            ),
            Achievement(
                id: "strain_hunter_21",
                title: "Maximum Output",
                description: "Hit the maximum 21 strain score",
                icon: "bolt.fill",
                category: .strain,
                tier: .diamond,
                requirement: AchievementRequirement(metric: .strainScore, comparison: .equal, threshold: 21, duration: nil),
                secret: true
            ),
            Achievement(
                id: "balanced_week",
                title: "Balance Master",
                description: "Match strain to recovery for 7 consecutive days",
                icon: "scale.3d",
                category: .strain,
                tier: .gold,
                requirement: AchievementRequirement(metric: .strainScore, comparison: .greaterThanOrEqual, threshold: 0, duration: 7)
            ),
            Achievement(
                id: "activities_100",
                title: "Century Runner",
                description: "Log 100 total activities",
                icon: "figure.run",
                category: .strain,
                tier: .platinum,
                requirement: AchievementRequirement(metric: .totalActivities, comparison: .greaterThanOrEqual, threshold: 100, duration: nil)
            )
        ])

        // ===== SLEEP ACHIEVEMENTS (6) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "sleep_master_7",
                title: "Sleep Apprentice",
                description: "Achieve 90%+ sleep efficiency for 7 days",
                icon: "moon.fill",
                category: .sleep,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .sleepEfficiency, comparison: .greaterThanOrEqual, threshold: 90, duration: 7)
            ),
            Achievement(
                id: "sleep_master_14",
                title: "Sleep Specialist",
                description: "Achieve 90%+ sleep efficiency for 14 days",
                icon: "moon.stars.fill",
                category: .sleep,
                tier: .silver,
                requirement: AchievementRequirement(metric: .sleepEfficiency, comparison: .greaterThanOrEqual, threshold: 90, duration: 14)
            ),
            Achievement(
                id: "sleep_master_30",
                title: "Sleep Master",
                description: "Achieve 90%+ sleep efficiency for 30 days",
                icon: "moon.circle.fill",
                category: .sleep,
                tier: .gold,
                requirement: AchievementRequirement(metric: .sleepEfficiency, comparison: .greaterThanOrEqual, threshold: 90, duration: 30)
            ),
            Achievement(
                id: "sleep_duration_8h",
                title: "Full Rest",
                description: "Get 8+ hours of sleep for 7 consecutive nights",
                icon: "bed.double.fill",
                category: .sleep,
                tier: .silver,
                requirement: AchievementRequirement(metric: .sleepDuration, comparison: .greaterThanOrEqual, threshold: 8, duration: 7)
            ),
            Achievement(
                id: "sleep_1000_min",
                title: "Dream Weaver",
                description: "Track 1,000 total minutes of sleep",
                icon: "zzz",
                category: .sleep,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .sleepDuration, comparison: .greaterThanOrEqual, threshold: 1000, duration: nil)
            ),
            Achievement(
                id: "perfect_sleep",
                title: "Perfect Night",
                description: "Achieve 98%+ sleep efficiency in a single night",
                icon: "star.fill",
                category: .sleep,
                tier: .gold,
                requirement: AchievementRequirement(metric: .sleepEfficiency, comparison: .greaterThanOrEqual, threshold: 98, duration: nil)
            )
        ])

        // ===== LONGEVITY ACHIEVEMENTS (5) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "bio_age_1yr",
                title: "Age Defier",
                description: "Lower your Strayn Age by 1 year",
                icon: "sparkles",
                category: .longevity,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .straynAge, comparison: .lessThanOrEqual, threshold: -1, duration: nil)
            ),
            Achievement(
                id: "bio_age_3yr",
                title: "Reverse Aging",
                description: "Lower your Strayn Age by 3 years",
                icon: "sparkles",
                category: .longevity,
                tier: .silver,
                requirement: AchievementRequirement(metric: .straynAge, comparison: .lessThanOrEqual, threshold: -3, duration: nil)
            ),
            Achievement(
                id: "bio_age_5yr",
                title: "Longevity Pioneer",
                description: "Lower your Strayn Age by 5 years",
                icon: "sparkle",
                category: .longevity,
                tier: .gold,
                requirement: AchievementRequirement(metric: .straynAge, comparison: .lessThanOrEqual, threshold: -5, duration: nil)
            ),
            Achievement(
                id: "vo2_boost_2",
                title: "Oxygen Rising",
                description: "Increase VO2 Max by 2%",
                icon: "lungs.fill",
                category: .longevity,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .vo2Max, comparison: .greaterThanOrEqual, threshold: 2, duration: nil)
            ),
            Achievement(
                id: "vo2_boost_5",
                title: "Oxygen Guru",
                description: "Increase VO2 Max by 5%",
                icon: "lungs.fill",
                category: .longevity,
                tier: .silver,
                requirement: AchievementRequirement(metric: .vo2Max, comparison: .greaterThanOrEqual, threshold: 5, duration: nil)
            )
        ])

        // ===== CONSISTENCY/HABITS ACHIEVEMENTS (6) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "journal_7",
                title: "Journal Starter",
                description: "Complete morning journal for 7 consecutive days",
                icon: "book.fill",
                category: .habits,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .journalStreak, comparison: .greaterThanOrEqual, threshold: 7, duration: 7)
            ),
            Achievement(
                id: "journal_30",
                title: "Habit Builder",
                description: "Complete morning journal for 30 consecutive days",
                icon: "book.circle.fill",
                category: .habits,
                tier: .silver,
                requirement: AchievementRequirement(metric: .journalStreak, comparison: .greaterThanOrEqual, threshold: 30, duration: 30)
            ),
            Achievement(
                id: "journal_90",
                title: "Consistency King",
                description: "Complete morning journal for 90 consecutive days",
                icon: "crown.fill",
                category: .habits,
                tier: .gold,
                requirement: AchievementRequirement(metric: .journalStreak, comparison: .greaterThanOrEqual, threshold: 90, duration: 90)
            ),
            Achievement(
                id: "journal_365",
                title: "Yearly Devotion",
                description: "Complete morning journal for 365 consecutive days",
                icon: "trophy.fill",
                category: .habits,
                tier: .diamond,
                requirement: AchievementRequirement(metric: .journalStreak, comparison: .greaterThanOrEqual, threshold: 365, duration: 365),
                secret: true
            ),
            Achievement(
                id: "no_alcohol_7",
                title: "Clean Week",
                description: "Log 7 consecutive days without alcohol",
                icon: "drop.fill",
                category: .habits,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .journalCount, comparison: .greaterThanOrEqual, threshold: 7, duration: 7)
            ),
            Achievement(
                id: "no_alcohol_30",
                title: "Sober Month",
                description: "Log 30 consecutive days without alcohol",
                icon: "drop.circle.fill",
                category: .habits,
                tier: .silver,
                requirement: AchievementRequirement(metric: .journalCount, comparison: .greaterThanOrEqual, threshold: 30, duration: 30)
            )
        ])

        // ===== MILESTONE ACHIEVEMENTS (5) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "first_day",
                title: "First Steps",
                description: "Complete your first day of tracking",
                icon: "flag.fill",
                category: .milestones,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 1, duration: nil)
            ),
            Achievement(
                id: "week_tracked",
                title: "One Week In",
                description: "Track for 7 consecutive days",
                icon: "7.circle.fill",
                category: .milestones,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 7, duration: 7)
            ),
            Achievement(
                id: "month_tracked",
                title: "Baseline Complete",
                description: "Track for 30 consecutive days to establish baseline",
                icon: "chart.bar.fill",
                category: .milestones,
                tier: .silver,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 30, duration: 30)
            ),
            Achievement(
                id: "quarter_tracked",
                title: "Quarter Century",
                description: "Track for 90 consecutive days",
                icon: "calendar",
                category: .milestones,
                tier: .gold,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 90, duration: 90)
            ),
            Achievement(
                id: "year_tracked",
                title: "One Year Strong",
                description: "Track for 365 consecutive days",
                icon: "star.circle.fill",
                category: .milestones,
                tier: .diamond,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 365, duration: 365)
            )
        ])

        // ===== SPECIAL ACHIEVEMENTS (5) =====

        allAchievements.append(contentsOf: [
            Achievement(
                id: "early_adopter",
                title: "Early Adopter",
                description: "One of the first to join Strayn",
                icon: "star.fill",
                category: .special,
                tier: .gold,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 1, duration: nil),
                secret: true
            ),
            Achievement(
                id: "hrv_elite",
                title: "HRV Elite",
                description: "Achieve an HRV score above 100ms",
                icon: "waveform.path.ecg",
                category: .special,
                tier: .platinum,
                requirement: AchievementRequirement(metric: .hrvValue, comparison: .greaterThanOrEqual, threshold: 100, duration: nil)
            ),
            Achievement(
                id: "low_rhr",
                title: "Athlete's Heart",
                description: "Achieve a resting heart rate below 50 BPM",
                icon: "heart.fill",
                category: .special,
                tier: .platinum,
                requirement: AchievementRequirement(metric: .restingHR, comparison: .lessThan, threshold: 50, duration: nil)
            ),
            Achievement(
                id: "share_first",
                title: "Social Butterfly",
                description: "Share your first achievement",
                icon: "square.and.arrow.up",
                category: .special,
                tier: .bronze,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 1, duration: nil)
            ),
            Achievement(
                id: "all_categories",
                title: "Well Rounded",
                description: "Unlock at least one achievement in every category",
                icon: "circle.hexagongrid.fill",
                category: .special,
                tier: .gold,
                requirement: AchievementRequirement(metric: .daysTracked, comparison: .greaterThanOrEqual, threshold: 1, duration: nil),
                secret: true
            )
        ])

        return allAchievements
    }

    // MARK: - Public Methods

    func checkAchievements(history: [DailyRecovery], strainHistory: [DailyStrain]? = nil) {
        for i in 0..<achievements.count {
            checkAchievement(at: i, recoveryHistory: history, strainHistory: strainHistory)
        }

        // Recalculate stats
        stats.recalculate(from: achievements)
        saveAchievements()
    }

    func unlock(_ achievementId: String) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        if !achievements[index].isUnlocked {
            achievements[index].isUnlocked = true
            achievements[index].progress = 1.0
            achievements[index].dateUnlocked = Date()

            recentUnlocks.insert(achievements[index], at: 0)
            if recentUnlocks.count > 5 {
                recentUnlocks.removeLast()
            }

            // Trigger celebration
            celebratingAchievement = achievements[index]
            showCelebration = true

            // Haptics
            if achievements[index].tier == .diamond || achievements[index].tier == .platinum {
                HapticsManager.shared.playAchievementUnlock()
            } else {
                HapticsManager.shared.playSuccess()
            }

            // Recalculate stats
            stats.recalculate(from: achievements)
            saveAchievements()

            // Post notification
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: nil,
                userInfo: ["achievement": achievements[index]]
            )
        }
    }

    func updateProgress(_ achievementId: String, progress: Double) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        if !achievements[index].isUnlocked {
            achievements[index].progress = min(1.0, max(0, progress))

            if achievements[index].progress >= 1.0 {
                unlock(achievementId)
            } else {
                saveAchievements()
            }
        }
    }

    func dismissCelebration() {
        withAnimation {
            showCelebration = false
            celebratingAchievement = nil
        }
    }

    func getAchievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    func getUnlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked }.sorted { ($0.dateUnlocked ?? Date.distantPast) > ($1.dateUnlocked ?? Date.distantPast) }
    }

    func getLockedAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked && !$0.secret }
    }

    func getNextToUnlock() -> [Achievement] {
        achievements
            .filter { !$0.isUnlocked && !$0.secret }
            .sorted { $0.progress > $1.progress }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Private Methods

    private func checkAchievement(at index: Int, recoveryHistory: [DailyRecovery], strainHistory: [DailyStrain]?) {
        let achievement = achievements[index]
        guard !achievement.isUnlocked else { return }

        let requirement = achievement.requirement

        switch requirement.metric {
        case .consecutiveGreenDays:
            let greenStreak = calculateGreenStreak(from: recoveryHistory)
            let progress = Double(greenStreak) / requirement.threshold
            updateProgress(achievement.id, progress: progress)

        case .recoveryScore:
            if let latest = recoveryHistory.last {
                if latest.recoveryScore >= requirement.threshold {
                    updateProgress(achievement.id, progress: 1.0)
                }
            }

        case .strainScore:
            if let strains = strainHistory, let latest = strains.last {
                if latest.strainScore >= requirement.threshold {
                    updateProgress(achievement.id, progress: 1.0)
                }
            }

        case .sleepEfficiency:
            if let duration = requirement.duration {
                let efficientDays = recoveryHistory.suffix(duration).filter { $0.sleepScore >= requirement.threshold }.count
                let progress = Double(efficientDays) / Double(duration)
                updateProgress(achievement.id, progress: progress)
            } else {
                if let latest = recoveryHistory.last, latest.sleepScore >= requirement.threshold {
                    updateProgress(achievement.id, progress: 1.0)
                }
            }

        case .daysTracked:
            let progress = Double(recoveryHistory.count) / requirement.threshold
            updateProgress(achievement.id, progress: progress)

        case .hrvValue:
            if let latest = recoveryHistory.last, let hrv = latest.rawHRV {
                if hrv >= requirement.threshold {
                    updateProgress(achievement.id, progress: 1.0)
                }
            }

        case .restingHR:
            if let latest = recoveryHistory.last, let rhr = latest.rawRestingHR {
                if requirement.comparison == .lessThan && rhr < requirement.threshold {
                    updateProgress(achievement.id, progress: 1.0)
                }
            }

        default:
            break
        }
    }

    private func calculateGreenStreak(from history: [DailyRecovery]) -> Int {
        var streak = 0
        for recovery in history.reversed() {
            if recovery.recoveryScore >= 67 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func setupNotificationListeners() {
        // Listen for journal completion
        NotificationCenter.default.publisher(for: .journalCompleted)
            .sink { [weak self] _ in
                self?.checkJournalAchievements()
            }
            .store(in: &cancellables)

        // Listen for journal streak milestones
        NotificationCenter.default.publisher(for: .journalStreakMilestone)
            .sink { [weak self] notification in
                if let streak = notification.userInfo?["streak"] as? Int {
                    self?.handleJournalStreak(streak)
                }
            }
            .store(in: &cancellables)
    }

    private func checkJournalAchievements() {
        let streak = HabitTracker.shared.streakInfo.currentStreak

        if streak >= 7 {
            updateProgress("journal_7", progress: 1.0)
        }
        if streak >= 30 {
            updateProgress("journal_30", progress: 1.0)
        }
        if streak >= 90 {
            updateProgress("journal_90", progress: 1.0)
        }
        if streak >= 365 {
            updateProgress("journal_365", progress: 1.0)
        }
    }

    private func handleJournalStreak(_ streak: Int) {
        let achievementIds = [
            7: "journal_7",
            30: "journal_30",
            90: "journal_90",
            365: "journal_365"
        ]

        if let id = achievementIds[streak] {
            unlock(id)
        }
    }

    // MARK: - Persistence

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge with new achievements
            let existingIds = Set(decoded.map { $0.id })
            let allAchievements = Self.createAllAchievements()

            achievements = allAchievements.map { newAchievement in
                if let existing = decoded.first(where: { $0.id == newAchievement.id }) {
                    // Preserve progress and unlock status
                    var updated = newAchievement
                    updated.isUnlocked = existing.isUnlocked
                    updated.progress = existing.progress
                    updated.dateUnlocked = existing.dateUnlocked
                    return updated
                }
                return newAchievement
            }
        } else {
            achievements = Self.createAllAchievements()
        }

        // Load stats
        if let statsData = UserDefaults.standard.data(forKey: "achievementStats"),
           let decoded = try? JSONDecoder().decode(UserAchievementStats.self, from: statsData) {
            stats = decoded
        } else {
            stats.recalculate(from: achievements)
        }

        // Load recent unlocks
        if let recentData = UserDefaults.standard.data(forKey: "recentUnlocks"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: recentData) {
            recentUnlocks = decoded
        }
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        if let statsEncoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(statsEncoded, forKey: "achievementStats")
        }
        if let recentEncoded = try? JSONEncoder().encode(recentUnlocks) {
            UserDefaults.standard.set(recentEncoded, forKey: "recentUnlocks")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Achievement Celebration View

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var ringScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: StraynSpacing.xl) {
                // Badge with animated rings
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(achievement.tier.glowColor, lineWidth: 2)
                            .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                            .scaleEffect(ringScale)
                            .opacity(showContent ? 0.8 - Double(i) * 0.2 : 0)
                            .animation(.spring(response: 0.6).delay(Double(i) * 0.1), value: showContent)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [achievement.tier.color, achievement.tier.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: achievement.tier.glowColor, radius: 30)
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showContent)
                }

                // Tier badge
                Text(achievement.tier.rawValue.uppercased())
                    .font(StraynTypography.metricLabel)
                    .tracking(4)
                    .foregroundColor(achievement.tier.color)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut.delay(0.3), value: showContent)

                // Title
                Text(achievement.title)
                    .font(StraynTypography.displaySmall())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.4), value: showContent)

                // Description
                Text(achievement.description)
                    .font(StraynTypography.bodyMedium)
                    .foregroundColor(StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut.delay(0.5), value: showContent)

                // Points
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("+\(achievement.points) points")
                        .font(StraynTypography.labelLarge(.bold))
                        .foregroundColor(.white)
                }
                .padding(.top, StraynSpacing.md)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut.delay(0.6), value: showContent)

                // Dismiss button
                Button(action: onDismiss) {
                    Text("AWESOME!")
                        .font(StraynTypography.labelLarge(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(StraynRadius.lg)
                }
                .padding(.top, StraynSpacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut.delay(0.7), value: showContent)
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
                ringScale = 1.0
            }
            HapticsManager.shared.playAchievementUnlock()
        }
    }
}
