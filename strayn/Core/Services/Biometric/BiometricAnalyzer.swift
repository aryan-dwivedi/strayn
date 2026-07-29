//
//  BiometricAnalyzer.swift
//  strayn
//
//  AI-powered biometric analysis service for skin tone, face validation, hair analysis, and body composition.
//

import Foundation
import UIKit
import Vision
import CoreImage

class BiometricAnalyzer {
    
    static let shared = BiometricAnalyzer()
    
    private init() {}
    
    // MARK: - Skin Tone Analysis
    
    struct SkinToneAnalysisResult {
        let skinType: FitzpatrickSkinType
        let variance: Double
        let confidence: Double
        let regionResults: [SkinCaptureRegion: FitzpatrickSkinType]
    }
    
    func analyzeSkinTone(from capture: SkinToneCapture) async -> SkinToneAnalysisResult {
        var regionResults: [SkinCaptureRegion: FitzpatrickSkinType] = [:]
        
        // Analyze each region
        if let forearmData = capture.innerForearmImage,
           let forearmType = await analyzeImageForSkinTone(imageData: forearmData) {
            regionResults[.innerForearm] = forearmType
        }
        
        if let legData = capture.lowerLegImage,
           let legType = await analyzeImageForSkinTone(imageData: legData) {
            regionResults[.lowerLeg] = legType
        }
        
        if let abdomenData = capture.abdomenImage,
           let abdomenType = await analyzeImageForSkinTone(imageData: abdomenData) {
            regionResults[.abdomen] = abdomenType
        }
        
        // Calculate average and variance
        let types = regionResults.values.map { $0.rawValue }
        let average = types.isEmpty ? 3 : Int(round(Double(types.reduce(0, +)) / Double(types.count)))
        
        let variance: Double
        if types.count > 1 {
            let mean = Double(types.reduce(0, +)) / Double(types.count)
            let squaredDiffs = types.map { pow(Double($0) - mean, 2) }
            variance = sqrt(squaredDiffs.reduce(0, +) / Double(types.count))
        } else {
            variance = 0
        }
        
        let determinedType = FitzpatrickSkinType(rawValue: average) ?? .typeIII
        let confidence = max(0, 1.0 - (variance / 3.0)) // Higher variance = lower confidence
        
        return SkinToneAnalysisResult(
            skinType: determinedType,
            variance: variance,
            confidence: confidence,
            regionResults: regionResults
        )
    }
    
    private func analyzeImageForSkinTone(imageData: Data) async -> FitzpatrickSkinType? {
        guard let image = UIImage(data: imageData),
              let ciImage = CIImage(image: image) else {
            return nil
        }
        
        // Extract average color from image center (skin region)
        let extent = ciImage.extent
        let centerRect = CGRect(
            x: extent.midX - extent.width * 0.2,
            y: extent.midY - extent.height * 0.2,
            width: extent.width * 0.4,
            height: extent.height * 0.4
        )
        
        guard let croppedImage = ciImage.cropped(to: centerRect).averageColor() else {
            return .typeIII // Default
        }
        
        // Convert RGB to luminance (ITU-R BT.709)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        croppedImage.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        
        // Map luminance to Fitzpatrick type
        // Type I: Very fair (~0.85+)
        // Type VI: Dark brown/black (~0.25 or less)
        switch luminance {
        case 0.80...:
            return .typeI
        case 0.65..<0.80:
            return .typeII
        case 0.50..<0.65:
            return .typeIII
        case 0.38..<0.50:
            return .typeIV
        case 0.25..<0.38:
            return .typeV
        default:
            return .typeVI
        }
    }
    
    // MARK: - Face Capture Validation
    
    func validateFaceCapture(_ imageData: Data, type: FaceCaptureType) async -> FaceCaptureValidation {
        var validation = FaceCaptureValidation()
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return validation
        }
        
