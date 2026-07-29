//
//  CoachingInsight.swift
//  strayn
//
//  Represents a data-driven coaching insight for the user
//

import Foundation

struct CoachingInsight: Identifiable, Codable {
    let id: UUID
    let date: Date

    // Insight content
    let title: String
    let message: String
    let category: InsightCategory
    let priority: Int  // 1 (highest) to 5 (lowest)

    // Supporting data
    let relatedMetrics: [String: Double]  // e.g., ["recovery": 45, "strain": 18]
    let recommendation: String?

    // Metadata
    let createdAt: Date
    var isRead: Bool

    enum InsightCategory: String, Codable {
        case recovery = "Recovery"
        case strain = "Strain"
        case sleep = "Sleep"
        case illness = "Health Alert"
        case adaptation = "Training Adaptation"
        case behavior = "Behavior Pattern"

        var systemIconName: String {
            switch self {
            case .recovery:
                return "heart.fill"
            case .strain:
                return "flame.fill"
            case .sleep:
                return "bed.double.fill"
            case .illness:
                return "exclamationmark.triangle.fill"
            case .adaptation:
                return "chart.line.uptrend.xyaxis"
            case .behavior:
                return "lightbulb.fill"
            }
        }

        var colorHex: String {
            switch self {
            case .recovery:
                return "#34C759"  // Green
            case .strain:
                return "#FF9500"  // Orange
            case .sleep:
                return "#5856D6"  // Purple
            case .illness:
                return "#FF3B30"  // Red
            case .adaptation:
                return "#007AFF"  // Blue
            case .behavior:
                return "#FFD60A"  // Yellow
            }
        }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        message: String,
        category: InsightCategory,
        priority: Int,
        relatedMetrics: [String: Double] = [:],
        recommendation: String? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.message = message
        self.category = category
        self.priority = priority
        self.relatedMetrics = relatedMetrics
        self.recommendation = recommendation
        self.createdAt = createdAt
        self.isRead = isRead
    }

    /// Is this a critical insight that needs immediate attention?
    var isCritical: Bool {
        return priority <= 2
    }

    /// Should this insight trigger a notification?
    var shouldNotify: Bool {
        return priority <= 2 && !isRead
    }
}
