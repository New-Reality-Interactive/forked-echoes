import SwiftUI

// Story 3.2: the shared Ending template (FR9) — one view for all four EndingKind flavors,
// differing only in the text `payload` supplies (AC #1). Deliberately NOT routed through
// StoryChoiceView's `readingComposition` wrapper (see StoryChoiceView.swift's `.ending`-phase
// branch and this story's Dev Notes "EndingView should NOT reuse readingComposition..." section):
// RunOptionsButton's actions have nothing meaningful to act on once RunSnapshot is already
// cleared (Story 3.1 AC #7), and readingComposition's left/right tap zones conflict with AC #3's
// full-surface "tap anywhere" — this view owns its own gesture/accessibility wiring instead. It
// does reuse the same swipe-back semantics as readingComposition's pager (see `body`'s
// `backSwipeGesture`, restored Story 3.3, 2026-08-06) — that part isn't in conflict, only the tap
// zones are.
struct EndingView: View {
    let payload: EndingPayload

    @Environment(StoryRunEngine.self) private var engine
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // AC #2, DESIGN.md components.ending-frame: the circuit Frame's powered-up ember
            // state is a RESTING condition on this screen, not a transition — always `true`,
            // never derived from engine.isEchoActive or any other condition.
            // Story 3.6, AC #1: .background, not .overlay — FrameView now also carries an opaque
            // surfaceRaised card fill (Task 2), which must render behind `content`'s text, not on
            // top of it. `content` above is already sized to maxWidth/maxHeight .infinity, so the
            // background matches it exactly; the corner marks/inset rule near the edges still show
            // since `content`'s own padding keeps text away from the very edge.
            .background { FrameView(isActive: true) }
            // AC #3: tap anywhere advances past Ending. FrameView's background above already has
            // .allowsHitTesting(false), so it never intercepts this gesture.
            .contentShape(Rectangle())
            .onTapGesture {
                engine.advancePage()
            }
            // User-clarified product decision, pre-dating Epic 3 and re-confirmed Story 3.3 Task 7
            // (2026-08-06): swipe-back through the story is intentionally allowed on Ending — a
            // committed choice stays committed (AD-3, FR-5) regardless of navigating back over it,
            // so there's no harm letting a player revisit earlier pages from here. This was working
            // before Epic 3 (the old Epic-2-era Ending placeholder rendered through
            // readingComposition, which already had swipe-back) and was dropped, unintentionally,
            // when Story 3.2 gave EndingView its own dedicated gesture wiring — restored here, not
            // a new feature. minimumDistance (LayoutMetrics.pageSwipeThreshold, same threshold
            // StoryChoiceView.pageTurnGesture uses) keeps an incidental tap from also registering as
            // a swipe, so this coexists with the tap-anywhere gesture above without competing for
            // the same short taps — only forward (tap) is offered on this screen, matching AC #3;
            // no equivalent forward-swipe is added, since tap-anywhere already covers that direction.
            .gesture(backSwipeGesture)
            // FR-11: a bare full-surface tap gesture has no automatic VoiceOver equivalent —
            // this mirrors StoryChoiceView's existing .accessibilityAction(named:) pattern for
            // its own page-turn actions.
            .accessibilityAction(named: Text(LocalizedStringKey("ending.continueHint"))) {
                engine.advancePage()
            }
            .accessibilityAction(named: Text("storyChoice.pager.previousPage")) {
                engine.goBack()
            }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: LayoutMetrics.pageSwipeThreshold)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                guard value.translation.width > 0 else { return }
                engine.goBack()
            }
    }

    // Story 2.8's accessibility-size-conditional ScrollView pattern (readingComposition,
    // BranchArrivalInterstitialView): a plain VStack at ordinary Dynamic Type sizes, reaching for
    // ScrollView only at accessibility sizes where real overflow is possible — avoids
    // reintroducing the ScrollView-vs-outer-gesture race project-context.md documents. Story 3.3
    // Task 7 (2026-08-05) briefly changed this to scroll unconditionally, on the theory that
    // EndingView had no competing drag gesture to dodge — reverted (2026-08-06) once swipe-back
    // was restored above: this screen DOES have a competing DragGesture again, so the ordinary-vs-
    // accessibility split matters here for the same reason it matters for readingComposition. The
    // text-clipping bug that originally motivated the unconditional-scroll attempt turned out to
    // have a different real cause (HeadlineTextStyle's .tracking() breaking Text wrapping — see
    // Typography.swift) and didn't actually need a ScrollView at ordinary sizes to fix.
    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // User-reported Simulator bug, 2026-08-06 (Story 3.6, Task 4), three rounds: at max
            // accessibility Dynamic Type, scrolled text painted past FrameView's rule line into
            // the status bar/home-indicator zones. Two earlier attempts (.clipped() alone, then
            // pinning the ScrollView to proxy.size before .clipped()) made no measurable
            // difference — the real cause is that this inline GeometryReader's own `proxy.size`
            // already INCLUDES the safe area (a well-known SwiftUI quirk: an inline GeometryReader
            // doesn't receive the same safe-area-reduced size an ordinary view does), so the
            // ScrollView was already self-clipping correctly to its own bounds — those bounds were
            // just larger than FrameView's separately-computed, correctly-safe frame (FrameView's
            // size comes from a plain, non-GeometryReader `.frame` chain, via `.background`). No
            // amount of clipping to `proxy.size` fixes a `proxy.size` that's the wrong value to
            // begin with. Fixed by explicitly subtracting `proxy.safeAreaInsets` to compute the
            // true safe region, then padding+sizing to exactly that — matching FrameView's frame
            // by construction instead of by coincidence.
            //
            // User re-reported, same day: the true safe-area insets themselves are asymmetric
            // (status bar/Dynamic Island taller than the home indicator), so using them directly
            // left a visibly lopsided gap above vs. below the scrolled content. Switched to
            // `GeometryProxy.symmetricSafeAreaInset` (LayoutMetrics.swift) — the user's own fix,
            // applied verbatim: half the (smaller) bottom inset, used for both edges.
            GeometryReader { proxy in
                let inset = proxy.symmetricSafeAreaInset
                let safeHeight = proxy.size.height - inset * 2

                ScrollView {
                    endingContent
                        .frame(maxWidth: .infinity, minHeight: safeHeight, alignment: .topLeading)
                }
                .frame(width: proxy.size.width, height: safeHeight)
                .padding(.top, inset)
                .clipped()
            }
        } else {
            endingContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var endingContent: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(LocalizedStringKey(payload.kind.eyebrowKey))
                .eyebrowStyle()

            Text(LocalizedStringKey(payload.titleKey))
                .headlineStyle()

            Text(LocalizedStringKey(payload.bodyKey))
                .bodyStyle()

            // AC #5: sourced from Localizable.xcstrings, consistent with the ending body copy's
            // own per-node localization (AD-2). Code review, Story 3.4 (2026-08-06): uses
            // DESIGN.md's `typography.caption` token (callout/600) via `captionStyle()` — the
            // prior `.font(.caption)` was SwiftUI's built-in caption style, a same-named but
            // visually unrelated token that isn't in DESIGN.md's type scale at all.
            Text(LocalizedStringKey("ending.continueHint"))
                .captionStyle()
                .foregroundStyle(Color.inkSecondary)
        }
        // AD-8: caps the column width in landscape like every other reading surface — no
        // EndingLandscapeView, just the shared reflow rule.
        .frame(maxWidth: LayoutMetrics.readingColumnMaxWidthLandscape, alignment: .leading)
        .readingCardPadding()
        // Code review, 2026-08-05: without this, the eyebrow/title/body/continue-hint Text
        // elements above are each their own accessibility element, and the custom
        // .accessibilityAction on `body` isn't reliably discoverable as a rotor action on any one
        // of them — same fix StoryChoiceView.swift's echo-callback block already applies for an
        // identical multi-Text-container VoiceOver gotcha.
        //
        // User-confirmed Accessibility Inspector Audit finding, Story 3.3 Task 7 (2026-08-06):
        // "Element has no description." This modifier previously lived on `body`'s outer chain,
        // wrapping `content` (GeometryReader -> ScrollView -> endingContent, after this story's
        // scroll-unconditionally fix) — combining doesn't reliably walk down through an
        // intervening ScrollView to gather descendant Texts' labels. Story 3.2's original
        // default-size `content` had no ScrollView at all, so the same call (at the same outer
        // level) worked then; adding the ScrollView broke it. Fixed by applying `.combine` here,
        // directly on the VStack that actually contains the Text children, regardless of whatever
        // scroll/geometry wrapping sits around it afterward.
        .accessibilityElement(children: .combine)
    }
}

