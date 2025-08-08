//
//  NodeTypeExtensions.swift
//  prismNg
//
//  Extensions for NodeType
//

import Foundation
import SwiftUI

extension NodeType {
    var icon: String {
        switch self {
        case .thought: return "brain"
        case .insight: return "lightbulb"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.circle"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "square.grid.3x3"
        }
    }
    
    var color: Color {
        switch self {
        case .thought: return .blue
        case .insight: return .yellow
        case .question: return .purple
        case .conclusion: return .green
        case .contradiction: return .red
        case .structure: return .orange
        }
    }
}