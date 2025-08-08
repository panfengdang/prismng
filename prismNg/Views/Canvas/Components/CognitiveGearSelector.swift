//
//  CognitiveGearSelector.swift
//  prismNg
//
//  Cognitive Gear Selector Component
//

import SwiftUI

struct CognitiveGearSelector: View {
    @Binding var currentGear: CognitiveGear
    @Binding var driftModeActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Gear Menu
            Menu {
                ForEach([CognitiveGear.capture, .muse, .inquiry, .synthesis, .reflection], id: \.self) { gear in
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
            
            // Drift Mode Toggle
            Toggle("", isOn: $driftModeActive)
                .labelsHidden()
                .toggleStyle(DriftToggleStyle())
        }
    }
}

struct DriftToggleStyle: ToggleStyle {
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