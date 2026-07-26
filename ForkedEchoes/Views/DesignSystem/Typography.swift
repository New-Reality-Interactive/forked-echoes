import SwiftUI

// DESIGN.md typography tokens needed by Home/Tutorial (headline, body, eyebrow).
// Each role binds to a named iOS text style so Dynamic Type keeps scaling it — weight/case
// are layered on top via View modifiers; tracking is scaled via @ScaledMetric so the
// letter-spacing-to-font-size ratio DESIGN.md specifies (em-relative) holds at accessibility
// sizes too, not just the default Dynamic Type category.

private struct EyebrowTextStyle: ViewModifier {
    @ScaledMetric(relativeTo: .caption2) private var tracking: CGFloat = 1.2

    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.heavy))
            .tracking(tracking)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkSecondary)
    }
}

private struct HeadlineTextStyle: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var tracking: CGFloat = -0.68

    func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.black))
            .tracking(tracking)
            .foregroundStyle(Color.inkPrimary)
    }
}

extension View {
    /// DESIGN.md `typography.eyebrow`: caption2, weight 800/heavy, tracking 0.1em, uppercase.
    func eyebrowStyle() -> some View {
        modifier(EyebrowTextStyle())
    }

    /// DESIGN.md `typography.headline`: largeTitle, weight 900/black, tracking -0.02em.
    /// Not uppercased here — the approved home/tutorial mockups render the story title in
    /// Title Case, overriding the token note's "Uppercase" for this specific use. DESIGN.md
    /// also binds `typography.stat` to the same `largeTitle` text style ("scale in lockstep"
    /// with headline) — don't reuse this helper for `stat` (e.g. Memory screen's score,
    /// Epic 3) without re-deciding the uppercase question for that context.
    func headlineStyle() -> some View {
        modifier(HeadlineTextStyle())
    }

    /// DESIGN.md `typography.body`: body, weight 500/medium.
    func bodyStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundStyle(Color.inkPrimary)
    }

    /// Home's story subtitle (`mockups/home.html` `.story-sub`). Not a named DESIGN.md
    /// `typography` role — the closest named iOS text style to its 15pt/no-tracking CSS is
    /// `subheadline`, bound (not a fixed point size) so Dynamic Type keeps scaling it.
    /// `mockups/home-landscape.html` specifies a smaller 13px value for the same element, but
    /// (like `.headlineStyle()` above it) this deliberately renders at one fixed size in both
    /// orientations — no precedent anywhere in this codebase for orientation-conditional type scale.
    func subtitleStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(Color.inkSecondary)
    }
}
