//
//  GlassmorphismModifier.swift
//  strayn
//
//  Premium glassmorphism effects for cards, overlays, and backgrounds.
//

import SwiftUI

// MARK: - Glassmorphic Card Modifier

struct GlassmorphicCard: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: CGFloat
    let blurRadius: CGFloat
    let shadowColor: Color?
    let shadowRadius: CGFloat

    init(
        cornerRadius: CGFloat = StraynRadius.xl,
        backgroundOpacity: CGFloat = 0.05,
        borderOpacity: CGFloat = 0.05,
        blurRadius: CGFloat = 0,
        shadowColor: Color? = nil,
        shadowRadius: CGFloat = 10
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.blurRadius = blurRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if blurRadius > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(backgroundOpacity))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowColor?.opacity(0.3) ?? Color.clear,
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Frosted Glass Modifier (Heavy blur)

struct FrostedGlass: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color

    init(cornerRadius: CGFloat = StraynRadius.lg, tint: Color = .white) {
        self.cornerRadius = cornerRadius
        self.tint = tint
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tint.opacity(0.05))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Metric Card Glow Effect

struct MetricGlow: ViewModifier {
    let color: Color
    let isActive: Bool
    let pulseAnimation: Bool

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(isPulsing ? 0.5 : 0.3) : Color.clear,
                radius: isPulsing ? 25 : 15,
                x: 0,
                y: isPulsing ? 8 : 4
            )
            .onAppear {
                if pulseAnimation {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
    }
}

// MARK: - Animated Border Gradient

struct AnimatedBorderGradient: ViewModifier {
    let colors: [Color]
    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let animationDuration: Double

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: colors + [colors.first ?? .clear]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: animationDuration)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.5)
                        .offset(x: -geometry.size.width * 0.25 + phase * geometry.size.width * 1.5)
                        .mask(content)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Premium Card Background

struct PremiumCardBackground: View {
    let cornerRadius: CGFloat
    let accentColor: Color?
    let isElevated: Bool

    init(
        cornerRadius: CGFloat = StraynRadius.xl,
        accentColor: Color? = nil,
        isElevated: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
        self.isElevated = isElevated
    }

    var body: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isElevated ? StraynColors.surfaceElevated : StraynColors.surfacePrimary)

            // Subtle accent gradient overlay
            if let accent = accentColor {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.1), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(StraynColors.borderSubtle, lineWidth: 1)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glassmorphic card styling
    func glassmorphicCard(
        cornerRadius: CGFloat = StraynRadius.xl,
        backgroundOpacity: CGFloat = 0.05,
        borderOpacity: CGFloat = 0.05,
        shadowColor: Color? = nil
    ) -> some View {
        modifier(GlassmorphicCard(
            cornerRadius: cornerRadius,
            backgroundOpacity: backgroundOpacity,
            borderOpacity: borderOpacity,
            shadowColor: shadowColor
        ))
    }

    /// Apply frosted glass effect
    func frostedGlass(
        cornerRadius: CGFloat = StraynRadius.lg,
        tint: Color = .white
    ) -> some View {
        modifier(FrostedGlass(cornerRadius: cornerRadius, tint: tint))
    }

    /// Apply metric glow effect
    func metricGlow(
        color: Color,
        isActive: Bool = true,
        pulse: Bool = false
    ) -> some View {
        modifier(MetricGlow(color: color, isActive: isActive, pulseAnimation: pulse))
    }

    /// Apply animated border gradient
    func animatedBorder(
        colors: [Color],
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = StraynRadius.xl,
        duration: Double = 3.0
    ) -> some View {
        modifier(AnimatedBorderGradient(
            colors: colors,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius,
            animationDuration: duration
        ))
    }

    /// Apply shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }

    /// Apply premium elevated card style
    func premiumCard(
        cornerRadius: CGFloat = StraynRadius.xl,
        accentColor: Color? = nil,
        isElevated: Bool = false
    ) -> some View {
        self.background(
            PremiumCardBackground(
                cornerRadius: cornerRadius,
                accentColor: accentColor,
                isElevated: isElevated
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Glassmorphic Card")
                .foregroundColor(.white)
                .padding()
                .glassmorphicCard(shadowColor: .blue)

            Text("Frosted Glass")
                .foregroundColor(.white)
                .padding()
                .frostedGlass()

            Text("With Glow")
                .foregroundColor(.white)
                .padding()
                .glassmorphicCard()
                .metricGlow(color: .green, pulse: true)

            Text("Animated Border")
                .foregroundColor(.white)
                .padding()
                .animatedBorder(colors: [.blue, .purple, .pink])
        }
        .padding()
    }
}
