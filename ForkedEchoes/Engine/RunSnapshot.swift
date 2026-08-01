import Foundation

// AD-4: the persisted run-state shape — exactly these four fields, in this order, no more (no
// `phase`, no timestamps; phase is derived from currentNodeId's node kind, AD-5, never stored).
// `tutorialSeen` has no producer anywhere in the codebase yet (see Story 2.4 Completion Notes) —
// it is always written/read as `false` until a future story wires a real signal into the engine.
struct RunSnapshot: Codable, Equatable {
    let currentNodeId: NodeID
    let choiceHistory: [ChoiceRecord]
    let alignmentScore: Int
    let tutorialSeen: Bool
}

extension RunSnapshot {
    /// Decodes and validates a `RunSnapshot` from `defaults`, returning `nil` on any failure —
    /// missing key, malformed data, or content-tree drift (AC #3). Shared by
    /// `StoryRunEngine`'s snapshot-decode-on-init path and `RunSnapshotPresence`'s decode-success
    /// check so the two validation rules can't drift apart (same reasoning as
    /// `StoryRunEngine.option(withId:in:)`'s shared-lookup precedent).
    static func loadValid(from defaults: UserDefaults) -> RunSnapshot? {
        guard let data = defaults.data(forKey: RunSnapshotPresence.runSnapshotKey),
              let snapshot = try? JSONDecoder().decode(RunSnapshot.self, from: data) else {
            return nil
        }

        // A snapshot pointing at a now-.ending node has nothing to resume (AC #5's intent) —
        // reject it so a stale post-content-edit snapshot can't resurrect a finished run.
        if case .ending = StoryTree.node(for: snapshot.currentNodeId) {
            return nil
        }

        // NodeID/ChoiceOptionID are closed Swift enums (AD-1) — a decoded currentNodeId always
        // resolves via StoryTree.node(for:); the remaining reachable content-tree-drift failure
        // is a choiceHistory entry recording an option id its node no longer offers.
        let choiceHistoryStillResolves = snapshot.choiceHistory.allSatisfy { record in
            guard case .choice(_, let options) = StoryTree.node(for: record.nodeId) else {
                return false
            }
            return options.contains(where: { $0.id == record.chosenOptionId })
        }

        return choiceHistoryStillResolves ? snapshot : nil
    }
}
