//
//  WHOOPOnboardingViewModel.swift
//  strayn
//
//  Extended ViewModel for 38-screen WHOOP-style onboarding flow.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Screen Index Enum

enum OnboardingScreenIndex: Int, CaseIterable {
    // Phase 1: Identity & Core Profile (5 screens)
    case welcome = 0
    case ageInput = 1
    case sexSelection = 2
    case heightInput = 3
    case weightInput = 4

    // Phase 2: Body Appearance (2 screens)
    case bodyTypeIntro = 5
    case bodyTypeSelection = 6

    // Phase 3: Skin Tone Capture (7 screens)
    case skinToneIntro = 7
    case skinCaptureForearm = 8
    case skinProcessingForearm = 9
    case skinCaptureLeg = 10
    case skinProcessingLeg = 11
    case skinCaptureAbdomen = 12
    case skinResult = 13

    // Phase 4: Face Photography (5 screens)
    case faceIntro = 14
    case faceCaptureFull = 15
    case faceProcessing = 16
    case faceCaptureUnderEye = 17
    case faceResult = 18

    // Phase 5: Hairline & Scalp (5 screens)
    case hairIntro = 19
    case hairCaptureFrontal = 20
    case hairCaptureCrown = 21
    case hairProcessing = 22
    case hairResult = 23

    // Phase 6: Body Composition (2 screens)
    case compositionProcessing = 24
    case compositionResult = 25

    // Phase 7: Lifestyle (5 screens)
    case activityLevel = 26
    case sleepDuration = 27
    case sleepQuality = 28
    case stressLevel = 29
    case hydration = 30

    // Phase 8: Nutrition (3 screens)
    case dietType = 31
    case nutritionGoal = 32
    case calorieReveal = 33

    // Phase 9: Goals (1 screen)
    case goalSelection = 34

    // Phase 10: Consent & Complete (3 screens)
    case privacySummary = 35
    case consentToggles = 36
    case completion = 37

    var isAutoAdvance: Bool {
        switch self {
        case .welcome, .skinProcessingForearm, .skinProcessingLeg, .faceProcessing,
             .hairProcessing, .compositionProcessing, .calorieReveal:
            return true
        default:
            return false
        }
    }

    var autoAdvanceDelay: TimeInterval {
        switch self {
        case .welcome:
            return 2.5
        case .skinProcessingForearm, .skinProcessingLeg, .faceProcessing, .hairProcessing:
            return 2.0
        case .compositionProcessing:
            return 3.5
        case .calorieReveal:
            return 3.0
        default:
            return 0
        }
    }

    var phaseName: String {
        switch self {
        case .welcome, .ageInput, .sexSelection, .heightInput, .weightInput:
            return "Profile"
        case .bodyTypeIntro, .bodyTypeSelection:
            return "Body"
        case .skinToneIntro, .skinCaptureForearm, .skinProcessingForearm, .skinCaptureLeg,
             .skinProcessingLeg, .skinCaptureAbdomen, .skinResult:
            return "Skin"
        case .faceIntro, .faceCaptureFull, .faceProcessing, .faceCaptureUnderEye, .faceResult:
            return "Face"
        case .hairIntro, .hairCaptureFrontal, .hairCaptureCrown, .hairProcessing, .hairResult:
            return "Hair"
        case .compositionProcessing, .compositionResult:
            return "Composition"
        case .activityLevel, .sleepDuration, .sleepQuality, .stressLevel, .hydration:
            return "Lifestyle"
        case .dietType, .nutritionGoal, .calorieReveal:
            return "Nutrition"
        case .goalSelection:
            return "Goals"
        case .privacySummary, .consentToggles, .completion:
            return "Privacy"
        }
    }
}

// MARK: - ViewModel

@MainActor
class WHOOPOnboardingViewModel: ObservableObject {

    // MARK: - Navigation State

    @Published var currentScreenIndex: Int = 0
    @Published var isTransitioning = false

    let totalScreens = OnboardingScreenIndex.allCases.count

    var currentScreen: OnboardingScreenIndex {
        OnboardingScreenIndex(rawValue: currentScreenIndex) ?? .welcome
    }

    var progress: Double {
        Double(currentScreenIndex + 1) / Double(totalScreens)
    }

    // MARK: - Auto-Advance Timer

    private var autoAdvanceTimer: Timer?

