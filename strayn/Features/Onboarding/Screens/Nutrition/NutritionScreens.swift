//
//  NutritionScreens.swift
//  strayn
//
//  Nutrition input screens - diet type, goal, calorie reveal.
//

import SwiftUI

// MARK: - Diet Type Screen

struct DietTypeScreen: View {
    @Binding var selection: DietType
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Diet type",
            subtitle: "What best describes your eating habits?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(DietType.allCases) { diet in
                            WHOOPSelectionCard(
                                item: diet,
                                isSelected: selection == diet,
                                icon: diet.icon,
                                title: diet.rawValue,
                                subtitle: diet.description,
                                accentColor: StraynColors.biologicalAge,
                                onSelect: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selection = diet
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Nutrition Goal Screen

struct NutritionGoalScreen: View {
    @Binding var selection: NutritionGoal
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Nutrition goal",
            subtitle: "What's your primary nutrition objective?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(NutritionGoal.allCases) { goal in
                            WHOOPSelectionCard(
                                item: goal,
                                isSelected: selection == goal,
                                icon: goal.icon,
                                title: goal.rawValue,
                                subtitle: goal.description,
                                accentColor: goalColor(for: goal),
                                onSelect: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selection = goal
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private func goalColor(for goal: NutritionGoal) -> Color {
        switch goal {
        case .fatLoss: return StraynColors.zoneRed
        case .muscleGain: return StraynColors.strain
        case .longevity: return StraynColors.recovery
        case .maintenance: return StraynColors.accentPrimary
        }
    }
}

// MARK: - Calorie Reveal Screen

struct CalorieRevealScreen: View {
    let bmr: Double?
    let tdee: Double?
    let targetCalories: Double?
    let nutritionGoal: NutritionGoal
    let onContinue: () -> Void

    @State private var showBMR = false
    @State private var showTDEE = false
    @State private var showTarget = false
    @State private var animatedBMR: Double = 0
    @State private var animatedTDEE: Double = 0
    @State private var animatedTarget: Double = 0

    var body: some View {
        OnboardingResultScreen(
            title: "Your Calorie Profile",
            subtitle: "Personalized based on your data",
            onContinue: onContinue
        ) {
            VStack(spacing: 24) {
                // BMR Card
                calorieCard(
                    title: "Basal Metabolic Rate",
                    value: Int(animatedBMR),
                    subtitle: "Calories burned at rest",
                    icon: "flame.fill",
                    color: StraynColors.zoneYellow,
                    visible: showBMR
                )

                // TDEE Card
                calorieCard(
                    title: "Daily Energy Expenditure",
                    value: Int(animatedTDEE),
                    subtitle: "Total daily calories burned",
                    icon: "bolt.fill",
                    color: StraynColors.strain,
                    visible: showTDEE
                )

                // Target Card
                calorieCard(
                    title: "Target Intake",
                    value: Int(animatedTarget),
                    subtitle: "For \(nutritionGoal.rawValue.lowercased())",
                    icon: "target",
                    color: StraynColors.recovery,
                    visible: showTarget,
                    isHighlighted: true
                )
            }
        }
        .onAppear {
            animateReveal()
        }
    }

    private func calorieCard(
        title: String,
        value: Int,
        subtitle: String,
        icon: String,
        color: Color,
        visible: Bool,
        isHighlighted: Bool = false
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("kcal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StraynColors.textTertiary)
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(StraynColors.textMuted)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? color.opacity(0.1) : StraynColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? color.opacity(0.3) : StraynColors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(color: isHighlighted ? color.opacity(0.2) : .clear, radius: 10)
        .scaleEffect(visible ? 1 : 0.9)
        .opacity(visible ? 1 : 0)
    }

    private func animateReveal() {
        // BMR reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showBMR = true
            }
            animateValue(to: bmr ?? 1500) { animatedBMR = $0 }
            HapticsManager.shared.playImpact(.light)
        }

        // TDEE reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showTDEE = true
            }
            animateValue(to: tdee ?? 2000) { animatedTDEE = $0 }
            HapticsManager.shared.playImpact(.light)
        }

        // Target reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showTarget = true
            }
            animateValue(to: targetCalories ?? 2000) { animatedTarget = $0 }
            HapticsManager.shared.playScoreReveal()
        }
    }

    private func animateValue(to target: Double, update: @escaping (Double) -> Void) {
        let steps = 30
        let stepDuration: TimeInterval = 0.03
        let increment = target / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                update(min(increment * Double(i), target))
            }
        }
    }
}

// MARK: - Previews

#Preview("Diet Type") {
    DietTypeScreen(selection: .constant(.nonVegetarian), onContinue: {}, onBack: {})
}

#Preview("Nutrition Goal") {
    NutritionGoalScreen(selection: .constant(.maintenance), onContinue: {}, onBack: {})
}

#Preview("Calorie Reveal") {
    CalorieRevealScreen(
        bmr: 1650,
        tdee: 2100,
        targetCalories: 2100,
        nutritionGoal: .maintenance,
        onContinue: {}
    )
}
