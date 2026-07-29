//
//  WeeklyReportService.swift
//  strayn
//
//  Created by Aryan Dwivedi on 18/01/26.
//

import Foundation
import PDFKit
import SwiftUI

class WeeklyReportService {
    static let shared = WeeklyReportService()
    
    @MainActor
    func generateReport(startDate: Date, endDate: Date) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Strayn App",
            kCGPDFContextAuthor: "Strayn Intelligence"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let width = 8.5 * 72.0 // 612
        let height = 11.0 * 72.0 // 792
        let pageRect = CGRect(x: 0, y: 0, width: width, height: height)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let title = "Strayn Weekly Health Report"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Date Range
            let dateText = "\(startDate.formatted(date: .numeric, time: .omitted)) - \(endDate.formatted(date: .numeric, time: .omitted))"
            dateText.draw(at: CGPoint(x: 50, y: 80), withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ])
            
            // Mock Content Drawing
            // In a real app, we would loop through data and draw charts/text
            let summary = """
            Recovery Trends:
            - Average Recovery: 72%
            - Strain Balance: Optimal
            - Sleep Consistency: B+
            
            Strayn Age Adjustment: -1.2 Years
            """
            
            summary.draw(in: CGRect(x: 50, y: 150, width: 500, height: 300), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: NSMutableParagraphStyle()
            ])
        }
        
        return savePDFData(data)
    }
    
    private func savePDFData(_ data: Data) -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let docURL = urls.first else { return nil }
        let fileURL = docURL.appendingPathComponent("Strayn_Report.pdf")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}
