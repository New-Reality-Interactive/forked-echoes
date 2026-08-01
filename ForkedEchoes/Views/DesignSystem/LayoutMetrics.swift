import SwiftUI

// Named layout/opacity constants for Home/Tutorial/ButtonStyles, so numeric literals trace to
// DESIGN.md tokens (where one exists) or a descriptive local name (where one doesn't), rather than
// floating free as bare numbers. Pure refactor (Story 1.6) — values are unchanged from what
// HomeView.swift/TutorialView.swift/ButtonStyles.swift already used.

enum Spacing {
    /// DESIGN.md `{spacing.2}` = 8pt.
    static let small: CGFloat = 8

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
}

enum ButtonMetrics {
    /// No DESIGN.md token. `SecondaryActionButtonStyle`'s border stroke width.
    static let borderWidth: CGFloat = 2

    /// No DESIGN.md token. Shared pressed-state opacity for both action button styles.
    static let pressedOpacity: Double = 0.75

    /// No DESIGN.md token. Shared disabled-state opacity for both action button styles.
    static let disabledOpacity: Double = 0.4
}
