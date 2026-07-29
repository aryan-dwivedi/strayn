//
//  StraynAgeCalculationEngine.swift
//  strayn
//
//  Calculates Strayn Age (biological age) using rolling 6-month averages
//  across Sleep, Activity, Cardiovascular, and Recovery pillars.
//

import Foundation

// MARK: - Strayn Age Calculation Engine

final class StraynAgeCalculationEngine {
    
    // MARK: - Shared Instance
    
    static let shared = StraynAgeCalculationEngine()
    
    // MARK: - Age Adjustment Constants
    
    /// These constants define how much each metric deviates from the norm affects biological age.
    /// Based on population-level research correlations (NOT causal medical claims).
    
    private struct AgeFactors {
        // Cardiovascular factors
        static let rhrPerYear: Double = 5.0           // 5 bpm above norm = +1 year
        static let vo2MaxPerYear: Double = 3.0        // 3 mL/kg/min below norm = +1 year
        static let cardiacEfficiencyPerYear: Double = 0.1
        
        // Autonomic/Recovery factors
        static let hrvPerYear: Double = 10.0          // 10ms below norm = +1 year
        static let recoveryScorePerYear: Double = 15.0 // 15 points below = +1 year
        
        // Sleep factors
        static let sleepEfficiencyPerYear: Double = 0.05  // 5% below 90% = +1 year
        static let sleepDurationPerYear: Double = 1800.0  // 30min below 7.5hr = +1 year
        static let sleepConsistencyPerYear: Double = 20.0 // 20 point drop = +1 year
        
        // Activity factors
        static let aerobicMinutesPerYear: Double = 50.0   // 50min below 150 = +1 year
        static let strengthMinutesPerYear: Double = 30.0  // 30min below 60 = +1 year
        static let stepsPerYear: Double = 2000.0          // 2000 steps below 8000 = +1 year
    }
    
    /// Age-specific baselines for normalization
    private struct AgeBaselines {
        /// Expected resting heart rate by age (increases ~0.1 bpm per year after 30)
        static func expectedRHR(forAge age: Int) -> Double {
            return 65.0 + (Double(max(0, age - 30)) * 0.1)
        }
        
        /// Expected HRV by age (decreases ~0.5 ms per year after 30)
        static func expectedHRV(forAge age: Int) -> Double {
            return 70.0 - (Double(max(0, age - 30)) * 0.5)
        }
        
        /// Expected VO2 Max by age (decreases ~0.3 mL/kg/min per year after 30)
        static func expectedVO2Max(forAge age: Int, isMale: Bool) -> Double {
            let baseline = isMale ? 45.0 : 40.0
            return baseline - (Double(max(0, age - 30)) * 0.3)
        }
        
        /// Expected sleep efficiency (generally stable, slight decrease after 50)
        static func expectedSleepEfficiency(forAge age: Int) -> Double {
            if age < 50 {
                return 0.90
            } else {
                return 0.90 - (Double(age - 50) * 0.002)
            }
        }
        
        /// Optimal sleep duration
        static let optimalSleepDuration: TimeInterval = 7.5 * 3600  // 7.5 hours
        
        /// Optimal weekly aerobic minutes
        static let optimalAerobicMinutes: Double = 150.0
        
        /// Optimal weekly strength minutes
        static let optimalStrengthMinutes: Double = 60.0
        
        /// Optimal daily steps
        static let optimalDailySteps: Double = 8000.0
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Main Calculation
    
