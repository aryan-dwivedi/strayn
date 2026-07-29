//
//  ComprehensiveOnboardingView.swift
//  strayn
//
//  Comprehensive 10-step biometric onboarding with input collection
//

import SwiftUI
import AVFoundation

struct ComprehensiveOnboardingView: View {
    @Binding var isFirstRun: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showCameraPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                // Step content
                ScrollView {
                    VStack(spacing: 30) {
                        stepContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
        }
        .navigationBarHidden(true)
        .alert("Camera Permission Required", isPresented: $showCameraPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Camera access is required for biometric analysis. Please enable in Settings.")
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(viewModel.currentStep.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
            }
            
            ProgressView(value: Double(viewModel.currentStep.rawValue + 1), total: Double(OnboardingStep.allCases.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .identityProfile:
            identityProfileStep
        case .bodyAppearance:
            bodyAppearanceStep
        case .skinTone:
            skinToneStep
        case .facePhoto:
            facePhotoStep
        case .hairlineScalp:
            hairlineScalpStep
        case .bodyComposition:
            bodyCompositionStep
        case .lifestyle:
            lifestyleStep
        case .nutrition:
            nutritionStep
        case .goals:
            goalsStep
        case .consent:
            consentStep
        }
    }
    
    // MARK: - Identity Profile Step
    private var identityProfileStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Personal Profile",
                subtitle: "Help us personalize your health journey"
            )
            
            VStack(spacing: 20) {
                // Age input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("Enter your age", text: $viewModel.age)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // Biological sex
                VStack(alignment: .leading, spacing: 12) {
                    Text("Biological Sex")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        ForEach([BiologicalSexOption.male, BiologicalSexOption.female], id: \.self) { option in
                            Button(action: {
                                viewModel.biologicalSex = option
                            }) {
                                HStack {
                                    Image(systemName: viewModel.biologicalSex == option ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.biologicalSex == option ? .blue : .gray)
                                    Text(option.rawValue.capitalized)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.biologicalSex == option ? Color.blue : Color.gray, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("Enter height in cm", text: $viewModel.heightCm)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("Enter weight in kg", text: $viewModel.weightKg)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    // MARK: - Body Appearance Step
    private var bodyAppearanceStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Body Assessment",
                subtitle: "Tell us about your body composition"
            )
            
            VStack(spacing: 20) {
                // Body type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Body Type")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach([BodyTypeAssessment.lean, BodyTypeAssessment.average, BodyTypeAssessment.athletic, BodyTypeAssessment.curvy], id: \.self) { type in
                            Button(action: {
                                viewModel.bodyType = type
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: bodyTypeIcon(for: type))
                                        .font(.title2)
                                        .foregroundColor(viewModel.bodyType == type ? .blue : .gray)
                                    Text(type.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.bodyType == type ? Color.blue : Color.gray, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Skin Tone Step
    private var skinToneStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Skin Tone Analysis",
                subtitle: "Select your Fitzpatrick skin type"
            )
            
            VStack(spacing: 16) {
                ForEach([FitzpatrickSkinType.typeI, FitzpatrickSkinType.typeII, FitzpatrickSkinType.typeIII, FitzpatrickSkinType.typeIV, FitzpatrickSkinType.typeV, FitzpatrickSkinType.typeVI], id: \.self) { type in
                    Button(action: {
                        viewModel.fitzpatrickType = type
                    }) {
                        HStack {
                            Circle()
                                .fill(skinTypeColor(for: type))
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Type \(type.rawValue)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(skinTypeDescription(for: type))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: viewModel.fitzpatrickType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.fitzpatrickType == type ? .blue : .gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.fitzpatrickType == type ? Color.blue : Color.gray, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Face Photo Step
    private var facePhotoStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Face Analysis",
                subtitle: "Take a photo for facial aging analysis"
            )
            
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            Text("Position your face in the frame")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Ensure good lighting and look directly at the camera")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    )
                
                Button(action: {
                    requestCameraPermission()
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Hairline/Scalp Step
    private var hairlineScalpStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Hair Analysis",
                subtitle: "Capture your hairline and scalp condition"
            )
            
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("Capture hairline and scalp")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Pull back hair to show hairline clearly")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    )
                
                Button(action: {
                    requestCameraPermission()
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Hair Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Body Composition Step
    private var bodyCompositionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Body Composition",
                subtitle: "Additional body measurements"
            )
            
            VStack(spacing: 20) {
                // Body fat percentage (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body Fat % (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("If known, enter body fat percentage", text: .constant(""))
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                // Activity level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Level")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        ForEach(["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"], id: \.self) { level in
                            Button(action: {
                                // Handle activity level selection
                            }) {
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                    Text(level)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Lifestyle Step
    private var lifestyleStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Lifestyle Factors",
                subtitle: "Tell us about your daily habits"
            )
            
            VStack(spacing: 20) {
                // Sleep hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average Sleep Hours")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("Hours per night", text: .constant(""))
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                // Stress level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stress Level")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                // Handle stress level
                            }) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(level)")
                                            .foregroundColor(.white)
                                            .font(.caption.weight(.medium))
                                    )
                            }
                        }
                    }
                    Text("1 = Low, 5 = High")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Nutrition Step
    private var nutritionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Nutrition Habits",
                subtitle: "Your dietary preferences and habits"
            )
            
            VStack(spacing: 20) {
                // Diet type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diet Type")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(["Standard", "Vegetarian", "Vegan", "Keto", "Mediterranean", "Other"], id: \.self) { diet in
                            Button(action: {
                                // Handle diet selection
                            }) {
                                Text(diet)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Step
    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Health Goals",
                subtitle: "What would you like to focus on?"
            )
            
            VStack(spacing: 16) {
                ForEach(["Improve Recovery", "Enhance Performance", "Increase Longevity", "Better Sleep", "Reduce Stress", "Weight Management"], id: \.self) { goal in
                    Button(action: {
                        // Handle goal selection
                    }) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            Text(goal)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Consent Step
    private var consentStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView(
                title: "Privacy & Consent",
                subtitle: "Your data security and privacy"
            )
            
            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Usage Agreement")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("""
                        • Your biometric data will be processed locally on your device
                        • Health data is encrypted and stored securely
                        • Photos are analyzed using AI and then deleted
                        • You can delete your data at any time
                        • We do not share personal data with third parties
                        """)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .frame(maxHeight: 300)
                
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("I Agree & Complete Setup")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep.rawValue > 0 {
                Button(action: previousStep) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            if viewModel.currentStep != .consent {
                Button(action: nextStep) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }
    
    // MARK: - Helper Views
    private func headerView(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Helper Functions
    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .identityProfile:
            return !viewModel.age.isEmpty && !viewModel.heightCm.isEmpty && !viewModel.weightKg.isEmpty
        case .skinTone:
            return true // Fitzpatrick type has default
        default:
            return true
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let nextStep = OnboardingStep(rawValue: viewModel.currentStep.rawValue + 1) {
                viewModel.currentStep = nextStep
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let previousStep = OnboardingStep(rawValue: viewModel.currentStep.rawValue - 1) {
                viewModel.currentStep = previousStep
            }
        }
    }
    
    private func completeOnboarding() {
        isFirstRun = false
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    // Handle camera access granted
                } else {
                    showCameraPermissionAlert = true
                }
            }
        }
    }
    
    private func bodyTypeIcon(for type: BodyTypeAssessment) -> String {
        switch type {
        case .lean: return "figure.stand"
        case .average: return "figure.walk"
        case .athletic: return "figure.strengthtraining.traditional"
        case .curvy: return "figure.dress.line.vertical.figure"
        case .overweight: return "figure.arms.open"
        }
    }
    
    private func skinTypeColor(for type: FitzpatrickSkinType) -> Color {
        switch type {
        case .typeI: return .init(red: 0.96, green: 0.87, blue: 0.82)
        case .typeII: return .init(red: 0.91, green: 0.78, blue: 0.69)
        case .typeIII: return .init(red: 0.83, green: 0.68, blue: 0.55)
        case .typeIV: return .init(red: 0.74, green: 0.56, blue: 0.41)
        case .typeV: return .init(red: 0.58, green: 0.42, blue: 0.31)
        case .typeVI: return .init(red: 0.41, green: 0.28, blue: 0.20)
        }
    }
    
    private func skinTypeDescription(for type: FitzpatrickSkinType) -> String {
        switch type {
        case .typeI: return "Always burns, never tans"
        case .typeII: return "Burns easily, tans minimally"
        case .typeIII: return "Burns moderately, tans gradually"
        case .typeIV: return "Burns minimally, tans well"
        case .typeV: return "Rarely burns, tans profusely"
        case .typeVI: return "Never burns, deeply pigmented"
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}