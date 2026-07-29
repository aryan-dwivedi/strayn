//
//  OnboardingModels.swift
//  strayn
//
//  Comprehensive data models for biometric onboarding and personalization engine.
//

import Foundation
import SwiftUI

// MARK: - Step 1: Identity & Core Profile

struct UserCoreProfile: Codable, Equatable {
    var age: Int
    var biologicalSex: BiologicalSexOption
    var heightCm: Double
    var weightKg: Double
    
    // Computed BMI
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    // Validation ranges
    static let ageRange = 13...100
    static let heightRange: ClosedRange<Double> = 120...230
    static let weightRange: ClosedRange<Double> = 30...200
    
    func isValid() -> Bool {
        Self.ageRange.contains(age) &&
        Self.heightRange.contains(heightCm) &&
        Self.weightRange.contains(weightKg)
    }
}

enum BiologicalSexOption: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case preferNotToSay = "Prefer not to say"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .preferNotToSay: return "person.fill.questionmark"
        }
    }
}

// MARK: - Step 2: Body & Appearance Baseline

struct BodyAppearanceBaseline: Codable, Equatable {
    var bodyColor: String?
    var bodyType: BodyTypeAssessment
}

enum BodyTypeAssessment: String, Codable, CaseIterable, Identifiable {
    case lean = "Lean"
    case average = "Average"
    case athletic = "Athletic"
    case curvy = "Curvy"
    case overweight = "Overweight"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .lean: return "Low body fat, visible definition"
        case .average: return "Moderate build, balanced proportions"
        case .athletic: return "Muscular build, well-defined"
        case .curvy: return "Fuller figure, natural curves"
        case .overweight: return "Above average weight for height"
        }
    }
    
    var icon: String {
        switch self {
        case .lean: return "figure.stand"
        case .average: return "figure.walk"
        case .athletic: return "figure.strengthtraining.traditional"
        case .curvy: return "figure.dress.line.vertical.figure"
        case .overweight: return "figure.arms.open"
        }
    }
}

// MARK: - Step 3: Fitzpatrick Skin Tone

enum FitzpatrickSkinType: Int, Codable, CaseIterable, Identifiable {
    case typeI = 1
    case typeII = 2
    case typeIII = 3
    case typeIV = 4
    case typeV = 5
    case typeVI = 6
    
    var id: Int { rawValue }
    
    var displayName: String {
        "Type \(rawValue)"
    }
    
    var description: String {
        switch self {
        case .typeI: return "Very fair, always burns, never tans"
        case .typeII: return "Fair, usually burns, tans minimally"
        case .typeIII: return "Medium, sometimes burns, tans uniformly"
        case .typeIV: return "Olive, rarely burns, tans easily"
        case .typeV: return "Brown, very rarely burns, tans very easily"
        case .typeVI: return "Dark brown/black, never burns"
        }
    }
    
    var uvSensitivity: UVSensitivity {
        switch self {
        case .typeI, .typeII: return .high
        case .typeIII, .typeIV: return .moderate
        case .typeV, .typeVI: return .low
        }
    }
    
    var color: Color {
        switch self {
        case .typeI: return Color(red: 1.0, green: 0.92, blue: 0.87)
        case .typeII: return Color(red: 0.98, green: 0.87, blue: 0.78)
        case .typeIII: return Color(red: 0.89, green: 0.76, blue: 0.63)
        case .typeIV: return Color(red: 0.78, green: 0.62, blue: 0.47)
        case .typeV: return Color(red: 0.60, green: 0.44, blue: 0.32)
        case .typeVI: return Color(red: 0.40, green: 0.28, blue: 0.20)
        }
    }
}

enum UVSensitivity: String, Codable {
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
}

struct SkinToneCapture: Codable, Equatable {
    var innerForearmImage: Data?
    var lowerLegImage: Data?
    var abdomenImage: Data?
    var capturedAt: Date?
    var determinedType: FitzpatrickSkinType?
    var regionVariance: Double?
    var isValid: Bool {
        innerForearmImage != nil && lowerLegImage != nil && abdomenImage != nil
    }
}

