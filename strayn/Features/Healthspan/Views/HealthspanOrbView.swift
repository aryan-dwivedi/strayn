//
//  HealthspanOrbView.swift
//  strayn
//
//  Animated particle orb visualization for Healthspan, inspired by WHOOP's
//  organic blob design. Color shifts based on Strayn Age delta.
//

import SwiftUI

// MARK: - Healthspan Orb View

struct HealthspanOrbView: View {
    let straynAge: Double
    let ageDelta: Double
    let chronologicalAge: Double
    let size: CGFloat
    
    @State private var animationPhase: Double = 0
    @State private var particles: [OrbParticle] = []
    @State private var blobPoints: [CGPoint] = []
    
    private let colorScheme: OrbColorScheme
    private let particleCount = 150
    
    init(straynAge: Double, ageDelta: Double, chronologicalAge: Double, size: CGFloat = 280) {
        self.straynAge = straynAge
        self.ageDelta = ageDelta
        self.chronologicalAge = chronologicalAge
        self.size = size
        self.colorScheme = OrbColorScheme.scheme(for: ageDelta)
    }
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme.glowColor,
                            colorScheme.glowColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 30)
            
            // Main orb blob
            OrbBlobShape(phase: animationPhase)
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme.primaryColor.opacity(0.9),
                            colorScheme.secondaryColor.opacity(0.7),
                            colorScheme.primaryColor.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Inner highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: size * 0.4
                            )
                        )
                        .frame(width: size * 0.9, height: size * 0.9)
                )
            
            // Particle layer
            ParticleFieldView(
                particles: particles,
                size: size,
                particleColor: colorScheme.particleColor
            )
            .clipShape(OrbBlobShape(phase: animationPhase))
            
            // Outer ring glow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            colorScheme.primaryColor.opacity(0.6),
                            colorScheme.secondaryColor.opacity(0.3),
                            colorScheme.primaryColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 1.02, height: size * 1.02)
                .blur(radius: 2)
            
            // Center content
            VStack(spacing: 4) {
                Text(String(format: "%.1f", straynAge))
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("STRAYN AGE")
                    .font(.system(size: size * 0.04, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(formattedDelta)
                    .font(.system(size: size * 0.055, weight: .semibold, design: .rounded))
                    .foregroundColor(deltaColor)
                    .padding(.top, 4)
            }
        }
        .frame(width: size * 1.3, height: size * 1.3)
        .onAppear {
            initializeParticles()
            startAnimation()
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDelta: String {
        let rounded = abs(ageDelta).rounded(toPlaces: 1)
        if ageDelta < -0.1 {
            return "\(rounded) years younger"
        } else if ageDelta > 0.1 {
            return "\(rounded) years older"
        } else {
            return "At your age"
        }
    }
    
    private var deltaColor: Color {
        if ageDelta <= -0.5 {
            return Color(red: 0.3, green: 0.95, blue: 0.6)  // Bright green
        } else if ageDelta >= 0.5 {
            return Color(red: 1.0, green: 0.85, blue: 0.4)  // Golden
        } else {
            return Color.white.opacity(0.8)
        }
    }
    
    // MARK: - Animation
    
    private func initializeParticles() {
        particles = (0..<particleCount).map { _ in
            OrbParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size),
                    y: CGFloat.random(in: 0...size)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1...1),
                    y: CGFloat.random(in: -1...1)
                ),
                color: colorScheme.primaryColor.opacity(Double.random(in: 0.3...0.9)),
                size: CGFloat.random(in: 1...4),
                opacity: Double.random(in: 0.3...0.9)
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animationPhase = Double.pi * 2
        }
    }
}

// MARK: - Orb Blob Shape

struct OrbBlobShape: Shape {
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2 * 0.85
        
        var path = Path()
        let points = 100
        
        for i in 0...points {
            let angle = Double(i) / Double(points) * Double.pi * 2
            
            // Multiple wave frequencies for organic look
            let wave1 = sin(angle * 3 + phase) * 0.08
            let wave2 = sin(angle * 5 + phase * 1.3) * 0.04
            let wave3 = cos(angle * 2 + phase * 0.7) * 0.06
            
            let radiusVariation = 1.0 + wave1 + wave2 + wave3
            let radius = baseRadius * radiusVariation
            
            let x = center.x + CGFloat(cos(angle)) * CGFloat(radius)
            let y = center.y + CGFloat(sin(angle)) * CGFloat(radius)
            
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

// MARK: - Particle Model

struct OrbParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

// MARK: - Particle Field View

struct ParticleFieldView: View {
    let particles: [OrbParticle]
    let size: CGFloat
    let particleColor: Color
    
    @State private var animationProgress: Double = 0
    
    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            
            for particle in particles {
                // Animate particles using velocity for movement
                let baseRadius = distance(from: particle.position, to: CGPoint(x: size/2, y: size/2))
                let timeOffset = animationProgress * 2.0 + particle.size
                
                let animatedX = center.x + cos(timeOffset) * baseRadius * 0.3 + (particle.position.x - size/2) * 0.7 + particle.velocity.x
                let animatedY = center.y + sin(timeOffset) * baseRadius * 0.3 + (particle.position.y - size/2) * 0.7 + particle.velocity.y
                
                let rect = CGRect(
                    x: animatedX - particle.size / 2,
                    y: animatedY - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                
                // Add glow effect
                let glowRect = rect.insetBy(dx: -particle.size, dy: -particle.size)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(particleColor.opacity(particle.opacity * 0.2))
                )
                
                context.fill(
                    Circle().path(in: rect),
                    with: .color(particleColor.opacity(particle.opacity))
                )
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                animationProgress = Double.pi * 2
            }
        }
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Positive (younger)
            HealthspanOrbView(
                straynAge: 33.8,
                ageDelta: -1.2,
                chronologicalAge: 35,
                size: 220
            )
            
            // Negative (older)
            HealthspanOrbView(
                straynAge: 38.4,
                ageDelta: 3.4,
                chronologicalAge: 35,
                size: 220
            )
        }
    }
}
