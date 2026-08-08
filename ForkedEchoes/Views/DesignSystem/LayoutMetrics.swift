import SwiftUI

// Named layout/opacity constants for Home/Tutorial/ButtonStyles, so numeric literals trace to
// DESIGN.md tokens (where one exists) or a descriptive local name (where one doesn't), rather than
// floating free as bare numbers. Pure refactor (Story 1.6) — values are unchanged from what
// HomeView.swift/TutorialView.swift/ButtonStyles.swift already used.

enum Spacing {
    /// DESIGN.md `{spacing.2}` = 8pt.
    static let small: CGFloat = 8

    /// DESIGN.md `{spacing.3}` = 12pt. Gap between stacked choice cards (Story 2.8, DESIGN.md
    /// Layout & Spacing) — deliberately distinct from `medium`/`{spacing.4}`, used elsewhere for
    /// generic stack spacing.
    static let choiceCardGap: CGFloat = 12

    /// DESIGN.md `{spacing.4}` = 16pt.
    static let medium: CGFloat = 16

    /// DESIGN.md `{spacing.6}` = 24pt.
    static let large: CGFloat = 24
}

enum LayoutMetrics {
    /// DESIGN.md `{components.reading-surface.min-tap-target}` = 44pt. Covers Home/Tutorial action
    /// buttons (per DESIGN.md's own note) as well as reading-surface interactive elements.
    static let minTapTarget: CGFloat = 44

    /// DESIGN.md `{components.reading-surface.column-max-width-landscape}` = 680pt. Caps the reading
    /// column's width in landscape so lines never exceed a comfortable reading measure.
    static let readingColumnMaxWidthLandscape: CGFloat = 680

    /// No DESIGN.md token. Matches `mockups/home.html`'s `.story-sub { max-width:280px }` — keeps
    /// Home's one-line subtitle compact instead of stretching edge-to-edge. Home-only; do not
    /// conflate with `actionStackMaxWidth` below, a different value for a different element.
    static let subtitleMaxWidth: CGFloat = 280

    /// No DESIGN.md token. Caps the Home/Tutorial action-button stack width in landscape so the
    /// buttons don't stretch edge-to-edge in a wide frame (AD-8, geometry-only constraint). Shared
    /// identically by HomeView and TutorialView — one constant, not a per-file duplicate.
    static let actionStackMaxWidth: CGFloat = 320

    /// DESIGN.md `{components.page-tap-zones.left-zone-width}` / `.right-zone-width` = 33%. Each
    /// invisible page-turn tap zone spans this fraction of the reading card's width, same
    /// proportional split in both orientations (Story 2.2).
    static let pageTapZoneWidthFraction: CGFloat = 0.33

    /// No DESIGN.md token. Minimum horizontal drag distance before a swipe counts as a page-turn
    /// gesture (Story 2.2). Tunable by feel, like Story 2.3's charge/undo timings — not a locked
    /// spec.
    static let pageSwipeThreshold: CGFloat = 50

    /// DESIGN.md `{components.choice-card.charge-duration}` = 3000ms. Press-and-hold duration
    /// before a choice card commits (Story 2.3). Tunable by feel per DESIGN.md's own note — not a
    /// locked spec; update the token here and in DESIGN.md together if adjusted.
    static let choiceChargeDuration: Duration = .seconds(3)

    /// DESIGN.md `{components.choice-card.tap-undo-window}` = 1500ms. Grace period after a quick
    /// tap during which a second tap on the same card fully cancels the commit (Story 2.3).
    /// Tunable by feel, same caveat as `choiceChargeDuration`.
    static let choiceUndoWindow: Duration = .milliseconds(1500)

    /// No DESIGN.md token. A single touch on a choice card is classified as a "quick tap" (vs. a
    /// hold released early) by comparing its total contact duration against this threshold
    /// (Story 2.3, fixing a bug found via Simulator testing: a separate `.onTapGesture` alongside
    /// a `.highPriorityGesture(DragGesture(minimumDistance: 0))` never fired — the drag gesture,
    /// matching any touch including a quick one, always won and consumed it. Both interactions
    /// are now handled by one gesture, distinguished by duration). Tunable by feel.
    static let choiceTapMaxHoldDuration: Duration = .milliseconds(300)

    /// DESIGN.md `{components.frame.corner-via-diameter}` = 7pt. The circuit Frame's dormant
    /// corner-mark via diameter (Story 2.5).
    static let frameCornerViaDiameter: CGFloat = 7

    /// DESIGN.md `{components.frame.corner-via-diameter-active}` = 9pt. The circuit Frame's
    /// active/echo corner-mark via diameter — grows from the dormant size as a shape cue
    /// redundant with the color/fill change (UX-DR1), not decoration (Story 2.5).
    static let frameCornerViaDiameterActive: CGFloat = 9

