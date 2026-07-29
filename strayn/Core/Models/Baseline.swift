//
//  Baseline.swift
//  strayn
//
//  Represents a rolling baseline for a health metric
//

import Foundation

struct Baseline: Identifiable, Codable {
    let id: UUID
    let userId: UUID

    // Metric being baselined
    let metric: BaselineMetric

    // Statistical values
    let mean: Double
    let standardDeviation: Double
    let median: Double?

    // Rolling window
    let startDate: Date  // First day in window
    let endDate: Date  // Last day in window
    let sampleCount: Int
    let windowDays: Int  // e.g., 14, 21, 30

    // Trend detection
    let trend: TrendDirection?  // .improving, .declining, .stable
    let trendSlope: Double?  // Change per day

    // Metadata
    let calculatedAt: Date
    let isValid: Bool  // False if insufficient data

    enum BaselineMetric: String, Codable {
        case hrv = "HRV"
        case restingHR = "Resting HR"
        case respiratoryRate = "Respiratory Rate"
        case sleepDuration = "Sleep Duration"

        var unit: String {
            switch self {
            case .hrv:
                return "ms"
            case .restingHR:
                return "bpm"
            case .respiratoryRate:
                return "breaths/min"
            case .sleepDuration:
                return "hours"
            }
        }

        /// Is higher better for this metric?
        var higherIsBetter: Bool {
            switch self {
            case .hrv, .sleepDuration:
                return true
            case .restingHR, .respiratoryRate:
                return false
            }
        }
    }

    enum TrendDirection: String, Codable {
        case improving = "Improving"
        case declining = "Declining"
        case stable = "Stable"

        /// Get trend for a metric based on slope
        static func trend(for metric: BaselineMetric, slope: Double) -> TrendDirection {
            // Threshold: 1% change over window period is considered a trend
            let threshold = 0.01

            if metric.higherIsBetter {
                if slope > threshold {
                    return .improving
                } else if slope < -threshold {
                    return .declining
                } else {
                    return .stable
                }
            } else {
                // Inverted for metrics where lower is better
                if slope < -threshold {
                    return .improving
                } else if slope > threshold {
                    return .declining
                } else {
                    return .stable
                }
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        metric: BaselineMetric,
        mean: Double,
        standardDeviation: Double,
        median: Double? = nil,
        startDate: Date,
        endDate: Date,
        sampleCount: Int,
        windowDays: Int,
        trend: TrendDirection? = nil,
        trendSlope: Double? = nil,
        calculatedAt: Date = Date(),
        isValid: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.metric = metric
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.median = median
        self.startDate = startDate
        self.endDate = endDate
        self.sampleCount = sampleCount
        self.windowDays = windowDays
        self.trend = trend
        self.trendSlope = trendSlope
        self.calculatedAt = calculatedAt
        self.isValid = isValid
    }

    /// Calculate Z-score for a value relative to this baseline
    func zScore(for value: Double) -> Double {
        guard standardDeviation > 0 else { return 0 }
        return (value - mean) / standardDeviation
    }

    /// Is the data quality sufficient for this baseline?
    var hasGoodDataQuality: Bool {
        return isValid && sampleCount >= (windowDays / 2)
    }
}
