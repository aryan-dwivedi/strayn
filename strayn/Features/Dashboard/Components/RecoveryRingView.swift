//
//  RecoveryRingView.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import SwiftUI

struct RecoveryRingView: View {
    var score: Double
    var size: CGFloat = 200
    
    // Animation state
    @State private var animatedScore: Double = 0
    @State private var isPulsing = false
    
    var color: Color {
        if score >= 67 { return .green }
        if score >= 34 { return .yellow }
        return .red
    }
    
    var body: some View {
        ZStack {
            // Glassmorphism Background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 0)
            
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)
                .frame(width: size, height: size)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * (animatedScore / 100))
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
            
            // Score Text
            VStack {
                Text("\(Int(animatedScore))")
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
                
                Text("RECOVERY")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                animatedScore = score
            }
            
            // Gentle pulse animation for "alive" feel
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onChange(of: score) { newValue in
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                animatedScore = newValue
            }
        }
    }
}
