//
//  WHOOPProgressRing.swift
//  strayn
//
//  WHOOP-style progress ring with glow animation for processing screens.
//

import SwiftUI

struct WHOOPProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let accentColor: Color
    let showPercentage: Bool

    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        accentColor: Color = StraynColors.accentPrimary,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.accentColor = accentColor
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .stroke(accentColor.opacity(0.3), lineWidth: lineWidth + 10)
                .blur(radius: 15)
                .scaleEffect(pulseScale)

            // Background ring
            Circle()
                .stroke(StraynColors.surfaceSecondary, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.5),
                            accentColor
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // End cap glow
            Circle()
                .fill(accentColor)
                .frame(width: lineWidth, height: lineWidth)
                .offset(y: -100)
                .rotationEffect(.degrees(360 * animatedProgress - 90))
                .shadow(color: accentColor, radius: 10)
                .opacity(animatedProgress > 0 ? 1 : 0)

            // Percentage text
            if showPercentage {
                VStack(spacing: 4) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("%")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(StraynColors.textSecondary)
                }
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedProgress = progress
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Processing Animation Ring

struct WHOOPProcessingRing: View {
    let title: String
    let subtitle: String?
    let accentColor: Color

    @State private var rotation: Double = 0
    @State private var pulseOpacity: Double = 0.3

    init(
        title: String = "Processing...",
        subtitle: String? = nil,
        accentColor: Color = StraynColors.accentPrimary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                // Outer glow
                Circle()
                    .stroke(accentColor.opacity(pulseOpacity), lineWidth: 20)
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                // Spinning ring segments
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .trim(from: CGFloat(index) * 0.25 + 0.05, to: CGFloat(index) * 0.25 + 0.2)
                        .stroke(
                            accentColor.opacity(1.0 - Double(index) * 0.25),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotation + Double(index) * 30))
                }

                // Inner pulsing circle
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseOpacity > 0.4 ? 1.1 : 1.0)

                // Center icon
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(accentColor)
                    .symbolEffect(.variableColor.iterative.reversing)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(StraynColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            // Rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.6
            }
        }
    }
}

// MARK: - Progress Bar (Top of screen)

struct WHOOPProgressBar: View {
    let current: Int
    let total: Int

    private var progress: Double {
        Double(current + 1) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(StraynColors.surfaceSecondary)
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [StraynColors.accentPrimary.opacity(0.7), StraynColors.accentPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            WHOOPProgressBar(current: 5, total: 38)

            WHOOPProgressRing(
                progress: 0.75,
                accentColor: StraynColors.recovery
            )

            WHOOPProcessingRing(
                title: "Analyzing your data...",
                subtitle: "This may take a moment"
            )
        }
    }
}