    // MARK: - Identity Data (Phase 1)

    @Published var selectedAge: Int = 25
    @Published var biologicalSex: BiologicalSexOption = .male
    @Published var selectedHeight: Int = 170  // cm
    @Published var selectedWeight: Double = 70.0  // kg

    // MARK: - Body Appearance (Phase 2)

    @Published var bodyType: BodyTypeAssessment = .average

    // MARK: - Skin Tone (Phase 3)

    @Published var skinForearmData: Data?
    @Published var skinLegData: Data?
    @Published var skinAbdomenData: Data?
    @Published var determinedSkinType: FitzpatrickSkinType?
    @Published var skinAnalysisProgress: Double = 0

    // MARK: - Face (Phase 4)

    @Published var faceFullData: Data?
    @Published var faceUnderEyeData: Data?
    @Published var faceAnalysisProgress: Double = 0

    // MARK: - Hair (Phase 5)

    @Published var hairFrontalData: Data?
    @Published var hairCrownData: Data?
    @Published var hairDensityScore: Double?
    @Published var thinningIndicator: ThinningIndicator?
    @Published var hairAnalysisProgress: Double = 0

    // MARK: - Body Composition (Phase 6)

    @Published var bodyFatCategory: BodyFatCategory = .moderate
    @Published var muscleSignal: MuscleSignal = .medium
    @Published var waterRetention: WaterRetentionLevel = .moderate
    @Published var compositionConfidence: Double = 0
    @Published var compositionProgress: Double = 0

    // MARK: - Lifestyle (Phase 7)

    @Published var activityLevel: ActivityLevel = .lightlyActive
    @Published var sleepDuration: Double = 7.5
    @Published var sleepQuality: Int = 3
    @Published var stressLevel: Int = 3
    @Published var hydration: HydrationLevel = .medium

    // MARK: - Nutrition (Phase 8)

    @Published var dietType: DietType = .nonVegetarian
    @Published var nutritionGoal: NutritionGoal = .maintenance
    @Published var calculatedBMR: Double?
    @Published var calculatedTDEE: Double?
    @Published var targetCalories: Double?

    // MARK: - Goals (Phase 9)

    @Published var selectedGoals: Set<PrimaryGoal> = []

    // MARK: - Consent (Phase 10)

    @Published var cameraConsent = false
    @Published var healthDataConsent = false
    @Published var aiInsightsConsent = false
    @Published var secureProcessingAck = false
    @Published var termsAccepted = false
    @Published var privacyAccepted = false

    // MARK: - Loading & Error States

    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    // MARK: - Dependencies

    private let biometricAnalyzer = BiometricAnalyzer.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var allConsentsGranted: Bool {
        cameraConsent && healthDataConsent && aiInsightsConsent &&
        secureProcessingAck && termsAccepted && privacyAccepted
    }

    var bmi: Double {
        let heightM = Double(selectedHeight) / 100
        return selectedWeight / (heightM * heightM)
    }

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Auto-calculate metabolic rates when relevant values change
        Publishers.CombineLatest4($selectedAge, $biologicalSex, $selectedHeight, $selectedWeight)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
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

