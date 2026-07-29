//
//  OnboardingComponents.swift
//  strayn
//
//  Reusable UI components for the enhanced onboarding experience.
//

import SwiftUI

// MARK: - Number Scroll View

struct NumberScrollView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        HStack(spacing: StraynSpacing.lg) {
            Picker("", selection: $value) {
                ForEach(Array(range), id: \.self) { number in
                    Text("\(number)")
                        .font(StraynTypography.displayMedium())
                        .foregroundColor(.white)
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 120)
            .compositingGroup()
            .clipped()
            
            Text(label)
                .font(StraynTypography.headlineLarge())
                .foregroundColor(StraynColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Decimal Number Scroll View

struct DecimalNumberScrollView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    
    private var values: [Double] {
        stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
    }
    
    var body: some View {
        HStack(spacing: StraynSpacing.lg) {
            Picker("", selection: $value) {
                ForEach(values, id: \.self) { number in
                    Text(String(format: "%.1f", number))
                        .font(StraynTypography.displayMedium())
                        .foregroundColor(.white)
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 120)
            .compositingGroup()
            .clipped()
            
            Text(label)
                .font(StraynTypography.headlineLarge())
                .foregroundColor(StraynColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Gender Option Card

struct GenderOptionCard: View {
    let option: BiologicalSexOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: StraynSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                            ? LinearGradient(colors: [StraynColors.accentPrimary, StraynColors.zoneGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [StraynColors.surfaceSecondary, StraynColors.surfaceSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: genderIcon(for: option))
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isSelected ? .black : StraynColors.textSecondary)
                }
                
                Text(option.rawValue)
                    .font(StraynTypography.labelLarge(.medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
            }
            .padding(.vertical, StraynSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? StraynColors.accentPrimary : StraynColors.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func genderIcon(for option: BiologicalSexOption) -> String {
        switch option {
        case .male: return "figure.dress.line.vertical.figure"
        case .female: return "figure.dress.line.vertical.figure"
        case .preferNotToSay: return "person.fill.questionmark"
        }
    }
}

// MARK: - Onboarding Text Input

struct OnboardingTextInput: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(StraynTypography.bodyLarge)
            .foregroundColor(.white)
            .padding(.horizontal, StraynSpacing.lg)
            .padding(.vertical, StraynSpacing.md)
            .lineLimit(3...6)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(StraynColors.surfaceSecondary.opacity(0.3))
                    .stroke(StraynColors.surfaceSecondary, lineWidth: 1)
            )
            .padding(.horizontal, StraynSpacing.xl)
    }
}

// MARK: - Fitzpatrick Scale View

struct FitzpatrickScaleView: View {
    @Binding var selectedType: FitzpatrickSkinType
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Text("SELECT YOUR SKIN TYPE")
                .font(StraynTypography.labelSmall(.bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: StraynSpacing.md) {
                ForEach(FitzpatrickSkinType.allCases, id: \.self) { type in
                    FitzpatrickTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                        onSelection()
                    }
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
        }
    }
}

struct FitzpatrickTypeCard: View {
    let type: FitzpatrickSkinType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: StraynSpacing.sm) {
                Circle()
                    .fill(type.displayColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? StraynColors.accentPrimary : Color.clear,
                                lineWidth: 3
                            )
                    )
                
                Text("Type \(type.typeNumber)")
                    .font(StraynTypography.labelMedium(.medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
            }
            .padding(.vertical, StraynSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.md)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Face Capture Preview View

struct FaceCapturePreviewView: View {
    let hasImage: Bool
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Button(action: onCapture) {
                ZStack {
                    RoundedRectangle(cornerRadius: StraynRadius.xl)
                        .fill(
                            hasImage 
                            ? LinearGradient(colors: [StraynColors.zoneGreen.opacity(0.3), StraynColors.zoneGreen.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [StraynColors.surfaceSecondary.opacity(0.3), StraynColors.surfaceSecondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .stroke(
                            hasImage ? StraynColors.zoneGreen : StraynColors.accentPrimary,
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 260)
                    
                    VStack(spacing: StraynSpacing.md) {
                        Image(systemName: hasImage ? "checkmark.circle.fill" : "camera.viewfinder")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(hasImage ? StraynColors.zoneGreen : StraynColors.accentPrimary)
                        
                        Text(hasImage ? "Photo Captured" : "Capture Face")
                            .font(StraynTypography.headlineSmall())
                            .foregroundColor(.white)
                        
                        if !hasImage {
                            Text("Position face in center")
                                .font(StraynTypography.bodyMedium)
                                .foregroundColor(StraynColors.textSecondary)
                        }
                    }
                }
            }
            .scaleEffect(hasImage ? 1.0 : 0.98)
            .animation(.spring(response: 0.4), value: hasImage)
        }
    }
}

// MARK: - Hair Capture Preview View

struct HairCapturePreviewView: View {
    let hasImage: Bool
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Button(action: onCapture) {
                ZStack {
                    RoundedRectangle(cornerRadius: StraynRadius.xl)
                        .fill(
                            hasImage 
                            ? LinearGradient(colors: [StraynColors.zoneGreen.opacity(0.3), StraynColors.zoneGreen.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [StraynColors.surfaceSecondary.opacity(0.3), StraynColors.surfaceSecondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .stroke(
                            hasImage ? StraynColors.zoneGreen : StraynColors.accentPrimary,
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 260)
                    
                    VStack(spacing: StraynSpacing.md) {
                        Image(systemName: hasImage ? "checkmark.circle.fill" : "scissors")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(hasImage ? StraynColors.zoneGreen : StraynColors.accentPrimary)
                        
                        Text(hasImage ? "Hair Captured" : "Capture Hair")
                            .font(StraynTypography.headlineSmall())
                            .foregroundColor(.white)
                        
                        if !hasImage {
                            Text("Include hairline & scalp")
                                .font(StraynTypography.bodyMedium)
                                .foregroundColor(StraynColors.textSecondary)
                        }
                    }
                }
            }
            .scaleEffect(hasImage ? 1.0 : 0.98)
            .animation(.spring(response: 0.4), value: hasImage)
        }
    }
}

// MARK: - Body Type Selector

struct BodyTypeSelector: View {
    @Binding var selectedType: BodyTypeAssessment
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Text("SELECT BODY TYPE")
                .font(StraynTypography.labelSmall(.bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: StraynSpacing.md) {
                ForEach(BodyTypeAssessment.allCases, id: \.self) { type in
                    BodyTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                        onSelection()
                    }
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
        }
    }
}

struct BodyTypeCard: View {
    let type: BodyTypeAssessment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: StraynSpacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? StraynColors.accentPrimary : StraynColors.textSecondary)
                
                Text(type.rawValue)
                    .font(StraynTypography.labelMedium(.medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, StraynSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? StraynColors.accentPrimary : StraynColors.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Activity Level Selector

struct ActivityLevelSelector: View {
    @Binding var selectedLevel: ActivityLevel
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Text("ACTIVITY LEVEL")
                .font(StraynTypography.labelSmall(.bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
            
            VStack(spacing: StraynSpacing.md) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelCard(
                        level: level,
                        isSelected: selectedLevel == level
                    ) {
                        selectedLevel = level
                        onSelection()
                    }
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
        }
    }
}

struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: StraynSpacing.md) {
                Image(systemName: level.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? StraynColors.accentPrimary : StraynColors.textSecondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(StraynTypography.labelLarge(.medium))
                        .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                    
                    Text(level.description)
                        .font(StraynTypography.bodySmall)
                        .foregroundColor(StraynColors.textTertiary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(StraynColors.accentPrimary)
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
            .padding(.vertical, StraynSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? StraynColors.accentPrimary : StraynColors.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Dietary Preference Selector

struct DietaryPreferenceSelector: View {
    @Binding var selectedPreferences: Set<DietaryPreference>
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Text("DIETARY PREFERENCES")
                .font(StraynTypography.labelSmall(.bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: StraynSpacing.md) {
                ForEach(DietaryPreference.allCases, id: \.self) { preference in
                    DietaryPreferenceCard(
                        preference: preference,
                        isSelected: selectedPreferences.contains(preference)
                    ) {
                        if selectedPreferences.contains(preference) {
                            selectedPreferences.remove(preference)
                        } else {
                            selectedPreferences.insert(preference)
                        }
                        onSelection()
                    }
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
        }
    }
}

struct DietaryPreferenceCard: View {
    let preference: DietaryPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: StraynSpacing.sm) {
                Image(systemName: preference.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? StraynColors.accentPrimary : StraynColors.textSecondary)
                
                Text(preference.rawValue)
                    .font(StraynTypography.labelMedium(.medium))
                    .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, StraynSpacing.md)
            .padding(.vertical, StraynSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.md)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? StraynColors.accentPrimary : StraynColors.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Primary Goal Selector

struct PrimaryGoalSelector: View {
    @Binding var selectedGoal: PrimaryGoal?
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.lg) {
            Text("PRIMARY GOAL")
                .font(StraynTypography.labelSmall(.bold))
                .tracking(2)
                .foregroundColor(StraynColors.textTertiary)
            
            VStack(spacing: StraynSpacing.md) {
                ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                    PrimaryGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                        onSelection()
                    }
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
        }
    }
}

struct PrimaryGoalCard: View {
    let goal: PrimaryGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: StraynSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color.opacity(0.3) : StraynColors.surfaceSecondary.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? goal.color : StraynColors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(StraynTypography.labelLarge(.medium))
                        .foregroundColor(isSelected ? .white : StraynColors.textSecondary)
                    
                    Text(goal.description)
                        .font(StraynTypography.bodySmall)
                        .foregroundColor(StraynColors.textTertiary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(StraynColors.accentPrimary)
                }
            }
            .padding(.horizontal, StraynSpacing.lg)
            .padding(.vertical, StraynSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.lg)
                    .fill(
                        isSelected 
                        ? StraynColors.surfaceSecondary.opacity(0.3)
                        : StraynColors.surfaceSecondary.opacity(0.1)
                    )
                    .stroke(
                        isSelected ? StraynColors.accentPrimary : StraynColors.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Consent Checklist View

struct ConsentChecklistView: View {
    @Binding var consents: [ConsentItem]
    let onSelection: () -> Void
    
    var body: some View {
        VStack(spacing: StraynSpacing.md) {
            ForEach(consents.indices, id: \.self) { index in
                ConsentChecklistItem(consent: $consents[index]) {
                    onSelection()
                }
            }
        }
        .padding(.horizontal, StraynSpacing.lg)
    }
}

struct ConsentChecklistItem: View {
    @Binding var consent: ConsentItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            consent.isAccepted.toggle()
            onToggle()
        }) {
            HStack(spacing: StraynSpacing.md) {
                Image(systemName: consent.isAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(consent.isAccepted ? StraynColors.accentPrimary : StraynColors.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(consent.title)
                        .font(StraynTypography.labelMedium(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(consent.description)
                        .font(StraynTypography.bodySmall)
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, StraynSpacing.md)
            .padding(.vertical, StraynSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: StraynRadius.md)
                    .fill(StraynColors.surfaceSecondary.opacity(0.1))
            )
        }
        .animation(.spring(response: 0.3), value: consent.isAccepted)
    }
}



extension FitzpatrickSkinType {
    var typeNumber: String {
        switch self {
        case .typeI: return "I"
        case .typeII: return "II"
        case .typeIII: return "III"
        case .typeIV: return "IV"
        case .typeV: return "V"
        case .typeVI: return "VI"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .typeI: return Color(red: 0.98, green: 0.94, blue: 0.89)
        case .typeII: return Color(red: 0.96, green: 0.90, blue: 0.82)
        case .typeIII: return Color(red: 0.91, green: 0.82, blue: 0.69)
        case .typeIV: return Color(red: 0.85, green: 0.71, blue: 0.55)
        case .typeV: return Color(red: 0.72, green: 0.55, blue: 0.41)
        case .typeVI: return Color(red: 0.54, green: 0.37, blue: 0.26)
        }
    }
}