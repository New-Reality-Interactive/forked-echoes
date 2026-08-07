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

    // Story 2.8, AC #3: gates the interstitial's entrance/exit transition below. Read here
    // (rather than duplicated inside BranchArrivalInterstitialView) since this is the one call
    // site that drives the animated phase-branch swap.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Story 2.8, AC #2: readingComposition only reaches for ScrollView at accessibility Dynamic
    // Type sizes, mirroring BranchArrivalInterstitialView's own precedent (Story 2.9) for the same
    // ScrollView-vs-outer-swipe-gesture race — a ScrollView's UIScrollView-backed gesture doesn't
    // reliably cede to this view's own DragGesture, confirmed empirically there. At ordinary sizes
    // there's no overflow risk to justify the race, so content renders exactly as it did before
    // this story.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Code review, 2026-08-01: the .fullScreenCover presentation (AD-5) has no system back
    // button or swipe-to-dismiss by construction — this closure is the Story session's real,
    // deliberate exit path, invoked from RunOptionsButton's "Exit to Home" action (Story 2.7).
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
        Group {
            if engine.phase == .ending, case .ending(let payload) = StoryTree.node(for: engine.currentNodeId) {
                // Story 3.2: a dedicated top-level phase branch, not routed through
                // readingComposition below — see this story's Dev Notes "EndingView should NOT
                // reuse readingComposition..." section. EndingView owns its own permanently-active
                // FrameView, gesture, and accessibility-action wiring.
                EndingView(payload: payload)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if engine.phase == .memory {
                // Story 3.3: a dedicated top-level phase branch, not routed through
                // readingComposition below — same shape as the .ending branch immediately above
                // it (no in-progress run for RunOptionsButton to act on; no swipe/tap-zone
                // gestures belong on a screen with no forward/backward paging concept).
                MemoryView(onExitToHome: onExitToHome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if engine.phase == .interstitial, case .reading(_, _, _, let arrival?) = StoryTree.node(for: engine.currentNodeId) {
                // Story 2.6, AC #2/#5: this branch fully replaces the ordinary composition below
                // — no page-turn gesture, no tap zones, no exit/run-options button attached at
                // all while gated (true first-visit-ever, Story 2.9/AD-5), not merely visually
                // hidden. advancePage() itself performs the Continue/dismiss behavior whenever
                // phase == .interstitial (StoryRunEngine.swift), so leaving the swipe gesture/tap
                // zones attached would let an ordinary swipe silently dismiss the interstitial
                // early — only the dedicated Continue button may call it while this phase holds.
                // Story 2.9 code review, 2026-08-02: .id(engine.currentNodeId) forces a fresh
                // BranchArrivalInterstitialView (and its @State isDismissing) if advancePage()
                // ever lands directly on a second, not-yet-dismissed arrival node — not reachable
                // with the current single-arrival-node tree, but without this, SwiftUI would
                // reuse the same instance/isDismissing across the transition and permanently
                // disable the second node's Continue button.
                BranchArrivalInterstitialView(arrival: arrival) {
                    engine.advancePage()
                }
                .id(engine.currentNodeId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                // Story 2.9 (AC #2): a node with arrival data that ISN'T gated (already visited —
                // phase derived .reading, not .interstitial) still shows the identical
                // illustration+caption as its permanent content, but through the ordinary
                // composition below: page-turn gestures, tap zones, and the exit button all
                // attach normally, and `content`'s `.reading` case (not this branch) renders
                // BranchArrivalInterstitialView with onContinue: nil — see that switch.
                readingComposition
            }
        }
        // Story 2.8, AC #3: animates the interstitial's entrance/exit (the `.transition(.opacity)`
        // above) whenever engine.phase changes, unless Reduce Motion is on — instant cut then,
        // same gating shape as FrameView's power-up transition.
        .animation(reduceMotion ? nil : .easeInOut, value: engine.phase)
        // Story 3.6, AC #1: the one surfaceBase application point for the whole Reading→Ending→
        // Memory chain — covers all four phase branches above since they all render through this
        // shared Group. RootView/MemoryView deliberately get no direct background of their own
        // (see this story's Dev Notes); the interstitial branch's own opaque surfaceInverse fill
        // fully occludes this. Ending/Reading/Choice sit visually on surfaceRaised instead, via
        // FrameView's own fill (Task 2) covering this background at those call sites.
        .background(Color.surfaceBase.ignoresSafeArea())
    }

    // Story 2.9 code review (user-reported, 2026-08-02 Simulator playtest, two rounds): a
    // revisited arrival node's content used to be `BranchArrivalInterstitialView` wrapped in a
    // `ScrollView` at every Dynamic Type size, which raced the outer swipe/tap-zone recognizers
    // (a `ScrollView`'s `UIScrollView`-backed gesture doesn't reliably cede to SwiftUI's own
    // `.gesture`/`.highPriorityGesture` arbitration — confirmed empirically, since neither
    // `.background`→`.overlay` nor `.gesture`→`.highPriorityGesture` on this side fully resolved
    // the flakiness). Fixed at the actual source instead (`BranchArrivalInterstitialView.swift`):
    // that view no longer uses a `ScrollView` at ordinary Dynamic Type sizes at all — only at
    // accessibility sizes, where real content overflow is possible.
    //
    // Story 2.8, AC #2: this same accessibility-size-conditional pattern now applies here too —
    // `readingComposition` needs a real `ScrollView` for accessibility-size headroom (this story's
    // new requirement), but only at accessibility sizes, to avoid reintroducing the identical
    // gesture race at ordinary sizes that Story 2.9 fixed for the interstitial.
    private var readingComposition: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // AC #2: content scrolls inside the fixed frame at accessibility sizes — the
                // frame itself (FrameView's background below) never resizes; only this scroll
                // wrapper's headroom does. Story 3.6, Task 4 (five-round Simulator debugging
                // history) / code review: shared GeometryReader+ScrollView+safe-area-clip logic
                // factored into `View.accessibilitySizeFramedScroll()` (LayoutMetrics.swift) —
                // see its doc comment for the full history and rationale (same pattern
                // `EndingView.content` uses).
                content
                    .id(engine.currentNodeId)
                    .transition(.opacity)
                    .accessibilitySizeFramedScroll()
            } else {
                content
                    .id(engine.currentNodeId)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        // Story 2.8, AC #3/EXPERIENCE.md Accessibility Floor: page-turn is "plain wayfinding
        // motion" that must collapse to an instant cut under Reduce Motion, same gating shape as
        // the interstitial's phase-keyed transition above and FrameView's power-up transition.
        // `.id(engine.currentNodeId)` above forces a fresh `content` instance per page so the
        // `.transition(.opacity)` actually fires; without it, two pages sharing the same `content`
        // switch case (e.g. two `.reading` prose nodes) would just update their `Text` in place
        // with nothing to animate.
        .animation(reduceMotion ? nil : .easeInOut, value: engine.currentNodeId)
        .contentShape(Rectangle())
        .gesture(pageTurnGesture)
            .background(pageTapZones)
            // Story 2.5, AC #4: the circuit Frame is reserved for Story/Choice reading content
            // only — never Home, Tutorial, or the Epic 2 Ending placeholder. Wrapping it here,
            // around this view's own content, keeps that reservation structural rather than a
            // rule someone has to remember to honor elsewhere — but `content`'s own `.ending`
            // case renders inside this same view, so this must explicitly skip it too (code
            // review, 2026-08-01: an unconditional overlay let the dormant Frame render on the
            // Ending placeholder as well). Story 2.6: the interstitial branch above never reaches
            // this modifier chain at all, so it's excluded by construction too (DESIGN.md
            // Components: "no circuit frame here").
            //
            // Story 3.6, AC #1: .background, not .overlay — FrameView now also carries an opaque
            // surfaceRaised card fill (Task 2), which must render behind `content`'s text, not on
            // top of it (an .overlay here fully hid the reading/choice text behind the fill,
            // caught via Simulator screenshot). `content` is already sized to maxWidth/maxHeight
            // .infinity, so the background matches it exactly; the corner marks/inset rule near
            // the edges still show since `content`'s own padding keeps text away from the very
            // edge.
            .background {
                if isFrameEligibleNode {
                    FrameView(isActive: engine.isEchoActive)
                }
            }
            .overlay(alignment: .topTrailing) {
                RunOptionsButton(
                    onExitToHome: {
                        engine.exitToHome()
                        onExitToHome()
                    },
                    onRestartRun: {
                        engine.restartRun()
                    },
                    onExitAndClearProgress: {
                        engine.exitAndClearProgress()
                        onExitToHome()
                    }
                )
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

    // Story 2.5, AC #4 (code review, 2026-08-01): the Frame belongs on Story/Choice reading
    // content, not the Ending placeholder — `.reading`/`.choice` are eligible, `.ending` is not.
    // Story 2.9: a `.reading` node with non-nil `arrival` is excluded too, gated or not — DESIGN.md
    // Components: "no circuit frame here" applies to the illustration+caption for its whole
    // lifetime as this node's content, not just while the gate is active (the gated case was
    // already excluded by construction, since `body`'s interstitial branch never reaches this
    // modifier chain at all — this extends the same exclusion to the ungated-revisit case, which
    // DOES render through `readingComposition` and therefore this overlay).
    private var isFrameEligibleNode: Bool {
        switch StoryTree.node(for: engine.currentNodeId) {
        case .reading(_, _, _, .some): false
        case .reading, .choice: true
        case .ending: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch StoryTree.node(for: engine.currentNodeId) {
        // Story 2.9 (AC #2): an arrival node that's already been visited (not gated — this
        // switch only ever runs when phase != .interstitial, so reaching this arm with non-nil
        // arrival means exactly that) shows the identical illustration+caption as its permanent
        // content, not `bodyKey` prose — `story.shoreArrival.body`-style keys go unused for
        // arrival nodes as of this story. `onContinue: nil` renders no Continue button (Story 2.9
        // Dev Notes' resolved design question) — readingComposition's ordinary gestures are the
        // only way to advance from here, exactly like any other reading page.
        case .reading(_, _, _, let arrival?):
            // Code review, 2026-08-02: this composition must stay full-bleed (DESIGN.md Layout &
            // Spacing: "the branch-arrival interstitial is the one full-bleed exception") — no
            // .readingCardPadding here, unlike the other cases below. BranchArrivalInterstitialView
            // already applies its own internal Spacing.large padding and fills the available area
            // with Color.surfaceInverse; wrapping it in readingComposition's outer padding left a
            // visible non-full-bleed margin around the art on every revisit.
            BranchArrivalInterstitialView(arrival: arrival, onContinue: nil)

        case .reading(let bodyKey, _, let echoBodyKey, _):
            // Content's keys are plain String (Content has zero dependency on SwiftUI, per
            // ARCHITECTURE-SPINE.md's layering) — must be explicitly boxed as LocalizedStringKey
            // here, or Text(_:) silently picks its verbatim StringProtocol overload instead of
            // looking the key up in Localizable.xcstrings (the same overload-resolution pitfall
            // project-context.md's Localization section documents for ternary-selected keys).
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(LocalizedStringKey(bodyKey))
                    .bodyStyle()

                // Story 2.5, AC #1/#3 (UX-DR5, FR-6): the Echo callback — inset within the
                // normal prose flow, not a separate screen/modal — only when this node is
                // authored with a non-nil echo key (AD-1: tree-shape-fixed, mirrors
                // engine.isEchoActive's own derivation).
                if let echoBodyKey {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        // DESIGN.md echo-callback token: the tag uses accent-ember-text, not
                        // accent-ember — accent-ember fails AA contrast at this text size on
                        // surface-inverse (DESIGN.md.components.echo-callback.note).
                        Text(LocalizedStringKey("storyChoice.echo.tag"))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentEmberText)
                        Text(LocalizedStringKey(echoBodyKey))
                            .echoCallbackStyle()
                    }
                    .padding(Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfaceInverse)
                    .foregroundStyle(Color.inkOnInverse)
                    // Code review, 2026-08-01: without this, VoiceOver announces the tag and
                    // the callback prose as two disconnected elements instead of one callback.
                    .accessibilityElement(children: .combine)
                }
            }
            .readingCardPadding(top: LayoutMetrics.runOptionsButtonClearance)

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
                    .bodyStyle()

                // DESIGN.md Layout & Spacing: gaps between stacked choice cards use `{spacing.3}`
                // — distinct from the prompt-to-choices gap above, which keeps the generic
                // `Spacing.medium` this VStack already used.
                VStack(alignment: .leading, spacing: Spacing.choiceCardGap) {
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
            }
            .readingCardPadding(top: LayoutMetrics.runOptionsButtonClearance)

        case .ending:
            // Story 3.2 originally shipped this as `preconditionFailure(...)`, reasoning that
            // body's top-level branch always intercepts an .ending node first (phase is purely
            // derived from node type, AD-5) so this arm should be structurally unreachable.
            // User-confirmed crash, Story 3.3 Task 7 (2026-08-05): it IS reachable — not because
            // phase/node-type derivation actually drift apart, but because of an animated-
            // transition rendering race. `body`'s `.animation(value: engine.phase)` cross-fades
            // readingComposition out while EndingView fades in; during that fade-out,
            // readingComposition (this whole branch, unlike its inner `content.id(_:)`) has no
            // `.id()` of its own, so SwiftUI keeps re-invoking its body against the live, shared
            // `engine` on every animation frame — once `engine.currentNodeId` has already flipped
            // to the ending node, the still-fading-out instance reconstructs `content` for that
            // new id and lands here for real. A `preconditionFailure` here crashes the app on
            // every single reading-to-ending transition with Reduce Motion off, not just on a
            // genuine content-authoring bug — this is a rendering-timing artifact of an
            // already-superseded branch, not a state invariant violation, so it must not crash.
            // Renders nothing (this branch is fading to zero opacity anyway) rather than a real
            // fallback UI, since a live player never actually sees this frame.
            EmptyView()
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

#Preview("Echo node") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .boatEcho))
}

#Preview("Choice node") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .firstChoice))
}

#Preview("Ending node, home") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .endingHomeward))
}

#Preview("Ending node, hard-fail") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .endingHardFail))
}