    func nextScreen() {
        guard currentScreenIndex < totalScreens - 1 else {
            completeOnboarding()
            return
        }

        guard !isTransitioning else { return }

        cancelAutoAdvanceTimer()
        HapticsManager.shared.playOnboardingStep()

        isTransitioning = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreenIndex += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isTransitioning = false
            self?.handleScreenEntered()
        }
    }

    func previousScreen() {
        guard currentScreenIndex > 0, !isTransitioning else { return }

        cancelAutoAdvanceTimer()
        HapticsManager.shared.playNavigationPop()

        isTransitioning = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreenIndex -= 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isTransitioning = false
        }
    }

    func skipToScreen(_ index: Int) {
        guard index >= 0, index < totalScreens, !isTransitioning else { return }

        cancelAutoAdvanceTimer()
        HapticsManager.shared.playImpact(.light)

        isTransitioning = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreenIndex = index
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isTransitioning = false
            self?.handleScreenEntered()
        }
    }

    private func handleScreenEntered() {
        let screen = currentScreen

        // Handle auto-advance screens
        if screen.isAutoAdvance {
            scheduleAutoAdvance(delay: screen.autoAdvanceDelay)
        }

        // Handle processing screens
        switch screen {
        case .compositionProcessing:
            analyzeBodyComposition()
        case .skinProcessingForearm, .skinProcessingLeg:
            simulateSkinProcessing()
        case .faceProcessing:
            simulateFaceProcessing()
        case .hairProcessing:
            analyzeHairline()
        case .calorieReveal:
            calculateMetabolicRates()
        default:
            break
        }
    }

    private func scheduleAutoAdvance(delay: TimeInterval) {
        cancelAutoAdvanceTimer()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.nextScreen()
            }
        }
    }

    private func cancelAutoAdvanceTimer() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }

    // MARK: - Skin Analysis

    func handleSkinCapture(_ data: Data, region: SkinCaptureRegion) {
        switch region {
        case .innerForearm:
            skinForearmData = data
        case .lowerLeg:
            skinLegData = data
        case .abdomen:
            skinAbdomenData = data
        }

        // Analyze when all captured
        if skinForearmData != nil && skinLegData != nil && skinAbdomenData != nil {
            Task {
                await analyzeSkinTone()
            }
        }
    }

    private func analyzeSkinTone() async {
        guard let forearm = skinForearmData,
              let leg = skinLegData,
              let abdomen = skinAbdomenData else { return }

        let capture = SkinToneCapture(
            innerForearmImage: forearm,
            lowerLegImage: leg,
            abdomenImage: abdomen
        )

        let result = await biometricAnalyzer.analyzeSkinTone(from: capture)
        determinedSkinType = result.skinType
    }

    private func simulateSkinProcessing() {
        skinAnalysisProgress = 0
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    skinAnalysisProgress = Double(i) / 10.0
                }
            }
        }
    }

    // MARK: - Face Analysis

    func handleFaceCapture(_ data: Data, type: FaceCaptureType) {
        switch type {
        case .fullFace:
            faceFullData = data
        case .underEye:
            faceUnderEyeData = data
        }
    }

    private func simulateFaceProcessing() {
        faceAnalysisProgress = 0
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 180_000_000)
                await MainActor.run {
                    faceAnalysisProgress = Double(i) / 10.0
                }
            }
        }
    }

    // MARK: - Hair Analysis

    func handleHairCapture(_ data: Data, type: HairCaptureType) {
        switch type {
        case .frontalHairline:
            hairFrontalData = data
        case .crownScalp:
            hairCrownData = data
        }
    }

    private func analyzeHairline() {
        guard hairFrontalData != nil && hairCrownData != nil else { return }

        hairAnalysisProgress = 0
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    hairAnalysisProgress = Double(i) / 10.0
                }
            }

            // Simulate result
            await MainActor.run {
                hairDensityScore = Double.random(in: 0.6...0.95)
                thinningIndicator = .none
            }
        }
    }

    // MARK: - Body Composition Analysis

    private func analyzeBodyComposition() {
        compositionProgress = 0

        Task {
            for i in 1...15 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    compositionProgress = Double(i) / 15.0
                }
            }

            let result = await biometricAnalyzer.estimateBodyComposition(
                age: selectedAge,
                sex: biologicalSex,
                heightCm: Double(selectedHeight),
                weightKg: selectedWeight,
                skinType: determinedSkinType,
                hairDensity: hairDensityScore
            )

            await MainActor.run {
                bodyFatCategory = result.bodyFatCategory
                muscleSignal = result.muscleSignal
                waterRetention = result.waterRetentionIndicator
                compositionConfidence = result.confidenceLevel
            }
        }
    }

    // MARK: - Metabolic Calculations

    func calculateMetabolicRates() {
        let height = Double(selectedHeight)
        let weight = selectedWeight
        let age = selectedAge

        // Mifflin-St Jeor Equation
        let bmr: Double
        switch biologicalSex {
        case .male:
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        case .preferNotToSay:
            let maleBmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
            let femaleBmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
            bmr = (maleBmr + femaleBmr) / 2
        }

        calculatedBMR = bmr

        // TDEE with activity multiplier
        var tdee = bmr * activityLevel.activityMultiplier

        // Adjustments based on biometric signals
        if let hairDensity = hairDensityScore {
            let densityAdjustment = (hairDensity - 0.5) * 0.02
            tdee *= (1 + densityAdjustment)
        }

        if let skinType = determinedSkinType {
            switch skinType.uvSensitivity {
            case .high:
                tdee *= 0.99
            case .moderate:
                break
            case .low:
                tdee *= 1.01
            }
        }

        calculatedTDEE = tdee
        calculateTargetCalories()
    }

    private func calculateTargetCalories() {
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

    // MARK: - Consent

    func grantAllConsents() {
        cameraConsent = true
        healthDataConsent = true
        aiInsightsConsent = true
        secureProcessingAck = true
        termsAccepted = true
        privacyAccepted = true
        HapticsManager.shared.playSuccess()
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() {
        isLoading = true

        Task {
            // Build onboarding data
            let onboardingData = buildOnboardingData()
            let baseline = await generatePhysiologicalBaseline()

            // Save to persistence
            await saveOnboardingData(onboardingData, baseline: baseline)

            await MainActor.run {
                isLoading = false
                AppState.shared.isOnboardingComplete = true
                HapticsManager.shared.playStreakCelebration()
            }
        }
    }

    private func buildOnboardingData() -> OnboardingData {
        var data = OnboardingData()

        data.coreProfile = UserCoreProfile(
            age: selectedAge,
            biologicalSex: biologicalSex,
            heightCm: Double(selectedHeight),
            weightKg: selectedWeight
        )

        data.bodyAppearance = BodyAppearanceBaseline(
            bodyColor: nil,
            bodyType: bodyType
        )

        data.skinToneCapture = SkinToneCapture(
            innerForearmImage: skinForearmData,
            lowerLegImage: skinLegData,
            abdomenImage: skinAbdomenData,
            capturedAt: Date(),
            determinedType: determinedSkinType
        )

        data.faceCapture = FaceCapture(
            fullFaceImage: faceFullData,
            underEyeImage: faceUnderEyeData,
            capturedAt: Date()
        )

        data.hairlineCapture = HairlineScalpCapture(
            frontalHairlineImage: hairFrontalData,
            crownScalpImage: hairCrownData,
            capturedAt: Date(),
            hairDensityScore: hairDensityScore,
            earlyThinningIndicator: thinningIndicator
        )

        data.bodyComposition = BodyCompositionEstimate(
            bodyFatCategory: bodyFatCategory,
            muscleSignal: muscleSignal,
            waterRetentionIndicator: waterRetention,
            confidenceLevel: compositionConfidence
        )

        data.lifestyle = LifestyleProfile(
            activityLevel: activityLevel,
            averageSleepDuration: sleepDuration,
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            sunlightExposure: 30,
            hydrationLevel: hydration,
            caffeineIntake: .moderate,
            alcoholIntake: .occasional
        )

        data.nutrition = NutritionProfile(
            dietType: dietType,
            mealsPerDay: 3,
            nutritionGoal: nutritionGoal,
            bmr: calculatedBMR,
            tdee: calculatedTDEE,
            targetCalories: targetCalories
        )

        data.primaryGoals = Array(selectedGoals)

        data.consent = ConsentRecord(
            cameraAnalysisConsent: cameraConsent,
            healthDataProcessingConsent: healthDataConsent,
            aiInsightsConsent: aiInsightsConsent,
            secureProcessingAcknowledged: secureProcessingAck,
            termsAccepted: termsAccepted,
            privacyPolicyAccepted: privacyAccepted,
            consentDate: Date()
        )

        data.startedAt = Date()
        data.completedAt = Date()

        return data
    }

    private func generatePhysiologicalBaseline() async -> PhysiologicalBaseline {
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
            bodyComposition: BodyCompositionEstimate(
                bodyFatCategory: bodyFatCategory,
                muscleSignal: muscleSignal,
                waterRetentionIndicator: waterRetention,
                confidenceLevel: compositionConfidence
            ),
            hairDensityScore: hairDensityScore,
            scalpHealth: nil,
            goalWeights: combinedWeights,
            primaryGoals: Array(selectedGoals),
            baselineStartDate: Date(),
            expectedCalibrationEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            createdAt: Date(),
            version: "1.0"
        )
    }

    private func saveOnboardingData(_ data: OnboardingData, baseline: PhysiologicalBaseline) async {
        if let encodedOnboarding = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encodedOnboarding, forKey: "onboardingData")
        }

        if let encodedBaseline = try? JSONEncoder().encode(baseline) {
            UserDefaults.standard.set(encodedBaseline, forKey: "physiologicalBaseline")
        }
    }
}
