//
//  ScoreCircleView.swift
//  strayn
//
//  A reusable circular gauge for displaying recovery and strain scores
//

import SwiftUI

struct ScoreCircleView: View {
    let score: Double
    let maxScore: Double
    let title: String
    let subtitle: String?
    let color: Color
    let size: CGFloat
    var forecastScore: Double? = nil

    @State private var animatedProgress: Double = 0
    @State private var animatedForecast: Double = 0

    private var progress: Double {
        min(1.0, score / maxScore)
    }
    
    private var forecastProgress: Double {
        guard let fs = forecastScore else { return 0 }
        return min(1.0, fs / maxScore)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: size * 0.1)
                
                // Forecast Ring (if available) - dashed and subtle
                if let _ = forecastScore {
                    Circle()
                        .trim(from: 0, to: CGFloat(animatedForecast))
                        .stroke(
                            color.opacity(0.3),
                            style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round, dash: [2, 4])
                        )
                        .rotationEffect(.degrees(-90))
                }
                
                // Main Progress Bar with Glow
                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.6), color]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // Content
                VStack(spacing: 0) {
                    Text(String(format: score.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", score))
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedProgress = progress
                    animatedForecast = forecastProgress
                }
            }
            
            Text(title)
                .font(.system(size: size * 0.1, weight: .semibold, design: .default))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct ScoreCircleView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 40) {
            ScoreCircleView(score: 84, maxScore: 100, title: "Recovery", subtitle: "Recovered", color: .green, size: 120)
            ScoreCircleView(score: 12.4, maxScore: 21, title: "Strain", subtitle: "Moderate", color: .blue, size: 120)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
