//
//  ModernCanvasToolbar.swift
//  prismNg
//
//  Canvas Toolbar Component
//

import SwiftUI

struct ModernCanvasToolbar: View {
    @Binding var currentTool: CanvasTool
    @Binding var canvasScale: CGFloat
    @Binding var showSearch: Bool
    @Binding var showAIPanel: Bool
    @Binding var driftModeActive: Bool
    @Binding var cognitiveGear: CognitiveGear
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool Selection
            HStack(spacing: 8) {
                ForEach(CanvasTool.allCases, id: \.self) { tool in
                    ToolButton(
                        icon: tool.rawValue,
                        isSelected: currentTool == tool,
                        action: { currentTool = tool }
                    )
                }
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Divider()
                .frame(height: 30)
            
            // Zoom Controls
            HStack(spacing: 4) {
                Button(action: { 
                    withAnimation(.spring(duration: 0.3)) {
                        canvasScale = max(0.1, canvasScale - 0.1)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 16))
                }
                
                Text("\(Int(canvasScale * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .frame(width: 50)
                
                Button(action: { 
                    withAnimation(.spring(duration: 0.3)) {
                        canvasScale = min(5.0, canvasScale + 0.1)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 16))
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)
                
                Button(action: { 
                    withAnimation(.spring(duration: 0.3)) {
                        canvasScale = 1.0
                    }
                }) {
                    Text("100%")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Cognitive Controls
            CognitiveGearCompact(
                currentGear: $cognitiveGear,
                driftModeActive: $driftModeActive
            )
            
            // AI Features
            Button(action: { showAIPanel.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("AI")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(showAIPanel ? Color.purple : Color.purple.opacity(0.1))
                .foregroundColor(showAIPanel ? .white : .purple)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Search
            Button(action: { showSearch.toggle() }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(showSearch ? .blue : .primary)
                    .padding(10)
                    .background(showSearch ? Color.blue.opacity(0.1) : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct CognitiveGearCompact: View {
    @Binding var currentGear: CognitiveGear
    @Binding var driftModeActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach([CognitiveGear.capture, .muse, .inquiry], id: \.self) { gear in
                    Button(action: { currentGear = gear }) {
                        Label(gear.displayName, systemImage: gear.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: currentGear.icon)
                    Text(currentGear.displayName)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(currentGear.color.opacity(0.1))
                .foregroundColor(currentGear.color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Toggle("", isOn: $driftModeActive)
                .labelsHidden()
                .toggleStyle(DriftModeToggleStyle())
        }
    }
}

struct DriftModeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: configuration.isOn ? "wind" : "wind.snow")
                    .font(.system(size: 14))
                Text("Drift")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(configuration.isOn ? Color.cyan : Color.gray.opacity(0.2))
            .foregroundColor(configuration.isOn ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .animation(.spring(duration: 0.2), value: configuration.isOn)
        }
    }
}