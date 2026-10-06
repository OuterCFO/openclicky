import Foundation
import CoreGraphics

nonisolated enum ReplyBubblePlacement {
    static func origin(anchor: CGPoint, size: CGSize, visibleFrame: CGRect) -> CGPoint {
        var x = anchor.x + 22
        var y = anchor.y - 6 - size.height
        if x + size.width > visibleFrame.maxX { x = anchor.x - 22 - size.width }
        if y < visibleFrame.minY { y = anchor.y + 6 }
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - size.width))
        y = max(visibleFrame.minY, min(y, visibleFrame.maxY - size.height))
        return CGPoint(x: x.rounded(), y: y.rounded())
    }
}
