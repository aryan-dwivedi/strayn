//
//  WHOOPCameraOverlay.swift
//  strayn
//
//  WHOOP-style camera overlay with guide frames and validation feedback.
//

import SwiftUI

struct WHOOPCameraOverlay: View {
    let title: String
    let instructions: String
    let isValid: Bool
    let validationIssues: [CameraValidationIssue]
    let captureType: CameraCaptureType?

    @State private var pulseScale: CGFloat = 1.0

    init(
        title: String,
        instructions: String,
        isValid: Bool,
        validationIssues: [CameraValidationIssue] = [],
        captureType: CameraCaptureType? = nil
    ) {
        self.title = title
        self.instructions = instructions
        self.isValid = isValid
        self.validationIssues = validationIssues
        self.captureType = captureType
    }

    var body: some View {
        ZStack {
            // Top gradient
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)

                Spacer()
            }
            .ignoresSafeArea()

            // Bottom gradient
            VStack {
                Spacer()

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 60)

                Spacer()

                // Guide frame
                guideFrame
                    .padding(.bottom, 20)

                // Validation feedback
                validationFeedback
                    .padding(.bottom, 20)

                Spacer()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(StraynColors.accentPrimary)

            Text(instructions)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Guide Frame

    private var guideFrame: some View {
        ZStack {
            // Frame shape based on capture type
            frameShape
                .stroke(
                    isValid ? StraynColors.zoneGreen : StraynColors.accentPrimary,
                    lineWidth: 3
                )
                .frame(width: frameSize.width, height: frameSize.height)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = isValid ? 1.0 : 1.02
                    }
                }

            // Corner accents
            ForEach(0..<4, id: \.self) { corner in
                CornerGuide(
                    corner: corner,
                    isValid: isValid,
                    frameSize: frameSize
                )
            }

            // Center crosshairs for face capture
            if case .face = captureType {
                crosshairs
            }
        }
    }

    private var frameShape: some InsettableShape {
        switch captureType {
        case .face:
            return AnyInsettableShape(Ellipse())
        default:
            return AnyInsettableShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    private var frameSize: CGSize {
        switch captureType {
        case .face:
            return CGSize(width: 280, height: 360)
        case .skin:
            return CGSize(width: 280, height: 320)
        case .hair:
            return CGSize(width: 280, height: 280)
        case .none:
            return CGSize(width: 280, height: 320)
        }
    }

    private var crosshairs: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 1)

            // Vertical line
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 40)
        }
    }

    // MARK: - Validation Feedback

    private var validationFeedback: some View {
        VStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 8) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isValid ? StraynColors.zoneGreen : StraynColors.zoneYellow)

                Text(isValid ? "Ready to capture" : "Adjust position")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )

            // Issue list
            if !validationIssues.isEmpty && !isValid {
                VStack(spacing: 6) {
                    ForEach(validationIssues.prefix(2)) { issue in
                        HStack(spacing: 6) {
                            Image(systemName: issue.icon)
                                .font(.system(size: 12))
                                .foregroundColor(StraynColors.zoneYellow)

                            Text(issue.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                )
            }
        }
    }
}

// MARK: - Corner Guide

private struct CornerGuide: View {
    let corner: Int
    let isValid: Bool
    let frameSize: CGSize

    private let cornerLength: CGFloat = 30
    private let cornerWidth: CGFloat = 4

    var body: some View {
        Path { path in
            switch corner {
            case 0: // Top-left
                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            case 1: // Top-right
                path.move(to: CGPoint(x: -cornerLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: cornerLength))
            case 2: // Bottom-right
                path.move(to: CGPoint(x: 0, y: -cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -cornerLength, y: 0))
            case 3: // Bottom-left
                path.move(to: CGPoint(x: cornerLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -cornerLength))
            default:
                break
            }
        }
        .stroke(
            isValid ? StraynColors.zoneGreen : StraynColors.accentPrimary,
            style: StrokeStyle(lineWidth: cornerWidth, lineCap: .round, lineJoin: .round)
        )
        .offset(x: xOffset, y: yOffset)
    }

    private var xOffset: CGFloat {
        let halfWidth = frameSize.width / 2
        switch corner {
        case 0, 3: return -halfWidth
        case 1, 2: return halfWidth
        default: return 0
        }
    }

    private var yOffset: CGFloat {
        let halfHeight = frameSize.height / 2
        switch corner {
        case 0, 1: return -halfHeight
        case 2, 3: return halfHeight
        default: return 0
        }
    }
}

// MARK: - Any Insettable Shape

struct AnyInsettableShape: InsettableShape {
    private let _path: (CGRect) -> Path
    private let _inset: (CGFloat) -> AnyInsettableShape

    init<S: InsettableShape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
        _inset = { amount in AnyInsettableShape(shape.inset(by: amount)) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }

    func inset(by amount: CGFloat) -> AnyInsettableShape {
        _inset(amount)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        WHOOPCameraOverlay(
            title: "Inner Forearm",
            instructions: "Hold your inner forearm in natural light",
            isValid: false,
            validationIssues: [.insufficientSkinCoverage, .poorLighting],
            captureType: .skin(.innerForearm)
        )
    }
}
