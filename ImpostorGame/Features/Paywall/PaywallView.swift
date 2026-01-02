//
//  PaywallView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct PaywallView: View {
    @State private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onPurchaseComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .yellow.opacity(0.4), radius: 20)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("فتح استضافة الألعاب")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("دفعة واحدة • بلا اشتراكات")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Features - compact
                VStack(spacing: 10) {
                    CompactFeatureRow(icon: "infinity", text: "ألعاب غير محدودة")
                    CompactFeatureRow(icon: "doc.text.fill", text: "جميع القوالب")
                    CompactFeatureRow(icon: "plus.circle.fill", text: "إنشاء قوالب خاصة")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Price and purchase button
                VStack(spacing: 12) {
                    // Price
                    Text(viewModel.price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    // Purchase button
                    Button {
                        Task {
                            await viewModel.purchase()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text(Constants.Strings.purchase)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .yellow.opacity(0.3), radius: 10)
                    }
                    .disabled(!viewModel.hasOffering)
                    .opacity(viewModel.hasOffering ? 1 : 0.6)
                    .padding(.horizontal)
                    
                    // Restore purchases
                    Button {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    } label: {
                        Text("استعادة المشتريات")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // Free note
                    Text("الانضمام للألعاب مجاني")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 24)
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(error: $viewModel.error)
        .onChange(of: viewModel.purchaseSuccessful) { _, success in
            if success {
                onPurchaseComplete()
                dismiss()
            }
        }
        .task {
            await viewModel.loadOfferings()
        }
        .rtl()
    }
    
    // MARK: - Background
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.3, green: 0.15, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Compact Feature Row
struct CompactFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.yellow)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PaywallView {
        print("Purchase complete")
    }
}

