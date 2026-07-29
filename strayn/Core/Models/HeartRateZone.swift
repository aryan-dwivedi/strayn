//
//  HeartRateZone.swift
//  strayn
//
//  Represents a heart rate training zone
//

import Foundation

struct HeartRateZone: Identifiable, Codable, Equatable {
    let id: UUID
    let zone: Int  // 1-5
    let lowerBound: Int  // bpm
    let upperBound: Int  // bpm
    let description: String  // e.g., "Light Activity"
    let colorHex: String  // Hex color for UI

    init(
        id: UUID = UUID(),
        zone: Int,
        lowerBound: Int,
        upperBound: Int,
        description: String,
        colorHex: String
    ) {
        self.id = id
        self.zone = zone
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.description = description
        self.colorHex = colorHex
    }

    /// Calculate 5 heart rate zones based on max HR
    static func calculateZones(maxHR: Int) -> [HeartRateZone] {
        return [
            HeartRateZone(
                zone: 1,
                lowerBound: 0,
                upperBound: Int(Double(maxHR) * 0.60),
                description: "Very Light",
                colorHex: "#A8E6CF"  // Soft green
            ),
            HeartRateZone(
                zone: 2,
                lowerBound: Int(Double(maxHR) * 0.60),
                upperBound: Int(Double(maxHR) * 0.70),
                description: "Light",
                colorHex: "#FFD3B6"  // Soft orange
            ),
            HeartRateZone(
                zone: 3,
                lowerBound: Int(Double(maxHR) * 0.70),
                upperBound: Int(Double(maxHR) * 0.80),
                description: "Moderate",
                colorHex: "#FFAAA5"  // Light coral
            ),
            HeartRateZone(
                zone: 4,
                lowerBound: Int(Double(maxHR) * 0.80),
                upperBound: Int(Double(maxHR) * 0.90),
                description: "Hard",
                colorHex: "#FF8B94"  // Medium coral
            ),
            HeartRateZone(
                zone: 5,
                lowerBound: Int(Double(maxHR) * 0.90),
                upperBound: maxHR,
                description: "Maximum",
                colorHex: "#FF6F69"  // Red
            )
        ]
    }

    /// Get the zone number for a given heart rate
    static func zone(for heartRate: Int, maxHR: Int) -> Int {
        let zones = calculateZones(maxHR: maxHR)
        for zone in zones {
            if heartRate >= zone.lowerBound && heartRate <= zone.upperBound {
                return zone.zone
            }
        }
        // Default to zone 1 if below all zones, zone 5 if above
        return heartRate < zones[0].lowerBound ? 1 : 5
    }

    /// Zone intensity weight for strain calculation
    var strainWeight: Double {
        switch zone {
        case 1: return 0.5
        case 2: return 1.0
        case 3: return 2.5
        case 4: return 5.0
        case 5: return 10.0
        default: return 0.0
        }
    }

    /// Detailed explanation of this zone
    var detailedDescription: String {
        switch zone {
        case 1:
            return "Very light activity. Minimal cardiovascular strain. Good for recovery days."
        case 2:
            return "Light activity. Comfortable pace. Ideal for aerobic base building and active recovery."
        case 3:
            return "Moderate intensity. Sustainable for longer periods. Improves aerobic fitness."
        case 4:
            return "Hard effort. Challenging but maintainable. Increases lactate threshold and VO₂ max."
        case 5:
            return "Maximum effort. Very challenging. Reserved for intervals and peak performance."
        default:
            return ""
        }
    }
}