    /// DESIGN.md `{components.frame.corner-pad-diameter}` = 5pt. The circuit Frame's corner-mark
    /// pad diameter, unchanged between dormant (hollow) and active (filled) states (Story 2.5).
    static let frameCornerPadDiameter: CGFloat = 5

    /// DESIGN.md's frame inset rule: `{spacing.2}` + 1px in from the card edge (Story 2.5,
    /// code review 2026-08-01). Corner marks are centered this far in from each edge so their
    /// full diameter stays on-screen instead of clipping at the literal (0,0)/(width,height)
    /// points.
    static let frameCornerInset: CGFloat = Spacing.small + 1

    /// DESIGN.md `{components.frame}`'s "1px inset rule" stroke width (Story 2.5, code review
    /// 2026-08-01) — the dormant corner pad's hollow-square stroke.
    static let frameStrokeWidth: CGFloat = 1

    /// No DESIGN.md token. Caps `BranchArrivalInterstitialView`'s illustration to this fraction
    /// of the available height (Story 2.9, user-reported Simulator bug 2026-08-02): the image's
    /// prior `.frame(maxHeight: .infinity)` had no actual ceiling inside a `ScrollView` (which
    /// offers its content effectively unbounded height for layout purposes), so the illustration
    /// alone consumed the full screen and pushed the caption/Continue button off-screen — with
    /// scrolling disabled at ordinary Dynamic Type sizes (the fix for a separate, unreliable-
    /// swipe bug), the button became completely unreachable. Tunable by feel, like this file's
    /// other fraction-based constants.
    static let interstitialIllustrationMaxHeightFraction: CGFloat = 0.5

    /// Story 2.9 code review, 2026-08-02: `interstitialIllustrationMaxHeightFraction` alone isn't
    /// enough in a compact-height (landscape) layout — the same off-screen-button risk it was
    /// added to fix, just at ordinary Dynamic Type instead of only accessibility sizes, since
    /// `BranchArrivalInterstitialView` deliberately keeps `ScrollView` disabled there to preserve
    /// swipe-gesture reliability (no scroll-to-reach fallback). A smaller fraction in compact
    /// height leaves more guaranteed room for the caption+button without reintroducing ScrollView.
    static let interstitialIllustrationMaxHeightFractionCompact: CGFloat = 0.35

    /// DESIGN.md `{components.choice-card.border-width}` = 3pt. The choice card's `ink-primary`
    /// border stroke (Story 2.8).
    static let choiceCardBorderWidth: CGFloat = 3

    /// No DESIGN.md token. User-reported Simulator gap, Story 2.8: `RunOptionsButton`'s
    /// top-trailing `.overlay` on `readingComposition` occupies `minTapTarget` (44pt) plus its own
    /// `Spacing.small` (8pt) padding on every side — a ~60pt footprint from the screen's top-right
    /// corner. Reading prose/choice-prompt text that reached that corner was rendering underneath
    /// it. This is the vertical clearance `readingCardPadding(top:)` uses instead of the default
    /// `Spacing.medium` for that one call site, so text starts below the button instead of beside
    /// it. Matches this codebase's mockup precedent (`tutorial.html`'s `.top-row`, a dedicated
    /// header row above content, not an overlay text can run under) more closely than the
    /// unguarded overlay did. Tunable by feel, like this file's other untokened constants.
    static let runOptionsButtonClearance: CGFloat = minTapTarget + Spacing.small * 2

    /// DESIGN.md `{components.run-options-button.opacity-receded}` = 0.35. Story 3.9: the
    /// button's opacity while reading content is actively scrolling (accessibility Dynamic Type
    /// sizes only, where `accessibilitySizeFramedScroll()`'s `ScrollView` can actually scroll).
    static let runOptionsButtonOpacityReceded: Double = 0.35

    /// DESIGN.md `{components.run-options-button.recede-transition-duration}` = 200ms. Story 3.9:
    /// cross-fade duration between the button's resting and receded opacity states.
    static let runOptionsButtonRecedeDuration: Duration = .milliseconds(200)
}