enum SkinCaptureRegion: String, CaseIterable, Identifiable {
    case innerForearm = "Inner Forearm"
    case lowerLeg = "Lower Leg"
    case abdomen = "Abdomen"
    
    var id: String { rawValue }
    
    var instructions: String {
        switch self {
        case .innerForearm: return "Hold your inner forearm in natural light. Ensure skin covers at least 60% of the frame."
        case .lowerLeg: return "Position your lower leg in natural light. Avoid areas with hair or marks."
        case .abdomen: return "Position your abdomen in even lighting. Ensure the area is clean and dry."
        }
    }
    
    var icon: String {
        switch self {
        case .innerForearm: return "hand.raised.fill"
        case .lowerLeg: return "figure.stand"
        case .abdomen: return "figure.arms.open"
        }
    }
}

// MARK: - Step 4: Face Photography

struct FaceCapture: Codable, Equatable {
    var fullFaceImage: Data?
    var underEyeImage: Data?
    var capturedAt: Date?
    var alignmentScore: Double?
    var blurScore: Double?
    var occlusionDetected: Bool = false
    var skinTextureQuality: Double?
    
    var isValid: Bool {
        guard fullFaceImage != nil,
              underEyeImage != nil,
              let alignment = alignmentScore,
              let blur = blurScore else { return false }
        return alignment >= 0.95 && blur < 0.05 && !occlusionDetected
    }
}

struct FaceCaptureValidation {
    var alignmentScore: Double = 0
    var blurPercentage: Double = 100
    var hasOcclusion: Bool = true
    var skinTextureVisible: Bool = false
    var isEvenlyLit: Bool = false
    var isCentered: Bool = false
    var eyesOpen: Bool = false
    
    var overallValid: Bool {
        alignmentScore >= 0.95 &&
        blurPercentage < 5 &&
        !hasOcclusion &&
        skinTextureVisible &&
        isEvenlyLit &&
        isCentered &&
        eyesOpen
    }
    
    var failureReasons: [String] {
        var reasons: [String] = []
        if alignmentScore < 0.95 { reasons.append("Face alignment: \(Int(alignmentScore * 100))% (need 95%)") }
        if blurPercentage >= 5 { reasons.append("Image blur: \(Int(blurPercentage))% (need <5%)") }
        if hasOcclusion { reasons.append("Face obstruction detected") }
        if !skinTextureVisible { reasons.append("Skin texture not clearly visible") }
        if !isEvenlyLit { reasons.append("Uneven lighting detected") }
        if !isCentered { reasons.append("Face not centered in frame") }
        if !eyesOpen { reasons.append("Eyes not fully open") }
        return reasons
    }
}

enum FaceCaptureType: String, CaseIterable, Identifiable {
    case fullFace = "Full Face"
    case underEye = "Under-Eye Region"
    
    var id: String { rawValue }
    
    var instructions: String {
        switch self {
        case .fullFace: return "Look directly at the camera with a neutral expression. Remove glasses, hats, or masks."
        case .underEye: return "Keep both eyes open and visible. Ensure the under-eye area is clearly visible."
        }
    }
    
    var icon: String {
        switch self {
        case .fullFace: return "face.smiling"
        case .underEye: return "eyes"
        }
    }
}

// MARK: - Step 5: Hairline & Scalp

struct HairlineScalpCapture: Codable, Equatable {
    var frontalHairlineImage: Data?
    var crownScalpImage: Data?
    var capturedAt: Date?
    var hairDensityScore: Double?
    var earlyThinningIndicator: ThinningIndicator?
    var scalpHealthScore: Double?
}

enum ThinningIndicator: String, Codable, CaseIterable {
    case none = "None Detected"
    case minimal = "Minimal Thinning"
    case moderate = "Moderate Thinning"
    case significant = "Significant Thinning"
    
    var color: Color {
        switch self {
        case .none: return .green
        case .minimal: return .yellow
        case .moderate: return .orange
        case .significant: return .red
        }
    }
}

