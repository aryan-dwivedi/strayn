//
//  OnboardingProfileService.swift
//  strayn
//
//  Service for managing user's physiological profile and baseline from onboarding data.
//

import Foundation
import Combine

class OnboardingProfileService: ObservableObject {
    
    static let shared = OnboardingProfileService()
    
    // MARK: - Published State
    
    @Published var physiologicalBaseline: PhysiologicalBaseline?
    @Published var onboardingData: OnboardingData?
    @Published var isCalibrating: Bool = false
    @Published var calibrationDaysRemaining: Int = 30
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Keys
    private let baselineKey = "physiologicalBaseline"
    private let onboardingDataKey = "onboardingData"
    
    // MARK: - Initialization
    
    private init() {
        loadSavedData()
        setupCalibrationTracking()
    }
    
    // MARK: - Data Loading
    
    private func loadSavedData() {
        // Load baseline
        if let data = userDefaults.data(forKey: baselineKey),
           let baseline = try? JSONDecoder().decode(PhysiologicalBaseline.self, from: data) {
            physiologicalBaseline = baseline
        }
        
        // Load onboarding data
        if let data = userDefaults.data(forKey: onboardingDataKey),
           let onboarding = try? JSONDecoder().decode(OnboardingData.self, from: data) {
            onboardingData = onboarding
        }
    }
    
    private func setupCalibrationTracking() {
        guard let baseline = physiologicalBaseline else { return }
        
        let now = Date()
        let endDate = baseline.expectedCalibrationEndDate
        
        if now < endDate {
            isCalibrating = true
            calibrationDaysRemaining = Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
        } else {
            isCalibrating = false
            calibrationDaysRemaining = 0
        }
    }
    
    // MARK: - Baseline Access
    
    var fitzpatrickType: FitzpatrickSkinType? {
        physiologicalBaseline?.fitzpatrickType
    }
    
    var uvSensitivity: UVSensitivity? {
        physiologicalBaseline?.uvSensitivity
    }
    
    var estimatedBMR: Double? {
        physiologicalBaseline?.estimatedBMR
    }
    
    var estimatedTDEE: Double? {
        physiologicalBaseline?.estimatedTDEE
    }
    
    var targetCalories: Double? {
        physiologicalBaseline?.targetCalories
    }
    
    var primaryGoals: [PrimaryGoal] {
        physiologicalBaseline?.primaryGoals ?? []
    }
    
    var goalWeights: [String: Double] {
        physiologicalBaseline?.goalWeights ?? [:]
    }
    
    var bodyComposition: BodyCompositionEstimate? {
        physiologicalBaseline?.bodyComposition
    }
    
    var hairDensityScore: Double? {
        physiologicalBaseline?.hairDensityScore
    }
    
    // MARK: - Profile Access
    
    var userAge: Int? {
        onboardingData?.coreProfile?.age
    }
    
    var userBiologicalSex: BiologicalSexOption? {
        onboardingData?.coreProfile?.biologicalSex
    }
    
    var userHeightCm: Double? {
        onboardingData?.coreProfile?.heightCm
    }
    
    var userWeightKg: Double? {
        onboardingData?.coreProfile?.weightKg
    }
    
    var userBMI: Double? {
        onboardingData?.coreProfile?.bmi
    }
    
    var lifestyle: LifestyleProfile? {
        onboardingData?.lifestyle
    }
    
    var nutrition: NutritionProfile? {
        onboardingData?.nutrition
    }
    
    // MARK: - Insight Weight Calculations
    
    /// Get the weight multiplier for a specific insight category
    func weightForCategory(_ category: String) -> Double {
        goalWeights[category] ?? 1.0
    }
    
    /// Check if user has a specific primary goal
    func hasGoal(_ goal: PrimaryGoal) -> Bool {
        primaryGoals.contains(goal)
    }
    
