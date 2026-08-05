import SwiftUI

// Story 3.2: the shared Ending template (FR9) — one view for all four EndingKind flavors,
// differing only in the text `payload` supplies (AC #1). Deliberately NOT routed through
// StoryChoiceView's `readingComposition` wrapper (see StoryChoiceView.swift's `.ending`-phase
// branch and this story's Dev Notes "EndingView should NOT reuse readingComposition..." section):
// RunOptionsButton's actions have nothing meaningful to act on once RunSnapshot is already
// cleared (Story 3.1 AC #7), and the swipe/tap-zone gestures conflict with AC #3's full-surface
// "tap anywhere" — this view owns its own gesture/accessibility wiring instead.
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
            .overlay { FrameView(isActive: true) }
            // AC #3: tap anywhere advances past Ending. FrameView's overlay above already has
            // .allowsHitTesting(false), so it never intercepts this gesture.
            .contentShape(Rectangle())
            .onTapGesture {
                engine.advancePage()
            }
            // FR-11: a bare full-surface tap gesture has no automatic VoiceOver equivalent —
            // this mirrors StoryChoiceView's existing .accessibilityAction(named:) pattern for
            // its own page-turn actions.
            .accessibilityAction(named: Text(LocalizedStringKey("ending.continueHint"))) {
                engine.advancePage()
            }
    }

    // Story 2.8's accessibility-size-conditional ScrollView pattern (readingComposition,
    // BranchArrivalInterstitialView): a plain VStack at ordinary Dynamic Type sizes, reaching for
    // ScrollView only at accessibility sizes where real overflow is possible — avoids
    // reintroducing the ScrollView-vs-outer-gesture race project-context.md documents for sizes
    // that don't actually need the scroll headroom.
    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            GeometryReader { proxy in
                ScrollView {
                    endingContent
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                }
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
            // own per-node localization (AD-2). No DESIGN.md typography token matches
            // mockups/ending.html's `.continue-hint` CSS, so this is styled by feel, like
            // LayoutMetrics.swift's other untokened constants.
            Text(LocalizedStringKey("ending.continueHint"))
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(Color.inkSecondary)
        }
        // AD-8: caps the column width in landscape like every other reading surface — no
        // EndingLandscapeView, just the shared reflow rule.
        .frame(maxWidth: LayoutMetrics.readingColumnMaxWidthLandscape, alignment: .leading)
        .readingCardPadding()
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