enum HairCaptureType: String, CaseIterable, Identifiable {
    case frontalHairline = "Frontal Hairline"
    case crownScalp = "Crown/Top Scalp"
    
    var id: String { rawValue }
    
    var instructions: String {
        switch self {
        case .frontalHairline: return "Pull hair back from forehead. Position camera perpendicular to hairline."
        case .crownScalp: return "Use overhead lighting. Part hair to expose scalp clearly."
        }
    }
    
    var icon: String {
        switch self {
        case .frontalHairline: return "person.crop.circle"
        case .crownScalp: return "circle.dotted"
        }
    }
}

// MARK: - Step 6: Body Composition

struct BodyCompositionEstimate: Codable, Equatable {
    var bodyFatCategory: BodyFatCategory
    var muscleSignal: MuscleSignal
    var waterRetentionIndicator: WaterRetentionLevel
    var confidenceLevel: Double // 0-1
    var analysisNotes: String?
    
    static let disclaimer = "This is a non-medical AI-assisted estimation. Consult healthcare professionals for accurate measurements."
}

enum BodyFatCategory: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Below average body fat percentage"
        case .moderate: return "Average body fat percentage"
        case .high: return "Above average body fat percentage"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "figure.stand"
        case .moderate: return "figure.walk"
        case .high: return "figure.arms.open"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        }
    }
}

enum MuscleSignal: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Lower muscle mass indicators"
        case .medium: return "Average muscle mass indicators"
        case .high: return "Higher muscle mass indicators"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "bolt"
        case .medium: return "bolt.fill"
        case .high: return "bolt.shield.fill"
        }
    }
}

enum WaterRetentionLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case elevated = "Elevated"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Minimal water retention detected"
        case .moderate: return "Normal hydration levels"
        case .elevated: return "Elevated fluid retention signals"
        }
    }
}

// MARK: - Step 7: Lifestyle & Physiology Inputs

struct LifestyleProfile: Codable, Equatable {
    var activityLevel: ActivityLevel
    var averageSleepDuration: Double // hours
    var sleepQuality: Int // 1-5
    var stressLevel: Int // 1-5
    var sunlightExposure: Int // minutes/day
    var hydrationLevel: HydrationLevel
    var caffeineIntake: IntakeLevel
    var alcoholIntake: AlcoholIntakeLevel
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case active = "Active"
    case highlyActive = "Highly Active"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise, desk job"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .active: return "Moderate exercise 3-5 days/week"
        case .highlyActive: return "Heavy exercise 6-7 days/week"
        }
    }
    
    var activityMultiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .active: return 1.55
        case .highlyActive: return 1.725
        }
    }
    
    var icon: String {
        switch self {
        case .sedentary: return "chair.fill"
        case .lightlyActive: return "figure.walk"
        case .active: return "figure.run"
        case .highlyActive: return "figure.highintensity.intervaltraining"
        }
    }
}

enum HydrationLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Less than 6 glasses/day"
        case .medium: return "6-8 glasses/day"
        case .high: return "More than 8 glasses/day"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "drop"
        case .medium: return "drop.fill"
        case .high: return "drop.circle.fill"
        }
    }
}

enum IntakeLevel: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .low: return "1.circle"
        case .moderate: return "2.circle"
        case .high: return "3.circle"
        }
    }
}

enum AlcoholIntakeLevel: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case occasional = "Occasional"
    case frequent = "Frequent"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .none: return "I don't drink alcohol"
        case .occasional: return "A few drinks per week"
        case .frequent: return "Daily or almost daily"
        }
    }
}

// MARK: - Step 8: Nutrition & AI Calorie Counter

struct NutritionProfile: Codable, Equatable {
    var dietType: DietType
    var mealsPerDay: Int
    var nutritionGoal: NutritionGoal
    
    // Calculated values
    var bmr: Double?
    var tdee: Double?
    var targetCalories: Double?
}

