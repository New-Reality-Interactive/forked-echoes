import Foundation

// Story 2.1: minimal placeholder tree (1 reading node -> 1 choice node w/ 2 options -> 2 terminal
// ending nodes) to exercise StoryRunEngine/UI. Story 2.5 added one echo-wired reading node on the
// .boat path; Story 2.6 added one branch-arrival node on the .shore path. The tree never
// reconverges: firstChoice's two options each lead to a distinct ending node (.boat via the echo
// node, .shore via the arrival node). Full v1 authoring is Epic 4's job (epics.md Epic 2 Content
// note) — this tree is expected to be replaced wholesale, not extended in place.
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
                    // Non-zero placeholder deltas to exercise alignmentScore accumulation in
                    // tests — not a narrative-design decision. Real per-choice values are Epic
                    // 4's job (Story 4.1/4.2 authoring), same as the rest of this placeholder tree.
                    ChoiceOption(
                        id: .boat,
                        labelKey: "story.firstChoice.choice.1",
                        alignmentDelta: 1,
                        target: .boatEcho
                    ),
                    ChoiceOption(
                        id: .shore,
                        labelKey: "story.firstChoice.choice.2",
                        alignmentDelta: -1,
                        target: .shoreArrival
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

        case .endingHomeward, .endingElsewhere:
            return .ending(EndingPayload(nodeId: id))
        }
    }
}
