//
//  WHOOPPaceScaleView.swift
//  strayn
//
//  WHOOP-inspired pace of aging scale (-1.0x to 3.0x)
//  Shows current aging pace with visual indicator.
//

import SwiftUI

// MARK: - WHOOP Pace Scale View

struct WHOOPPaceScaleView: View {
    let currentPace: Double
    let isSlowPace: Bool
    
    // Scale configuration: -1.0x to 3.0x
    private let minPace: Double = -1.0
    private let maxPace: Double = 3.0
    private let neutralPace: Double = 1.0
    
    private var normalizedPosition: CGFloat {
        // Convert pace to 0...1 range
        let range = maxPace - minPace
        let position = (currentPace - minPace) / range
        return CGFloat(max(0, min(1, position)))
    }
    
    private var paceColor: Color {
        if currentPace < 0.5 {
            return Color(red: 0.2, green: 0.85, blue: 0.6) // Bright green/teal
        } else if currentPace < 1.0 {
            return Color(red: 0.3, green: 0.75, blue: 0.5) // Green
        } else if currentPace < 1.5 {
            return Color(red: 0.9, green: 0.8, blue: 0.3) // Yellow
        } else if currentPace < 2.0 {
            return Color(red: 0.95, green: 0.65, blue: 0.3) // Orange
        } else {
            return Color(red: 0.9, green: 0.4, blue: 0.3) // Red/Orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("PACE OF AGING")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                // Current pace value
                HStack(spacing: 4) {
                    Text(String(format: "%.1fx", currentPace))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(paceColor)
                    
                    if isSlowPace {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(paceColor)
                    }
                }
            }
            
            // Scale visualization
            GeometryReader { geometry in
                let width = geometry.size.width
                let indicatorX = normalizedPosition * width
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 12)
                    
                    // Gradient fill showing range
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.85, blue: 0.6), // -1x green
                                    Color(red: 0.3, green: 0.7, blue: 0.5),  // 0x
                                    Color(red: 0.9, green: 0.8, blue: 0.3),  // 1x yellow
                                    Color(red: 0.95, green: 0.55, blue: 0.25),// 2x orange
                                    Color(red: 0.9, green: 0.4, blue: 0.3)   // 3x red
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 12)
                        .opacity(0.3)
                    
                    // Filled portion up to current pace
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    paceColor.opacity(0.8),
                                    paceColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, indicatorX + 6), height: 12)
                    
                    // Current position indicator (diamond/notch)
                    WHOOPPaceIndicator(color: paceColor)
                        .frame(width: 20, height: 24)
                        .offset(x: indicatorX - 10, y: -6)
                    
                    // 1.0x marker line (neutral pace)
                    let neutralX = ((neutralPace - minPace) / (maxPace - minPace)) * width
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2, height: 18)
                        .offset(x: neutralX - 1, y: -3)
                }
                .frame(height: 12)
            }
            .frame(height: 24)
            
            // Scale labels
            HStack {
                Text("-1.0x")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("1.0x")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("3.0x")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Description text
            Text(paceDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
                .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var paceDescription: String {
        if currentPace < 0 {
            return "Your biological age is reversing - aging backwards!"
        } else if currentPace < 0.7 {
            return "Exceptional! You're aging slower than time passes."
        } else if currentPace < 1.0 {
            return "Great pace - you're aging slower than normal."
        } else if currentPace < 1.2 {
            return "You're aging at a normal rate."
        } else if currentPace < 2.0 {
            return "Above average - focus on recovery and sleep."
        } else {
            return "High pace - prioritize rest and reduce strain."
        }
    }
}

// MARK: - Pace Indicator (Diamond/Notch Shape)

struct WHOOPPaceIndicator: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Diamond shape with bottom point
            WHOOPDiamondShape()
                .fill(color)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // Inner highlight
            WHOOPDiamondShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(2)
        }
    }
}

// MARK: - Diamond Shape

struct WHOOPDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let midX = rect.midX
        let topY = rect.minY + rect.height * 0.15
        let bottomY = rect.maxY
        let sideInset = rect.width * 0.1
        let middleY = rect.height * 0.4
        
        // Top point
        path.move(to: CGPoint(x: midX, y: topY))
        
        // Right side
        path.addLine(to: CGPoint(x: rect.maxX - sideInset, y: middleY))
        
        // Bottom right curve to point
        path.addQuadCurve(
            to: CGPoint(x: midX, y: bottomY),
            control: CGPoint(x: rect.maxX - sideInset, y: bottomY - rect.height * 0.2)
        )
        
        // Bottom left curve from point
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + sideInset, y: middleY),
            control: CGPoint(x: rect.minX + sideInset, y: bottomY - rect.height * 0.2)
        )
        
        // Back to top
        path.addLine(to: CGPoint(x: midX, y: topY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Compact Scale View (for inline display)

struct WHOOPCompactPaceScale: View {
    let currentPace: Double
    
    private let minPace: Double = -1.0
    private let maxPace: Double = 3.0
    
    private var normalizedPosition: CGFloat {
        let range = maxPace - minPace
        let position = (currentPace - minPace) / range
        return CGFloat(max(0, min(1, position)))
    }
    
    private var paceColor: Color {
        if currentPace < 0.5 {
            return Color(red: 0.2, green: 0.85, blue: 0.6)
        } else if currentPace < 1.0 {
            return Color(red: 0.3, green: 0.75, blue: 0.5)
        } else if currentPace < 1.5 {
            return Color(red: 0.9, green: 0.8, blue: 0.3)
        } else {
            return Color(red: 0.95, green: 0.55, blue: 0.3)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let indicatorX = normalizedPosition * width
            
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(paceColor)
                    .frame(width: max(8, indicatorX), height: 8)
                
                // Position dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: paceColor.opacity(0.5), radius: 3)
                    .offset(x: indicatorX - 6, y: 0)
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 30) {
            WHOOPPaceScaleView(currentPace: 0.7, isSlowPace: true)
            
            WHOOPPaceScaleView(currentPace: 1.4, isSlowPace: false)
            
            WHOOPPaceScaleView(currentPace: -0.3, isSlowPace: true)
            
            WHOOPCompactPaceScale(currentPace: 0.8)
                .frame(width: 200)
        }
        .padding()
    }
}