    func calculateStraynAge(
        input: StraynAgeInputData,
        previousStraynAge: StraynAge?
    ) -> StraynAge {
        
        let chronologicalAge = Double(input.chronologicalAge)
        let isMale = input.biologicalSex == .male
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        
        // 1. Calculate Cardiovascular Age
        let cardiovascularAge = calculateCardiovascularAge(
            chronologicalAge: input.chronologicalAge,
            isMale: isMale,
            restingHR: input.restingHeartRateAverage,
            rhrTrend: input.restingHeartRateTrend,
            vo2Max: input.vo2Max,
            vo2MaxTrend: input.vo2MaxTrend,
            cardiacEfficiency: input.cardiacEfficiencyScore
        )
        
        // 2. Calculate Autonomic (Recovery) Age
        let autonomicAge = calculateAutonomicAge(
            chronologicalAge: input.chronologicalAge,
            hrv: input.hrvAverage,
            hrvTrend: input.hrvTrend,
            recoveryScore: input.averageRecoveryScore,
            recoveryConsistency: input.recoveryConsistency
        )
        
        // 3. Calculate Sleep Age
        let sleepAge = calculateSleepAge(
            chronologicalAge: input.chronologicalAge,
            sleepDuration: input.averageSleepDuration,
            sleepEfficiency: input.sleepEfficiencyAverage,
            sleepConsistency: input.sleepConsistencyScore,
            deepSleepPercentage: input.deepSleepPercentage,
            remSleepPercentage: input.remSleepPercentage
        )
        
        // 4. Calculate Metabolic Age (if VO2 Max available)
        let metabolicAge: StraynAge.AgeComponent?
        if let vo2 = input.vo2Max {
            metabolicAge = calculateMetabolicAge(
                chronologicalAge: input.chronologicalAge,
                isMale: isMale,
                vo2Max: vo2,
                weeklyAerobicMinutes: input.weeklyModerateAerobicMinutes,
                weeklyStrengthMinutes: input.weeklyStrengthTrainingMinutes,
                dailySteps: input.dailyStepAverage
            )
        } else {
            metabolicAge = nil
        }
        
        // 5. Determine weights
        let weights = metabolicAge != nil ?
            StraynAge.ComponentWeights.default :
            StraynAge.ComponentWeights.withoutMetabolic
        
        // 6. Calculate weighted Strayn Age
        var weightedAge = 0.0
        weightedAge += cardiovascularAge.estimatedAge * weights.cardiovascular
        weightedAge += autonomicAge.estimatedAge * weights.autonomic
        weightedAge += sleepAge.estimatedAge * weights.sleep
        if let metabolic = metabolicAge {
            weightedAge += metabolic.estimatedAge * weights.metabolic
        }
        
        let totalWeight = weights.cardiovascular + weights.autonomic + weights.sleep +
            (metabolicAge != nil ? weights.metabolic : 0)
        let finalAge = weightedAge / totalWeight
        
        // 7. Apply smoothing (limit change from previous calculation)
        let smoothedAge = applySmoothingIfNeeded(newAge: finalAge, previous: previousStraynAge)
        
        // 8. Calculate trends
        let weeklyTrend = calculateTrend(current: smoothedAge, previous: previousStraynAge?.age)
        
        // 9. Determine confidence
        let confidence = calculateConfidence(input: input)
        
        return StraynAge(
            age: smoothedAge,
            chronologicalAge: chronologicalAge,
            cardiovascularAge: cardiovascularAge,
            autonomicAge: autonomicAge,
            sleepAge: sleepAge,
            metabolicAge: metabolicAge,
            confidence: confidence,
            componentWeights: weights,
            weeklyTrend: weeklyTrend,
            monthlyTrend: nil,  // Would need more history
            calculationWindowStart: sixMonthsAgo,
            calculationWindowEnd: now
        )
    }
    
    // MARK: - Component Age Calculations
    
    private func calculateCardiovascularAge(
        chronologicalAge: Int,
        isMale: Bool,
        restingHR: Double?,
        rhrTrend: Baseline.TrendDirection?,
        vo2Max: Double?,
        vo2MaxTrend: Baseline.TrendDirection?,
        cardiacEfficiency: Double?
    ) -> StraynAge.AgeComponent {
        
        var ageDelta = 0.0
        var drivers: [StraynAge.AgeComponent.Driver] = []
        let chronoAge = Double(chronologicalAge)
        
        // Resting Heart Rate impact
        if let rhr = restingHR {
            let expectedRHR = AgeBaselines.expectedRHR(forAge: chronologicalAge)
            let rhrDelta = (rhr - expectedRHR) / AgeFactors.rhrPerYear
            ageDelta += rhrDelta
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if rhrDelta <= -1.0 {
                impact = .veryPositive
            } else if rhrDelta < 0 {
                impact = .positive
            } else if rhrDelta < 1.0 {
                impact = .neutral
            } else if rhrDelta < 2.0 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Resting Heart Rate",
                impact: impact,
                value: rhr,
                optimalRange: "\(Int(expectedRHR - 5))-\(Int(expectedRHR)) bpm",
                explanation: rhrDelta < 0 ?
                    "Your low resting HR indicates strong cardiovascular fitness" :
                    "Higher resting HR may indicate room for cardiovascular improvement"
            ))
        }
        
