//
//  WHOOPStyleOrbView.swift
//  strayn
//
//  WHOOP-inspired organic blob orb visualization with particles.
//  Color transitions from teal/green (younger) to gold/amber (older).
//

import SwiftUI

// MARK: - WHOOP Style Orb View

struct WHOOPStyleOrbView: View {
    let age: Double
    let ageDelta: Double
    let size: CGFloat
    
    @State private var animationPhase: Double = 0
    @State private var particles: [WHOOPParticle] = []
    
    private var colorScheme: WHOOPOrbColors {
        WHOOPOrbColors.scheme(for: ageDelta)
    }
    
    init(age: Double, ageDelta: Double, size: CGFloat = 300) {
        self.age = age
        self.ageDelta = ageDelta
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme.glowColor.opacity(0.4),
                            colorScheme.glowColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 25)
            
            // Main organic blob shape
            OrganicBlobShape(phase: animationPhase, complexity: 0.15)
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme.primaryColor.opacity(0.95),
                            colorScheme.secondaryColor.opacity(0.8),
                            colorScheme.primaryColor.opacity(0.5)
                        ],
                        center: UnitPoint(x: 0.45, y: 0.45),
                        startRadius: size * 0.05,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Top-left highlight reflection
                    OrganicBlobShape(phase: animationPhase, complexity: 0.15)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: size * 0.35
                            )
                        )
                        .frame(width: size, height: size)
                )
            
            // Particle field
            WHOOPParticleField(
                particles: particles,
                size: size,
                baseColor: colorScheme.particleColor,
                animationPhase: animationPhase
            )
            .clipShape(OrganicBlobShape(phase: animationPhase, complexity: 0.15))
            .frame(width: size, height: size)
            
            // Subtle outer ring
            OrganicBlobShape(phase: animationPhase, complexity: 0.15)
                .stroke(
                    colorScheme.primaryColor.opacity(0.4),
                    lineWidth: 1.5
                )
                .frame(width: size * 1.02, height: size * 1.02)
                .blur(radius: 1)
            
            // Center content
            VStack(spacing: 6) {
                Text(String(format: "%.1f", age))
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("STRAYN AGE")
                    .font(.system(size: size * 0.04, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.65))
                
                Text(deltaText)
                    .font(.system(size: size * 0.05, weight: .semibold))
                    .foregroundColor(deltaTextColor)
                    .padding(.top, 4)
            }
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .onAppear {
            initializeParticles()
            startAnimation()
        }
    }
    
    // MARK: - Computed Properties
    
    private var deltaText: String {
        let rounded = abs(ageDelta).rounded(toPlaces: 1)
        if ageDelta < -0.1 {
            return "\(rounded) years younger"
        } else if ageDelta > 0.1 {
            return "\(rounded) years older"
        } else {
            return "At your age"
        }
    }
    
    private var deltaTextColor: Color {
        if ageDelta < -0.1 {
            return Color(red: 0.3, green: 0.95, blue: 0.6) // Bright green
        } else if ageDelta > 0.1 {
            return Color(red: 1.0, green: 0.85, blue: 0.4) // Golden yellow
        } else {
            return Color.white.opacity(0.7)
        }
    }
    
    // MARK: - Animation Setup
    
    private func initializeParticles() {
        particles = (0..<200).map { _ in
            let distance = CGFloat.random(in: 0.1...0.9)
            let angle = Double.random(in: 0...(Double.pi * 2))
            let x = 0.5 + Foundation.cos(angle) * Double(distance) * 0.45
            let y = 0.5 + Foundation.sin(angle) * Double(distance) * 0.45
            
            return WHOOPParticle(
                position: CGPoint(x: x, y: y),
                baseRadius: distance,
                angle: CGFloat(angle),
                speed: Double.random(in: 0.3...1.0),
                size: CGFloat.random(in: 1...4),
                opacity: Double.random(in: 0.4...1.0)
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            animationPhase = Double.pi * 2
        }
    }
}

// MARK: - WHOOP Particle Model

struct WHOOPParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var baseRadius: CGFloat
    var angle: CGFloat
    var speed: Double
    var size: CGFloat
    var opacity: Double
}

// MARK: - WHOOP Particle Field

