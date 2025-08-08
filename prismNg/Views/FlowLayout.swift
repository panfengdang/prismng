//
//  FlowLayout.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for row in result.rows {
            let rowXOffset = (bounds.width - row.frame.width) / 2
            for index in row.range {
                let xPos = rowXOffset + row.frame.minX + row.xOffsets[index - row.range.lowerBound] + bounds.minX
                let yPos = row.frame.minY + bounds.minY
                subviews[index].place(
                    at: CGPoint(x: xPos, y: yPos),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(
                        width: row.widths[index - row.range.lowerBound],
                        height: row.frame.height
                    )
                )
            }
        }
    }
    
    struct FlowResult {
        var bounds = CGSize.zero
        var rows = [Row]()
        
        struct Row {
            var range: Range<Int>
            var xOffsets: [Double]
            var widths: [Double]
            var frame: CGRect
        }
        
        init(in maxPossibleWidth: Double, subviews: Subviews, spacing: CGFloat) {
            var itemsInRow = 0
            var remainingWidth = maxPossibleWidth.isFinite ? maxPossibleWidth : .greatestFiniteMagnitude
            var rowMinY = 0.0
            var rowHeight = 0.0
            var xOffsets: [Double] = []
            var widths: [Double] = []
            for (index, subview) in zip(subviews.indices, subviews) {
                let idealSize = subview.sizeThatFits(.unspecified)
                if index != 0 && widths.count != 0 && (idealSize.width + spacing) > remainingWidth {
                    // Finish the current row without this subview.
                    finalizeRow(
                        rowMinY: rowMinY,
                        rowHeight: rowHeight,
                        xOffsets: xOffsets,
                        widths: widths,
                        spacing: spacing
                    )
                    // Start a new row with this subview.
                    xOffsets.removeAll()
                    widths.removeAll()
                    itemsInRow = 0
                    rowMinY += rowHeight + spacing
                    rowHeight = 0.0
                    remainingWidth = maxPossibleWidth.isFinite ? maxPossibleWidth : .greatestFiniteMagnitude
                }
                addToRow(
                    idealSize: idealSize,
                    spacing: spacing,
                    &xOffsets,
                    &widths,
                    &remainingWidth,
                    &rowHeight
                )
                itemsInRow += 1
            }
            if itemsInRow > 0 {
                // Finish the last row.
                finalizeRow(
                    rowMinY: rowMinY,
                    rowHeight: rowHeight,
                    xOffsets: xOffsets,
                    widths: widths,
                    spacing: spacing
                )
            }
        }
        
        mutating func finalizeRow(rowMinY: Double, rowHeight: Double, xOffsets: [Double], widths: [Double], spacing: CGFloat) {
            let rowWidth = widths.reduce(0, +) + Double(widths.count - 1) * spacing
            rows.append(
                Row(
                    range: (rows.last?.range.upperBound ?? 0)..<(rows.last?.range.upperBound ?? 0) + widths.count,
                    xOffsets: xOffsets,
                    widths: widths,
                    frame: CGRect(x: 0, y: rowMinY, width: rowWidth, height: rowHeight)
                )
            )
            bounds.width = max(bounds.width, rowWidth)
            bounds.height = rowMinY + rowHeight
        }
        
        func addToRow(idealSize: CGSize, spacing: CGFloat, _ xOffsets: inout [Double], _ widths: inout [Double], _ remainingWidth: inout Double, _ rowHeight: inout Double) {
            xOffsets.append(maxPossibleWidth(in: widths, spacing: spacing))
            widths.append(idealSize.width)
            remainingWidth -= idealSize.width + spacing
            rowHeight = max(rowHeight, idealSize.height)
        }
        
        func maxPossibleWidth(in widths: [Double], spacing: CGFloat) -> Double {
            widths.reduce(0, +) + Double(widths.count) * spacing
        }
    }
}

// Usage example preview
struct FlowLayout_Previews: PreviewProvider {
    static var previews: some View {
        FlowLayout(spacing: 8) {
            ForEach(["Hello", "World", "This", "Is", "A", "Flow", "Layout"], id: \.self) { text in
                Text(text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}