enum DietType: String, Codable, CaseIterable, Identifiable {
    case vegetarian = "Vegetarian"
    case eggetarian = "Eggetarian"
    case nonVegetarian = "Non-Vegetarian"
    case vegan = "Vegan"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .vegetarian: return "Plant-based diet, includes dairy"
        case .eggetarian: return "Vegetarian diet, includes eggs"
        case .nonVegetarian: return "Includes meat, poultry, fish"
        case .vegan: return "Strictly plant-based, no animal products"
        }
    }
    
    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .eggetarian: return "oval.portrait.fill"
        case .nonVegetarian: return "fork.knife"
        case .vegan: return "carrot.fill"
        }
    }
}

enum NutritionGoal: String, Codable, CaseIterable, Identifiable {
    case fatLoss = "Fat Loss"
    case muscleGain = "Muscle Gain"
    case longevity = "Longevity"
    case maintenance = "Maintenance"
    
    var id: String { rawValue }
    
    var calorieAdjustment: Double {
        switch self {
        case .fatLoss: return -500 // deficit
        case .muscleGain: return 300 // surplus
        case .longevity: return -100 // slight deficit
        case .maintenance: return 0
        }
    }
    
    var description: String {
        switch self {
        case .fatLoss: return "Reduce body fat while preserving muscle"
        case .muscleGain: return "Build muscle mass with caloric surplus"
        case .longevity: return "Optimize for healthspan and cellular health"
        case .maintenance: return "Maintain current body composition"
        }
    }
    
    var icon: String {
        switch self {
        case .fatLoss: return "flame.fill"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .longevity: return "heart.fill"
        case .maintenance: return "scale.3d"
        }
    }
}

// MARK: - Step 9: Goal & Intent Mapping

enum PrimaryGoal: String, Codable, CaseIterable, Identifiable {
    case betterSleep = "Better Sleep"
    case higherRecovery = "Higher Recovery"
    case stressReduction = "Stress Reduction"
    case fatLoss = "Fat Loss"
    case muscleBuilding = "Muscle Building"
    case longevity = "Longevity & Biological Age"
    case athleticPerformance = "Athletic Performance"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .betterSleep: return "Improve sleep quality and duration"
        case .higherRecovery: return "Maximize daily recovery scores"
        case .stressReduction: return "Lower stress and improve HRV"
        case .fatLoss: return "Reduce body fat percentage"
        case .muscleBuilding: return "Increase lean muscle mass"
        case .longevity: return "Optimize biological age markers"
        case .athleticPerformance: return "Enhance fitness and performance"
        }
    }
    
    var icon: String {
        switch self {
        case .betterSleep: return "moon.fill"
        case .higherRecovery: return "battery.100.bolt"
        case .stressReduction: return "brain.head.profile"
        case .fatLoss: return "flame.fill"
        case .muscleBuilding: return "figure.strengthtraining.traditional"
        case .longevity: return "sparkles"
        case .athleticPerformance: return "figure.run"
        }
    }
    
    var color: Color {
        switch self {
        case .betterSleep: return Color.purple
        case .higherRecovery: return Color.green
        case .stressReduction: return Color.blue
        case .fatLoss: return Color.orange
        case .muscleBuilding: return Color.red
        case .longevity: return Color.yellow
        case .athleticPerformance: return Color.cyan
        }
    }
    
    /// Weight adjustments for insight generation
    var insightWeights: [String: Double] {
        switch self {
        case .betterSleep:
            return ["sleep": 1.5, "recovery": 1.2, "strain": 0.8]
        case .higherRecovery:
            return ["recovery": 1.5, "hrv": 1.3, "sleep": 1.2]
        case .stressReduction:
            return ["hrv": 1.5, "stress": 1.4, "recovery": 1.2]
        case .fatLoss:
            return ["strain": 1.4, "calories": 1.5, "sleep": 1.0]
        case .muscleBuilding:
            return ["strain": 1.5, "protein": 1.4, "recovery": 1.3]
        case .longevity:
            return ["biologicalAge": 1.5, "hrv": 1.4, "sleep": 1.3]
        case .athleticPerformance:
            return ["strain": 1.5, "vo2max": 1.4, "recovery": 1.3]
        }
    }
}

// MARK: - Step 10: Consent & Privacy

