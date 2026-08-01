import Observation

// AD-3: the sole owner and mutator of run state. Views never write currentNodeId/choiceHistory/
// alignmentScore directly — every mutation goes through one of the intent methods below.
//
// This story (2.1) is a skeleton only: persistence (RunSnapshot/UserDefaults) is Story 2.4's job.
// Pager-gating (forward blocked on an *unresolved* choice, permeable once decided) is Story 2.2/
// 2.3's job — see advancePage()'s own doc comment for the corrected AD-5 semantics. A committed
// choice is irrevocable (AD-3, FR-5) in both directions: `goBack()` only moves `currentNodeId`
// back along `visitedNodeIds` — it never removes a `choiceHistory` entry or reverses
// `alignmentScore` — and `selectChoice(_:)` refuses to fire again on a node that already has a
// `choiceHistory` entry, so navigating back to a decided choice and picking again is a no-op, not
// a second commit.
@Observable
final class StoryRunEngine {
    private(set) var currentNodeId: NodeID
    private(set) var choiceHistory: [ChoiceRecord] = []
    private(set) var alignmentScore: Int = 0

    private var visitedNodeIds: [NodeID] = []

    init(startingAt nodeId: NodeID = StoryTree.root) {
        currentNodeId = nodeId
    }

    /// Commits the option with the given id on the current choice node. No-op if the current node
    /// isn't a choice node, if `optionId` doesn't match one of its options, or if this node
    /// already has a committed choice (a choice is irrevocable once made — AD-3, FR-5; code-review
    /// finding 2026-07-31: `goBack()` returning to a decided node used to leave it re-selectable).
    func selectChoice(_ optionId: ChoiceOptionID) {
        guard case .choice(_, let options) = StoryTree.node(for: currentNodeId),
              !choiceHistory.contains(where: { $0.nodeId == currentNodeId }),
              let option = Self.option(withId: optionId, in: options) else {
            return
        }

        choiceHistory.append(ChoiceRecord(nodeId: currentNodeId, chosenOptionId: optionId))
        alignmentScore += option.alignmentDelta
        visitedNodeIds.append(currentNodeId)
        currentNodeId = option.target
    }

    /// Moves forward. From a reading node, follows its `next` link. From a *decided* choice node
    /// (one with a `choiceHistory` entry), follows the recorded option's `target` — AD-5 blocks
    /// forward only on an *unresolved* choice; once resolved, a choice node behaves like a reading
    /// node for navigation purposes (the "locked, no alternate-choice control" contract, FR-5, is a
    /// display concern, Story 2.3's job, independent of whether forward navigation is gated). No-op
    /// on an unresolved choice node or an ending node.
    ///
    /// Story 2.2 originally shipped this as a no-op on *any* non-reading node, including a decided
    /// choice — its own test asserted the block was permanent. That contradicted AD-5's documented
    /// "blocks forward on an unresolved choice" wording and only surfaced once Story 2.3's real
    /// choice-selection UI made revisiting a decided page (via goBack()) an actual player action:
    /// swiping forward again from that revisit had nowhere to go. Corrected here.
    func advancePage() {
        switch StoryTree.node(for: currentNodeId) {
        case .reading(_, let next):
            visitedNodeIds.append(currentNodeId)
            currentNodeId = next

        case .choice(_, let options):
            guard let decision = choiceHistory.first(where: { $0.nodeId == currentNodeId }),
                  let target = Self.option(withId: decision.chosenOptionId, in: options)?.target else {
                return
            }
            visitedNodeIds.append(currentNodeId)
            currentNodeId = target

        case .ending:
            return
        }
    }

    /// Moves back to the previously visited node, if any. Never mutates `choiceHistory` or
    /// `alignmentScore` — a committed choice stays committed (AD-3, FR-5).
    func goBack() {
        guard let previous = visitedNodeIds.popLast() else {
            return
        }

        currentNodeId = previous
    }

    // Code-review finding, 2026-08-01: selectChoice(_:) and advancePage()'s .choice branch both
    // independently resolved "what does this option id target" — a single shared lookup avoids
    // the two drifting apart if either is ever changed on its own.
    private static func option(withId id: ChoiceOptionID, in options: [ChoiceOption]) -> ChoiceOption? {
        options.first(where: { $0.id == id })
    }
}

// AD-4 (Story 2.4 shape preview): choiceHistory as ID pairs, never frozen prose — Memory
// re-resolves display text from the current String Catalog by id at render time.
struct ChoiceRecord: Hashable {
    let nodeId: NodeID
    let chosenOptionId: ChoiceOptionID
}