#Preview("Memory, multi-choice run") {
    let engine = StoryRunEngine(startingAt: .firstChoice)
    engine.selectChoice(.boat)
    engine.advancePage() // .boatEcho -> .endingHomeward
    engine.advancePage() // .ending -> .memory
    return StoryChoiceView(onExitToHome: {})
        .environment(engine)
}

#Preview("Memory, single-entry run (AC #7)") {
    let engine = StoryRunEngine(startingAt: .firstChoice)
    engine.selectChoice(.gotcha) // one hop directly to .endingHardFail
    engine.advancePage() // .ending -> .memory
    return StoryChoiceView(onExitToHome: {})
        .environment(engine)
}

#Preview("Branch arrival, gated first visit") {
    StoryChoiceView(onExitToHome: {})
        .environment(StoryRunEngine(startingAt: .shoreArrival))
}

#Preview("Branch arrival, ungated revisit") {
    // Story 2.9 code review, 2026-08-02: advancePage() now follows `next` past a dismissed
    // arrival node (the "User correction" rework), so a single advancePage() call no longer
    // stays on .shoreArrival — it reaches .endingElsewhere. goBack() afterward returns to the
    // now-dismissed, ungated .shoreArrival, the same state a genuine revisit derives to (see
    // advancingFromARevisitedDismissedArrivalNodeReachesTheSameNextTargetAgain in
    // StoryRunEngineTests.swift).
    let engine = StoryRunEngine(startingAt: .shoreArrival)
    engine.advancePage()
    engine.goBack()
    return StoryChoiceView(onExitToHome: {})
        .environment(engine)
}
