//
//  CameraManager.swift
//  strayn
//
//  Camera capture manager with FaceID-grade validation and real-time analysis.
//

import Foundation
import AVFoundation
import SwiftUI
import Vision
import Combine

// MARK: - Thread-Safe Validation Timer

final class ValidationTimer: Sendable {
    private let lock = NSLock()
    private var _lastValidationTime = Date()
    
    func shouldValidate(interval: TimeInterval) -> Bool {
        let now = Date()
        lock.lock()
        defer { lock.unlock() }
        
        if now.timeIntervalSince(_lastValidationTime) >= interval {
            _lastValidationTime = now
            return true
        }
        return false
    }
}

@MainActor
class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var capturedImageData: Data?
    @Published var validationResult: CameraValidationResult?
    @Published var isValidating = false
    @Published var showValidationOverlay = true
    @Published var currentInstructions: String = ""
    
    // Real-time validation
    @Published var skinCoveragePercent: Double = 0
    @Published var lightingQuality: LightingQuality = .acceptable
    @Published var isFrameValid = false
    @Published var currentIssues: [CameraValidationIssue] = []
    
    // MARK: - Properties
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let analysisQueue = DispatchQueue(label: "camera.analysis.queue")
    
    private var captureType: CameraCaptureType = .skin(.innerForearm)
    private var captureCompletion: ((Data?) -> Void)?
    
    nonisolated private let validationTimer = ValidationTimer()
    private let validationInterval: TimeInterval = 0.5 // Validate every 500ms
    
    private let biometricAnalyzer = BiometricAnalyzer.shared
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            requestAuthorization()
        default:
            isAuthorized = false
        }
    }
    
    private func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupSession()
                }
            }
        }
    }
    
    // MARK: - Session Setup
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Add camera input (front camera for face, back for others)
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        // Add video output for real-time validation
        videoOutput.setSampleBufferDelegate(self, queue: analysisQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - Camera Control
    
    func startSession(for captureType: CameraCaptureType) {
        self.captureType = captureType
        self.currentInstructions = captureType.instructions
        
        // Switch camera if needed
        switchCamera(for: captureType)
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    private func switchCamera(for captureType: CameraCaptureType) {
        let preferredPosition: AVCaptureDevice.Position
        
        switch captureType {
        case .face:
            preferredPosition = .front
        case .skin, .hair:
            preferredPosition = .back
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove existing input
            if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                if currentInput.device.position != preferredPosition {
                    self.session.removeInput(currentInput)
                    
                    // Add new input
                    guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition),
                          let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                        self.session.commitConfiguration()
                        return
                    }
                    
                    if self.session.canAddInput(newInput) {
                        self.session.addInput(newInput)
                    }
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Capture
    
    func capturePhoto(completion: @escaping (Data?) -> Void) {
        guard isFrameValid else {
            HapticsManager.shared.playError()
            return
        }
        
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        if let previewFormat = settings.availablePreviewPhotoPixelFormatTypes.first {
            settings.previewPhotoFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewFormat
            ]
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        HapticsManager.shared.playImpact(.medium)
    }
    
    // MARK: - Reset
    
    func reset() {
        capturedImage = nil
        capturedImageData = nil
        validationResult = nil
        isFrameValid = false
        currentIssues = []
        skinCoveragePercent = 0
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil,
              let imageData = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { [weak self] in
                self?.captureCompletion?(nil)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImageData = imageData
            self?.capturedImage = UIImage(data: imageData)
            self?.captureCompletion?(imageData)
            HapticsManager.shared.playSuccess()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Rate limit validation
        guard validationTimer.shouldValidate(interval: validationInterval) else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Perform real-time validation
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let result = await self.biometricAnalyzer.validateCameraFrame(
                pixelBuffer: pixelBuffer,
                for: self.captureType
            )
            
            self.validationResult = result
            self.isFrameValid = result.isValid
            self.currentIssues = result.issues
            self.skinCoveragePercent = result.skinCoveragePercent ?? 0
            self.lightingQuality = result.lightingQuality ?? .acceptable
        }
    }
}

// MARK: - Camera Preview Representable

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update if needed
    }
}

class CameraPreviewUIView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Camera Capture View

