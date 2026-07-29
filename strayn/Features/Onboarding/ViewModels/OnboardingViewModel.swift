//
//  OnboardingViewModel.swift
//  strayn
//
//  State management for the 10-step biometric onboarding flow.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentStep: OnboardingStep = .identityProfile
    @Published var onboardingData = OnboardingData()
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCameraSheet = false
    @Published var currentCameraCapture: CameraCaptureType?
    
    // Identity sub-step management
    @Published var identitySubStep: Int = 0 // 0: age, 1: gender, 2: height, 3: weight
    
    // Number scroll view values
    @Published var selectedAge: Int = 25
    @Published var selectedHeight: Int = 170
    @Published var selectedWeight: Double = 70.0
    
    // Fitzpatrick type selection
    @Published var fitzpatrickType: FitzpatrickSkinType = .typeIII
    
    // Step-specific state
    @Published var cameraValidation: CameraValidationResult?
    @Published var analysisProgress: Double = 0
    @Published var isAnalyzing = false
    
    // Step 1: Identity
    @Published var age: String = ""
    @Published var biologicalSex: BiologicalSexOption = .male
    @Published var heightCm: String = ""
    @Published var weightKg: String = ""
    
    // Step 2: Body Appearance
    @Published var bodyColor: String = ""
    @Published var bodyType: BodyTypeAssessment = .average
    
    // Step 8: Dietary Preferences
    @Published var dietaryPreferences: Set<DietaryPreference> = []
    
    // Step 9: Primary Goal
    @Published var primaryGoal: PrimaryGoal = .betterSleep
    
    // Step 10: Consents
    @Published var consents: [ConsentItem] = []
    
    // Step 3: Skin Tone
    @Published var skinCaptureRegion: SkinCaptureRegion = .innerForearm
    @Published var skinInnerForearmCaptured = false
    @Published var skinLowerLegCaptured = false
    @Published var skinAbdomenCaptured = false
    @Published var determinedSkinType: FitzpatrickSkinType?
    
    // Step 4: Face
    @Published var faceCaptureType: FaceCaptureType = .fullFace
    @Published var fullFaceCaptured = false
    @Published var faceImageData: Data?
    @Published var underEyeCaptured = false
    @Published var faceValidation: FaceCaptureValidation?
    
    // Step 5: Hairline
    @Published var hairCaptureType: HairCaptureType = .frontalHairline
    @Published var frontalHairlineCaptured = false
    @Published var crownScalpCaptured = false
    @Published var hairImageData: Data?
    @Published var hairDensityScore: Double?
    @Published var thinningIndicator: ThinningIndicator?
    
    // Step 6: Body Composition (auto-calculated)
    @Published var bodyFatCategory: BodyFatCategory = .moderate
    @Published var muscleSignal: MuscleSignal = .medium
    @Published var waterRetention: WaterRetentionLevel = .moderate
    @Published var compositionConfidence: Double = 0
    
    // Step 7: Lifestyle
    @Published var activityLevel: ActivityLevel = .lightlyActive
    @Published var sleepDuration: Double = 7.5
    @Published var sleepQuality: Int = 3
    @Published var stressLevel: Int = 3
    @Published var sunlightMinutes: Int = 30
    @Published var hydration: HydrationLevel = .medium
    @Published var caffeineIntake: IntakeLevel = .moderate
    @Published var alcoholIntake: AlcoholIntakeLevel = .occasional
    
    // Step 8: Nutrition
    @Published var dietType: DietType = .nonVegetarian
    @Published var mealsPerDay: Int = 3
    @Published var nutritionGoal: NutritionGoal = .maintenance
    @Published var calculatedBMR: Double?
    @Published var calculatedTDEE: Double?
    @Published var targetCalories: Double?
    
    // Step 9: Goals
    @Published var selectedGoals: Set<PrimaryGoal> = []
    
    // Step 10: Consent
    @Published var cameraConsent = false
    @Published var healthDataConsent = false
    @Published var aiInsightsConsent = false
    @Published var secureProcessingAck = false
    @Published var termsAccepted = false
    @Published var privacyAccepted = false
    
    // MARK: - Dependencies
    
    private let biometricAnalyzer = BiometricAnalyzer.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(totalSteps)
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .identityProfile:
            return validateIdentityStep()
        case .bodyAppearance:
            return true // Optional step
        case .skinTone:
            return skinInnerForearmCaptured && skinLowerLegCaptured && skinAbdomenCaptured
        case .facePhoto:
            return fullFaceCaptured && underEyeCaptured
        case .hairlineScalp:
            return frontalHairlineCaptured && crownScalpCaptured
        case .bodyComposition:
            return true // Auto-calculated
        case .lifestyle:
            return true
        case .nutrition:
            return true
        case .goals:
            return !selectedGoals.isEmpty
        case .consent:
            return allConsentsGranted
        }
    }
    
    var allConsentsGranted: Bool {
        cameraConsent && healthDataConsent && aiInsightsConsent &&
        secureProcessingAck && termsAccepted && privacyAccepted
    }
    
    var buttonTitle: String {
        switch currentStep {
        case .identityProfile:
            return "Continue"
        case .consent:
            return "Complete Setup"
        default:
            return "Next"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        onboardingData.startedAt = Date()
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-calculate BMR/TDEE when relevant values change
        Publishers.CombineLatest4($age, $biologicalSex, $heightCm, $weightKg)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.calculateMetabolicRates()
            }
            .store(in: &cancellables)
        
        $activityLevel
            .sink { [weak self] _ in
                self?.calculateMetabolicRates()
            }
            .store(in: &cancellables)
        
        $nutritionGoal
            .sink { [weak self] _ in
                self?.calculateTargetCalories()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard canProceed else {
            showValidationError()
            return
        }
        
        saveCurrentStepData()
        
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = nextStep
            }
            
            // Trigger step-specific actions
            onStepEntered(nextStep)
        } else {
            // Final step - complete onboarding
            completeOnboarding()
        }
        
        HapticsManager.shared.playImpact(.medium)
    }
    
    func previousStep() {
        if let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = prevStep
            }
            HapticsManager.shared.playImpact(.light)
        }
    }
    
    func goToStep(_ step: OnboardingStep) {
        // Only allow going back or to current step
        guard step.rawValue <= currentStep.rawValue else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = step
        }
        HapticsManager.shared.playImpact(.light)
    }
    
    // MARK: - Identity Sub-Step Navigation
    
    func nextIdentitySubStep() {
        guard identitySubStep < 3 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            identitySubStep += 1
        }
    }
    
    func previousIdentitySubStep() {
        guard identitySubStep > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            identitySubStep -= 1
        }
    }
    
    func proceedToStep(_ step: OnboardingStep) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = step
        }
    }
    
    private func onStepEntered(_ step: OnboardingStep) {
        switch step {
        case .bodyComposition:
            analyzeBodyComposition()
        case .nutrition:
            calculateMetabolicRates()
        default:
            break
        }
    }
    
    // MARK: - Step 1: Identity Validation
    
    func validateIdentityStep() -> Bool {
        guard let ageInt = Int(age),
              let height = Double(heightCm),
              let weight = Double(weightKg) else {
            return false
        }
        
        return UserCoreProfile.ageRange.contains(ageInt) &&
               UserCoreProfile.heightRange.contains(height) &&
               UserCoreProfile.weightRange.contains(weight)
    }
    
    func validateAge() -> String? {
        guard let ageInt = Int(age) else { return "Enter a valid age" }
        if !UserCoreProfile.ageRange.contains(ageInt) {
            return "Age must be between 13 and 100"
        }
        return nil
    }
    
    func validateHeight() -> String? {
        guard let height = Double(heightCm) else { return "Enter a valid height" }
        if !UserCoreProfile.heightRange.contains(height) {
            return "Height must be between 120 and 230 cm"
        }
        return nil
    }
    
    func validateWeight() -> String? {
        guard let weight = Double(weightKg) else { return "Enter a valid weight" }
        if !UserCoreProfile.weightRange.contains(weight) {
            return "Weight must be between 30 and 200 kg"
        }
        return nil
    }
    
    // MARK: - Camera Capture Actions
    
    func startSkinCapture(region: SkinCaptureRegion) {
        skinCaptureRegion = region
        currentCameraCapture = .skin(region)
        showCameraSheet = true
    }
    
    // Simplified capture methods for UI
    func startSkinCapture() {
        startSkinCapture(region: .innerForearm)
    }
    
    func startFaceCapture() {
        startFaceCapture(type: .fullFace)
    }
    
    func startHairCapture() {
        startHairCapture(type: .crownScalp)
    }
    
    func startFaceCapture(type: FaceCaptureType) {
        faceCaptureType = type
        currentCameraCapture = .face(type)
        showCameraSheet = true
    }
    
    func startHairCapture(type: HairCaptureType) {
        hairCaptureType = type
        currentCameraCapture = .hair(type)
        showCameraSheet = true
    }
    
    func handleCapturedImage(_ imageData: Data, for captureType: CameraCaptureType) {
        Task {
            isAnalyzing = true
            analysisProgress = 0
            
            // Simulate analysis progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                analysisProgress = Double(i) / 10.0
            }
            
            switch captureType {
            case .skin(let region):
                await processSkinCapture(imageData, region: region)
            case .face(let type):
                await processFaceCapture(imageData, type: type)
            case .hair(let type):
                await processHairCapture(imageData, type: type)
            }
            
            isAnalyzing = false
            showCameraSheet = false
            HapticsManager.shared.playSuccess()
        }
    }
    
    private func processSkinCapture(_ imageData: Data, region: SkinCaptureRegion) async {
        // Initialize skin capture if needed
        if onboardingData.skinToneCapture == nil {
            onboardingData.skinToneCapture = SkinToneCapture()
        }
        
        switch region {
        case .innerForearm:
            onboardingData.skinToneCapture?.innerForearmImage = imageData
            skinInnerForearmCaptured = true
        case .lowerLeg:
            onboardingData.skinToneCapture?.lowerLegImage = imageData
            skinLowerLegCaptured = true
        case .abdomen:
            onboardingData.skinToneCapture?.abdomenImage = imageData
            skinAbdomenCaptured = true
        }
        
        // If all regions captured, analyze
        if skinInnerForearmCaptured && skinLowerLegCaptured && skinAbdomenCaptured {
            let result = await biometricAnalyzer.analyzeSkinTone(from: onboardingData.skinToneCapture!)
            determinedSkinType = result.skinType
            onboardingData.skinToneCapture?.determinedType = result.skinType
            onboardingData.skinToneCapture?.regionVariance = result.variance
            onboardingData.skinToneCapture?.capturedAt = Date()
        }
    }
    
    private func processFaceCapture(_ imageData: Data, type: FaceCaptureType) async {
        if onboardingData.faceCapture == nil {
            onboardingData.faceCapture = FaceCapture()
        }
        
        switch type {
        case .fullFace:
            onboardingData.faceCapture?.fullFaceImage = imageData
            fullFaceCaptured = true
        case .underEye:
            onboardingData.faceCapture?.underEyeImage = imageData
            underEyeCaptured = true
        }
        
        // Validate face capture
        let validation = await biometricAnalyzer.validateFaceCapture(imageData, type: type)
        faceValidation = validation
        
        if !validation.overallValid {
            // Show validation errors
            errorMessage = validation.failureReasons.first ?? "Face capture validation failed"
            showError = true
            
            // Reset capture flag
            switch type {
            case .fullFace:
                fullFaceCaptured = false
            case .underEye:
                underEyeCaptured = false
            }
        } else {
            onboardingData.faceCapture?.alignmentScore = validation.alignmentScore
            onboardingData.faceCapture?.blurScore = validation.blurPercentage / 100
            onboardingData.faceCapture?.occlusionDetected = validation.hasOcclusion
            onboardingData.faceCapture?.capturedAt = Date()
        }
    }
    
    private func processHairCapture(_ imageData: Data, type: HairCaptureType) async {
        if onboardingData.hairlineCapture == nil {
            onboardingData.hairlineCapture = HairlineScalpCapture()
        }
        
        switch type {
        case .frontalHairline:
            onboardingData.hairlineCapture?.frontalHairlineImage = imageData
            frontalHairlineCaptured = true
        case .crownScalp:
            onboardingData.hairlineCapture?.crownScalpImage = imageData
            crownScalpCaptured = true
        }
        
        // If both captured, analyze
        if frontalHairlineCaptured && crownScalpCaptured {
            let result = await biometricAnalyzer.analyzeHairline(from: onboardingData.hairlineCapture!)
            hairDensityScore = result.densityScore
            thinningIndicator = result.thinningIndicator
            onboardingData.hairlineCapture?.hairDensityScore = result.densityScore
            onboardingData.hairlineCapture?.earlyThinningIndicator = result.thinningIndicator
            onboardingData.hairlineCapture?.scalpHealthScore = result.scalpHealthScore
            onboardingData.hairlineCapture?.capturedAt = Date()
        }
    }
    
    // MARK: - Step 6: Body Composition Analysis
    
    func analyzeBodyComposition() {
        guard let ageInt = Int(age),
              let height = Double(heightCm),
              let weight = Double(weightKg) else { return }
        
        isAnalyzing = true
        analysisProgress = 0
        
        Task {
            // Simulate AI analysis
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    analysisProgress = Double(i) / 10.0
                }
            }
            
            let result = await biometricAnalyzer.estimateBodyComposition(
                age: ageInt,
                sex: biologicalSex,
                heightCm: height,
                weightKg: weight,
                skinType: determinedSkinType,
                hairDensity: hairDensityScore
            )
            
            await MainActor.run {
                bodyFatCategory = result.bodyFatCategory
                muscleSignal = result.muscleSignal
                waterRetention = result.waterRetentionIndicator
                compositionConfidence = result.confidenceLevel
                
                onboardingData.bodyComposition = result
                isAnalyzing = false
            }
        }
    }
    
    // MARK: - Step 8: Metabolic Calculations
    
    func calculateMetabolicRates() {
        guard let ageInt = Int(age),
              let height = Double(heightCm),
              let weight = Double(weightKg) else { return }
        
        // Mifflin-St Jeor Equation (more accurate than Harris-Benedict)
        let bmr: Double
        switch biologicalSex {
        case .male:
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(ageInt)) + 5
        case .female:
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(ageInt)) - 161
        case .preferNotToSay:
            // Use average of male/female calculations
            let maleBmr = (10 * weight) + (6.25 * height) - (5 * Double(ageInt)) + 5
            let femaleBmr = (10 * weight) + (6.25 * height) - (5 * Double(ageInt)) - 161
            bmr = (maleBmr + femaleBmr) / 2
        }
        
        calculatedBMR = bmr
        
        // TDEE with activity multiplier
        var tdee = bmr * activityLevel.activityMultiplier
        
        // Adjust TDEE based on biometric signals
        // Hair density affects thermal regulation (metabolic rate proxy)
        if let hairDensity = hairDensityScore {
            let densityAdjustment = (hairDensity - 0.5) * 0.02 // ±1% adjustment
            tdee *= (1 + densityAdjustment)
        }
        
        // UV sensitivity affects vitamin D and metabolic processes
        if let skinType = determinedSkinType {
            switch skinType.uvSensitivity {
            case .high:
                tdee *= 0.99 // Slightly lower
            case .moderate:
                break // No adjustment
            case .low:
                tdee *= 1.01 // Slightly higher
            }
        }
        
        calculatedTDEE = tdee
        calculateTargetCalories()
    }
    
    func calculateTargetCalories() {
        guard let tdee = calculatedTDEE else { return }
        targetCalories = tdee + nutritionGoal.calorieAdjustment
    }
    
    // MARK: - Goal Selection
    
    func toggleGoal(_ goal: PrimaryGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
        HapticsManager.shared.playSelection()
    }
    
    // MARK: - Consent Management
    
    func grantAllConsents() {
        cameraConsent = true
        healthDataConsent = true
        aiInsightsConsent = true
        secureProcessingAck = true
        termsAccepted = true
        privacyAccepted = true
        HapticsManager.shared.playSuccess()
    }
    
    // MARK: - Data Persistence
    
    private func saveCurrentStepData() {
        switch currentStep {
        case .identityProfile:
            if let ageInt = Int(age),
               let height = Double(heightCm),
               let weight = Double(weightKg) {
                onboardingData.coreProfile = UserCoreProfile(
                    age: ageInt,
                    biologicalSex: biologicalSex,
                    heightCm: height,
                    weightKg: weight
                )
            }
            
        case .bodyAppearance:
            onboardingData.bodyAppearance = BodyAppearanceBaseline(
                bodyColor: bodyColor.isEmpty ? nil : bodyColor,
                bodyType: bodyType
            )
            
        case .lifestyle:
            onboardingData.lifestyle = LifestyleProfile(
                activityLevel: activityLevel,
                averageSleepDuration: sleepDuration,
                sleepQuality: sleepQuality,
                stressLevel: stressLevel,
                sunlightExposure: sunlightMinutes,
                hydrationLevel: hydration,
                caffeineIntake: caffeineIntake,
                alcoholIntake: alcoholIntake
            )
            
        case .nutrition:
            onboardingData.nutrition = NutritionProfile(
                dietType: dietType,
                mealsPerDay: mealsPerDay,
                nutritionGoal: nutritionGoal,
                bmr: calculatedBMR,
                tdee: calculatedTDEE,
                targetCalories: targetCalories
            )
            
        case .goals:
            onboardingData.primaryGoals = Array(selectedGoals)
            
        case .consent:
            onboardingData.consent = ConsentRecord(
                cameraAnalysisConsent: cameraConsent,
                healthDataProcessingConsent: healthDataConsent,
                aiInsightsConsent: aiInsightsConsent,
                secureProcessingAcknowledged: secureProcessingAck,
                termsAccepted: termsAccepted,
                privacyPolicyAccepted: privacyAccepted,
                consentDate: Date()
            )
            
        default:
            break
        }
    }
    
    private func showValidationError() {
        switch currentStep {
        case .identityProfile:
            if let ageError = validateAge() {
                errorMessage = ageError
            } else if let heightError = validateHeight() {
                errorMessage = heightError
            } else if let weightError = validateWeight() {
                errorMessage = weightError
            }
        case .skinTone:
            errorMessage = "Please capture all three skin regions"
        case .facePhoto:
            errorMessage = "Please complete both face captures"
        case .hairlineScalp:
            errorMessage = "Please capture both hairline images"
        case .goals:
            errorMessage = "Please select at least one goal"
        case .consent:
            errorMessage = "Please accept all consents to continue"
        default:
            break
        }
        
        showError = true
        HapticsManager.shared.playError()
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() {
        saveCurrentStepData()
        onboardingData.completedAt = Date()
        
        isLoading = true
        
        Task {
            // Generate physiological baseline
            let baseline = await generatePhysiologicalBaseline()
            
            // Save to persistence
            await saveOnboardingData(baseline: baseline)
            
            await MainActor.run {
                isLoading = false
                
                // Mark onboarding complete
                AppState.shared.isOnboardingComplete = true
                
                HapticsManager.shared.playSuccess()
            }
        }
    }
    
    private func generatePhysiologicalBaseline() async -> PhysiologicalBaseline {
        // Combine all goal weights
        var combinedWeights: [String: Double] = [:]
        for goal in selectedGoals {
            for (key, value) in goal.insightWeights {
                combinedWeights[key, default: 1.0] += (value - 1.0)
            }
        }
        
        return PhysiologicalBaseline(
            userId: UUID(),
            estimatedBMR: calculatedBMR ?? 1500,
            estimatedTDEE: calculatedTDEE ?? 2000,
            targetCalories: targetCalories ?? 2000,
            fitzpatrickType: determinedSkinType ?? .typeIII,
            uvSensitivity: determinedSkinType?.uvSensitivity ?? .moderate,
            bodyComposition: onboardingData.bodyComposition ?? BodyCompositionEstimate(
                bodyFatCategory: bodyFatCategory,
                muscleSignal: muscleSignal,
                waterRetentionIndicator: waterRetention,
                confidenceLevel: compositionConfidence
            ),
            hairDensityScore: hairDensityScore,
            scalpHealth: onboardingData.hairlineCapture?.scalpHealthScore,
            goalWeights: combinedWeights,
            primaryGoals: Array(selectedGoals),
            baselineStartDate: Date(),
            expectedCalibrationEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            createdAt: Date(),
            version: "1.0"
        )
    }
    
    private func saveOnboardingData(baseline: PhysiologicalBaseline) async {
        // Encode and save to UserDefaults (could use CoreData for production)
        if let encodedOnboarding = try? JSONEncoder().encode(onboardingData) {
            UserDefaults.standard.set(encodedOnboarding, forKey: "onboardingData")
        }
        
        if let encodedBaseline = try? JSONEncoder().encode(baseline) {
            UserDefaults.standard.set(encodedBaseline, forKey: "physiologicalBaseline")
        }
    }
}

// MARK: - Camera Capture Type

enum CameraCaptureType: Identifiable {
    case skin(SkinCaptureRegion)
    case face(FaceCaptureType)
    case hair(HairCaptureType)
    
    var id: String {
        switch self {
        case .skin(let region): return "skin_\(region.rawValue)"
        case .face(let type): return "face_\(type.rawValue)"
        case .hair(let type): return "hair_\(type.rawValue)"
        }
    }
    
    var title: String {
        switch self {
        case .skin(let region): return region.rawValue
        case .face(let type): return type.rawValue
        case .hair(let type): return type.rawValue
        }
    }
    
    var instructions: String {
        switch self {
        case .skin(let region): return region.instructions
        case .face(let type): return type.instructions
        case .hair(let type): return type.instructions
        }
    }
}
