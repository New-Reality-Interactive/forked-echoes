import SwiftUI

// Story 2.5: the circuit Frame's corner-mark shape cue — a via (circle) + pad (hollow square
// dormant / filled square active) at each of the reading content area's four corners. `isActive`
// binds to `engine.isEchoActive` (StoryChoiceView), which is derived from `currentNodeId`
// (AD-5) — nothing here decides activeness itself.
//
// Placeholder colors only (this story's Scoping Note): `Color.inkPrimary` dormant, reusing
// `Color.selectedFill` (already reused by ChoiceCardView for a different "highlighted state"
// purpose, Story 2.3) for active — DESIGN.md's real Frame token set (`trace-brass`,
// `accent-ember`, etc.) needs Color Set assets that don't exist yet and is Story 2.8's scope. No
// glow, no animated transition — an instant dormant/active swap is correct until Story 2.8
// introduces something for Reduce Motion to later govern.
//
// Reserved for Story/Choice reading content only (AC #4) — never wrapped around Home, Tutorial,
// or the Epic 2 Ending placeholder.
struct FrameView: View {
    let isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            ForEach(Corner.allCases, id: \.self) { corner in
                cornerMark
                    .position(corner.point(in: proxy.size))
            }
        }
        .allowsHitTesting(false)
    }

    private var cornerMark: some View {
        let color = isActive ? Color.selectedFill : Color.inkPrimary
        let viaDiameter = isActive
            ? LayoutMetrics.frameCornerViaDiameterActive
            : LayoutMetrics.frameCornerViaDiameter

        return ZStack {
            Circle()
                .fill(color)
                .frame(width: viaDiameter, height: viaDiameter)

            if isActive {
                Rectangle()
                    .fill(color)
                    .frame(width: LayoutMetrics.frameCornerPadDiameter, height: LayoutMetrics.frameCornerPadDiameter)
            } else {
                Rectangle()
                    .stroke(color, lineWidth: 1)
                    .frame(width: LayoutMetrics.frameCornerPadDiameter, height: LayoutMetrics.frameCornerPadDiameter)
            }
        }
    }

    private enum Corner: CaseIterable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing

        func point(in size: CGSize) -> CGPoint {
            switch self {
            case .topLeading: CGPoint(x: 0, y: 0)
            case .topTrailing: CGPoint(x: size.width, y: 0)
            case .bottomLeading: CGPoint(x: 0, y: size.height)
            case .bottomTrailing: CGPoint(x: size.width, y: size.height)
            }
        }
    }
}

#Preview("Dormant") {
    FrameView(isActive: false)
        .frame(width: 300, height: 400)
        .background(Color.surfaceBase)
}

#Preview("Active") {
    FrameView(isActive: true)
        .frame(width: 300, height: 400)
        .background(Color.surfaceBase)
}