struct CameraCaptureView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.dismiss) private var dismiss
    
    let captureType: CameraCaptureType
    let onCapture: (Data) -> Void
    
    @State private var showCaptureAnimation = false
    @State private var countdown: Int?
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isAuthorized {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                unauthorizedView
            }
            
            // Overlay
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                Spacer()
                
                // Capture guide
                captureGuide
                
                Spacer()
                
                // Validation indicators
                validationIndicators
                
                // Bottom controls
                bottomControls
            }
            
            // Countdown overlay
            if let count = countdown {
                countdownOverlay(count)
            }
            
            // Capture flash effect
            if showCaptureAnimation {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.5)
                    .animation(.easeOut(duration: 0.15), value: showCaptureAnimation)
            }
        }
        .onAppear {
            cameraManager.startSession(for: captureType)
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Views
    
    private var unauthorizedView: some View {
        VStack(spacing: StraynSpacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(StraynColors.textSecondary)
            
            Text("Camera Access Required")
                .font(StraynTypography.headlineMedium())
                .foregroundColor(.white)
            
            Text("Please enable camera access in Settings to capture biometric data.")
                .font(StraynTypography.bodyMedium)
                .foregroundColor(StraynColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(StraynPrimaryButtonStyle())
        }
        .padding()
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                Text(captureType.title.uppercased())
                    .font(StraynTypography.labelSmall(.bold))
                    .tracking(2)
                    .foregroundColor(StraynColors.accentPrimary)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var captureGuide: some View {
        VStack(spacing: StraynSpacing.md) {
            // Guide frame
            ZStack {
                RoundedRectangle(cornerRadius: StraynRadius.xl)
                    .stroke(
                        cameraManager.isFrameValid ? StraynColors.zoneGreen : StraynColors.accentPrimary,
                        lineWidth: 3
                    )
                    .frame(width: 280, height: 350)
                
                // Corner accents
                ForEach(0..<4, id: \.self) { corner in
                    CornerAccent(corner: corner, isValid: cameraManager.isFrameValid)
                }
            }
            
            // Instructions
            Text(cameraManager.currentInstructions)
                .font(StraynTypography.bodyMedium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: StraynRadius.sm)
                        .fill(Color.black.opacity(0.7))
                )
        }
    }
    
    private var validationIndicators: some View {
        VStack(spacing: StraynSpacing.sm) {
            // Real-time validation status
            HStack(spacing: StraynSpacing.md) {
                ValidationIndicator(
                    icon: "sun.max.fill",
                    label: "Lighting",
                    status: lightingStatus
                )
                
                ValidationIndicator(
                    icon: "camera.metering.spot",
                    label: "Focus",
                    status: cameraManager.currentIssues.contains(.imageTooBlurry) ? .warning : .good
                )
                
                if case .skin = captureType {
                    ValidationIndicator(
                        icon: "viewfinder",
                        label: "Coverage",
                        status: skinCoverageStatus
                    )
                }
            }
            .padding(.horizontal)
            
            // Active issues
            if !cameraManager.currentIssues.isEmpty {
                VStack(spacing: 4) {
                    ForEach(cameraManager.currentIssues.prefix(2)) { issue in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(StraynColors.zoneYellow)
                            
                            Text(issue.rawValue)
                                .font(StraynTypography.labelSmall())
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: StraynRadius.sm)
                        .fill(Color.black.opacity(0.7))
                )
            }
        }
        .padding(.bottom, StraynSpacing.lg)
    }
    
    private var bottomControls: some View {
        HStack {
            Spacer()
            
            // Capture button
            Button(action: startCapture) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(cameraManager.isFrameValid ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 68, height: 68)
                }
            }
            .disabled(!cameraManager.isFrameValid)
            
            Spacer()
        }
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func countdownOverlay(_ count: Int) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            Text("\(count)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Computed Properties
    
    private var lightingStatus: ValidationStatus {
        switch cameraManager.lightingQuality {
        case .excellent, .good:
            return .good
        case .acceptable:
            return .warning
        case .poor:
            return .error
        }
    }
    
    private var skinCoverageStatus: ValidationStatus {
        if cameraManager.skinCoveragePercent >= 0.6 {
            return .good
        } else if cameraManager.skinCoveragePercent >= 0.4 {
            return .warning
        } else {
            return .error
        }
    }
    
    // MARK: - Actions
    
    private func startCapture() {
        guard cameraManager.isFrameValid else { return }
        
        // Start countdown
        countdown = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let current = countdown, current > 1 {
                countdown = current - 1
                HapticsManager.shared.playImpact(.light)
            } else {
                timer.invalidate()
                countdown = nil
                performCapture()
            }
        }
    }
    
    private func performCapture() {
        showCaptureAnimation = true
        
        cameraManager.capturePhoto { imageData in
            showCaptureAnimation = false
            
            if let data = imageData {
                onCapture(data)
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct CornerAccent: View {
    let corner: Int
    let isValid: Bool
    
    var body: some View {
        let size: CGFloat = 30
        let offset: CGFloat = 140
        
        Path { path in
            switch corner {
            case 0: // Top-left
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
            case 1: // Top-right
                path.move(to: CGPoint(x: -size, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size))
            case 2: // Bottom-right
                path.move(to: CGPoint(x: 0, y: -size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -size, y: 0))
            case 3: // Bottom-left
                path.move(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -size))
            default:
                break
            }
        }
        .stroke(isValid ? StraynColors.zoneGreen : StraynColors.accentPrimary, lineWidth: 4)
        .offset(
            x: corner == 0 || corner == 3 ? -offset : offset,
            y: corner == 0 || corner == 1 ? -offset - 35 : offset + 35
        )
    }
}

enum ValidationStatus {
    case good, warning, error
    
    var color: Color {
        switch self {
        case .good: return StraynColors.zoneGreen
        case .warning: return StraynColors.zoneYellow
        case .error: return StraynColors.zoneRed
        }
    }
    
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct ValidationIndicator: View {
    let icon: String
    let label: String
    let status: ValidationStatus
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(status.color)
            }
            
            Text(label)
                .font(StraynTypography.labelSmall())
                .foregroundColor(StraynColors.textSecondary)
        }
    }
}

// MARK: - Button Style

struct StraynPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StraynTypography.labelLarge(.bold))
            .foregroundColor(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.white)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}