// Story 3.2, Task 2: a pure function of the EndingKind already on the node (Story 3.1) — no new
// StoryNode/EndingPayload field needed, unlike Story/Choice's eyebrow tag (Story 2.8's Scope
// Decision — see this story's RESOLVED CONFLICT Dev Notes). Views-layer only, keeps Content
// SwiftUI-free, mirroring BranchArrivalInterstitialView.swift's BranchIllustration.assets
// precedent for the same "Content enum case -> Views-layer presentation data" pattern.
private extension EndingKind {
    var eyebrowKey: String {
        switch self {
        case .home: "story.ending.eyebrow.home"
        case .stay: "story.ending.eyebrow.stay"
        case .limbo: "story.ending.eyebrow.limbo"
        case .hardFail: "story.ending.eyebrow.hardFail"
        }
    }
}

#Preview("Home ending") {
    EndingView(payload: EndingPayload(
        nodeId: .endingHomeward,
        kind: .home,
        titleKey: "story.endingHomeward.title",
        bodyKey: "story.endingHomeward.body"
    ))
    .environment(StoryRunEngine(startingAt: .endingHomeward))
}

#Preview("Hard-fail ending") {
    EndingView(payload: EndingPayload(
        nodeId: .endingHardFail,
        kind: .hardFail,
        titleKey: "story.endingHardFail.title",
        bodyKey: "story.endingHardFail.body"
    ))
    .environment(StoryRunEngine(startingAt: .endingHardFail))
}
