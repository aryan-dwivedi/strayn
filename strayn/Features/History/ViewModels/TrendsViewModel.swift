//
//  TrendsViewModel.swift
//  strayn
//
//  Enhanced AI-powered trends analysis with pattern detection and personalized insights.
//

import Foundation
import Combine

// MARK: - AI Insight Models

enum InsightType: String, CaseIterable {
    case trend = "Trend"
    case correlation = "Correlation"
    case anomaly = "Anomaly"
    case recommendation = "Recommendation"
    case celebration = "Celebration"
    case warning = "Warning"

    var icon: String {
        switch self {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .correlation: return "link"
        case .anomaly: return "exclamationmark.triangle.fill"
        case .recommendation: return "lightbulb.fill"
        case .celebration: return "star.fill"
        case .warning: return "bell.badge.fill"
        }
    }

    var accentColorName: String {
        switch self {
        case .trend: return "accentPrimary"
        case .correlation: return "sleep"
        case .anomaly: return "zoneYellow"
        case .recommendation: return "biologicalAge"
        case .celebration: return "zoneGreen"
        case .warning: return "zoneRed"
        }
    }
}

enum InsightPriority: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct AIInsight: Identifiable, Hashable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let priority: InsightPriority
    let metric: String?
    let actionable: Bool
    let timestamp: Date

    init(type: InsightType, title: String, message: String, priority: InsightPriority = .medium, metric: String? = nil, actionable: Bool = false) {
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
        self.metric = metric
        self.actionable = actionable
        self.timestamp = Date()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AIInsight, rhs: AIInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Trend Analysis Models

struct TrendAnalysis {
    let direction: TrendDirection
    let velocity: TrendVelocity
    let confidence: Double
    let periodDays: Int

    enum TrendDirection: String {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }
    }

    enum TrendVelocity: String {
        case rapid = "rapidly"
        case moderate = "moderately"
        case slow = "slowly"
        case minimal = "minimally"
    }
}

struct StrainRecoveryBalance {
    let status: BalanceStatus
    let strainToRecoveryRatio: Double
    let recommendation: String

    enum BalanceStatus: String {
        case optimal = "Optimal"
        case slightlyOverreaching = "Slightly Overreaching"
        case overreaching = "Overreaching"
        case undertraining = "Undertraining"
        case detraining = "Detraining"
    }
}

struct SleepPattern {
    let consistency: ConsistencyLevel
    let averageDuration: TimeInterval
    let averageEfficiency: Double
    let bedtimeVariability: TimeInterval
    let recommendation: String

    enum ConsistencyLevel: String {
        case excellent = "Excellent"
        case good = "Good"
        case moderate = "Moderate"
        case poor = "Poor"
        case erratic = "Erratic"
    }
}

struct AnomalyDetection {
    let hasAnomaly: Bool
    let metric: String
    let deviation: Double
    let expectedRange: ClosedRange<Double>
    let actualValue: Double
    let severity: AnomalySeverity

    enum AnomalySeverity {
        case minor, moderate, significant
    }
}

// MARK: - TrendsViewModel

