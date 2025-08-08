//
//  RadialMenuView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

// MARK: - Radial Menu View
struct RadialMenuView: View {
    @Binding var isPresented: Bool
    let location: CGPoint
    let onSelection: (RadialMenuItem) -> Void
    
    @State private var selectedItem: RadialMenuItem?
    @State private var dragLocation: CGPoint = .zero
    @State private var animationProgress: Double = 0
    
    private let menuItems: [RadialMenuItem] = [
        RadialMenuItem(id: "text", icon: "text.bubble", title: "文本", angle: 0),
        RadialMenuItem(id: "voice", icon: "mic", title: "语音", angle: .pi / 2),
        RadialMenuItem(id: "question", icon: "questionmark.circle", title: "问题", angle: .pi),
        RadialMenuItem(id: "insight", icon: "lightbulb", title: "灵感", angle: -.pi / 2)
    ]
    
    private let menuRadius: CGFloat = 80
    private let itemRadius: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Center indicator
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(animationProgress)
                .opacity(animationProgress)
            
            // Menu items
            ForEach(menuItems) { item in
                RadialMenuItemView(
                    item: item,
                    isSelected: selectedItem?.id == item.id,
                    radius: menuRadius,
                    itemRadius: itemRadius,
                    animationProgress: animationProgress
                )
            }
            
            // Selection indicator
            if let selected = selectedItem {
                SelectionIndicatorView(
                    angle: selected.angle,
                    radius: menuRadius,
                    animationProgress: animationProgress
                )
            }
        }
        .position(location)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
        .onDisappear {
            animationProgress = 0
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateSelection(at: value.location)
                }
                .onEnded { value in
                    if let selected = selectedItem {
                        onSelection(selected)
                    }
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
        )
    }
    
    private func updateSelection(at point: CGPoint) {
        let dx = point.x - location.x
        let dy = point.y - location.y
        let distance = hypot(dx, dy)
        
        guard distance > 30 else {
            selectedItem = nil
            return
        }
        
        let angle = atan2(dy, dx)
        
        // Find closest menu item
        selectedItem = menuItems.min(by: { item1, item2 in
            let diff1 = abs(angleDistance(angle, item1.angle))
            let diff2 = abs(angleDistance(angle, item2.angle))
            return diff1 < diff2
        })
    }
    
    private func angleDistance(_ a1: Double, _ a2: Double) -> Double {
        var diff = a1 - a2
        while diff > .pi { diff -= 2 * .pi }
        while diff < -.pi { diff += 2 * .pi }
        return diff
    }
}

// MARK: - Radial Menu Item View
struct RadialMenuItemView: View {
    let item: RadialMenuItem
    let isSelected: Bool
    let radius: CGFloat
    let itemRadius: CGFloat
    let animationProgress: Double
    
    private var itemPosition: CGPoint {
        CGPoint(
            x: Darwin.cos(item.angle) * radius,
            y: Darwin.sin(item.angle) * radius
        )
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color(.systemGray5))
                .frame(width: itemRadius * 2, height: itemRadius * 2)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), 
                       radius: isSelected ? 8 : 4)
            
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .primary)
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .offset(
            x: itemPosition.x * animationProgress,
            y: itemPosition.y * animationProgress
        )
        .opacity(animationProgress)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Selection Indicator View
struct SelectionIndicatorView: View {
    let angle: Double
    let radius: CGFloat
    let animationProgress: Double
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            let endPoint = CGPoint(
                x: Darwin.cos(angle) * radius * 0.6,
                y: Darwin.sin(angle) * radius * 0.6
            )
            path.addLine(to: endPoint)
        }
        .stroke(Color.blue, lineWidth: 3)
        .opacity(animationProgress * 0.6)
    }
}

// MARK: - Radial Menu Item Model
struct RadialMenuItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let angle: Double
}

// MARK: - Radial Menu Overlay Modifier
struct RadialMenuModifier: ViewModifier {
    @Binding var showRadialMenu: Bool
    @Binding var radialMenuLocation: CGPoint
    let onSelection: (RadialMenuItem) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showRadialMenu {
                        // Background dim
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showRadialMenu = false
                                }
                            }
                        
                        // Radial menu
                        RadialMenuView(
                            isPresented: $showRadialMenu,
                            location: radialMenuLocation,
                            onSelection: onSelection
                        )
                    }
                }
            )
    }
}

extension View {
    func radialMenu(
        isPresented: Binding<Bool>,
        location: Binding<CGPoint>,
        onSelection: @escaping (RadialMenuItem) -> Void
    ) -> some View {
        modifier(RadialMenuModifier(
            showRadialMenu: isPresented,
            radialMenuLocation: location,
            onSelection: onSelection
        ))
    }
}