struct ConsentRecord: Codable, Equatable {
    var cameraAnalysisConsent: Bool = false
    var healthDataProcessingConsent: Bool = false
    var aiInsightsConsent: Bool = false
    var secureProcessingAcknowledged: Bool = false
    var termsAccepted: Bool = false
    var privacyPolicyAccepted: Bool = false
    var consentDate: Date?
    
    var allConsentsGranted: Bool {
        cameraAnalysisConsent &&
        healthDataProcessingConsent &&
        aiInsightsConsent &&
        secureProcessingAcknowledged &&
        termsAccepted &&
        privacyPolicyAccepted
    }
}

// MARK: - Complete Onboarding Data

struct OnboardingData: Codable {
    // Step 1
    var coreProfile: UserCoreProfile?
    
    // Step 2
    var bodyAppearance: BodyAppearanceBaseline?
    
    // Step 3
    var skinToneCapture: SkinToneCapture?
    
    // Step 4
    var faceCapture: FaceCapture?
    
    // Step 5
    var hairlineCapture: HairlineScalpCapture?
    
    // Step 6
    var bodyComposition: BodyCompositionEstimate?
    
    // Step 7
    var lifestyle: LifestyleProfile?
    
    // Step 8
    var nutrition: NutritionProfile?
    
    // Step 9
    var primaryGoals: [PrimaryGoal] = []
    
    // Step 10
    var consent: ConsentRecord?
    
    // Metadata
    var startedAt: Date?
    var completedAt: Date?
    var version: String = "1.0"
    
    var isComplete: Bool {
        coreProfile != nil &&
        bodyAppearance != nil &&
        skinToneCapture?.isValid == true &&
        faceCapture?.isValid == true &&
        hairlineCapture != nil &&
        bodyComposition != nil &&
        lifestyle != nil &&
        nutrition != nil &&
        !primaryGoals.isEmpty &&
        consent?.allConsentsGranted == true
    }
}

// MARK: - Onboarding Step Enum

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case identityProfile = 0
    case bodyAppearance = 1
    case skinTone = 2
    case facePhoto = 3
    case hairlineScalp = 4
    case bodyComposition = 5
    case lifestyle = 6
    case nutrition = 7
    case goals = 8
    case consent = 9
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .identityProfile: return "Profile"
        case .bodyAppearance: return "Body"
        case .skinTone: return "Skin Tone"
        case .facePhoto: return "Face Scan"
        case .hairlineScalp: return "Hair Analysis"
        case .bodyComposition: return "Composition"
        case .lifestyle: return "Lifestyle"
        case .nutrition: return "Nutrition"
        case .goals: return "Goals"
        case .consent: return "Privacy"
        }
    }
    
    var subtitle: String {
        switch self {
        case .identityProfile: return "Basic information"
        case .bodyAppearance: return "Body assessment"
        case .skinTone: return "Fitzpatrick scale"
        case .facePhoto: return "FaceID-grade capture"
        case .hairlineScalp: return "Hair density baseline"
        case .bodyComposition: return "AI composition analysis"
        case .lifestyle: return "Daily habits"
        case .nutrition: return "Calorie personalization"
        case .goals: return "Your focus areas"
        case .consent: return "Privacy & security"
        }
    }
}

// MARK: - Camera Validation Types

struct CameraValidationResult {
    var isValid: Bool
    var issues: [CameraValidationIssue]
    var skinCoveragePercent: Double?
    var lightingQuality: LightingQuality?
    var sharpnessScore: Double?
}

enum CameraValidationIssue: String, Identifiable {
    case insufficientSkinCoverage = "Skin must cover at least 60% of frame"
    case poorLighting = "Natural lighting required"
    case tooMuchGlare = "Reduce glare or reflections"
    case shadowsDetected = "Move to remove shadows"
    case colorFilterDetected = "Disable camera filters"
    case imageTooBlurry = "Hold camera steady for sharp focus"
    case makeupDetected = "Remove makeup from capture area"
    case tattooVisible = "Capture area without tattoos"
    case occlusionDetected = "Clear obstruction from frame"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .insufficientSkinCoverage: return "viewfinder"
        case .poorLighting: return "sun.max"
        case .tooMuchGlare: return "light.max"
        case .shadowsDetected: return "shadow"
        case .colorFilterDetected: return "camera.filters"
        case .imageTooBlurry: return "camera.metering.unknown"
        case .makeupDetected: return "paintbrush.fill"
        case .tattooVisible: return "pencil.tip"
        case .occlusionDetected: return "eye.slash"
        }
    }
}

