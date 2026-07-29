//
//  LifestyleScreens.swift
//  strayn
//
//  Lifestyle input screens - activity, sleep, stress, hydration.
//

import SwiftUI

// MARK: - Activity Level Screen

struct ActivityLevelScreen: View {
    @Binding var selection: ActivityLevel
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Activity level",
            subtitle: "How active are you on a typical week?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(ActivityLevel.allCases) { level in
                            WHOOPSelectionCard(
                                item: level,
                                isSelected: selection == level,
                                icon: level.icon,
                                title: level.rawValue,
                                subtitle: level.description,
                                onSelect: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selection = level
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

// MARK: - Sleep Duration Screen

struct SleepDurationScreen: View {
    @Binding var hours: Double
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Sleep duration",
            subtitle: "How many hours do you typically sleep?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                WHOOPSleepSlider(hours: $hours, accentColor: StraynColors.sleep)
                    .padding(.horizontal, 32)

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Sleep Quality Screen

struct SleepQualityScreen: View {
    @Binding var quality: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Sleep quality",
            subtitle: "How would you rate your typical sleep?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                WHOOPStarRating(
                    rating: $quality,
                    maxRating: 5,
                    label: nil,
                    accentColor: StraynColors.sleep
                )

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Stress Level Screen

struct StressLevelScreen: View {
    @Binding var level: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    private let stressLevels: [WHOOPLevelRating.LevelOption] = [
        .init(id: 1, label: "Very Low", color: StraynColors.zoneGreen),
        .init(id: 2, label: "Low", color: StraynColors.zoneGreen),
        .init(id: 3, label: "Moderate", color: StraynColors.zoneYellow),
        .init(id: 4, label: "High", color: StraynColors.zoneYellow),
        .init(id: 5, label: "Very High", color: StraynColors.zoneRed)
    ]

    var body: some View {
        OnboardingScreenContainer(
            title: "Stress level",
            subtitle: "How stressed do you typically feel?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer()

                // Stress visualization
                VStack(spacing: 24) {
                    Image(systemName: stressIcon)
                        .font(.system(size: 60))
                        .foregroundColor(stressColor)
                        .symbolEffect(.pulse, options: .repeating)

                    WHOOPLevelRating(
                        level: $level,
                        levels: stressLevels
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, 24)

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private var stressIcon: String {
        switch level {
        case 1, 2: return "brain.head.profile"
        case 3: return "brain"
        case 4, 5: return "brain.filled.head.profile"
        default: return "brain"
        }
    }

    private var stressColor: Color {
        switch level {
        case 1, 2: return StraynColors.zoneGreen
        case 3: return StraynColors.zoneYellow
        case 4, 5: return StraynColors.zoneRed
        default: return StraynColors.zoneYellow
        }
    }
}

// MARK: - Hydration Screen

struct HydrationScreen: View {
    @Binding var level: HydrationLevel
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        OnboardingScreenContainer(
            title: "Daily hydration",
            subtitle: "How much water do you typically drink?",
            showBackButton: true,
            onBack: onBack
        ) {
            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                // Water drop animation
                ZStack {
                    ForEach(0..<dropCount, id: \.self) { index in
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(StraynColors.hrv.opacity(0.8))
                            .offset(x: dropOffset(for: index))
                    }
                }
                .frame(height: 60)
                .padding(.bottom, 32)

                // Selection cards
                VStack(spacing: 12) {
                    ForEach(HydrationLevel.allCases) { hydrationLevel in
                        WHOOPSelectionCard(
                            item: hydrationLevel,
                            isSelected: level == hydrationLevel,
                            icon: hydrationLevel.icon,
                            title: hydrationLevel.rawValue,
                            subtitle: hydrationLevel.description,
                            accentColor: StraynColors.hrv,
                            onSelect: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    level = hydrationLevel
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                WHOOPContinueButton(action: onContinue)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private var dropCount: Int {
        switch level {
        case .low: return 2
        case .medium: return 4
        case .high: return 6
        }
    }

    private func dropOffset(for index: Int) -> CGFloat {
        let spacing: CGFloat = 35
        let totalWidth = CGFloat(dropCount - 1) * spacing
        return CGFloat(index) * spacing - totalWidth / 2
    }
}

// MARK: - Previews

#Preview("Activity") {
    ActivityLevelScreen(selection: .constant(.active), onContinue: {}, onBack: {})
}

#Preview("Sleep Duration") {
    SleepDurationScreen(hours: .constant(7.5), onContinue: {}, onBack: {})
}

#Preview("Sleep Quality") {
    SleepQualityScreen(quality: .constant(4), onContinue: {}, onBack: {})
}

#Preview("Stress") {
    StressLevelScreen(level: .constant(3), onContinue: {}, onBack: {})
}

#Preview("Hydration") {
    HydrationScreen(level: .constant(.medium), onContinue: {}, onBack: {})
}
