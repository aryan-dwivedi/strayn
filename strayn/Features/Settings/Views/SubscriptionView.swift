//
//  SubscriptionView.swift
//  strayn
//
//  Premium "Strayn Pro" subscription gate.
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Unlock Strayn Pro")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("Biological Intelligence Unlimited")
                        .font(.headline)
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(.top, 40)
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(title: "Biological Age Deep Dive", subtitle: "Breakdown of Cardiovascular & Autonomic age.")
                    featureRow(title: "Predictive Recovery", subtitle: "48-hour forecasting for optimal training.")
                    featureRow(title: "Correlation Discovery", subtitle: "AI-driven mapping of habits to biology.")
                    featureRow(title: "Unlimited History", subtitle: "Every beat, every night, forever.")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Pricing Card
                VStack(spacing: 16) {
                    VStack {
                        Text("Annual Membership")
                            .font(.headline)
                        Text("$9.99 / MONTH")
                            .font(.title3.bold())
                        Text("Billed as $119.99/yr")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).stroke(Color.blue, lineWidth: 2))
                    
                    Button(action: { dismiss() }) {
                        Text("Start 7-Day Free Trial")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("No thanks, I'll stick to basic scores")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }
    
    private func featureRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
