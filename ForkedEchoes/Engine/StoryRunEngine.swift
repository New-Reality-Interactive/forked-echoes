import Observation

// AD-3: the sole owner and mutator of run state. Views never write currentNodeId/choiceHistory/
// alignmentScore directly — every mutation goes through one of the intent methods below.
//
// This story (2.1) is a skeleton only: persistence (RunSnapshot/UserDefaults) is Story 2.4's job,
// and full pager-gating (forward blocked on an unresolved choice) is Story 2.2's job. A committed
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
              let option = options.first(where: { $0.id == optionId }) else {
            return
        }

        choiceHistory.append(ChoiceRecord(nodeId: currentNodeId, chosenOptionId: optionId))
        alignmentScore += option.alignmentDelta
        visitedNodeIds.append(currentNodeId)
        currentNodeId = option.target
    }

    /// Moves forward along a reading node's `next` link. No-op if the current node isn't a reading
    /// node (e.g. an unresolved choice node) — full forward-blocking semantics land in Story 2.2.
    func advancePage() {
        guard case .reading(_, let next) = StoryTree.node(for: currentNodeId) else {
            return
        }

        visitedNodeIds.append(currentNodeId)
        currentNodeId = next
    }

    /// Moves back to the previously visited node, if any. Never mutates `choiceHistory` or
    /// `alignmentScore` — a committed choice stays committed (AD-3, FR-5).
    func goBack() {
        guard let previous = visitedNodeIds.popLast() else {
            return
        }

        currentNodeId = previous
    }
}

// AD-4 (Story 2.4 shape preview): choiceHistory as ID pairs, never frozen prose — Memory
// re-resolves display text from the current String Catalog by id at render time.
struct ChoiceRecord: Hashable {
    let nodeId: NodeID
    let chosenOptionId: ChoiceOptionID
}
