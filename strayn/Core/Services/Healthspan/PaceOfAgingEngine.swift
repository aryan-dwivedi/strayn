//
//  PaceOfAgingEngine.swift
//  strayn
//
//  Calculates Pace of Aging by comparing recent 30-day metrics
//  against 6-month baselines. Acts as an early warning system.
//

import Foundation

// MARK: - Pace of Aging Engine

final class PaceOfAgingEngine {
    
    // MARK: - Shared Instance
    
    static let shared = PaceOfAgingEngine()
    
    // MARK: - Configuration
    
    private struct PaceConfig {
        /// Weights for each pillar in overall pace calculation
        static let sleepWeight: Double = 0.30
        static let activityWeight: Double = 0.25
        static let cardiovascularWeight: Double = 0.25
        static let recoveryWeight: Double = 0.20
        
        /// Thresholds for pace zone classification
        static let optimalThreshold: Double = 0.5
        static let slowThreshold: Double = 0.8
        static let steadyThreshold: Double = 1.2
        static let elevatedThreshold: Double = 1.5
        
        /// Sensitivity factors (how much % change affects pace)
        static let sleepDurationSensitivity: Double = 0.15   // 15% change = significant
        static let sleepConsistencySensitivity: Double = 0.20
        static let activityMinutesSensitivity: Double = 0.25
        static let stepsSensitivity: Double = 0.20
        static let rhrSensitivity: Double = 0.10             // 10% change = significant
        static let hrvSensitivity: Double = 0.15
        static let vo2Sensitivity: Double = 0.08
        static let recoverySensitivity: Double = 0.15
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Main Calculation
    
    func calculatePaceOfAging(input: PaceOfAgingInputData) -> PaceOfAging {
        
        // 1. Calculate per-pillar paces
        let sleepPace = calculateSleepPillarPace(input: input)
        let activityPace = calculateActivityPillarPace(input: input)
        let cardiovascularPace = calculateCardiovascularPillarPace(input: input)
        let recoveryPace = calculateRecoveryPillarPace(input: input)
        
        // 2. Calculate weighted overall pace
        var totalWeight = 0.0
        var weightedPace = 0.0
        
        if sleepPace.recentAverage != nil {
            weightedPace += sleepPace.pace * PaceConfig.sleepWeight
            totalWeight += PaceConfig.sleepWeight
        }
        if activityPace.recentAverage != nil {
            weightedPace += activityPace.pace * PaceConfig.activityWeight
            totalWeight += PaceConfig.activityWeight
        }
        if cardiovascularPace.recentAverage != nil {
            weightedPace += cardiovascularPace.pace * PaceConfig.cardiovascularWeight
            totalWeight += PaceConfig.cardiovascularWeight
        }
        if recoveryPace.recentAverage != nil {
            weightedPace += recoveryPace.pace * PaceConfig.recoveryWeight
            totalWeight += PaceConfig.recoveryWeight
        }
        
        let overallPace = totalWeight > 0 ? weightedPace / totalWeight : 1.0
        
        // 3. Identify primary drivers
        let drivers = identifyPrimaryDrivers(
            input: input,
            sleepPace: sleepPace,
            activityPace: activityPace,
            cardiovascularPace: cardiovascularPace,
            recoveryPace: recoveryPace
        )
        
        // 4. Calculate trend
        let (trend, trendDelta) = calculateTrend(
            currentPace: overallPace,
            previousPace: input.previousPace
        )
        
        // 5. Determine confidence
        let confidence = calculateConfidence(input: input)
        
        return PaceOfAging(
            pace: overallPace,
            sleepPace: sleepPace,
            activityPace: activityPace,
            cardiovascularPace: cardiovascularPace,
            recoveryPace: recoveryPace,
            primaryDrivers: drivers,
            trend: trend,
            trendDelta: trendDelta,
            recentWindowDays: 30,
            baselineWindowMonths: 6,
            calculationDate: Date(),
            confidence: confidence
        )
    }
    
    // MARK: - Pillar Pace Calculations
    
    private func calculateSleepPillarPace(input: PaceOfAgingInputData) -> PaceOfAging.PillarPace {
        var paceFactors: [Double] = []
        var changeSum = 0.0
        
        // Sleep Duration pace
        if let recent = input.recentSleepDuration,
           let baseline = input.baselineSleepDuration {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            // Negative change (less sleep) = accelerated aging
            let durationPace = 1.0 - (change / PaceConfig.sleepDurationSensitivity)
            paceFactors.append(max(0.1, min(3.0, durationPace)))
        }
        
        // Sleep Consistency pace
        if let recent = input.recentSleepConsistency,
           let baseline = input.baselineSleepConsistency {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            let consistencyPace = 1.0 - (change / PaceConfig.sleepConsistencySensitivity)
            paceFactors.append(max(0.1, min(3.0, consistencyPace)))
        }
        
        let avgPace = paceFactors.isEmpty ? 1.0 :
            paceFactors.reduce(0, +) / Double(paceFactors.count)
        
        let impact = determineImpact(pace: avgPace)
        
        return PaceOfAging.PillarPace(
            pillar: .sleep,
            pace: avgPace,
            zone: PaceOfAging.PaceZone.zone(for: avgPace),
            recentAverage: input.recentSleepDuration.map { $0 / 3600 },  // Convert to hours
            baselineAverage: input.baselineSleepDuration.map { $0 / 3600 },
            changeFromBaseline: changeSum / Double(max(1, paceFactors.count)),
            impact: impact
        )
    }
    
