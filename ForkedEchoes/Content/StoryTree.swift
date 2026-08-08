import Foundation

// Story 2.1: minimal placeholder tree (1 reading node -> 1 choice node w/ 2 options -> 2 terminal
// ending nodes) to exercise StoryRunEngine/UI. Story 2.5 added one echo-wired reading node on the
// .boat path; Story 2.6 added one branch-arrival node on the .shore path. The tree never
// reconverges: .boat leads to a distinct ending node via the echo node, .shore via the arrival
// node. Full v1 authoring is Epic 4's job (epics.md Epic 2 Content note) — this tree is expected
// to be replaced wholesale, not extended in place.
//
// Story 3.1: firstChoice now has 4 options, one per EndingKind case. .boat/.shore (and everything
// between them and their original endings) are untouched — only two new options were appended.
// .gotcha and .driftLimbo each target a new terminal node directly, one hop from firstChoice, so
// selecting either produces an immediate selectChoice(_:)-to-Ending transition (AD-5) with no
// intervening reading/interstitial node — .gotcha is this tree's designated hard-fail choice
// (AD-6, FR8), .driftLimbo exists purely to exercise the fourth EndingKind case.
//
// Prose keys follow ARCHITECTURE-SPINE.md's `story.<nodeId>.body` / `story.<nodeId>.choice.<n>`
// convention, referenced as plain dot-path String keys (project-context.md Localization section —
// not generated symbols, see 2-1-minimal-story-content-and-engine-foundation.md's RESOLVED
// CONFLICT note).
enum StoryTree {
    static let root: NodeID = .intro

    // Content-authoring guardrails (code-review finding, 2026-07-31): AD-1's compile-time
    // safety covers node/option *identity* (enum cases), but a choice node's `options` array is
    // still a plain Swift array, so nothing in the type system stops an authored node from
    // shipping with zero options (an unreachable soft-lock) or two options sharing the same id
    // (an ambiguous `selectChoice(_:)` match, and a SwiftUI `ForEach(id: \.id)` identity
    // collision). These preconditions fail loudly at content-access time instead of silently
    // misbehaving — low-risk today with 2 hand-verified options, real risk once Epic 4 authors
    // 10-15 branches by hand.
    static func node(for id: NodeID) -> StoryNode {
        let node = resolvedNode(for: id)
        if case .choice(_, let options) = node {
            precondition(!options.isEmpty, "content-authoring error: \(id) is a choice node with zero options")
            precondition(
                Set(options.map(\.id)).count == options.count,
                "content-authoring error: \(id) has duplicate option ids"
            )
        }
        return node
    }

    private static func resolvedNode(for id: NodeID) -> StoryNode {
        switch id {
        case .intro:
            return .reading(bodyKey: "story.intro.body", next: .firstChoice)

        case .firstChoice:
            return .choice(
                promptKey: "story.firstChoice.body",
                options: [
                    // Placeholder deltas exercising alignmentScore accumulation in tests — not a
                    // narrative-design decision. Real per-choice values are Epic 4's job (Story
                    // 4.1/4.2 authoring), same as the rest of this placeholder tree. Story 3.8:
                    // one option (.shore) is deliberately 0 — the pre-Epic-4 tree previously had no
                    // path netting to a genuinely neutral score at all, which meant AC #1's
                    // "0" vs "+0" fix (MemoryView.swift) had no real-gameplay path to manually
                    // verify; two options stay positive (.boat/.driftLimbo) and one stays negative
                    // (.gotcha) so all three sign cases (+/0/-) remain reachable by normal play.
                    ChoiceOption(
                        id: .boat,
                        labelKey: "story.firstChoice.choice.1",
                        consequenceKey: "story.firstChoice.choice.1.consequence",
                        alignmentDelta: 1,
                        target: .boatEcho
                    ),
                    ChoiceOption(
                        id: .shore,
                        labelKey: "story.firstChoice.choice.2",
                        consequenceKey: "story.firstChoice.choice.2.consequence",
                        alignmentDelta: 0,
                        target: .shoreArrival
                    ),
                    // Story 3.1: the designated gotcha (hard-fail) choice — one hop from
                    // firstChoice directly to .endingHardFail.
                    ChoiceOption(
                        id: .gotcha,
                        labelKey: "story.firstChoice.choice.3",
                        consequenceKey: "story.firstChoice.choice.3.consequence",
                        alignmentDelta: -3,
                        target: .endingHardFail
                    ),
                    // Story 3.1: reaches the fourth EndingKind case (.limbo), otherwise unexercised
                    // by .boat/.shore. Positive delta (code review, 2026-08-05) — .shore now holds
                    // the tree's one deliberate 0 (Story 3.8), so this one stays non-zero to keep
                    // two positive options per the comment above.
                    ChoiceOption(
                        id: .driftLimbo,
                        labelKey: "story.firstChoice.choice.4",
                        consequenceKey: "story.firstChoice.choice.4.consequence",
                        alignmentDelta: 2,
                        target: .endingLimbo
                    ),
                ]
            )

        // Story 2.5: echo-wired node reached only via .boat (AD-1 — the tree's shape fixes this
        // at author-time, no runtime choiceHistory lookup decides it). The tree still never
        // reconverges: .boat now flows through this one extra node before .endingHomeward.
        case .boatEcho:
            return .reading(bodyKey: "story.boatEcho.body", next: .endingHomeward, echoBodyKey: "story.boatEcho.echo")

        // Story 2.6: branch-arrival node reached only via .shore (AD-1 — tree-shape fixes this
        // at author-time). The tree still never reconverges: .shore now flows through this one
        // extra node before .endingElsewhere.
        case .shoreArrival:
            return .reading(
                bodyKey: "story.shoreArrival.body",
                next: .endingElsewhere,
                arrival: BranchArrival(illustration: .shoreArrival, captionKey: "story.shoreArrival.caption")
            )

        case .endingHomeward:
            return .ending(EndingPayload(
                nodeId: id,
                kind: .home,
                titleKey: "story.endingHomeward.title",
                bodyKey: "story.endingHomeward.body"
            ))

        case .endingElsewhere:
            return .ending(EndingPayload(
                nodeId: id,
                kind: .stay,
                titleKey: "story.endingElsewhere.title",
                bodyKey: "story.endingElsewhere.body"
            ))

        // Story 3.1: two new terminal nodes, reached directly from firstChoice's new options —
        // exercise the remaining two EndingKind cases not covered by the pre-existing tree.
        case .endingLimbo:
            return .ending(EndingPayload(
                nodeId: id,
                kind: .limbo,
                titleKey: "story.endingLimbo.title",
                bodyKey: "story.endingLimbo.body"
            ))

        case .endingHardFail:
            // Story 3.2 (AC #4): tone-appropriate dark comedy, per mockups/ending.html's sample.
            return .ending(EndingPayload(
                nodeId: id,
                kind: .hardFail,
                titleKey: "story.endingHardFail.title",
                bodyKey: "story.endingHardFail.body"
            ))
        }
    }
}
