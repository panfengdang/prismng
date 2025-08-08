//
//  ModernCanvasBackground.swift
//  prismNg
//
//  Canvas background with grid
//

import SwiftUI

struct ModernCanvasBackground: View {
    let canvasOffset: CGSize
    let canvasScale: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawGrid(context: context, size: size)
                drawCenterCross(context: context, size: size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let gridSize: CGFloat = 20 * canvasScale
        let offsetX = canvasOffset.width.truncatingRemainder(dividingBy: gridSize)
        let offsetY = canvasOffset.height.truncatingRemainder(dividingBy: gridSize)
        
        // Vertical lines
        for x in stride(from: offsetX, to: size.width, by: gridSize) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(.gray.opacity(0.1)),
                lineWidth: 0.5
            )
        }
        
        // Horizontal lines
        for y in stride(from: offsetY, to: size.height, by: gridSize) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(.gray.opacity(0.1)),
                lineWidth: 0.5
            )
        }
        
        // Major grid lines every 5 units
        let majorGridSize = gridSize * 5
        let majorOffsetX = canvasOffset.width.truncatingRemainder(dividingBy: majorGridSize)
        let majorOffsetY = canvasOffset.height.truncatingRemainder(dividingBy: majorGridSize)
        
        for x in stride(from: majorOffsetX, to: size.width, by: majorGridSize) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(.gray.opacity(0.2)),
                lineWidth: 1
            )
        }
        
        for y in stride(from: majorOffsetY, to: size.height, by: majorGridSize) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(.gray.opacity(0.2)),
                lineWidth: 1
            )
        }
    }
    
    private func drawCenterCross(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let crossSize: CGFloat = 10
        
        // Draw center cross indicator
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: center.x - crossSize, y: center.y))
                path.addLine(to: CGPoint(x: center.x + crossSize, y: center.y))
                path.move(to: CGPoint(x: center.x, y: center.y - crossSize))
                path.addLine(to: CGPoint(x: center.x, y: center.y + crossSize))
            },
            with: .color(.blue.opacity(0.3)),
            lineWidth: 1
        )
    }
}