//
//  FreeTierOnboardingView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

// MARK: - Free Tier Onboarding View
struct FreeTierOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("跳过") {
                    isPresented = false
                }
                .padding()
            }
            
            // Content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                
                FreeFeaturesPage()
                    .tag(1)
                
                AIQuotaPage()
                    .tag(2)
                
                GetStartedPage(isPresented: $isPresented)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("上一步") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                if currentPage < 3 {
                    Button("下一步") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "brain")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                        .offset(x: 50, y: -30)
                )
            
            VStack(spacing: 16) {
                Text("欢迎使用 Prism")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("永久免费版")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                
                Text("您的 AI 思维伙伴\n无需付费即可开始")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Free Features Page
struct FreeFeaturesPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("免费功能")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "infinity",
                    title: "无限本地节点",
                    description: "创建无限数量的想法节点，完全离线运行"
                )
                
                FeatureRow(
                    icon: "hand.tap",
                    title: "双轨交互",
                    description: "传统按钮与手势控制，随心切换"
                )
                
                FeatureRow(
                    icon: "magnifyingglass",
                    title: "本地向量搜索",
                    description: "基于语义的智能搜索，快速找到相关内容"
                )
                
                FeatureRow(
                    icon: "rectangle.connected.to.line.below",
                    title: "思维导图",
                    description: "可视化您的想法网络，探索连接"
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// MARK: - AI Quota Page
struct AIQuotaPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("AI 智能分析")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            // Quota visualization
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                VStack {
                    Text("2")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("次/天")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 20) {
                Text("每日 2 次免费 AI 分析")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    AIFeatureItem(text: "智能联想推荐")
                    AIFeatureItem(text: "结构化分析")
                    AIFeatureItem(text: "矛盾点发现")
                    AIFeatureItem(text: "深度洞察生成")
                }
                
                Text("每日凌晨自动重置配额")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            
            Spacer()
        }
    }
}

// MARK: - Get Started Page
struct GetStartedPage: View {
    @Binding var isPresented: Bool
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated checkmarks
            VStack(spacing: 20) {
                AnimatedCheckmark(text: "完全免费，永不过期", animate: $animateElements, delay: 0)
                AnimatedCheckmark(text: "所有本地功能无限制", animate: $animateElements, delay: 0.2)
                AnimatedCheckmark(text: "每日 2 次 AI 分析", animate: $animateElements, delay: 0.4)
                AnimatedCheckmark(text: "随时可选择升级", animate: $animateElements, delay: 0.6)
            }
            
            Spacer()
            
            // Start button
            Button {
                isPresented = false
            } label: {
                Text("开始使用")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .scaleEffect(animateElements ? 1 : 0.8)
            .opacity(animateElements ? 1 : 0)
            
            // Upgrade option
            Button {
                isPresented = false
                // TODO: Show subscription view
            } label: {
                Text("了解更多高级功能")
                    .font(.callout)
                    .foregroundColor(.blue)
            }
            .opacity(animateElements ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateElements = true
            }
        }
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AIFeatureItem: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.yellow)
            Text(text)
                .font(.callout)
        }
    }
}

struct AnimatedCheckmark: View {
    let text: String
    @Binding var animate: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
                .scaleEffect(animate ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay), value: animate)
            
            Text(text)
                .font(.body)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(delay + 0.1), value: animate)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    FreeTierOnboardingView(isPresented: .constant(true))
}