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

    // Story 2.3: shared across sibling ChoiceCardViews so only one card can be mid-charge/
    // mid-undo-window at a time (AC #1) — a card's own local @State can't see its siblings.
    @State private var activeChoiceOptionID: ChoiceOptionID?

    // Code review, 2026-08-01: the .fullScreenCover presentation (AD-5) has no system back
    // button or swipe-to-dismiss by construction, and nothing else in the app can dismiss it
    // yet — a player who taps "Start Story" had no way back out. This is a temporary interim
    // exit control, not a designed feature; Story 2.7's run-options sheet (or Memory's "Return
    // Home") replaces it with the real, deliberate exit path.
    //
    // A plain @Environment(\.dismiss) only closes this fullScreenCover, revealing whatever sits
    // underneath in RootView's NavigationStack — Home if the session was launched from Home, but
    // Tutorial if it was launched from there (user-caught in Simulator testing, 2026-08-01: the
    // button is labeled "Exit to Home," and it must actually go there regardless of launch
    // point). RootView owns both the fullScreenCover and the NavigationStack's path, so it's the
    // only place that can reset both together — this closure is that capability, injected rather
    // than reached for via environment.
    let onExitToHome: () -> Void

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(pageTurnGesture)
            .background(pageTapZones)
            .overlay(alignment: .topTrailing) {
                exitButton
            }
            .accessibilityAction(named: Text("storyChoice.pager.nextPage")) {
                engine.advancePage()
            }
            .accessibilityAction(named: Text("storyChoice.pager.previousPage")) {
                engine.goBack()
            }
            .onChange(of: engine.currentNodeId) { _, _ in
                // Code-review finding, 2026-08-01: ChoiceOptionID is shared across all choice
                // nodes (StoryNode.swift), not scoped per-node — without this reset, a stale
                // activeChoiceOptionID left over from a previous choice page could misattribute
                // "currently active" state to an unrelated card on a newly-arrived-at node.
                activeChoiceOptionID = nil
            }
    }

    private var exitButton: some View {
        Button {
            onExitToHome()
        } label: {
            Text("storyChoice.action.exitToHome")
                .frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)
        }
        .buttonStyle(.secondaryAction)
        .padding(Spacing.small)
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
            // Story 2.3: engine.choiceHistory is the sole source of truth for whether this page
            // is decided — StoryChoiceView has no persisted "was mid-interaction" state to
            // restore (correctly, per AC #6), so a fresh revisit and the live page both derive
            // "decided" the same way. Because ChoiceCardView.onFinalize only fires at true
            // finalization (RESOLVED CONFLICT in the story file), choiceHistory never contains an
            // entry while a charge/undo window is still in flight, so no special-casing is needed
            // here for "decided but still reconsiderable."
            let decidedRecord = engine.choiceHistory.first(where: { $0.nodeId == engine.currentNodeId })

            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(LocalizedStringKey(promptKey))

                ForEach(options, id: \.id) { option in
                    ChoiceCardView(
                        option: option,
                        isDecided: decidedRecord != nil,
                        isSelected: decidedRecord?.chosenOptionId == option.id,
                        activeOptionID: $activeChoiceOptionID,
                        onFinalize: { optionID in
                            engine.selectChoice(optionID)
                        }
                    )
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

                // Deliberately no explicit .frame here, unlike its two siblings — HStack's
                // implicit flex-sizing gives it whatever width the two fixed-width side zones
                // don't claim (code review, 2026-08-01: pinning this down so a future edit
                // doesn't "helpfully" add an explicit frame and silently break the intended
                // roughly-33/34/33 split the side zones' math assumes).
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
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .intro))
}

#Preview("Choice node") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .firstChoice))
}

#Preview("Ending node") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .endingHomeward))
}
