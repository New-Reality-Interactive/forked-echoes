import SwiftUI

// Story 2.1: proves the engine -> view data flow works end-to-end. No page-turn gestures
// (Story 2.2), no choice-card commit interaction (Story 2.3), and no DESIGN.md styling
// (Story 2.8) yet — this view only renders whatever StoryRunEngine.currentNodeId currently
// resolves to.
struct StoryChoiceView: View {
    @Environment(StoryRunEngine.self) private var engine

    var body: some View {
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
