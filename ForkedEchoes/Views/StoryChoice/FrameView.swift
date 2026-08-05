import SwiftUI

// Story 2.5: the circuit Frame's corner-mark shape cue — a via (circle) + pad (hollow square
// dormant / filled square active) at each of the reading content area's four corners. `isActive`
// binds to `engine.isEchoActive` (StoryChoiceView), which is derived from `currentNodeId`
// (AD-5) — nothing here decides activeness itself.
//
// DESIGN.md `components.frame`: `trace-brass` dormant, `accent-ember` active, plus the one
// permitted glow in the whole system (Elevation & Depth) on the active state. The power-up
// color/glow change animates unless Reduce Motion is on, per Story 2.8 AC #3 — read directly from
// SwiftUI's environment (AD-3: StoryRunEngine never touches rendering/animation).
//
// Reserved for Story/Choice reading content and the Ending screen only (Story 2.5 AC #4, Story
// 3.2 AC #2) — never wrapped around Home or Tutorial. Story 3.2's EndingView wraps this
// permanently active (isActive: true always) as the screen's one deliberate exception to
// isActive tracking engine.isEchoActive — a resting condition, not a transition.
struct FrameView: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // No DESIGN.md token for exact radius/opacity of the power-up glow — a modest,
    // clearly-visible-but-not-garish value, tunable by feel like this file's other untokened
    // constants (LayoutMetrics.swift's own convention for values with no source token).
    private static let glowRadius: CGFloat = 6
    private static let powerUpAnimationDuration: TimeInterval = 0.25

    var body: some View {
        GeometryReader { proxy in
            ForEach(Corner.allCases, id: \.self) { corner in
                cornerMark
                    .position(corner.point(in: proxy.size))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : .easeInOut(duration: Self.powerUpAnimationDuration), value: isActive)
    }

    private var cornerMark: some View {
        let color = isActive ? Color.accentEmber : Color.traceBrass
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
                    .stroke(color, lineWidth: LayoutMetrics.frameStrokeWidth)
                    .frame(width: LayoutMetrics.frameCornerPadDiameter, height: LayoutMetrics.frameCornerPadDiameter)
            }
        }
        .shadow(color: isActive ? Color.accentEmber : .clear, radius: Self.glowRadius)
    }

    private enum Corner: CaseIterable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing

        func point(in size: CGSize) -> CGPoint {
            let inset = LayoutMetrics.frameCornerInset
            return switch self {
            case .topLeading: CGPoint(x: inset, y: inset)
            case .topTrailing: CGPoint(x: size.width - inset, y: inset)
            case .bottomLeading: CGPoint(x: inset, y: size.height - inset)
            case .bottomTrailing: CGPoint(x: size.width - inset, y: size.height - inset)
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
