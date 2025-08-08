//
//  QuotaIndicatorView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

struct QuotaIndicatorView: View {
    @ObservedObject var quotaService: QuotaManagementService
    @State private var showUpgradeSheet = false
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            // AI icon
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(quotaColor)
            
            if quotaService.isUnlimitedQuota() {
                Text("∞")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
            } else {
                // Quota usage
                HStack(spacing: 3) {
                    Text("\(quotaService.getRemainingQuota())")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(quotaColor)
                    
                    Text("/")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(quotaService.dailyQuotaLimit)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Visual indicator
                QuotaProgressView(percentage: quotaService.getQuotaPercentage())
                    .frame(width: 40, height: 4)
            }
            
            // Time until reset
            if !quotaService.isUnlimitedQuota() && quotaService.getRemainingQuota() == 0 {
                Text(quotaService.getTimeUntilReset())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(quotaColor.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            showUpgradeSheet = true
        }
        .sheet(isPresented: $showUpgradeSheet) {
            SubscriptionView(quotaService: quotaService)
        }
        .alert("AI 额度已用完", isPresented: $quotaService.showQuotaExceededAlert) {
            Button("了解") {
                quotaService.showQuotaExceededAlert = false
            }
            Button("升级") {
                showUpgradeSheet = true
            }
        } message: {
            Text("您今天的免费 AI 分析额度已经用完了。升级到付费套餐以获得更多额度。")
        }
    }
    
    private var quotaColor: Color {
        let percentage = quotaService.getQuotaPercentage()
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .purple
        }
    }
}

// MARK: - Quota Progress View
struct QuotaProgressView: View {
    let percentage: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                Capsule()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * min(1.0, percentage))
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
        }
    }
    
    private var progressColor: Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .purple
        }
    }
}

// MARK: - Compact Quota Badge
struct QuotaBadgeView: View {
    @ObservedObject var quotaService: QuotaManagementService
    
    var body: some View {
        if quotaService.isUnlimitedQuota() {
            Image(systemName: "infinity")
                .font(.caption2)
                .foregroundColor(.purple)
                .padding(4)
                .background(Circle().fill(Color.purple.opacity(0.1)))
        } else {
            Text("\(quotaService.getRemainingQuota())")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(badgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(badgeColor.opacity(0.1))
                )
        }
    }
    
    private var badgeColor: Color {
        let remaining = quotaService.getRemainingQuota()
        if remaining == 0 {
            return .red
        } else if remaining == 1 {
            return .orange
        } else {
            return .purple
        }
    }
}

// MARK: - AI Feature Button with Quota Check
// AIFeatureButton is now defined in Views/AIFeatureButton.swift