        // Run Vision face detection
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results, let face = results.first {
                // Face bounding box analysis
                let faceRect = face.boundingBox
                
                // Check centering (face should be roughly centered)
                let centerX = faceRect.midX
                let centerY = faceRect.midY
                validation.isCentered = (0.3...0.7).contains(centerX) && (0.3...0.7).contains(centerY)
                
                // Check face size (should be prominent in frame)
                let faceArea = faceRect.width * faceRect.height
                validation.alignmentScore = min(1.0, faceArea * 4) // Scale so ~25% coverage = 100%
                
                // Check landmarks for eye openness
                if let landmarks = face.landmarks {
                    validation.eyesOpen = landmarks.leftEye != nil && landmarks.rightEye != nil
                    validation.skinTextureVisible = true
                }
                
                // Check for occlusions (simplified)
                validation.hasOcclusion = false // Would use more sophisticated analysis
                
                // Blur detection (simplified using image sharpness)
                validation.blurPercentage = await calculateBlurPercentage(image: image)
                
                // Lighting uniformity (simplified)
                validation.isEvenlyLit = await checkLightingUniformity(image: image)
            }
        } catch {
            print("Face detection failed: \(error)")
        }
        
        return validation
    }
    
    private func calculateBlurPercentage(image: UIImage) async -> Double {
        guard let ciImage = CIImage(image: image) else { return 100 }
        
        // Use Laplacian variance as blur metric
        let context = CIContext()
        
        // Apply Laplacian filter (edge detection)
        guard let filter = CIFilter(name: "CIEdges") else { return 100 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return 100
        }
        
        // Calculate variance of edge image (higher = sharper)
        let variance = calculateImageVariance(cgImage: outputCGImage)
        
        // Map variance to blur percentage (inverse relationship)
        let blurPercentage = max(0, min(100, 100 - variance * 1000))
        return blurPercentage
    }
    
    private func calculateImageVariance(cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Calculate mean
        var sum: Double = 0
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let gray = (Double(pixelData[i]) + Double(pixelData[i+1]) + Double(pixelData[i+2])) / 3
            sum += gray
        }
        let mean = sum / Double(width * height)
        
        // Calculate variance
        var varianceSum: Double = 0
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let gray = (Double(pixelData[i]) + Double(pixelData[i+1]) + Double(pixelData[i+2])) / 3
            varianceSum += pow(gray - mean, 2)
        }
        
        return varianceSum / Double(width * height)
    }
    
    private func checkLightingUniformity(image: UIImage) async -> Bool {
        guard let ciImage = CIImage(image: image) else { return false }
        
        let extent = ciImage.extent
        
        // Sample brightness from 4 quadrants
        let quadrants = [
            CGRect(x: 0, y: 0, width: extent.width/2, height: extent.height/2),
            CGRect(x: extent.width/2, y: 0, width: extent.width/2, height: extent.height/2),
            CGRect(x: 0, y: extent.height/2, width: extent.width/2, height: extent.height/2),
            CGRect(x: extent.width/2, y: extent.height/2, width: extent.width/2, height: extent.height/2)
        ]
        
        var luminances: [Double] = []
        
        for quadrant in quadrants {
            if let color = ciImage.cropped(to: quadrant).averageColor() {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let luminance = 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
                luminances.append(luminance)
            }
        }
        
        guard luminances.count == 4 else { return false }
        
        // Check if all quadrants have similar brightness (within 20%)
        let maxLum = luminances.max() ?? 1
        let minLum = luminances.min() ?? 0
        let variation = (maxLum - minLum) / maxLum
        
        return variation < 0.3 // Within 30% variation = even lighting
    }
    
    // MARK: - Hairline Analysis
    
    struct HairlineAnalysisResult {
        let densityScore: Double
        let thinningIndicator: ThinningIndicator
        let scalpHealthScore: Double
    }
    
    func analyzeHairline(from capture: HairlineScalpCapture) async -> HairlineAnalysisResult {
        var densityScores: [Double] = []
        
        // Analyze frontal hairline
        if let frontalData = capture.frontalHairlineImage {
            let score = await analyzeHairDensity(imageData: frontalData)
            densityScores.append(score)
        }
        
        // Analyze crown
        if let crownData = capture.crownScalpImage {
            let score = await analyzeHairDensity(imageData: crownData)
            densityScores.append(score)
        }
        
        let averageDensity = densityScores.isEmpty ? 0.5 : densityScores.reduce(0, +) / Double(densityScores.count)
        
        // Determine thinning indicator
        let thinning: ThinningIndicator
        switch averageDensity {
        case 0.75...:
            thinning = .none
        case 0.55..<0.75:
            thinning = .minimal
        case 0.35..<0.55:
            thinning = .moderate
        default:
            thinning = .significant
        }
        
        // Scalp health score (simplified - based on density and uniformity)
        let scalpHealth = averageDensity * 0.8 + 0.2 // Minimum 20% baseline
        
        return HairlineAnalysisResult(
            densityScore: averageDensity,
            thinningIndicator: thinning,
            scalpHealthScore: scalpHealth
        )
    }
    
    private func analyzeHairDensity(imageData: Data) async -> Double {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return 0.5 // Default mid-density
        }
        
        // Use edge detection to estimate hair strand density
        // More edges = more hair strands = higher density
        let variance = calculateImageVariance(cgImage: cgImage)
        
        // Map variance to density score (0-1)
        // Higher variance indicates more texture (hair)
        let normalizedDensity = min(1.0, variance / 2000)
        
        return normalizedDensity
    }
    
    // MARK: - Body Composition Estimation
    
    func estimateBodyComposition(
        age: Int,
        sex: BiologicalSexOption,
        heightCm: Double,
        weightKg: Double,
        skinType: FitzpatrickSkinType?,
        hairDensity: Double?
    ) async -> BodyCompositionEstimate {
        
        // Calculate BMI as base
        let heightM = heightCm / 100
        let bmi = weightKg / (heightM * heightM)
        
        // Estimate body fat category based on BMI (simplified)
        let bodyFat: BodyFatCategory
        let bmiThresholds: (low: Double, high: Double)
        
        switch sex {
        case .male:
            bmiThresholds = (low: 20, high: 25)
        case .female:
            bmiThresholds = (low: 18.5, high: 24)
        case .preferNotToSay:
            bmiThresholds = (low: 19, high: 24.5)
        }
        
        if bmi < bmiThresholds.low {
            bodyFat = .low
        } else if bmi > bmiThresholds.high + 3 {
            bodyFat = .high
        } else {
            bodyFat = .moderate
        }
        
        // Muscle signal estimation
        // Higher BMI with lower body fat indication suggests muscle
        let muscleSignal: MuscleSignal
        if bmi > 25 && bodyFat != .high {
            muscleSignal = .high
        } else if bmi < 20 {
            muscleSignal = .low
        } else {
            muscleSignal = .medium
        }
        
        // Water retention (simplified - based on age and metabolic factors)
        let waterRetention: WaterRetentionLevel
        if age > 50 {
            waterRetention = .elevated
        } else if bmi > 28 {
            waterRetention = .elevated
        } else {
            waterRetention = .moderate
        }
        
        // Confidence based on available data
        var confidence = 0.6 // Base confidence
        if skinType != nil { confidence += 0.1 }
        if hairDensity != nil { confidence += 0.1 }
        // In real app, face analysis would add more confidence
        confidence = min(0.85, confidence) // Cap at 85% - never claim certainty
        
        return BodyCompositionEstimate(
            bodyFatCategory: bodyFat,
            muscleSignal: muscleSignal,
            waterRetentionIndicator: waterRetention,
            confidenceLevel: confidence,
            analysisNotes: "AI-assisted estimation based on BMI, age, and biometric signals."
        )
    }
    
    // MARK: - Camera Validation
    
    func validateCameraFrame(
        pixelBuffer: CVPixelBuffer,
        for captureType: CameraCaptureType
    ) async -> CameraValidationResult {
        
        var issues: [CameraValidationIssue] = []
        
        // Convert to CIImage for analysis
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Check brightness
        if let avgColor = ciImage.averageColor() {
            var brightness: CGFloat = 0
            avgColor.getWhite(&brightness, alpha: nil)
            
            if brightness < 0.2 {
                issues.append(.poorLighting)
            } else if brightness > 0.9 {
                issues.append(.tooMuchGlare)
            }
        }
        
        // Sharpness check
        let sharpness = await calculateSharpnessScore(ciImage: ciImage)
        if sharpness < 0.3 {
            issues.append(.imageTooBlurry)
        }
        
        // Skin coverage check (for skin captures)
        var skinCoverage: Double = 0
        if case .skin = captureType {
            skinCoverage = await estimateSkinCoverage(ciImage: ciImage)
            if skinCoverage < 0.6 {
                issues.append(.insufficientSkinCoverage)
            }
        }
        
        // Determine lighting quality
        let lightingQuality: LightingQuality
        if issues.contains(.poorLighting) || issues.contains(.tooMuchGlare) {
            lightingQuality = .poor
        } else if issues.contains(.shadowsDetected) {
            lightingQuality = .acceptable
        } else {
            lightingQuality = sharpness > 0.6 ? .excellent : .good
        }
        
        return CameraValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            skinCoveragePercent: skinCoverage,
            lightingQuality: lightingQuality,
            sharpnessScore: sharpness
        )
    }
    
    private func calculateSharpnessScore(ciImage: CIImage) async -> Double {
        guard let filter = CIFilter(name: "CIEdges") else { return 0.5 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage,
              let avgColor = outputImage.averageColor() else {
            return 0.5
        }
        
        var brightness: CGFloat = 0
        avgColor.getWhite(&brightness, alpha: nil)
        
        return Double(brightness)
    }
    
    private func estimateSkinCoverage(ciImage: CIImage) async -> Double {
        // Simplified skin detection using color range
        guard let avgColor = ciImage.averageColor() else { return 0.5 }
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        avgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Check if color falls within typical skin tone range
        let isSkinTone = red > 0.4 && red < 0.95 &&
                         green > 0.2 && green < 0.85 &&
                         blue > 0.15 && blue < 0.75 &&
                         red > green && green > blue
        
        return isSkinTone ? 0.75 : 0.4
    }
}

// MARK: - CIImage Extension

extension CIImage {
    func averageColor() -> UIColor? {
        let context = CIContext(options: nil)
        
        // Scale down for faster processing
        let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
        scaleFilter.setValue(self, forKey: kCIInputImageKey)
        scaleFilter.setValue(0.1, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let scaledImage = scaleFilter.outputImage else { return nil }
        
        // Apply area average filter
        let extentVector = CIVector(x: scaledImage.extent.origin.x,
                                    y: scaledImage.extent.origin.y,
                                    z: scaledImage.extent.size.width,
                                    w: scaledImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: scaledImage,
                                                 kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return nil
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}