extension Duration {
    /// `Duration` pairs naturally with `Task.sleep(for:)`, but SwiftUI's `.animation(.linear
    /// (duration:))` takes a `TimeInterval`/`Double` seconds — this converts without picking a
    /// constant type that fits one API and fights the other (Story 2.3).
    var timeInterval: TimeInterval {
        let components = components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}

extension View {
    /// DESIGN.md Layout & Spacing: "the reading card's internal padding sits at `{spacing.6}`/
    /// `{spacing.4}`" (24pt/16pt) — DESIGN.md doesn't name which axis gets which value; interpreted
    /// here as horizontal/vertical (generous side margins for a book-like reading measure, per the
    /// same section's "this is a book, not a form" framing). User-reported Simulator gap, Story
    /// 2.8: `readingComposition`'s content previously had no padding at all, running edge-to-edge
    /// under the frame's corner marks — this closes that gap. `top` defaults to the same
    /// `{spacing.4}` value but is overridable — `StoryChoiceView` passes
    /// `LayoutMetrics.runOptionsButtonClearance` instead, since that's the one call site sharing
    /// its top-trailing corner with `RunOptionsButton`'s overlay.
    func readingCardPadding(top: CGFloat = Spacing.medium) -> some View {
        self
            .padding(.horizontal, Spacing.large)
            .padding(.top, top)
            .padding(.bottom, Spacing.medium)
    }
}

extension View {
    /// Story 3.6 code review, 2026-08-07: `readingComposition` (`StoryChoiceView.swift`) and
    /// `EndingView.content` both implemented this same GeometryReader+ScrollView+safe-area-clip
    /// pattern for accessibility Dynamic Type sizes — factored into one shared implementation so
    /// a future fix to this geometry only has to be made once.
    ///
    /// History (Story 3.6, Task 4's five-round Simulator debugging, then four code-review rounds):
    /// **every one of those rounds was safe-area math that was never needed.** Rounds 4-8 tried
    /// each edge's true `safeAreaInsets`, then half the bottom inset, then `max(top, bottom)`,
    /// then no top padding at all — all of them subtracting `proxy.safeAreaInsets` from
    /// `proxy.size.height` to derive the viewport.
    ///
    /// Two user Simulator screenshots (2026-08-07) taken one round apart finally pinned the real
    /// geometry down. With the top padding removed, content started at the frame's *edge* (visibly
    /// crossing the rule line) and fell ~90pt short at the bottom; with it applied, content sat
    /// ~48pt *below* the rule and still ran short at the bottom. Both are explained by one fact
    /// that had been assumed backwards the whole time: **`proxy.size` here is already the correct,
    /// safe-area-reduced height — the exact region `FrameView` backs — while `proxy.safeAreaInsets`
    /// still *reports* the device's insets.** Subtracting them shrank the viewport by ~93pt it
    /// didn't need to lose; padding the top then pushed what was left further down.
    ///
    /// So this helper does no safe-area math at all. Do not reintroduce `safeAreaInsets` here:
    /// this view is already laid out inside the safe area, and consulting them double-counts it.
    ///
    /// The viewport is `proxy.size` inset vertically by `Spacing.large` — deliberately the *same*
    /// constant `readingCardPadding` uses for its horizontal padding, so the gap between the
    /// frame and the text reads as one consistent margin on all four sides (24pt from the frame's
    /// bounds, 15pt from the rule line, in every direction). Because the inset is on the scroll
    /// *viewport* rather than the content, that margin holds while scrolling instead of scrolling
    /// away, and content clips short of the rule line rather than against it. Keep this in sync
    /// with `readingCardPadding`'s horizontal value if either ever changes — they are one visual
    /// margin expressed in two places (the horizontal side can live on the content, since nothing
    /// scrolls horizontally; the vertical side cannot).
    /// `isScrolling`: Story 3.9 addition — when non-nil, reports whether this `ScrollView` is
    /// actively scrolling via `.onScrollPhaseChange`. Defaults to `nil` so `EndingView.content`
    /// (this pattern's other call site, with no `RunOptionsButton` to drive) needs zero changes.
    func accessibilitySizeFramedScroll(isScrolling: Binding<Bool>? = nil) -> some View {
        GeometryReader { proxy in
            let inset = Spacing.large
            let viewportHeight = proxy.size.height - inset * 2

            ScrollView {
                self
                    .frame(maxWidth: .infinity, minHeight: viewportHeight, alignment: .topLeading)
            }
            .frame(width: proxy.size.width, height: viewportHeight)
            .padding(.vertical, inset)
            .clipped()
            .onScrollPhaseChange { _, newPhase in
                isScrolling?.wrappedValue = newPhase.isScrolling
            }
        }
    }
}

enum ButtonMetrics {
    /// No DESIGN.md token. `SecondaryActionButtonStyle`'s border stroke width.
    static let borderWidth: CGFloat = 2

    /// No DESIGN.md token. Shared pressed-state opacity for both action button styles.
    static let pressedOpacity: Double = 0.75

    /// No DESIGN.md token. Shared disabled-state opacity for both action button styles.
    static let disabledOpacity: Double = 0.4
}
