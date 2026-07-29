//
//  WHOOPSlider.swift
//  strayn
//
//  WHOOP-style custom slider with visual feedback and haptics.
//

import SwiftUI

struct WHOOPSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String?
    let valueLabel: String?
    let accentColor: Color
    let showTicks: Bool

    @State private var isDragging = false
    @State private var lastHapticValue: Double = 0

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.5,
        label: String? = nil,
        valueLabel: String? = nil,
        accentColor: Color = StraynColors.accentPrimary,
        showTicks: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.valueLabel = valueLabel
        self.accentColor = accentColor
        self.showTicks = showTicks
    }

    private var progress: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Label and value display
            if label != nil || valueLabel != nil {
                HStack {
                    if let label = label {
                        Text(label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(StraynColors.textSecondary)
                    }

                    Spacer()

                    if let valueLabel = valueLabel {
                        Text(valueLabel)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }

            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(StraynColors.surfaceSecondary)
                        .frame(height: 12)

                    // Filled track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.7), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, CGFloat(progress) * geometry.size.width), height: 12)

                    // Tick marks
                    if showTicks {
                        tickMarks(width: geometry.size.width)
                    }

                    // Thumb
                    thumb
                        .offset(x: CGFloat(progress) * (geometry.size.width - 28))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            updateValue(from: gesture.location.x, width: geometry.size.width)
                        }
                        .onEnded { _ in
                            isDragging = false
                            HapticsManager.shared.playImpact(.light)
                        }
                )
            }
            .frame(height: 32)

            // Range labels
            HStack {
                Text(String(format: "%.1f", range.lowerBound))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textMuted)

                Spacer()

                Text(String(format: "%.1f", range.upperBound))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textMuted)
            }
        }
    }

    private var thumb: some View {
        ZStack {
            // Glow
            if isDragging {
                Circle()
                    .fill(accentColor.opacity(0.4))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8)
            }

            // Thumb circle
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                )
        }
        .scaleEffect(isDragging ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }

    @ViewBuilder
    private func tickMarks(width: CGFloat) -> some View {
        let tickCount = Int((range.upperBound - range.lowerBound) / step) + 1
        let visibleTicks = min(tickCount, 20) // Limit visible ticks

        HStack(spacing: 0) {
            ForEach(0..<visibleTicks, id: \.self) { index in
                Rectangle()
                    .fill(StraynColors.textMuted.opacity(0.3))
                    .frame(width: 1, height: 6)
                if index < visibleTicks - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private func updateValue(from x: CGFloat, width: CGFloat) {
        let clampedX = max(0, min(x, width))
        let percentage = clampedX / width
        let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percentage)
        let steppedValue = round(rawValue / step) * step
        let newValue = max(range.lowerBound, min(range.upperBound, steppedValue))

        if newValue != value {
            value = newValue

            // Haptic feedback on step changes
            if abs(newValue - lastHapticValue) >= step {
                HapticsManager.shared.playSliderTick()
                lastHapticValue = newValue
            }
        }
    }
}

// MARK: - Sleep Duration Slider (Specialized)

struct WHOOPSleepSlider: View {
    @Binding var hours: Double
    let accentColor: Color

    init(
        hours: Binding<Double>,
        accentColor: Color = StraynColors.sleep
    ) {
        self._hours = hours
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 24) {
            // Moon phase visualization
            MoonPhaseView(hours: hours)

            // Large hour display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", hours))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("hrs")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(StraynColors.textSecondary)
            }

            // Slider
            WHOOPSlider(
                value: $hours,
                range: 4...12,
                step: 0.5,
                accentColor: accentColor,
                showTicks: false
            )
        }
    }
}

// MARK: - Moon Phase View

private struct MoonPhaseView: View {
    let hours: Double

    private var moonFill: Double {
        // Maps 4-12 hours to 0.2-1.0 moon fill
        (hours - 4) / 8 * 0.8 + 0.2
    }

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(StraynColors.sleep.opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 20)

            // Moon
            Image(systemName: moonIconName)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [StraynColors.sleep, StraynColors.sleep.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
        }
    }

    private var moonIconName: String {
        switch hours {
        case 4..<5: return "moon.stars"
        case 5..<6: return "moon.fill"
        case 6..<7: return "moon.fill"
        case 7..<8: return "moon.fill"
        case 8..<9: return "moon.zzz.fill"
        default: return "moon.zzz.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            WHOOPSlider(
                value: .constant(7.5),
                range: 4...12,
                step: 0.5,
                label: "Sleep Duration",
                valueLabel: "7.5 hrs"
            )

            WHOOPSleepSlider(hours: .constant(7.5))
        }
        .padding()
    }
}