@MainActor
class TrendsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recoveryHistory: [DailyRecovery] = []
    @Published var strainHistory: [DailyStrain] = []
    @Published var heatmapData: [Date: Double] = [:]
    @Published var aiAnalysis: String = "Analyzing your physiological trends..."

    // Enhanced AI Analysis
    @Published var insights: [AIInsight] = []
    @Published var recoveryTrend: TrendAnalysis?
    @Published var strainTrend: TrendAnalysis?
    @Published var hrvTrend: TrendAnalysis?
    @Published var strainRecoveryBalance: StrainRecoveryBalance?
    @Published var sleepPattern: SleepPattern?
    @Published var anomalies: [AnomalyDetection] = []

    // Statistics
    @Published var averageRecovery: Double = 0
    @Published var averageStrain: Double = 0
    @Published var averageHRV: Double = 0
    @Published var greenDaysCount: Int = 0
    @Published var yellowDaysCount: Int = 0
    @Published var redDaysCount: Int = 0
    @Published var bestRecoveryDay: DailyRecovery?
    @Published var worstRecoveryDay: DailyRecovery?

    // Loading state
    @Published var isAnalyzing: Bool = false

    // MARK: - Private Properties

    private let recoveryRepo = CoreDataRecoveryRepository.shared
    private let strainRepo = CoreDataStrainRepository.shared
    private let calendar = Calendar.current

    // Baseline values for comparison
    private var userBaseline: UserBaseline?

    struct UserBaseline {
        var avgRecovery: Double
        var avgHRV: Double
        var avgRestingHR: Double
        var avgSleepDuration: TimeInterval
    }

    // MARK: - Public Methods

    func fetchHistory(for range: TimeRange) async {
        isAnalyzing = true

        let today = calendar.startOfDay(for: Date())

        let days: Int
        switch range {
        case .week: days = -7
        case .month: days = -30
        case .year: days = -365
        }

        let startDate = calendar.date(byAdding: .day, value: days, to: today)!

        do {
            self.recoveryHistory = try await recoveryRepo.getRecoveries(from: startDate, to: Date())
            self.strainHistory = try await strainRepo.getStrains(from: startDate, to: Date())

            // Populate heatmap data
            var hMap: [Date: Double] = [:]
            for rec in recoveryHistory {
                hMap[calendar.startOfDay(for: rec.date)] = rec.recoveryScore
            }
            self.heatmapData = hMap

            // Calculate statistics
            calculateStatistics()

            // Run comprehensive AI analysis
            await runAIAnalysis(for: range)

        } catch {
            print("Error fetching history: \(error)")
            aiAnalysis = "Unable to analyze trends. Please ensure health data is available."
        }

        isAnalyzing = false
    }

    // MARK: - Statistics Calculation

    private func calculateStatistics() {
        guard !recoveryHistory.isEmpty else { return }

        // Average calculations
        averageRecovery = recoveryHistory.reduce(0.0) { $0 + $1.recoveryScore } / Double(recoveryHistory.count)

        if !strainHistory.isEmpty {
            averageStrain = strainHistory.reduce(0.0) { $0 + $1.strainScore } / Double(strainHistory.count)
        }

        let hrvValues = recoveryHistory.compactMap { $0.rawHRV }
        if !hrvValues.isEmpty {
            averageHRV = hrvValues.reduce(0.0, +) / Double(hrvValues.count)
        }

        // Zone counts
        greenDaysCount = recoveryHistory.filter { $0.recoveryScore >= 67 }.count
        yellowDaysCount = recoveryHistory.filter { $0.recoveryScore >= 34 && $0.recoveryScore < 67 }.count
        redDaysCount = recoveryHistory.filter { $0.recoveryScore < 34 }.count

        // Best and worst days
        bestRecoveryDay = recoveryHistory.max(by: { $0.recoveryScore < $1.recoveryScore })
        worstRecoveryDay = recoveryHistory.min(by: { $0.recoveryScore < $1.recoveryScore })

        // Calculate baseline from last 30 days (or available data)
        calculateUserBaseline()
    }

    private func calculateUserBaseline() {
        guard recoveryHistory.count >= 7 else { return }

        let baselineData = Array(recoveryHistory.suffix(30))

        userBaseline = UserBaseline(
            avgRecovery: baselineData.reduce(0.0) { $0 + $1.recoveryScore } / Double(baselineData.count),
            avgHRV: baselineData.compactMap { $0.rawHRV }.reduce(0.0, +) / Double(baselineData.compactMap { $0.rawHRV }.count),
            avgRestingHR: baselineData.compactMap { $0.rawRestingHR }.reduce(0.0, +) / Double(baselineData.compactMap { $0.rawRestingHR }.count),
            avgSleepDuration: baselineData.compactMap { $0.rawSleepDuration }.reduce(0.0, +) / Double(baselineData.compactMap { $0.rawSleepDuration }.count)
        )
    }

    // MARK: - AI Analysis Engine

    private func runAIAnalysis(for range: TimeRange) async {
        insights.removeAll()
        anomalies.removeAll()

        guard !recoveryHistory.isEmpty else {
            aiAnalysis = "Not enough data to generate insights. Keep tracking to unlock AI analysis."
            return
        }

        // Run all analysis components
        analyzeRecoveryTrend()
        analyzeStrainTrend()
        analyzeHRVTrend()
        analyzeStrainRecoveryBalance()
        analyzeSleepPatterns()
        detectAnomalies()
        generateCorrelationInsights()
        generateCelebrations()
        generateRecommendations()

        // Sort insights by priority
        insights.sort { $0.priority > $1.priority }

        // Generate summary
        generateAISummary(for: range)
    }

    // MARK: - Trend Analysis

    private func analyzeRecoveryTrend() {
        guard recoveryHistory.count >= 3 else { return }

        let scores = recoveryHistory.map { $0.recoveryScore }
        recoveryTrend = calculateTrend(values: scores, metric: "Recovery")

        if let trend = recoveryTrend {
            let insight = AIInsight(
                type: .trend,
                title: "Recovery Trend",
                message: "Your recovery is \(trend.velocity.rawValue) \(trend.direction.rawValue) over the past \(trend.periodDays) days.",
                priority: trend.direction == .declining ? .high : .medium,
                metric: "Recovery"
            )
            insights.append(insight)
        }
    }

    private func analyzeStrainTrend() {
        guard strainHistory.count >= 3 else { return }

        let strains = strainHistory.map { $0.strainScore }
        strainTrend = calculateTrend(values: strains, metric: "Strain")

        if let trend = strainTrend, trend.direction != .stable {
            let insight = AIInsight(
                type: .trend,
                title: "Training Load Trend",
                message: "Your training load is \(trend.velocity.rawValue) \(trend.direction == .improving ? "increasing" : "decreasing").",
                priority: .medium,
                metric: "Strain"
            )
            insights.append(insight)
        }
    }

    private func analyzeHRVTrend() {
        let hrvValues = recoveryHistory.compactMap { $0.rawHRV }
        guard hrvValues.count >= 3 else { return }

        hrvTrend = calculateTrend(values: hrvValues, metric: "HRV")

        if let trend = hrvTrend, trend.direction == .declining && trend.velocity != .minimal {
            let insight = AIInsight(
                type: .warning,
                title: "HRV Declining",
                message: "Your HRV has been declining \(trend.velocity.rawValue). This may indicate accumulated stress or fatigue.",
                priority: .high,
                metric: "HRV",
                actionable: true
            )
            insights.append(insight)
        }
    }

    private func calculateTrend(values: [Double], metric: String) -> TrendAnalysis {
        let count = values.count
        let periodDays = count

        // Calculate simple linear regression
        let xMean = Double(count - 1) / 2.0
        let yMean = values.reduce(0, +) / Double(count)

        var numerator: Double = 0
        var denominator: Double = 0

        for (i, y) in values.enumerated() {
            let x = Double(i)
            numerator += (x - xMean) * (y - yMean)
            denominator += (x - xMean) * (x - xMean)
        }

        let slope = denominator != 0 ? numerator / denominator : 0

        // Determine direction
        let direction: TrendAnalysis.TrendDirection
        let normalizedSlope = slope / yMean * 100 // As percentage of mean

        if abs(normalizedSlope) < 0.5 {
            direction = .stable
        } else if normalizedSlope > 0 {
            direction = .improving
        } else {
            direction = .declining
        }

        // Determine velocity
        let velocity: TrendAnalysis.TrendVelocity
        let absSlope = abs(normalizedSlope)

        if absSlope >= 3 {
            velocity = .rapid
        } else if absSlope >= 1.5 {
            velocity = .moderate
        } else if absSlope >= 0.5 {
            velocity = .slow
        } else {
            velocity = .minimal
        }

        // Calculate R-squared for confidence
        var ssRes: Double = 0
        var ssTot: Double = 0

        for (i, y) in values.enumerated() {
            let predicted = yMean + slope * (Double(i) - xMean)
            ssRes += (y - predicted) * (y - predicted)
            ssTot += (y - yMean) * (y - yMean)
        }

        let rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0

        return TrendAnalysis(
            direction: direction,
            velocity: velocity,
            confidence: max(0, min(1, rSquared)),
            periodDays: periodDays
        )
    }

    // MARK: - Strain-Recovery Balance

    private func analyzeStrainRecoveryBalance() {
        guard !recoveryHistory.isEmpty && !strainHistory.isEmpty else { return }

        // Calculate average strain for days with green recovery
        let greenDays = recoveryHistory.filter { $0.recoveryScore >= 67 }
        let yellowDays = recoveryHistory.filter { $0.recoveryScore >= 34 && $0.recoveryScore < 67 }
        let redDays = recoveryHistory.filter { $0.recoveryScore < 34 }

        // Calculate strain-to-recovery ratio
        let avgRecovery = averageRecovery / 100.0 // Normalize to 0-1
        let normalizedStrain = min(averageStrain / 21.0, 1.0) // Max strain is ~21

        let ratio = avgRecovery > 0 ? normalizedStrain / avgRecovery : 0

        let status: StrainRecoveryBalance.BalanceStatus
        let recommendation: String

        if ratio < 0.5 {
            status = .undertraining
            recommendation = "Your training load is relatively low compared to your recovery. Consider increasing intensity on green days."
        } else if ratio < 0.8 {
            status = .optimal
            recommendation = "You're maintaining an excellent balance between strain and recovery. Keep it up!"
        } else if ratio < 1.0 {
            status = .slightlyOverreaching
            recommendation = "Training load is slightly high relative to recovery. Monitor for signs of fatigue."
        } else if ratio < 1.3 {
            status = .overreaching
            recommendation = "You may be accumulating fatigue. Consider a deload day or active recovery session."
        } else {
            status = .detraining
            recommendation = "Very low training stimulus detected. If intentional rest, great. Otherwise, consider resuming training."
        }

        strainRecoveryBalance = StrainRecoveryBalance(
            status: status,
            strainToRecoveryRatio: ratio,
            recommendation: recommendation
        )

        if status != .optimal {
            let insight = AIInsight(
                type: status == .overreaching ? .warning : .recommendation,
                title: "Training Balance: \(status.rawValue)",
                message: recommendation,
                priority: status == .overreaching ? .high : .medium,
                actionable: true
            )
            insights.append(insight)
        }
    }

    // MARK: - Sleep Pattern Analysis

    private func analyzeSleepPatterns() {
        let sleepDurations = recoveryHistory.compactMap { $0.rawSleepDuration }
        let sleepScores = recoveryHistory.map { $0.sleepScore }

        guard sleepDurations.count >= 3 else { return }

        let avgDuration = sleepDurations.reduce(0, +) / Double(sleepDurations.count)
        let avgEfficiency = sleepScores.reduce(0, +) / Double(sleepScores.count)

        // Calculate variance for consistency
        let variance = sleepDurations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(sleepDurations.count)
        let stdDev = sqrt(variance)

        // Consistency level based on standard deviation (in hours)
        let stdDevHours = stdDev / 3600

        let consistency: SleepPattern.ConsistencyLevel
        if stdDevHours < 0.5 {
            consistency = .excellent
        } else if stdDevHours < 1.0 {
            consistency = .good
        } else if stdDevHours < 1.5 {
            consistency = .moderate
        } else if stdDevHours < 2.0 {
            consistency = .poor
        } else {
            consistency = .erratic
        }

        let recommendation: String
        switch consistency {
        case .excellent, .good:
            recommendation = "Your sleep schedule is consistent, which supports optimal recovery."
        case .moderate:
            recommendation = "Try to maintain more consistent sleep and wake times for better recovery."
        case .poor, .erratic:
            recommendation = "Highly variable sleep patterns may be impacting your recovery. Aim for consistent bed and wake times."
        }

        sleepPattern = SleepPattern(
            consistency: consistency,
            averageDuration: avgDuration,
            averageEfficiency: avgEfficiency,
            bedtimeVariability: stdDev,
            recommendation: recommendation
        )

        if consistency == .poor || consistency == .erratic {
            let insight = AIInsight(
                type: .recommendation,
                title: "Sleep Consistency Alert",
                message: recommendation,
                priority: .high,
                metric: "Sleep",
                actionable: true
            )
            insights.append(insight)
        }

        // Check for insufficient sleep
        let avgHours = avgDuration / 3600
        if avgHours < 7 {
            let insight = AIInsight(
                type: .warning,
                title: "Insufficient Sleep",
                message: "You're averaging \(String(format: "%.1f", avgHours)) hours of sleep. Most adults need 7-9 hours for optimal recovery.",
                priority: .high,
                metric: "Sleep",
                actionable: true
            )
            insights.append(insight)
        }
    }

    // MARK: - Anomaly Detection

    private func detectAnomalies() {
        guard let baseline = userBaseline else { return }

        // Check latest recovery against baseline
        if let latest = recoveryHistory.last {
            let recoveryDeviation = (latest.recoveryScore - baseline.avgRecovery) / baseline.avgRecovery

            if abs(recoveryDeviation) > 0.25 {
                let anomaly = AnomalyDetection(
                    hasAnomaly: true,
                    metric: "Recovery",
                    deviation: recoveryDeviation,
                    expectedRange: (baseline.avgRecovery * 0.85)...(baseline.avgRecovery * 1.15),
                    actualValue: latest.recoveryScore,
                    severity: abs(recoveryDeviation) > 0.4 ? .significant : .moderate
                )
                anomalies.append(anomaly)

                let isPositive = recoveryDeviation > 0
                let insight = AIInsight(
                    type: isPositive ? .celebration : .anomaly,
                    title: isPositive ? "Exceptional Recovery" : "Recovery Anomaly Detected",
                    message: isPositive ?
                        "Today's recovery is \(Int(abs(recoveryDeviation) * 100))% above your baseline!" :
                        "Recovery is \(Int(abs(recoveryDeviation) * 100))% below baseline. Review recent stressors or training load.",
                    priority: isPositive ? .medium : .high,
                    metric: "Recovery"
                )
                insights.append(insight)
            }

            // Check HRV anomaly
            if let hrv = latest.rawHRV {
                let hrvDeviation = (hrv - baseline.avgHRV) / baseline.avgHRV

                if hrvDeviation < -0.2 {
                    let anomaly = AnomalyDetection(
                        hasAnomaly: true,
                        metric: "HRV",
                        deviation: hrvDeviation,
                        expectedRange: (baseline.avgHRV * 0.85)...(baseline.avgHRV * 1.15),
                        actualValue: hrv,
                        severity: hrvDeviation < -0.35 ? .significant : .moderate
                    )
                    anomalies.append(anomaly)

                    let insight = AIInsight(
                        type: .anomaly,
                        title: "Low HRV Alert",
                        message: "Your HRV is \(Int(abs(hrvDeviation) * 100))% below baseline. Consider rest or light activity today.",
                        priority: .high,
                        metric: "HRV",
                        actionable: true
                    )
                    insights.append(insight)
                }
            }

            // Check resting HR anomaly (elevated is concerning)
            if let rhr = latest.rawRestingHR {
                let rhrDeviation = (rhr - baseline.avgRestingHR) / baseline.avgRestingHR

                if rhrDeviation > 0.1 {
                    let insight = AIInsight(
                        type: .warning,
                        title: "Elevated Resting HR",
                        message: "Resting heart rate is \(Int(rhr)) bpm, above your baseline of \(Int(baseline.avgRestingHR)) bpm. This may indicate stress, illness, or overtraining.",
                        priority: .high,
                        metric: "Resting HR",
                        actionable: true
                    )
                    insights.append(insight)
                }
            }
        }
    }

    // MARK: - Correlation Insights

    private func generateCorrelationInsights() {
        guard recoveryHistory.count >= 7 else { return }

        // Correlate sleep with next-day recovery
        var sleepRecoveryPairs: [(sleep: Double, recovery: Double)] = []

        for i in 1..<recoveryHistory.count {
            if let sleepDuration = recoveryHistory[i-1].rawSleepDuration {
                sleepRecoveryPairs.append((sleep: sleepDuration / 3600, recovery: recoveryHistory[i].recoveryScore))
            }
        }

        if sleepRecoveryPairs.count >= 5 {
            let correlation = calculateCorrelation(pairs: sleepRecoveryPairs)

            if abs(correlation) > 0.4 {
                let insight = AIInsight(
                    type: .correlation,
                    title: "Sleep-Recovery Link",
                    message: correlation > 0 ?
                        "Strong correlation detected: longer sleep leads to better recovery in your data." :
                        "Interestingly, your sleep duration doesn't strongly predict recovery. Quality may matter more.",
                    priority: .medium,
                    actionable: true
                )
                insights.append(insight)
            }
        }

        // Correlate strain with next-day recovery
        if strainHistory.count >= 5 {
            var strainRecoveryPairs: [(sleep: Double, recovery: Double)] = []

            for strain in strainHistory {
                let strainDate = calendar.startOfDay(for: strain.date)
                if let nextDayRecovery = recoveryHistory.first(where: {
                    calendar.startOfDay(for: $0.date) == calendar.date(byAdding: .day, value: 1, to: strainDate)
                }) {
                    strainRecoveryPairs.append((sleep: strain.strainScore, recovery: nextDayRecovery.recoveryScore))
                }
            }

            if strainRecoveryPairs.count >= 5 {
                let correlation = calculateCorrelation(pairs: strainRecoveryPairs)

                if correlation < -0.4 {
                    let insight = AIInsight(
                        type: .correlation,
                        title: "Strain Impact Detected",
                        message: "High strain days tend to result in lower recovery the next day. Plan rest days after intense sessions.",
                        priority: .medium,
                        actionable: true
                    )
                    insights.append(insight)
                }
            }
        }
    }

    private func calculateCorrelation(pairs: [(sleep: Double, recovery: Double)]) -> Double {
        let n = Double(pairs.count)
        let sumX = pairs.map { $0.sleep }.reduce(0, +)
        let sumY = pairs.map { $0.recovery }.reduce(0, +)
        let sumXY = pairs.map { $0.sleep * $0.recovery }.reduce(0, +)
        let sumX2 = pairs.map { $0.sleep * $0.sleep }.reduce(0, +)
        let sumY2 = pairs.map { $0.recovery * $0.recovery }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        return denominator != 0 ? numerator / denominator : 0
    }

    // MARK: - Celebrations

    private func generateCelebrations() {
        // Celebrate green streaks
        var currentStreak = 0
        for recovery in recoveryHistory.reversed() {
            if recovery.recoveryScore >= 67 {
                currentStreak += 1
            } else {
                break
            }
        }

        if currentStreak >= 3 {
            let insight = AIInsight(
                type: .celebration,
                title: "\(currentStreak)-Day Green Streak! 🔥",
                message: "You've maintained optimal recovery for \(currentStreak) consecutive days. Outstanding!",
                priority: .medium
            )
            insights.append(insight)
        }

        // Celebrate personal bests
        if let best = bestRecoveryDay, best.recoveryScore >= 95 {
            let insight = AIInsight(
                type: .celebration,
                title: "Elite Recovery Achieved!",
                message: "You hit \(Int(best.recoveryScore))% recovery - in the elite performance zone!",
                priority: .medium
            )
            insights.append(insight)
        }

        // Celebrate improving HRV trend
        if let hrvTrend = hrvTrend, hrvTrend.direction == .improving && hrvTrend.velocity != .minimal {
            let insight = AIInsight(
                type: .celebration,
                title: "HRV on the Rise",
                message: "Your HRV is trending upward, indicating improving cardiovascular fitness and stress resilience.",
                priority: .medium,
                metric: "HRV"
            )
            insights.append(insight)
        }
    }

    // MARK: - Recommendations

    private func generateRecommendations() {
        // Recommendation based on today's recovery
        if let today = recoveryHistory.last {
            if today.recoveryScore >= 67 {
                let insight = AIInsight(
                    type: .recommendation,
                    title: "Green Day Strategy",
                    message: "With \(Int(today.recoveryScore))% recovery, today is ideal for high-intensity training. Push harder workouts to green days.",
                    priority: .medium,
                    actionable: true
                )
                insights.append(insight)
            } else if today.recoveryScore < 34 {
                let insight = AIInsight(
                    type: .recommendation,
                    title: "Recovery Day Recommended",
                    message: "Low recovery suggests your body needs rest. Light activity like walking or yoga is best today.",
                    priority: .high,
                    actionable: true
                )
                insights.append(insight)
            }
        }

        // Recommendation for consistent patterns
        if let sleepPattern = sleepPattern, sleepPattern.averageDuration < 7 * 3600 {
            let insight = AIInsight(
                type: .recommendation,
                title: "Sleep Optimization",
                message: "Adding 30 minutes to your sleep could improve recovery by 5-10%. Try moving bedtime earlier.",
                priority: .high,
                actionable: true
            )
            insights.append(insight)
        }
    }

    // MARK: - AI Summary Generation

    private func generateAISummary(for range: TimeRange) {
        guard !recoveryHistory.isEmpty else {
            aiAnalysis = "Start tracking to receive AI-powered insights about your health trends."
            return
        }

        let rangeText = range == .week ? "7-day" : (range == .month ? "30-day" : "yearly")

        var summary = "Your \(rangeText) analysis: "

        // Recovery trend
        if let trend = recoveryTrend {
            summary += "Recovery is \(trend.velocity.rawValue) \(trend.direction.rawValue). "
        }

        // Balance assessment
        if let balance = strainRecoveryBalance {
            summary += "Training balance is \(balance.status.rawValue.lowercased()). "
        }

        // Sleep
        if let sleep = sleepPattern {
            let avgHours = sleep.averageDuration / 3600
            summary += "Averaging \(String(format: "%.1f", avgHours))h sleep with \(sleep.consistency.rawValue.lowercased()) consistency. "
        }

        // Key recommendation
        if let topRecommendation = insights.first(where: { $0.type == .recommendation && $0.actionable }) {
            summary += topRecommendation.message
        }

        aiAnalysis = summary
    }

    // MARK: - Filtered Insights

    func getInsights(for type: InsightType? = nil, limit: Int = 10) -> [AIInsight] {
        var filtered = insights

        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }

        return Array(filtered.prefix(limit))
    }

    func getHighPriorityInsights() -> [AIInsight] {
        return insights.filter { $0.priority >= .high }
    }

    func getActionableInsights() -> [AIInsight] {
        return insights.filter { $0.actionable }
    }
}