        // VO2 Max impact
        if let vo2 = vo2Max {
            let expectedVO2 = AgeBaselines.expectedVO2Max(forAge: chronologicalAge, isMale: isMale)
            let vo2Delta = (expectedVO2 - vo2) / AgeFactors.vo2MaxPerYear
            ageDelta += vo2Delta * 0.5  // VO2 gets partial weight in cardio
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if vo2Delta <= -1.0 {
                impact = .veryPositive
            } else if vo2Delta < 0 {
                impact = .positive
            } else if vo2Delta < 1.0 {
                impact = .neutral
            } else if vo2Delta < 2.0 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "VO₂ Max",
                impact: impact,
                value: vo2,
                optimalRange: ">\(Int(expectedVO2)) mL/kg/min",
                explanation: vo2Delta < 0 ?
                    "Excellent aerobic capacity for your age" :
                    "Aerobic capacity below age norm"
            ))
        }
        
        let estimatedAge = chronoAge + ageDelta
        
        return StraynAge.AgeComponent(
            name: "Cardiovascular",
            estimatedAge: estimatedAge,
            ageDelta: ageDelta,
            weight: 0.30,
            confidence: restingHR != nil ? .high : .low,
            primaryDrivers: drivers
        )
    }
    
    private func calculateAutonomicAge(
        chronologicalAge: Int,
        hrv: Double?,
        hrvTrend: Baseline.TrendDirection?,
        recoveryScore: Double?,
        recoveryConsistency: Double?
    ) -> StraynAge.AgeComponent {
        
        var ageDelta = 0.0
        var drivers: [StraynAge.AgeComponent.Driver] = []
        let chronoAge = Double(chronologicalAge)
        
        // HRV impact
        if let hrvValue = hrv {
            let expectedHRV = AgeBaselines.expectedHRV(forAge: chronologicalAge)
            let hrvDelta = (expectedHRV - hrvValue) / AgeFactors.hrvPerYear
            ageDelta += hrvDelta
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if hrvDelta <= -1.0 {
                impact = .veryPositive
            } else if hrvDelta < 0 {
                impact = .positive
            } else if hrvDelta < 1.0 {
                impact = .neutral
            } else if hrvDelta < 2.0 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Heart Rate Variability",
                impact: impact,
                value: hrvValue,
                optimalRange: ">\(Int(expectedHRV)) ms",
                explanation: hrvDelta < 0 ?
                    "Strong autonomic nervous system health" :
                    "HRV below expected range for your age"
            ))
        }
        
        // Recovery Score impact
        if let recovery = recoveryScore {
            let recoveryDelta = (70.0 - recovery) / AgeFactors.recoveryScorePerYear
            ageDelta += recoveryDelta * 0.5  // Partial weight
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if recovery >= 75 {
                impact = .positive
            } else if recovery >= 50 {
                impact = .neutral
            } else if recovery >= 33 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Recovery Score",
                impact: impact,
                value: recovery,
                optimalRange: ">67%",
                explanation: recovery >= 67 ?
                    "Consistently recovering well" :
                    "Recovery patterns showing room for improvement"
            ))
        }
        
        let estimatedAge = chronoAge + ageDelta
        
        return StraynAge.AgeComponent(
            name: "Autonomic",
            estimatedAge: estimatedAge,
            ageDelta: ageDelta,
            weight: 0.25,
            confidence: hrv != nil ? .high : .medium,
            primaryDrivers: drivers
        )
    }
    
    private func calculateSleepAge(
        chronologicalAge: Int,
        sleepDuration: TimeInterval?,
        sleepEfficiency: Double?,
        sleepConsistency: Double?,
        deepSleepPercentage: Double?,
        remSleepPercentage: Double?
    ) -> StraynAge.AgeComponent {
        
        var ageDelta = 0.0
        var drivers: [StraynAge.AgeComponent.Driver] = []
        let chronoAge = Double(chronologicalAge)
        
        // Sleep Duration impact
        if let duration = sleepDuration {
            let optimal = AgeBaselines.optimalSleepDuration
            let durationDelta = (optimal - duration) / AgeFactors.sleepDurationPerYear
            ageDelta += durationDelta
            
            let hours = duration / 3600.0
            let impact: StraynAge.AgeComponent.Driver.Impact
            if hours >= 7.5 {
                impact = .positive
            } else if hours >= 6.5 {
                impact = .neutral
            } else if hours >= 5.5 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Sleep Duration",
                impact: impact,
                value: hours,
                optimalRange: "7-9 hours",
                explanation: hours >= 7 ?
                    "Adequate sleep duration" :
                    "Sleep duration below optimal range"
            ))
        }
        
        // Sleep Efficiency impact
        if let efficiency = sleepEfficiency {
            let expectedEfficiency = AgeBaselines.expectedSleepEfficiency(forAge: chronologicalAge)
            let efficiencyDelta = (expectedEfficiency - efficiency) / AgeFactors.sleepEfficiencyPerYear
            ageDelta += efficiencyDelta
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if efficiency >= 0.90 {
                impact = .positive
            } else if efficiency >= 0.80 {
                impact = .neutral
            } else if efficiency >= 0.70 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Sleep Efficiency",
                impact: impact,
                value: efficiency * 100,
                optimalRange: ">85%",
                explanation: efficiency >= 0.85 ?
                    "High quality sleep time" :
                    "Time awake in bed reducing sleep quality"
            ))
        }
        
        // Sleep Consistency impact
        if let consistency = sleepConsistency {
            let consistencyDelta = (80.0 - consistency) / AgeFactors.sleepConsistencyPerYear
            ageDelta += consistencyDelta * 0.5
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if consistency >= 80 {
                impact = .positive
            } else if consistency >= 60 {
                impact = .neutral
            } else if consistency >= 40 {
                impact = .negative
            } else {
                impact = .veryNegative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Sleep Consistency",
                impact: impact,
                value: consistency,
                optimalRange: ">80%",
                explanation: consistency >= 70 ?
                    "Consistent sleep schedule supports circadian health" :
                    "Irregular sleep times may disrupt circadian rhythm"
            ))
        }
        
        let estimatedAge = chronoAge + ageDelta
        
        return StraynAge.AgeComponent(
            name: "Sleep",
            estimatedAge: estimatedAge,
            ageDelta: ageDelta,
            weight: 0.25,
            confidence: sleepDuration != nil ? .high : .low,
            primaryDrivers: drivers
        )
    }
    
    private func calculateMetabolicAge(
        chronologicalAge: Int,
        isMale: Bool,
        vo2Max: Double,
        weeklyAerobicMinutes: Double?,
        weeklyStrengthMinutes: Double?,
        dailySteps: Double?
    ) -> StraynAge.AgeComponent {
        
        var ageDelta = 0.0
        var drivers: [StraynAge.AgeComponent.Driver] = []
        let chronoAge = Double(chronologicalAge)
        
        // VO2 Max impact (primary metabolic marker)
        let expectedVO2 = AgeBaselines.expectedVO2Max(forAge: chronologicalAge, isMale: isMale)
        let vo2Delta = (expectedVO2 - vo2Max) / AgeFactors.vo2MaxPerYear
        ageDelta += vo2Delta
        
        let vo2Impact: StraynAge.AgeComponent.Driver.Impact
        if vo2Delta <= -1.0 {
            vo2Impact = .veryPositive
        } else if vo2Delta < 0 {
            vo2Impact = .positive
        } else if vo2Delta < 1.0 {
            vo2Impact = .neutral
        } else {
            vo2Impact = .negative
        }
        
        drivers.append(StraynAge.AgeComponent.Driver(
            metric: "VO₂ Max",
            impact: vo2Impact,
            value: vo2Max,
            optimalRange: ">\(Int(expectedVO2)) mL/kg/min",
            explanation: vo2Delta < 0 ?
                "Above-average aerobic capacity" :
                "Aerobic capacity has room for improvement"
        ))
        
        // Weekly Aerobic Minutes impact
        if let aerobic = weeklyAerobicMinutes {
            let aerobicDelta = (AgeBaselines.optimalAerobicMinutes - aerobic) / AgeFactors.aerobicMinutesPerYear
            ageDelta += aerobicDelta * 0.3
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if aerobic >= 150 {
                impact = .positive
            } else if aerobic >= 100 {
                impact = .neutral
            } else {
                impact = .negative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Weekly Aerobic Activity",
                impact: impact,
                value: aerobic,
                optimalRange: ">150 min/week",
                explanation: aerobic >= 150 ?
                    "Meeting recommended activity levels" :
                    "Below recommended 150 minutes/week"
            ))
        }
        
        // Daily Steps impact
        if let steps = dailySteps {
            let stepsDelta = (AgeBaselines.optimalDailySteps - steps) / AgeFactors.stepsPerYear
            ageDelta += stepsDelta * 0.2
            
            let impact: StraynAge.AgeComponent.Driver.Impact
            if steps >= 10000 {
                impact = .positive
            } else if steps >= 7000 {
                impact = .neutral
            } else {
                impact = .negative
            }
            
            drivers.append(StraynAge.AgeComponent.Driver(
                metric: "Daily Steps",
                impact: impact,
                value: steps,
                optimalRange: ">8,000 steps",
                explanation: steps >= 8000 ?
                    "Good daily movement" :
                    "More daily movement could help"
            ))
        }
        
        let estimatedAge = chronoAge + ageDelta
        
        return StraynAge.AgeComponent(
            name: "Metabolic",
            estimatedAge: estimatedAge,
            ageDelta: ageDelta,
            weight: 0.20,
            confidence: .high,
            primaryDrivers: drivers
        )
    }
    
    // MARK: - Helpers
    
    private func applySmoothingIfNeeded(newAge: Double, previous: StraynAge?) -> Double {
        guard let prevAge = previous?.age else { return newAge }
        
        // Limit weekly change to ±0.3 years to prevent jarring changes
        let maxWeeklyChange = 0.3
        let change = newAge - prevAge
        
        if abs(change) <= maxWeeklyChange {
            return newAge
        }
        
        return prevAge + (change > 0 ? maxWeeklyChange : -maxWeeklyChange)
    }
    
    private func calculateTrend(current: Double, previous: Double?) -> StraynAge.Trend? {
        guard let prev = previous else { return nil }
        
        let delta = current - prev
        if delta < -0.1 {
            return .improving
        } else if delta > 0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func calculateConfidence(input: StraynAgeInputData) -> StraynAge.ConfidenceLevel {
        let totalDays = input.totalDaysInWindow
        let dataPoints = input.daysWithSleepData + input.daysWithActivityData + input.daysWithHeartRateData
        let ratio = Double(dataPoints) / Double(totalDays * 3)  // 3 data types
        
        if ratio >= 0.7 {
            return .high
        } else if ratio >= 0.4 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Mock Data Support

extension StraynAgeCalculationEngine {
    
    static func createMockStraynAge(
        chronologicalAge: Int,
        ageDelta: Double
    ) -> StraynAge {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        let chronoAge = Double(chronologicalAge)
        
        return StraynAge(
            age: chronoAge + ageDelta,
            chronologicalAge: chronoAge,
            cardiovascularAge: StraynAge.AgeComponent(
                name: "Cardiovascular",
                estimatedAge: chronoAge + ageDelta - 0.5,
                ageDelta: ageDelta - 0.5,
                weight: 0.30,
                confidence: .high,
                primaryDrivers: [
                    StraynAge.AgeComponent.Driver(
                        metric: "Resting Heart Rate",
                        impact: .positive,
                        value: 58,
                        optimalRange: "55-65 bpm",
                        explanation: "Your low resting HR indicates strong cardiovascular fitness"
                    ),
                    StraynAge.AgeComponent.Driver(
                        metric: "VO₂ Max",
                        impact: .veryPositive,
                        value: 48,
                        optimalRange: ">42 mL/kg/min",
                        explanation: "Excellent aerobic capacity for your age"
                    )
                ]
            ),
            autonomicAge: StraynAge.AgeComponent(
                name: "Autonomic",
                estimatedAge: chronoAge + ageDelta + 0.2,
                ageDelta: ageDelta + 0.2,
                weight: 0.25,
                confidence: .high,
                primaryDrivers: [
                    StraynAge.AgeComponent.Driver(
                        metric: "Heart Rate Variability",
                        impact: .positive,
                        value: 65,
                        optimalRange: ">55 ms",
                        explanation: "Strong autonomic nervous system health"
                    )
                ]
            ),
            sleepAge: StraynAge.AgeComponent(
                name: "Sleep",
                estimatedAge: chronoAge + ageDelta - 0.8,
                ageDelta: ageDelta - 0.8,
                weight: 0.25,
                confidence: .high,
                primaryDrivers: [
                    StraynAge.AgeComponent.Driver(
                        metric: "Sleep Duration",
                        impact: .positive,
                        value: 7.5,
                        optimalRange: "7-9 hours",
                        explanation: "Adequate sleep duration"
                    ),
                    StraynAge.AgeComponent.Driver(
                        metric: "Sleep Consistency",
                        impact: .positive,
                        value: 85,
                        optimalRange: ">80%",
                        explanation: "Consistent sleep schedule supports circadian health"
                    )
                ]
            ),
            metabolicAge: StraynAge.AgeComponent(
                name: "Metabolic",
                estimatedAge: chronoAge + ageDelta + 0.3,
                ageDelta: ageDelta + 0.3,
                weight: 0.20,
                confidence: .high,
                primaryDrivers: [
                    StraynAge.AgeComponent.Driver(
                        metric: "Weekly Aerobic Activity",
                        impact: .positive,
                        value: 180,
                        optimalRange: ">150 min/week",
                        explanation: "Meeting recommended activity levels"
                    )
                ]
            ),
            confidence: .high,
            componentWeights: .default,
            weeklyTrend: .improving,
            monthlyTrend: .stable,
            calculationWindowStart: sixMonthsAgo,
            calculationWindowEnd: now
        )
    }
}
