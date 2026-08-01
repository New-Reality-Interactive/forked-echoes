import SwiftUI

// Story 2.1 proved the engine -> view data flow end-to-end (no gestures, no choice-card commit
// interaction, no DESIGN.md styling). Story 2.2 adds page-turn navigation: swipe, invisible
// left/right tap zones, and VoiceOver "Next Page"/"Previous Page" rotor actions all call the same
// StoryRunEngine.advancePage()/goBack() intents (AD-3 — one intent method per user action, never
// separate code paths that could diverge). The View never decides whether a page-turn is allowed;
// it always calls the intent and lets the engine's own no-op guards be the single source of truth
// for whether anything happens (AD-5) — this is what makes AC #4's forward-block-on-unresolved-
// choice hold identically across all three input paths for free. No DESIGN.md styling yet
// (Story 2.8) and no choice-card commit interaction yet (Story 2.3).
//
// This view is presented via RootView's .fullScreenCover, not pushed onto the NavigationStack
// (AD-5, amended 2026-07-31) — so there is no system back button or interactivePopGestureRecognizer
// swipe gesture to compete with this view's own swipe-left/right DragGesture. An earlier attempt at
// this story kept the NavigationStack push and tried to selectively disable that system gesture
// via UIKit interop; real Simulator testing showed it winning over the in-page swipe regardless of
// where the drag started, and the interop fix didn't reliably suppress it. See RootView.swift and
// ARCHITECTURE-SPINE.md#AD-5 for the corrected shape.
struct StoryChoiceView: View {
    @Environment(StoryRunEngine.self) private var engine

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(pageTurnGesture)
            .background(pageTapZones)
            .accessibilityAction(named: Text("storyChoice.pager.nextPage")) {
                engine.advancePage()
            }
            .accessibilityAction(named: Text("storyChoice.pager.previousPage")) {
                engine.goBack()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch StoryTree.node(for: engine.currentNodeId) {
        case .reading(let bodyKey, _):
            // Content's keys are plain String (Content has zero dependency on SwiftUI, per
            // ARCHITECTURE-SPINE.md's layering) — must be explicitly boxed as LocalizedStringKey
            // here, or Text(_:) silently picks its verbatim StringProtocol overload instead of
            // looking the key up in Localizable.xcstrings (the same overload-resolution pitfall
            // project-context.md's Localization section documents for ternary-selected keys).
            Text(LocalizedStringKey(bodyKey))

        case .choice(let promptKey, let options):
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(LocalizedStringKey(promptKey))

                ForEach(options, id: \.id) { option in
                    Text(LocalizedStringKey(option.labelKey))
                }
            }

        case .ending:
            // AC #4: temporary stand-in Epic 3 Story 3.2 replaces with the real Ending screen —
            // tracked in deferred-work.md so it isn't forgotten (code-review finding, 2026-07-31).
            // Text(verbatim:) matches the precedent set by the placeholder this story removes
            // (StoryChoicePlaceholderView.swift) — dev-facing copy, not authored story content.
            // The payload (terminal NodeID) isn't needed yet — Story 3.1 is what gives it real use.
            Text(verbatim: "Run complete — Ending screen coming in Epic 3")
        }
    }

    // Story 2.2, AC #1/#2 (UX-DR4): swipe left advances, swipe right returns. minimumDistance
    // (LayoutMetrics.pageSwipeThreshold) keeps an incidental tap/press from registering as a
    // swipe; the exact value is tunable by feel, not a locked spec.
    private var pageTurnGesture: some Gesture {
        DragGesture(minimumDistance: LayoutMetrics.pageSwipeThreshold)
            .onEnded { value in
                // minimumDistance only guarantees *total* displacement past the threshold, not
                // direction — a mostly-vertical drag with an incidental sideways drift would
                // otherwise misfire as a page turn (found via manual Simulator testing,
                // 2026-07-31: swiping up was triggering advancePage()). Require the horizontal
                // component to dominate before treating this as a page-turn swipe at all.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                if value.translation.width < 0 {
                    engine.advancePage()
                } else if value.translation.width > 0 {
                    engine.goBack()
                }
            }
    }

    // Story 2.2, AC #1/#2 (DESIGN.md components.page-tap-zones): invisible left/right-third tap
    // zones, tap-equivalent to the swipe gesture — no visual chrome of their own. The middle third
    // has no gesture attached and explicitly disables hit-testing so it never intercepts taps
    // meant for whatever content (e.g. Story 2.3's choice cards) ends up on top of it.
    //
    // Attached via .background(_:), not .overlay(_:) — these zones must sit BEHIND the reading/
    // choice content in z-order, not in front of it. Today content has no gesture of its own, so
    // this makes no observable difference; it matters once Story 2.3 adds real tap/hold gestures
    // directly to choice cards, which need to win over these zones wherever a card visually
    // overlaps them (found via manual Simulator testing, 2026-07-31 — an .overlay(_:) placement
    // let these zones swallow every tap on the choice page before it could ever reach a card).
    private var pageTapZones: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: proxy.size.width * LayoutMetrics.pageTapZoneWidthFraction)
                    .contentShape(Rectangle())
                    .onTapGesture { engine.goBack() }

                Color.clear
                    .allowsHitTesting(false)

                Color.clear
                    .frame(width: proxy.size.width * LayoutMetrics.pageTapZoneWidthFraction)
                    .contentShape(Rectangle())
                    .onTapGesture { engine.advancePage() }
            }
        }
    }
}

#Preview("Reading node") {
    StoryChoiceView()
        .environment(StoryRunEngine(startingAt: .intro))
}

#Preview("Choice node") {
    StoryChoiceView()
        .environment(StoryRunEngine(startingAt: .firstChoice))
}

#Preview("Ending node") {
    StoryChoiceView()
        .environment(StoryRunEngine(startingAt: .endingHomeward))
}