    /// Get prioritized insight categories based on user's goals
    var prioritizedInsightCategories: [String] {
        goalWeights
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    // MARK: - Calorie Calculations
    
    /// Calculate adjusted calories based on activity and goals
    func adjustedCalories(forActivity activityMultiplier: Double, goal: NutritionGoal? = nil) -> Double? {
        guard let bmr = estimatedBMR else { return nil }
        
        let tdee = bmr * activityMultiplier
        let goalAdjustment = goal?.calorieAdjustment ?? nutrition?.nutritionGoal.calorieAdjustment ?? 0
        
        return tdee + goalAdjustment
    }
    
    /// Calculate macro targets based on goal
    func macroTargets() -> MacroTargets? {
        guard let calories = targetCalories,
              let goal = nutrition?.nutritionGoal else { return nil }
        
        // Standard macro ratios by goal
        let ratios: (protein: Double, carbs: Double, fat: Double)
        
        switch goal {
        case .fatLoss:
            ratios = (0.35, 0.35, 0.30) // Higher protein for satiety
        case .muscleGain:
            ratios = (0.30, 0.45, 0.25) // Higher carbs for energy
        case .longevity:
            ratios = (0.25, 0.45, 0.30) // Balanced with healthy fats
        case .maintenance:
            ratios = (0.25, 0.50, 0.25) // Standard balanced
        }
        
        return MacroTargets(
            proteinGrams: (calories * ratios.protein) / 4,
            carbsGrams: (calories * ratios.carbs) / 4,
            fatGrams: (calories * ratios.fat) / 9
        )
    }
    
    // MARK: - UV/Sun Recommendations
    
    /// Get recommended sun exposure based on skin type
    var recommendedSunExposure: SunExposureRecommendation? {
        guard let skinType = fitzpatrickType else { return nil }
        
        switch skinType {
        case .typeI, .typeII:
            return SunExposureRecommendation(
                maxMinutesWithoutProtection: 10,
                spfRecommendation: "50+",
                peakHoursWarning: "Avoid 10am-4pm sun exposure",
                vitaminDNote: "Consider supplementation"
            )
        case .typeIII, .typeIV:
            return SunExposureRecommendation(
                maxMinutesWithoutProtection: 25,
                spfRecommendation: "30-50",
                peakHoursWarning: "Limit exposure 11am-3pm",
                vitaminDNote: "Moderate sun for vitamin D"
            )
        case .typeV, .typeVI:
            return SunExposureRecommendation(
                maxMinutesWithoutProtection: 45,
                spfRecommendation: "15-30",
                peakHoursWarning: "Sun protection still recommended",
                vitaminDNote: "May benefit from supplementation"
            )
        }
    }
    
    // MARK: - Thermal Regulation Insights
    
    /// Get thermal regulation indicators based on hair density
    var thermalRegulationIndicator: ThermalRegulationIndicator? {
        guard let hairDensity = hairDensityScore else { return nil }
        
        if hairDensity > 0.7 {
            return ThermalRegulationIndicator(
                heatRetention: .high,
                coolingEfficiency: .moderate,
                recommendations: ["Stay hydrated in warm environments", "Consider lighter clothing during exercise"]
            )
        } else if hairDensity > 0.4 {
            return ThermalRegulationIndicator(
                heatRetention: .moderate,
                coolingEfficiency: .good,
                recommendations: ["Normal thermal regulation", "Standard hydration guidelines apply"]
            )
        } else {
            return ThermalRegulationIndicator(
                heatRetention: .low,
                coolingEfficiency: .high,
                recommendations: ["May lose heat faster in cold environments", "Consider head covering in cold weather"]
            )
        }
    }
    
    // MARK: - Data Persistence
    
    func saveBaseline(_ baseline: PhysiologicalBaseline) {
        if let encoded = try? JSONEncoder().encode(baseline) {
            userDefaults.set(encoded, forKey: baselineKey)
            physiologicalBaseline = baseline
            setupCalibrationTracking()
        }
    }
    
    func saveOnboardingData(_ data: OnboardingData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: onboardingDataKey)
            onboardingData = data
        }
    }
    
    func clearAllData() {
        userDefaults.removeObject(forKey: baselineKey)
        userDefaults.removeObject(forKey: onboardingDataKey)
        physiologicalBaseline = nil
        onboardingData = nil
    }
}

// MARK: - Supporting Types

struct MacroTargets {
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    
    var totalCalories: Double {
        (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9)
    }
}

struct SunExposureRecommendation {
    let maxMinutesWithoutProtection: Int
    let spfRecommendation: String
    let peakHoursWarning: String
    let vitaminDNote: String
}

struct ThermalRegulationIndicator {
    enum Level: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case good = "Good"
    }
    
    let heatRetention: Level
    let coolingEfficiency: Level
    let recommendations: [String]
}