enum LightingQuality: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case acceptable = "Acceptable"
    case poor = "Poor"
}

// MARK: - Physiological Baseline Output

struct PhysiologicalBaseline: Codable {
    let userId: UUID
    
    // Derived metrics
    let estimatedBMR: Double
    let estimatedTDEE: Double
    let targetCalories: Double
    let fitzpatrickType: FitzpatrickSkinType
    let uvSensitivity: UVSensitivity
    let bodyComposition: BodyCompositionEstimate
    let hairDensityScore: Double?
    let scalpHealth: Double?
    
    // Personalization weights
    let goalWeights: [String: Double]
    let primaryGoals: [PrimaryGoal]
    
    // Calibration period
    let baselineStartDate: Date
    let expectedCalibrationEndDate: Date
    
    // Version & timestamp
    let createdAt: Date
    let version: String
}

// MARK: - OnboardingStep Extensions

extension OnboardingStep {
    var icon: String {
        switch self {
        case .identityProfile: return "person.crop.circle"
        case .bodyAppearance: return "figure.stand"
        case .skinTone: return "paintpalette"
        case .facePhoto: return "camera.viewfinder"
        case .hairlineScalp: return "scissors"
        case .bodyComposition: return "figure.arms.open"
        case .lifestyle: return "figure.run"
        case .nutrition: return "leaf"
        case .goals: return "target"
        case .consent: return "checkmark.shield"
        }
    }
}

// MARK: - Additional Types for Enhanced Onboarding

enum DietaryPreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    case mediterranean = "Mediterranean"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
    case intermittentFasting = "Intermittent Fasting"
    case noRestrictions = "No Restrictions"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .vegetarian: return "leaf"
        case .vegan: return "carrot"
        case .pescatarian: return "fish"
        case .keto: return "flame"
        case .paleo: return "figure.hunting"
        case .mediterranean: return "drop"
        case .lowCarb: return "minus.square"
        case .highProtein: return "plus.square"
        case .glutenFree: return "x.square"
        case .dairyFree: return "minus.circle"
        case .intermittentFasting: return "clock"
        case .noRestrictions: return "checkmark.circle"
        }
    }
    
    var description: String {
        switch self {
        case .vegetarian: return "No meat, but includes dairy & eggs"
        case .vegan: return "No animal products"
        case .pescatarian: return "Vegetarian plus fish"
        case .keto: return "Very low carb, high fat"
        case .paleo: return "Whole foods, no processed"
        case .mediterranean: return "Fish, olive oil, whole grains"
        case .lowCarb: return "Reduced carbohydrate intake"
        case .highProtein: return "Higher protein intake"
        case .glutenFree: return "No gluten-containing grains"
        case .dairyFree: return "No dairy products"
        case .intermittentFasting: return "Timed eating windows"
        case .noRestrictions: return "No dietary restrictions"
        }
    }
}

struct ConsentItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let isRequired: Bool
    var isAccepted: Bool = false
    
    static let defaultConsents: [ConsentItem] = [
        ConsentItem(title: "Health Data Analysis", description: "Allow Strayn to analyze your health data to provide personalized insights and recommendations.", isRequired: true),
        ConsentItem(title: "Biometric Data Collection", description: "Consent to capture and analyze photos for biometric assessment and aging analysis.", isRequired: true),
        ConsentItem(title: "Health Research Participation", description: "Contribute anonymized data to health research studies (optional).", isRequired: false),
        ConsentItem(title: "Marketing Communications", description: "Receive updates about new features and health tips via email (optional).", isRequired: false)
    ]
}