    private func calculateActivityPillarPace(input: PaceOfAgingInputData) -> PaceOfAging.PillarPace {
        var paceFactors: [Double] = []
        var changeSum = 0.0
        
        // Weekly Activity pace
        if let recent = input.recentWeeklyActivityMinutes,
           let baseline = input.baselineWeeklyActivityMinutes,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            // Less activity = accelerated aging
            let activityPace = 1.0 - (change / PaceConfig.activityMinutesSensitivity)
            paceFactors.append(max(0.1, min(3.0, activityPace)))
        }
        
        // Daily Steps pace
        if let recent = input.recentDailySteps,
           let baseline = input.baselineDailySteps,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            let stepsPace = 1.0 - (change / PaceConfig.stepsSensitivity)
            paceFactors.append(max(0.1, min(3.0, stepsPace)))
        }
        
        let avgPace = paceFactors.isEmpty ? 1.0 :
            paceFactors.reduce(0, +) / Double(paceFactors.count)
        
        let impact = determineImpact(pace: avgPace)
        
        return PaceOfAging.PillarPace(
            pillar: .activity,
            pace: avgPace,
            zone: PaceOfAging.PaceZone.zone(for: avgPace),
            recentAverage: input.recentWeeklyActivityMinutes,
            baselineAverage: input.baselineWeeklyActivityMinutes,
            changeFromBaseline: changeSum / Double(max(1, paceFactors.count)),
            impact: impact
        )
    }
    
    private func calculateCardiovascularPillarPace(input: PaceOfAgingInputData) -> PaceOfAging.PillarPace {
        var paceFactors: [Double] = []
        var changeSum = 0.0
        
        // Resting HR pace (lower is better, so increase = bad)
        if let recent = input.recentRestingHR,
           let baseline = input.baselineRestingHR,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum -= change  // Inverted: increase in RHR is negative
            
            // Higher RHR = accelerated aging
            let rhrPace = 1.0 + (change / PaceConfig.rhrSensitivity)
            paceFactors.append(max(0.1, min(3.0, rhrPace)))
        }
        
        // VO2 Max pace (higher is better)
        if let recent = input.recentVO2Max,
           let baseline = input.baselineVO2Max,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            // Lower VO2 = accelerated aging
            let vo2Pace = 1.0 - (change / PaceConfig.vo2Sensitivity)
            paceFactors.append(max(0.1, min(3.0, vo2Pace)))
        }
        
        let avgPace = paceFactors.isEmpty ? 1.0 :
            paceFactors.reduce(0, +) / Double(paceFactors.count)
        
        let impact = determineImpact(pace: avgPace)
        
        return PaceOfAging.PillarPace(
            pillar: .cardiovascular,
            pace: avgPace,
            zone: PaceOfAging.PaceZone.zone(for: avgPace),
            recentAverage: input.recentRestingHR,
            baselineAverage: input.baselineRestingHR,
            changeFromBaseline: changeSum / Double(max(1, paceFactors.count)),
            impact: impact
        )
    }
    
    private func calculateRecoveryPillarPace(input: PaceOfAgingInputData) -> PaceOfAging.PillarPace {
        var paceFactors: [Double] = []
        var changeSum = 0.0
        
        // HRV pace (higher is better)
        if let recent = input.recentHRV,
           let baseline = input.baselineHRV,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            // Lower HRV = accelerated aging
            let hrvPace = 1.0 - (change / PaceConfig.hrvSensitivity)
            paceFactors.append(max(0.1, min(3.0, hrvPace)))
        }
        
        // Recovery Score pace
        if let recent = input.recentRecoveryScore,
           let baseline = input.baselineRecoveryScore,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            changeSum += change
            
            let recoveryPace = 1.0 - (change / PaceConfig.recoverySensitivity)
            paceFactors.append(max(0.1, min(3.0, recoveryPace)))
        }
        
        let avgPace = paceFactors.isEmpty ? 1.0 :
            paceFactors.reduce(0, +) / Double(paceFactors.count)
        
        let impact = determineImpact(pace: avgPace)
        
        return PaceOfAging.PillarPace(
            pillar: .recovery,
            pace: avgPace,
            zone: PaceOfAging.PaceZone.zone(for: avgPace),
            recentAverage: input.recentHRV,
            baselineAverage: input.baselineHRV,
            changeFromBaseline: changeSum / Double(max(1, paceFactors.count)),
            impact: impact
        )
    }
    
    // MARK: - Driver Identification
    
    private func identifyPrimaryDrivers(
        input: PaceOfAgingInputData,
        sleepPace: PaceOfAging.PillarPace,
        activityPace: PaceOfAging.PillarPace,
        cardiovascularPace: PaceOfAging.PillarPace,
        recoveryPace: PaceOfAging.PillarPace
    ) -> [PaceOfAging.PaceDriver] {
        
        var drivers: [PaceOfAging.PaceDriver] = []
        
        // Sleep drivers
        if let recent = input.recentSleepDuration,
           let baseline = input.baselineSleepDuration {
            let change = (recent - baseline) / baseline
            if abs(change) > 0.05 {  // More than 5% change
                let direction: PaceOfAging.PaceDriver.Direction = change > 0 ? .slowing : .accelerating
                let magnitude: PaceOfAging.PaceDriver.Magnitude = abs(change) > 0.15 ? .major : abs(change) > 0.08 ? .moderate : .minor
                
                drivers.append(PaceOfAging.PaceDriver(
                    metric: "Sleep Duration",
                    pillar: .sleep,
                    direction: direction,
                    magnitude: magnitude,
                    explanation: direction == .slowing ?
                        "Increased sleep duration is supporting recovery and slowing aging" :
                        "Reduced sleep is accelerating your pace of aging",
                    actionableInsight: direction == .accelerating ?
                        "Try adding 30 minutes to your sleep window this week" : nil
                ))
            }
        }
        
        if let recent = input.recentSleepConsistency,
           let baseline = input.baselineSleepConsistency {
            let change = (recent - baseline) / baseline
            if abs(change) > 0.10 {
                let direction: PaceOfAging.PaceDriver.Direction = change > 0 ? .slowing : .accelerating
                let magnitude: PaceOfAging.PaceDriver.Magnitude = abs(change) > 0.20 ? .major : .moderate
                
                drivers.append(PaceOfAging.PaceDriver(
                    metric: "Sleep Consistency",
                    pillar: .sleep,
                    direction: direction,
                    magnitude: magnitude,
                    explanation: direction == .slowing ?
                        "More consistent sleep times are benefiting your circadian health" :
                        "Irregular sleep schedule is increasing your pace of aging",
                    actionableInsight: direction == .accelerating ?
                        "Set consistent bed and wake times, even on weekends" : nil
                ))
            }
        }
        
        // Activity drivers
        if let recent = input.recentWeeklyActivityMinutes,
           let baseline = input.baselineWeeklyActivityMinutes,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            if abs(change) > 0.15 {
                let direction: PaceOfAging.PaceDriver.Direction = change > 0 ? .slowing : .accelerating
                let magnitude: PaceOfAging.PaceDriver.Magnitude = abs(change) > 0.30 ? .major : .moderate
                
                drivers.append(PaceOfAging.PaceDriver(
                    metric: "Weekly Activity",
                    pillar: .activity,
                    direction: direction,
                    magnitude: magnitude,
                    explanation: direction == .slowing ?
                        "Increased activity is improving cardiovascular and metabolic health" :
                        "Reduced activity may be accelerating aging",
                    actionableInsight: direction == .accelerating ?
                        "Aim for 150+ minutes of moderate activity this week" : nil
                ))
            }
        }
        
        // Cardiovascular drivers
        if let recent = input.recentRestingHR,
           let baseline = input.baselineRestingHR {
            let change = (recent - baseline) / baseline
            if abs(change) > 0.05 {
                // Note: For RHR, increase is bad
                let direction: PaceOfAging.PaceDriver.Direction = change < 0 ? .slowing : .accelerating
                let magnitude: PaceOfAging.PaceDriver.Magnitude = abs(change) > 0.12 ? .major : .moderate
                
                drivers.append(PaceOfAging.PaceDriver(
                    metric: "Resting Heart Rate",
                    pillar: .cardiovascular,
                    direction: direction,
                    magnitude: magnitude,
                    explanation: direction == .slowing ?
                        "Lower resting HR indicates improved cardiovascular efficiency" :
                        "Elevated resting HR may signal stress or reduced fitness",
                    actionableInsight: direction == .accelerating ?
                        "Focus on recovery and consider adding easy cardio sessions" : nil
                ))
            }
        }
        
        // HRV drivers
        if let recent = input.recentHRV,
           let baseline = input.baselineHRV,
           baseline > 0 {
            let change = (recent - baseline) / baseline
            if abs(change) > 0.08 {
                let direction: PaceOfAging.PaceDriver.Direction = change > 0 ? .slowing : .accelerating
                let magnitude: PaceOfAging.PaceDriver.Magnitude = abs(change) > 0.15 ? .major : .moderate
                
                drivers.append(PaceOfAging.PaceDriver(
                    metric: "Heart Rate Variability",
                    pillar: .recovery,
                    direction: direction,
                    magnitude: magnitude,
                    explanation: direction == .slowing ?
                        "Improved HRV indicates better autonomic balance and recovery" :
                        "Lower HRV suggests your body is under more stress",
                    actionableInsight: direction == .accelerating ?
                        "Prioritize sleep quality and consider stress-reduction practices" : nil
                ))
            }
        }
        
        // Sort by magnitude and return top drivers
        let sortedDrivers = drivers.sorted { d1, d2 in
            let order: [PaceOfAging.PaceDriver.Magnitude: Int] = [.major: 0, .moderate: 1, .minor: 2]
            return (order[d1.magnitude] ?? 3) < (order[d2.magnitude] ?? 3)
        }
        
        return Array(sortedDrivers.prefix(5))
    }
    
    // MARK: - Helpers
    
    private func determineImpact(pace: Double) -> PaceOfAging.PillarPace.Impact {
        switch pace {
        case ..<0.6: return .stronglyPositive
        case 0.6..<0.9: return .positive
        case 0.9..<1.1: return .neutral
        case 1.1..<1.4: return .negative
        default: return .stronglyNegative
        }
    }
    
    private func calculateTrend(
        currentPace: Double,
        previousPace: Double?
    ) -> (PaceOfAging.Trend, Double) {
        guard let previous = previousPace else {
            return (.stable, 0)
        }
        
        let delta = currentPace - previous
        
        if delta < -0.1 {
            return (.improving, delta)
        } else if delta > 0.1 {
            return (.worsening, delta)
        } else {
            return (.stable, delta)
        }
    }
    
    private func calculateConfidence(input: PaceOfAgingInputData) -> StraynAge.ConfidenceLevel {
        let recentCoverage = Double(input.recentDaysWithData) / 30.0
        let baselineCoverage = Double(input.baselineDaysWithData) / 150.0
        let avgCoverage = (recentCoverage + baselineCoverage) / 2.0
        
        if avgCoverage >= 0.7 {
            return .high
        } else if avgCoverage >= 0.4 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Mock Data Support

extension PaceOfAgingEngine {
    
    static func createMockPaceOfAging(pace: Double) -> PaceOfAging {
        return PaceOfAging(
            pace: pace,
            sleepPace: PaceOfAging.PillarPace(
                pillar: .sleep,
                pace: pace - 0.1,
                zone: PaceOfAging.PaceZone.zone(for: pace - 0.1),
                recentAverage: 7.5,
                baselineAverage: 7.2,
                changeFromBaseline: 0.04,
                impact: .positive
            ),
            activityPace: PaceOfAging.PillarPace(
                pillar: .activity,
                pace: pace + 0.1,
                zone: PaceOfAging.PaceZone.zone(for: pace + 0.1),
                recentAverage: 175,
                baselineAverage: 160,
                changeFromBaseline: 0.09,
                impact: .positive
            ),
            cardiovascularPace: PaceOfAging.PillarPace(
                pillar: .cardiovascular,
                pace: pace,
                zone: PaceOfAging.PaceZone.zone(for: pace),
                recentAverage: 58,
                baselineAverage: 60,
                changeFromBaseline: -0.03,
                impact: .positive
            ),
            recoveryPace: PaceOfAging.PillarPace(
                pillar: .recovery,
                pace: pace + 0.05,
                zone: PaceOfAging.PaceZone.zone(for: pace + 0.05),
                recentAverage: 62,
                baselineAverage: 58,
                changeFromBaseline: 0.07,
                impact: .positive
            ),
            primaryDrivers: [
                PaceOfAging.PaceDriver(
                    metric: "Sleep Duration",
                    pillar: .sleep,
                    direction: .slowing,
                    magnitude: .moderate,
                    explanation: "Increased sleep duration is supporting recovery and slowing aging",
                    actionableInsight: nil
                ),
                PaceOfAging.PaceDriver(
                    metric: "Weekly Activity",
                    pillar: .activity,
                    direction: .slowing,
                    magnitude: .moderate,
                    explanation: "Increased activity is improving cardiovascular and metabolic health",
                    actionableInsight: nil
                ),
                PaceOfAging.PaceDriver(
                    metric: "Resting Heart Rate",
                    pillar: .cardiovascular,
                    direction: .slowing,
                    magnitude: .minor,
                    explanation: "Lower resting HR indicates improved cardiovascular efficiency",
                    actionableInsight: nil
                )
            ],
            trend: .improving,
            trendDelta: -0.05,
            confidence: .high
        )
    }
}
