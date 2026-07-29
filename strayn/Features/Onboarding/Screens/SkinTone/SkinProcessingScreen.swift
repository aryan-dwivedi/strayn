//
//  SkinProcessingScreen.swift
//  strayn
//
//  Skin analysis processing screen with ring animation.
//

import SwiftUI

struct SkinProcessingScreen: View {
    let progress: Double
    let regionName: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Processing animation
            WHOOPProcessingRing(
                title: "Analyzing \(regionName)...",
                subtitle: "Please wait while we analyze your skin tone",
                accentColor: StraynColors.biologicalAge
            )

            Spacer()

            // Progress bar at bottom
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(StraynColors.biologicalAge)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StraynColors.textSecondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Preview

#Preview {
    SkinProcessingScreen(
        progress: 0.65,
        regionName: "Inner Forearm"
    )
}
