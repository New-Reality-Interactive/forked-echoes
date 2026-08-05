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
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.black))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

extension View {
    /// DESIGN.md `typography.choice-label`: headline, weight 800 (rounded to `.heavy`, SwiftUI's
    /// closest built-in weight — same rounding `HeadlineTextStyle`/`EyebrowTextStyle` already do
    /// for 900/800). No tracking token for this role, so no `@ScaledMetric` needed here.
    func choiceLabelStyle() -> some View {
        self
            .font(.headline.weight(.heavy))
            .foregroundStyle(Color.inkPrimary)
    }

    /// DESIGN.md `typography.echo-callback`: body, weight 600/semibold. No hardcoded foreground —
    /// the echo-callback component token's `text-color` is applied at the call site (Story 2.8),
    /// not baked into this typography role.
    func echoCallbackStyle() -> some View {
        self
            .font(.body.weight(.semibold))
    }

    /// DESIGN.md `typography.eyebrow`: caption2, weight 800/heavy, tracking 0.1em, uppercase.
    func eyebrowStyle() -> some View {
        modifier(EyebrowTextStyle())
    }

    /// DESIGN.md `typography.headline`: largeTitle, weight 900/black, tracking -0.02em.
    /// `color` defaults to `ink-primary` (Home/Tutorial's story-title use, which also stays
    /// Title Case rather than uppercase — the mockups' one carved-out exception to the token's
    /// "Uppercase" note, so this helper never applies `.textCase` itself; callers that need
    /// Uppercase per the token's default rule add `.textCase(.uppercase)` themselves). Story 2.8:
    /// parameterized so a different-surface headline (e.g. the branch-arrival interstitial's
    /// `selected-fill`-on-`surface-inverse` caption) can reuse this modifier's font/tracking
    /// without forking a second copy of the `@ScaledMetric` tracking constant — chaining a plain
    /// `.foregroundStyle` after this modifier does NOT reliably override the color it sets
    /// internally (code review, 2026-08-02: confirmed in Simulator, the root cause of a real
    /// invisible-caption bug this story shipped and fixed), so the color must be passed in here.
    /// DESIGN.md also binds `typography.stat` to the same `largeTitle` text style ("scale in
    /// lockstep" with headline) — don't reuse this helper for `stat` (e.g. Memory screen's score,
    /// Epic 3) without re-deciding the uppercase question for that context.
    func headlineStyle(color: Color = Color.inkPrimary) -> some View {
        modifier(HeadlineTextStyle(color: color))
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
