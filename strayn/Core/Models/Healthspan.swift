//
//  Healthspan.swift
//  strayn
//
//  Core model representing long-term health intelligence combining
//  Sleep, Activity, Cardiovascular Fitness, and Recovery trends.
//

import Foundation

// MARK: - Healthspan State

/// Represents the current state of the Healthspan feature
enum HealthspanState: Codable, Equatable {
    case locked(reason: LockReason)
    case calibrating(phase: CalibrationPhase)
    case active
    case insufficientRecentData
    case userHidden
    
    enum LockReason: String, Codable {
        case insufficientData = "Need more recovery days"
        case newUser = "Building your baseline"
        case dataTooOld = "Resume tracking to unlock"
    }
    
    enum CalibrationPhase: Codable, Equatable {
        case partial(daysCompleted: Int, daysRequired: Int)  // First 30 days
        case full(daysCompleted: Int, daysRequired: Int)     // 30-90 days
        
        var progress: Double {
            switch self {
            case .partial(let completed, let required):
                return Double(completed) / Double(required)
            case .full(let completed, let required):
                return Double(completed) / Double(required)
            }
        }
        
        var displayText: String {
            switch self {
            case .partial(let completed, _):
                return "Initial Calibration • Day \(completed) of 30"
            case .full(let completed, _):
                return "Calibrating • Day \(completed) of 90"
            }
        }
    }
}

// MARK: - Healthspan

/// Main Healthspan model containing Strayn Age and Pace of Aging
struct Healthspan: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    
    // Core outputs
    let straynAge: StraynAge
    let paceOfAging: PaceOfAging
    
    // State
    let state: HealthspanState
    let calibrationProgress: Double  // 0-1
    
    // Data window
    let windowStart: Date           // Start of analysis window (6 months back)
    let windowEnd: Date             // End of analysis window
    let validDaysInWindow: Int      // Days with sufficient data
    
    // Update tracking
    let lastUpdated: Date
    let nextUpdateDate: Date        // Weekly updates
    
    // Data quality
    let dataQuality: DataQuality
    let dataCompleteness: Double    // 0-1
    
    // Metadata
    let version: Int                // For future algorithm updates
    let calculatedAt: Date
    
    struct DataQuality: Codable {
        let sleepDataQuality: Double      // 0-1
        let activityDataQuality: Double   // 0-1
        let heartRateDataQuality: Double  // 0-1
        let overallQuality: QualityLevel
        
        enum QualityLevel: String, Codable {
            case excellent = "Excellent"
            case good = "Good"
            case fair = "Fair"
            case poor = "Poor"
            
            var description: String {
                switch self {
                case .excellent: return "All metrics well-tracked"
                case .good: return "Most metrics available"
                case .fair: return "Some data gaps"
                case .poor: return "Limited data available"
                }
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        straynAge: StraynAge,
        paceOfAging: PaceOfAging,
        state: HealthspanState,
        calibrationProgress: Double,
        windowStart: Date,
        windowEnd: Date,
        validDaysInWindow: Int,
        lastUpdated: Date = Date(),
        nextUpdateDate: Date,
        dataQuality: DataQuality,
        dataCompleteness: Double,
        version: Int = 1,
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.straynAge = straynAge
        self.paceOfAging = paceOfAging
        self.state = state
        self.calibrationProgress = calibrationProgress
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.validDaysInWindow = validDaysInWindow
        self.lastUpdated = lastUpdated
        self.nextUpdateDate = nextUpdateDate
        self.dataQuality = dataQuality
        self.dataCompleteness = dataCompleteness
        self.version = version
        self.calculatedAt = calculatedAt
    }
    
    /// Days until next weekly update
    var daysUntilUpdate: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextUpdateDate).day ?? 0
    }
    
    /// Whether the feature is ready to display
    var isViewable: Bool {
        switch state {
        case .active, .calibrating:
            return true
        case .locked, .insufficientRecentData, .userHidden:
            return false
        }
    }
    
    /// Summary text for the current state
    var stateSummary: String {
        switch state {
        case .locked(let reason):
            return reason.rawValue
        case .calibrating(let phase):
            return phase.displayText
        case .active:
            return "Updated weekly"
        case .insufficientRecentData:
            return "Resume tracking to update"
        case .userHidden:
            return "Hidden by user"
        }
    }
}

// MARK: - Healthspan Unlock Requirements

struct HealthspanUnlockRequirements {
    /// Minimum valid recovery days needed in the last 31 days to unlock
    static let minimumValidDaysToUnlock = 21
    
    /// Window size for checking unlock eligibility
    static let unlockWindowDays = 31
    
    /// Days required for partial calibration
    static let partialCalibrationDays = 30
    
    /// Days required for full calibration
    static let fullCalibrationDays = 90
    
    /// Minimum valid days per month for updates
    static let minimumValidDaysPerMonth = 21
    
    /// Update frequency
    static let updateFrequencyDays = 7
    
    /// Rolling window for Strayn Age calculation (months)
    static let straynAgeWindowMonths = 6
    
    /// Rolling window for Pace of Aging calculation (days)
    static let paceOfAgingWindowDays = 30
}

// MARK: - Healthspan History

/// Historical record for trend analysis
struct HealthspanHistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let straynAge: Double
    let paceOfAging: Double
    let chronologicalAge: Double
    let ageDelta: Double  // straynAge - chronologicalAge
    
    init(
        id: UUID = UUID(),
        date: Date,
        straynAge: Double,
        paceOfAging: Double,
        chronologicalAge: Double
    ) {
        self.id = id
        self.date = date
        self.straynAge = straynAge
        self.paceOfAging = paceOfAging
        self.chronologicalAge = chronologicalAge
        self.ageDelta = straynAge - chronologicalAge
    }
}