struct WHOOPParticleField: View {
    let particles: [WHOOPParticle]
    let size: CGFloat
    let baseColor: Color
    let animationPhase: Double
    
    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            
            for particle in particles {
                // Orbital motion
                let currentAngle = Double(particle.angle) + animationPhase * particle.speed * 0.3
                let radiusPulse = 1.0 + Foundation.sin(animationPhase * particle.speed) * 0.1
                let radius = Double(particle.baseRadius * size * 0.45) * radiusPulse
                
                let x = center.x + CGFloat(Foundation.cos(currentAngle) * radius)
                let y = center.y + CGFloat(Foundation.sin(currentAngle) * radius)
                
                // Particle glow
                let glowRect = CGRect(
                    x: x - particle.size * 2,
                    y: y - particle.size * 2,
                    width: particle.size * 4,
                    height: particle.size * 4
                )
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(baseColor.opacity(particle.opacity * 0.15))
                )
                
                // Main particle
                let rect = CGRect(
                    x: x - particle.size / 2,
                    y: y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(baseColor.opacity(particle.opacity))
                )
            }
        }
    }
}

// MARK: - Organic Blob Shape

struct OrganicBlobShape: Shape {
    var phase: Double
    var complexity: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = Double(min(rect.width, rect.height) / 2 * 0.88)
        
        var path = Path()
        let points = 120
        
        for i in 0...points {
            let angle = Double(i) / Double(points) * Double.pi * 2
            
            // Multiple wave frequencies for organic shape
            let wave1 = Foundation.sin(angle * 3 + phase) * complexity
            let wave2 = Foundation.sin(angle * 5 + phase * 1.2) * complexity * 0.5
            let wave3 = Foundation.cos(angle * 2 + phase * 0.8) * complexity * 0.7
            let wave4 = Foundation.sin(angle * 7 + phase * 0.5) * complexity * 0.3
            
            let radiusVariation = 1.0 + wave1 + wave2 + wave3 + wave4
            let radius = baseRadius * radiusVariation
            
            let x = center.x + CGFloat(Foundation.cos(angle) * radius)
            let y = center.y + CGFloat(Foundation.sin(angle) * radius)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - WHOOP Orb Colors

struct WHOOPOrbColors {
    let primaryColor: Color
    let secondaryColor: Color
    let glowColor: Color
    let particleColor: Color
    
    static func scheme(for ageDelta: Double) -> WHOOPOrbColors {
        if ageDelta <= -2.0 {
            // Very young - bright teal/cyan
            return WHOOPOrbColors(
                primaryColor: Color(red: 0.1, green: 0.65, blue: 0.6),
                secondaryColor: Color(red: 0.15, green: 0.55, blue: 0.55),
                glowColor: Color(red: 0.1, green: 0.7, blue: 0.65),
                particleColor: Color.white
            )
        } else if ageDelta <= 0 {
            // Younger - teal/green
            return WHOOPOrbColors(
                primaryColor: Color(red: 0.15, green: 0.55, blue: 0.5),
                secondaryColor: Color(red: 0.1, green: 0.45, blue: 0.45),
                glowColor: Color(red: 0.15, green: 0.6, blue: 0.55),
                particleColor: Color.white
            )
        } else if ageDelta <= 2.0 {
            // Slightly older - warm gold
            return WHOOPOrbColors(
                primaryColor: Color(red: 0.7, green: 0.55, blue: 0.25),
                secondaryColor: Color(red: 0.6, green: 0.45, blue: 0.2),
                glowColor: Color(red: 0.75, green: 0.6, blue: 0.3),
                particleColor: Color.white
            )
        } else {
            // Much older - deep amber/orange
            return WHOOPOrbColors(
                primaryColor: Color(red: 0.75, green: 0.5, blue: 0.2),
                secondaryColor: Color(red: 0.65, green: 0.4, blue: 0.15),
                glowColor: Color(red: 0.8, green: 0.55, blue: 0.25),
                particleColor: Color.white.opacity(0.9)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            WHOOPStyleOrbView(
                age: 37.7,
                ageDelta: -1.2,
                size: 260
            )
            
            WHOOPStyleOrbView(
                age: 76.4,
                ageDelta: 3.4,
                size: 260
            )
        }
    }
}
