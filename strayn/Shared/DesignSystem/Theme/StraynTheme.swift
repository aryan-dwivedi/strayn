//
//  StraynTheme.swift
//  strayn
//
//  Premium design system combining WHOOP aesthetics with modern iOS patterns.
//

import SwiftUI

// MARK: - Color Palette

struct StraynColors {
    // Primary Metric Colors
    static let recovery = Color(red: 0.0, green: 0.85, blue: 0.55)      // Vibrant green
    static let strain = Color(red: 0.2, green: 0.6, blue: 1.0)          // Electric blue
    static let sleep = Color(red: 0.6, green: 0.4, blue: 0.9)           // Soft purple
    static let biologicalAge = Color(red: 1.0, green: 0.6, blue: 0.2)   // Warm orange
    static let stress = Color(red: 1.0, green: 0.35, blue: 0.35)        // Alert red
    static let hrv = Color(red: 0.3, green: 0.8, blue: 0.7)             // Teal
    static let vo2Max = Color(red: 0.4, green: 0.7, blue: 1.0)          // Sky blue

    // Zone Colors
    static let zoneGreen = Color(red: 0.0, green: 0.85, blue: 0.55)
    static let zoneYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let zoneRed = Color(red: 1.0, green: 0.35, blue: 0.35)
    
    // Healthspan Colors
    static let healthspanPrimary = Color(red: 0.0, green: 0.8, blue: 0.6)      // Teal green
    static let healthspanSecondary = Color(red: 0.2, green: 0.6, blue: 0.9)   // Blue
    static let healthspanPositive = Color(red: 0.0, green: 0.9, blue: 0.6)     // Bright green
    static let healthspanNeutral = Color(red: 0.9, green: 0.75, blue: 0.3)     // Golden yellow
    static let healthspanNegative = Color(red: 0.85, green: 0.65, blue: 0.2)  // Amber/gold
    static let healthspanExcellent = Color(red: 0.0, green: 0.95, blue: 0.7)  // Bright teal
    static let healthspanGood = Color(red: 0.3, green: 0.85, blue: 0.6)       // Light green
    static let healthspanWarning = Color(red: 1.0, green: 0.75, blue: 0.3)    // Warning gold
    static let healthspanAlert = Color(red: 1.0, green: 0.5, blue: 0.3)       // Alert orange

    // Background & Surface
    static let background = Color.black
    static let surfacePrimary = Color.white.opacity(0.05)
    static let surfaceSecondary = Color.white.opacity(0.08)
    static let surfaceElevated = Color.white.opacity(0.12)

    // Border & Stroke
    static let borderSubtle = Color.white.opacity(0.05)
    static let borderMedium = Color.white.opacity(0.1)
    static let borderStrong = Color.white.opacity(0.2)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.3)

    // Accent
    static let accentPrimary = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let accentSecondary = Color(red: 0.6, green: 0.4, blue: 0.9)

    // Gradients
    static let recoveryGradient = LinearGradient(
        colors: [recovery, recovery.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let strainGradient = LinearGradient(
        colors: [strain, strain.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sleepGradient = LinearGradient(
        colors: [sleep, sleep.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumBackgroundGradient = LinearGradient(
        colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Ring Gradients (for WHOOP-style rings)
    static func ringGradient(for color: Color) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [color.opacity(0.8), color, color.opacity(0.8)]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}

// MARK: - Typography

struct StraynTypography {
    // Display - Large hero numbers
    static func displayLarge(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 64, weight: weight, design: .rounded)
    }

    static func displayMedium(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 48, weight: weight, design: .rounded)
    }

    static func displaySmall(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 36, weight: weight, design: .rounded)
    }

    // Headlines
    static func headlineLarge(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 28, weight: weight, design: .rounded)
    }

    static func headlineMedium(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 22, weight: weight, design: .rounded)
    }

    static func headlineSmall(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 18, weight: weight, design: .rounded)
    }

    // Body
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)

    // Labels
    static func labelLarge(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 14, weight: weight)
    }

    static func labelMedium(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 12, weight: weight)
    }

    static func labelSmall(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 10, weight: weight)
    }

    // Metric Labels (with tracking)
    static let metricLabel = Font.system(size: 10, weight: .black)
    static let metricLabelTracking: CGFloat = 2

    // Monospaced for numbers
    static func monospacedDigits(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Spacing

struct StraynSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40
    static let massive: CGFloat = 48
}

// MARK: - Corner Radius

struct StraynRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let full: CGFloat = 100
}

// MARK: - Shadows

struct StraynShadows {
    static func glow(color: Color, radius: CGFloat = 20) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 5)
    }

    static func cardShadow() -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    static func elevatedShadow() -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Animation Presets

struct StraynAnimations {
    // Spring animations
    static let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springMedium = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let springGentle = Animation.spring(response: 0.8, dampingFraction: 0.8)
    static let springSlow = Animation.spring(response: 1.2, dampingFraction: 0.85)

    // Score reveal animation
    static let scoreReveal = Animation.spring(response: 1.5, dampingFraction: 0.8)

    // Ease animations
    static let easeQuick = Animation.easeOut(duration: 0.2)
    static let easeMedium = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.5)

    // Delayed animations
    static func delayed(_ delay: Double) -> Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.75).delay(delay)
    }

    // Stagger helper
    static func staggerDelay(index: Int, baseDelay: Double = 0.05) -> Double {
        Double(index) * baseDelay
    }
}

// MARK: - View Extensions

extension View {
    func straynCard(
        cornerRadius: CGFloat = StraynRadius.xl,
        borderColor: Color = StraynColors.borderSubtle
    ) -> some View {
        self
            .background(StraynColors.surfacePrimary)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    func straynMetricLabel() -> some View {
        self
            .font(StraynTypography.metricLabel)
            .tracking(StraynTypography.metricLabelTracking)
            .foregroundColor(StraynColors.textTertiary)
    }

    func straynGlow(color: Color, radius: CGFloat = 15) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 4)
    }
}

// MARK: - Recovery Zone Type (mirrors DailyRecovery.RecoveryZone for theme independence)

enum RecoveryZoneType: String {
    case green, yellow, red

    var color: Color {
        switch self {
        case .green: return StraynColors.zoneGreen
        case .yellow: return StraynColors.zoneYellow
        case .red: return StraynColors.zoneRed
        }
    }

    static func from(score: Double) -> RecoveryZoneType {
        if score >= 67 { return .green }
        else if score >= 34 { return .yellow }
        else { return .red }
    }
}

// MARK: - Color Extensions

extension Color {
    static func forRecoveryScore(_ score: Double) -> Color {
        RecoveryZoneType.from(score: score).color
    }

    static func forStrainLevel(_ strain: Double) -> Color {
        switch strain {
        case 0..<8: return StraynColors.zoneGreen
        case 8..<14: return StraynColors.zoneYellow
        default: return StraynColors.zoneRed
        }
    }

    static func forSleepEfficiency(_ efficiency: Double) -> Color {
        switch efficiency {
        case 0.9...: return StraynColors.zoneGreen
        case 0.75..<0.9: return StraynColors.zoneYellow
        default: return StraynColors.zoneRed
        }
    }
}
