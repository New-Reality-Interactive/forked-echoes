import SwiftUI

// Story 2.6: full-bleed branch-arrival interstitial (UX-DR6) — the one moment the reading
// surface's circuit Frame steps aside for pure art (DESIGN.md Components: "no circuit frame
// here"). Shown only while `engine.phase == .interstitial`; dismissed exclusively via its own
// Continue button, which calls the same `engine.advancePage()` intent every other "move forward"
// interaction uses (AD-3).
//
// Placeholder colors only (this story's Scoping Note, mirroring FrameView.swift's precedent):
// `Color.inkPrimary` stands in for DESIGN.md's `surface-inverse` background, `Color.surfaceBase`
// for `ink-on-inverse` caption text. `Color.selectedFill` on the headline is a real DESIGN.md
// token match, not a placeholder substitution. No entrance/exit animation — an instant show/hide
// is correct until Story 2.8 introduces transitions/Reduce Motion handling for every Epic 2
// reading-surface component at once.
struct BranchArrivalInterstitialView: View {
    let arrival: BranchArrival
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.large) {
            Image(arrival.illustration.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text(LocalizedStringKey(arrival.illustration.accessibilityLabelKey)))

            // AC #1/#6: the interstitial's one flavor caption, styled as an oversized headline
            // (DESIGN.md `components.interstitial.headline-color` = selected-fill) — this stands
            // in for the node's ordinary body prose, which stays hidden until Continue.
            Text(LocalizedStringKey(arrival.captionKey))
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundStyle(Color.selectedFill)
                .multilineTextAlignment(.center)

            Button(action: onContinue) {
                Text(LocalizedStringKey("storyChoice.interstitial.continue"))
                    .frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)
            }
            .buttonStyle(.primaryAction)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.inkPrimary)
    }
}

// AD-1: exhaustive switch over BranchIllustration's cases — adding a future flavor without
// adding its mapping arm here is a compile error. Views-layer only, keeps Content SwiftUI-free
// (StoryChoiceView.swift's bodyKey/LocalizedStringKey boxing precedent for the same layering rule).
private extension BranchIllustration {
    var imageResource: ImageResource {
        switch self {
        case .shoreArrival: .shoreArrivalPlaceholder
        }
    }

    var accessibilityLabelKey: String {
        switch self {
        case .shoreArrival: "story.shoreArrival.illustration.accessibilityLabel"
        }
    }
}

#Preview("Shore arrival interstitial") {
    BranchArrivalInterstitialView(
        arrival: BranchArrival(illustration: .shoreArrival, captionKey: "story.shoreArrival.caption"),
        onContinue: {}
    )
}
