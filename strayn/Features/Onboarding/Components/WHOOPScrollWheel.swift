//
//  WHOOPScrollWheel.swift
//  strayn
//
//  WHOOP-style scroll wheel picker for numeric input with spring physics and haptic feedback.
//

import SwiftUI

struct WHOOPScrollWheel: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    var step: Int = 1

    @State private var dragOffset: CGFloat = 0
    @State private var lastHapticValue: Int = 0

    private let itemWidth: CGFloat = 60
    private let visibleItems: Int = 7

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2

            ZStack {
                // Selection indicator line
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(StraynColors.accentPrimary)
                        .frame(width: 3, height: 30)

                    Spacer()

                    Rectangle()
                        .fill(StraynColors.accentPrimary)
                        .frame(width: 3, height: 30)
                }
                .frame(height: 160)

                // Scrollable numbers
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { num in
                                numberItem(num, centerX: centerX, geometry: geometry)
                                    .id(num)
                            }
                        }
                        .padding(.horizontal, centerX - itemWidth / 2)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.none) {
                                proxy.scrollTo(value, anchor: .center)
                            }
                        }
                        lastHapticValue = value
                    }
                    .onChange(of: value) { newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }

                        // Haptic feedback on value change
                        if newValue != lastHapticValue {
                            HapticsManager.shared.playSliderTick()
                            lastHapticValue = newValue
                        }
                    }
                }
            }
        }
        .frame(height: 160)
    }

    private func numberItem(_ num: Int, centerX: CGFloat, geometry: GeometryProxy) -> some View {
        let isSelected = num == value
        let distance = abs(num - value)
        let scale = max(0.5, 1.0 - Double(distance) * 0.15)
        let opacity = max(0.2, 1.0 - Double(distance) * 0.25)

        return Text("\(num)")
            .font(.system(size: isSelected ? 56 : 32, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(opacity))
            .frame(width: itemWidth)
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    value = num
                }
                HapticsManager.shared.playSelection()
            }
    }
}

// MARK: - Double Version for Weight

struct WHOOPScrollWheelDouble: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String
    var step: Double = 0.5
    var decimalPlaces: Int = 1

    @State private var lastHapticValue: Double = 0

    private let itemWidth: CGFloat = 70

    private var values: [Double] {
        stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
    }

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2

            ZStack {
                // Selection indicator
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(StraynColors.accentPrimary)
                        .frame(width: 3, height: 30)

                    Spacer()

                    Rectangle()
                        .fill(StraynColors.accentPrimary)
                        .frame(width: 3, height: 30)
                }
                .frame(height: 160)

                // Scrollable numbers
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(values, id: \.self) { num in
                                numberItem(num)
                                    .id(num)
                            }
                        }
                        .padding(.horizontal, centerX - itemWidth / 2)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.none) {
                                proxy.scrollTo(closestValue(to: value), anchor: .center)
                            }
                        }
                        lastHapticValue = value
                    }
                    .onChange(of: value) { newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(closestValue(to: newValue), anchor: .center)
                        }

                        if newValue != lastHapticValue {
                            HapticsManager.shared.playSliderTick()
                            lastHapticValue = newValue
                        }
                    }
                }
            }
        }
        .frame(height: 160)
    }

    private func closestValue(to target: Double) -> Double {
        values.min(by: { abs($0 - target) < abs($1 - target) }) ?? target
    }

    private func numberItem(_ num: Double) -> some View {
        let isSelected = abs(num - value) < step / 2
        let distance = abs(num - value) / step
        let scale = max(0.5, 1.0 - distance * 0.12)
        let opacity = max(0.2, 1.0 - distance * 0.2)

        return Text(String(format: "%.\(decimalPlaces)f", num))
            .font(.system(size: isSelected ? 48 : 28, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(opacity))
            .frame(width: itemWidth)
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    value = num
                }
                HapticsManager.shared.playSelection()
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            WHOOPScrollWheel(
                value: .constant(25),
                range: 13...100,
                suffix: "years"
            )

            WHOOPScrollWheelDouble(
                value: .constant(70.0),
                range: 30...200,
                suffix: "kg"
            )
        }
    }
}
