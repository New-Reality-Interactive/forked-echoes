import SwiftUI

// Story 2.6: full-bleed branch-arrival illustration + caption (UX-DR6) — the one moment the
// reading surface's circuit Frame steps aside for pure art (DESIGN.md Components: "no circuit
// frame here").
//
// Story 2.9 (AD-5, amended 2026-08-02): this is now the arrival node's *permanent* content, shown
// both while gated (`engine.phase == .interstitial`, true first-visit-ever) and on every ordinary
// revisit — only `onContinue` distinguishes the two. Pass a non-nil `onContinue` only for the
// gated case: it renders the Continue button as the sole dismissal path and StoryChoiceView
// detaches page-turn gestures/tap-zones for as long as that's true (AC #1). Pass `nil` for an
// already-visited revisit: no Continue button renders, and the caller (StoryChoiceView) attaches
// ordinary swipe/tap-zone/back gestures instead, exactly like any other reading page (AC #2) —
// this view itself has no opinion on gesture wiring, only on whether the forced-advance button
// exists.
//
// Placeholder colors only (this story's Scoping Note, mirroring FrameView.swift's precedent):
// `Color.inkPrimary` stands in for DESIGN.md's `surface-inverse` background, `Color.surfaceBase`
// for `ink-on-inverse` caption text. `Color.selectedFill` on the headline is a real DESIGN.md
// token match, not a placeholder substitution. No entrance/exit animation — an instant show/hide
// is correct until Story 2.8 introduces transitions/Reduce Motion handling for every Epic 2
// reading-surface component at once.
struct BranchArrivalInterstitialView: View {
    let arrival: BranchArrival
    let onContinue: (() -> Void)?

    // Code-review finding, 2026-08-02: guards against a rapid double-tap on Continue invoking
    // onContinue twice before SwiftUI re-renders the phase change away — the second call would
    // otherwise fire against the now-.reading phase and skip past the node's prose entirely.
    @State private var isDismissing = false

    // Story 2.9 (user-reported Simulator bug, 2026-08-02): a `ScrollView` is backed by a real
    // `UIScrollView` and its own gesture recognition, which does not reliably cede priority to a
    // SwiftUI `.gesture`/`.highPriorityGesture` attached around it — confirmed empirically:
    // `.scrollDisabled(true)` (first attempted fix) did NOT stop the outer page-turn swipe from
    // racing/losing intermittently, still reported "takes multiple attempts" after that fix
    // shipped. `.scrollDisabled` disables scroll *interaction* but does not guarantee the
    // `UIScrollView` stops participating in touch/gesture arbitration at all. The only reliable
    // fix is removing `ScrollView` from the hierarchy entirely for the common case: `body` below
    // renders a plain (non-scrolling) `VStack` — structurally identical to how ordinary reading
    // pages render (`StoryChoiceView.content`'s `.reading` case, confirmed swipe-reliable) — and
    // only reaches for `ScrollView` at accessibility Dynamic Type sizes, where the original
    // overflow risk this view's `ScrollView` was added for (Story 2.6 code review) is real.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Story 2.9 code review, 2026-08-02: the fixed illustration-height fraction alone left no
    // room guarantee in a compact-height (landscape) layout at ordinary Dynamic Type, where
    // ScrollView stays deliberately disabled (see above) — reintroducing the same off-screen-
    // button risk this story fixed, just via a different trigger. A smaller fraction in compact
    // height keeps the caption+button reachable without reintroducing ScrollView's gesture race.
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        // Story 2.9 (user-reported Simulator bug, 2026-08-02): the illustration's prior
        // `.frame(maxHeight: .infinity)` had no real ceiling inside a `ScrollView` (which offers
        // its content effectively unbounded height for layout purposes) — the image alone
        // consumed the full screen and pushed the caption/Continue button off-screen. Bounding
        // the image to a fraction of the actually-available height via GeometryReader — the same
        // GeometryReader+ScrollView pattern project-context.md documents for Home/Tutorial — is
        // what guarantees room for the caption+button below it, at every screen size and
        // orientation, instead of relying on scroll-to-reach.
        GeometryReader { proxy in
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView { arrivalContent(availableHeight: proxy.size.height) }
                } else {
                    arrivalContent(availableHeight: proxy.size.height)
                }
            }
        }
        .background(Color.inkPrimary)
    }

    @ViewBuilder
    private func arrivalContent(availableHeight: CGFloat) -> some View {
        VStack(spacing: Spacing.large) {
            Image(arrival.illustration.assets.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: availableHeight * illustrationMaxHeightFraction)
                .accessibilityLabel(Text(LocalizedStringKey(arrival.illustration.assets.accessibilityLabelKey)))

            // AC #1/#6: the interstitial's one flavor caption, styled as an oversized headline
            // (DESIGN.md `components.interstitial.headline-color` = selected-fill) — this stands
            // in for the node's ordinary body prose, which stays hidden until Continue.
            Text(LocalizedStringKey(arrival.captionKey))
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundStyle(Color.selectedFill)
                .multilineTextAlignment(.center)

            // Story 2.9 (AC #2): only rendered while gated. A revisited arrival node is an
            // ordinary page — there's nothing to force-advance past, so no button at all.
            if let onContinue {
                Button(action: {
                    guard !isDismissing else { return }
                    isDismissing = true
                    onContinue()
                }) {
                    Text(LocalizedStringKey("storyChoice.interstitial.continue"))
                        .frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)
                }
                .buttonStyle(.primaryAction)
                .disabled(isDismissing)
            }
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, minHeight: availableHeight)
    }

    private var illustrationMaxHeightFraction: CGFloat {
        verticalSizeClass == .compact
            ? LayoutMetrics.interstitialIllustrationMaxHeightFractionCompact
            : LayoutMetrics.interstitialIllustrationMaxHeightFraction
    }
}

// AD-1: exhaustive switch over BranchIllustration's cases — adding a future flavor without
// adding its mapping arm here is a compile error. Views-layer only, keeps Content SwiftUI-free
// (StoryChoiceView.swift's bodyKey/LocalizedStringKey boxing precedent for the same layering rule).
//
// Code-review finding, 2026-08-02: imageResource and accessibilityLabelKey used to be two
// independent exhaustive switches — the compiler enforced completeness within each but not
// consistency across them, so a future case could satisfy one and silently miss the other.
// Collapsed into one switch returning both.
private extension BranchIllustration {
    var assets: (imageResource: ImageResource, accessibilityLabelKey: String) {
        switch self {
        case .shoreArrival:
            (.shoreArrivalPlaceholder, "story.shoreArrival.illustration.accessibilityLabel")
        }
    }
}

#Preview("Shore arrival, gated first visit") {
    BranchArrivalInterstitialView(
        arrival: BranchArrival(illustration: .shoreArrival, captionKey: "story.shoreArrival.caption"),
        onContinue: {}
    )
}

#Preview("Shore arrival, ungated revisit") {
    BranchArrivalInterstitialView(
        arrival: BranchArrival(illustration: .shoreArrival, captionKey: "story.shoreArrival.caption"),
        onContinue: nil
    )
}
