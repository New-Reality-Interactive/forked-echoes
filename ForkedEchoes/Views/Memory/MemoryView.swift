import SwiftUI

// Story 3.3: the Memory/Recap screen (FR10) — read-only choice-and-consequence recap plus the
// alignment score/tier header, shown for 100% of completed runs (AC #2). Deliberately NOT wrapped
// in FrameView (DESIGN.md mockups/memory.html: "Memory is spacious like Home — no circuit frame,
// this screen looks back rather than reads forward"; components.memory-row/memory-score have no
// frame reference either), and NOT routed through StoryChoiceView's readingComposition — same
// reasoning EndingView already established one phase earlier: no swipe/tap-zone gestures belong on
// a screen with no forward/backward paging concept.
struct MemoryView: View {
    let onExitToHome: () -> Void

    @Environment(StoryRunEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header

            // Dev Notes "Why Memory's rows always scroll, unlike Reading/Ending": no competing
            // swipe/drag gesture on this screen, so rows scroll unconditionally at every Dynamic
            // Type size — unlike readingComposition/EndingView's accessibility-size-conditional
            // ScrollView, which exists purely to dodge a gesture race that doesn't exist here.
            GeometryReader { proxy in
                ScrollView {
                    rows
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                }
            }

            actions
        }
        // AD-8: caps the column width in landscape like every other reading-adjacent screen — no
        // MemoryLandscapeView, just the shared reflow rule. No landscape-specific Memory mockup
        // exists yet; DESIGN.md/EXPERIENCE.md both explicitly defer it to a future epic.
        .frame(maxWidth: LayoutMetrics.readingColumnMaxWidthLandscape, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readingCardPadding()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Pure UI chrome matching mockups/memory.html — no content-model dependency, no AC
            // requires it. Deliberately NOT a dynamic per-run title (see this story's Dev Notes
            // "No dynamic per-run title on Memory").
            Text(LocalizedStringKey("memory.eyebrow"))
                .eyebrowStyle()

            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                // AC #3: a purely reflective stat with no bearing on the ending already shown on
                // the previous screen. Explicit +/- sign matches mockups/memory.html's "+7"/"-3"
                // formatting.
                Text(engine.alignmentScore.formatted(.number.sign(strategy: .always())))
                    .statStyle()
                    .foregroundStyle(Color.accentEmber)

                // AC #4: cosmetic only — never changes or predicts which ending was reached.
                Text(LocalizedStringKey(Tier.scoreToTier(score: engine.alignmentScore).labelKey))
                    .metaStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    // AC #1, #7: sourced from engine.choiceHistory (RunSnapshot itself is already cleared by the
    // time Memory renders, per AD-4/Story 3.1 AC #7), re-resolving label/consequence text from the
    // current String Catalog by id at render time — never stale frozen prose.
    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Code review: divider goes *between* rows only (mockups/memory.html's
            // `.row { border-bottom }` doesn't trail the last row) — drawn before every row
            // except the first, rather than after every row unconditionally.
            ForEach(Array(engine.choiceHistory.enumerated()), id: \.element) { index, record in
                if let option = chosenOption(for: record) {
                    if index > 0 {
                        Rectangle()
                            .fill(Color.traceBrass)
                            .frame(height: LayoutMetrics.frameStrokeWidth)
                            // Code review, Story 3.4 (2026-08-06): purely decorative, like
                            // FrameView's corner marks — without this it can surface as an
                            // empty/unlabeled VoiceOver rotor stop.
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(LocalizedStringKey(option.labelKey))
                            .choiceLabelStyle()

                        // DESIGN.md memory-row.text-consequence = typography.body,
                        // text-color-consequence = ink-secondary — bodyStyle() itself hardcodes
                        // ink-primary, so this row-specific color override doesn't go through
                        // bodyStyle() unmodified. Exactly one call site, so it isn't promoted into
                        // Typography.swift as a new global role.
                        Text(LocalizedStringKey(option.consequenceKey))
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    .padding(.vertical, Spacing.medium)
                    // Code review, Story 3.4 (2026-08-06): same multi-Text VoiceOver fragmentation
                    // fix EndingView.swift's endingContent already applies — without this, the
                    // label and consequence are two disjoint swipe stops instead of one row.
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.small) {
            // AC #5: RunSnapshot was already cleared on entering Ending (AD-4), so no destructive
            // confirmation is needed — routes through engine.exitToHome() (AD-3's fixed intent
            // surface, same call shape as RunOptionsButton's "Exit to Home") then the View-layer
            // navigation closure.
            Button {
                engine.exitToHome()
                onExitToHome()
            } label: {
                Text(LocalizedStringKey("memory.returnHome"))
                    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
            }
            .buttonStyle(.secondaryAction)

            // AC #6: no confirmation required (AD-3) — stays inside the same .fullScreenCover
            // session; resetting currentNodeId makes engine.phase re-derive to .reading on its
            // own (AD-5), so no onExitToHome() call here.
            Button {
                engine.startNewRun()
            } label: {
                Text(LocalizedStringKey("memory.startNewRun"))
                    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
            }
            .buttonStyle(.primaryAction)
        }
    }

    // AC #1: reuses StoryRunEngine.option(withId:in:) (widened to internal, code review
    // 2026-08-06) rather than duplicating its lookup.
    private func chosenOption(for record: ChoiceRecord) -> ChoiceOption? {
        guard case .choice(_, let options) = StoryTree.node(for: record.nodeId) else {
            return nil
        }
        return StoryRunEngine.option(withId: record.chosenOptionId, in: options)
    }
}

#Preview("Multi-choice run") {
    let engine = StoryRunEngine(startingAt: .firstChoice)
    engine.selectChoice(.boat)
    engine.advancePage() // .boatEcho -> .endingHomeward
    engine.advancePage() // .ending -> .memory
    return MemoryView(onExitToHome: {})
        .environment(engine)
}

#Preview("Single-entry run (hard-fail, AC #7)") {
    let engine = StoryRunEngine(startingAt: .firstChoice)
    engine.selectChoice(.gotcha)
    engine.advancePage() // .ending -> .memory
    return MemoryView(onExitToHome: {})
        .environment(engine)
}
