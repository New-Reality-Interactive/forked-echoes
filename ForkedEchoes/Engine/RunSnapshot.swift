import Foundation

// AD-4: the persisted run-state shape. Four fields, in this order, from Story 2.4 through Story
// 2.8; Story 2.9 added a fifth (`visitedArrivalNodeIds`), Story 2.10 a sixth (`visitedNodeIds`),
// each a deliberate, documented exception — the branch-arrival interstitial's first-visit-ever
// gate (AD-5, amended 2026-08-02) and the back-navigation stack (AD-3) both need their own
// persisted signal to survive a real app relaunch; neither is derivable from the original four
// fields alone. `phase` itself is still never stored — it stays derived from currentNodeId's node
// kind plus `visitedArrivalNodeIds`, AD-5's "phase derived, not stored" ethos unchanged.
// Story 3.8: `tutorialSeen` (present through Story 3.7) was removed as dead scope — it never had a
// producer (always written `false`) and no consumer anywhere in the codebase since Story 2.4, and
// no planning artifact (PRD/epics.md/DESIGN.md/EXPERIENCE.md) describes a feature that would
// consume a "has the player seen the tutorial" signal. Old on-disk snapshots that still contain a
// `tutorialSeen` JSON key decode fine — CodingKeys below simply no longer names that key, and
// Codable's keyed-container decode silently ignores unknown keys (see RunSnapshotTests.swift's
// decode-compatibility fixtures, which keep the JSON literal to prove this).
struct RunSnapshot: Codable, Equatable {
    let currentNodeId: NodeID
    let choiceHistory: [ChoiceRecord]
    let alignmentScore: Int
    /// Story 2.9: branch-arrival nodes (StoryNode.reading's `arrival` case) the player has fully
    /// passed at least once — i.e. dismissed the interstitial for — surviving relaunch. Lets a
    /// freshly-constructed StoryRunEngine (resumingFromSnapshot(defaults:)) know an arrival node
    /// should render as an ordinary page rather than re-gating, without needing to persist the
    /// full session-scoped back-navigation stack. Defaults to empty on decode (see init(from:))
    /// so a snapshot written by a pre-2.9 build, which has no such key, still decodes cleanly
    /// instead of RunSnapshot.loadValid(from:) rejecting it outright (NFR4's "no crash, fresh
    /// Home fallback" contract, Story 2.4 AC #3 — a missing key must not be treated the same as
    /// a genuinely malformed snapshot).
    let visitedArrivalNodeIds: Set<NodeID>
    /// Story 2.10: the ordered back-navigation stack StoryRunEngine.goBack() pops, surviving
    /// relaunch. Before this story, StoryRunEngine's own private `visitedNodeIds` was never part
    /// of RunSnapshot, so goBack() was silently a no-op immediately after any relaunch until the
    /// player advanced forward again in the new session (a gap surfaced during Story 2.9
    /// Simulator testing, deferred to this story by explicit user decision). An ordered `[NodeID]`,
    /// not a `Set` like `visitedArrivalNodeIds` above — order and duplicate entries both matter
    /// for a stack. Defaults to empty on decode (see init(from:)) so a snapshot written before
    /// this story shipped, which has no such key, still decodes cleanly instead of
    /// RunSnapshot.loadValid(from:) rejecting it outright — same reasoning as
    /// visitedArrivalNodeIds above.
    let visitedNodeIds: [NodeID]

    init(
        currentNodeId: NodeID,
        choiceHistory: [ChoiceRecord],
        alignmentScore: Int,
        visitedArrivalNodeIds: Set<NodeID> = [],
        visitedNodeIds: [NodeID] = []
    ) {
        self.currentNodeId = currentNodeId
        self.choiceHistory = choiceHistory
        self.alignmentScore = alignmentScore
        self.visitedArrivalNodeIds = visitedArrivalNodeIds
        self.visitedNodeIds = visitedNodeIds
    }

    // Custom Codable, not synthesized: a synthesized init(from:) would fail to decode any
    // snapshot written before visitedArrivalNodeIds/visitedNodeIds existed as keys.
    // decodeIfPresent + a `?? []` fallback is what makes that decode succeed instead of falling
    // through to RunSnapshot.loadValid(from:)'s "reject and start fresh" path for a reason that
    // isn't actually a corrupted snapshot.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentNodeId = try container.decode(NodeID.self, forKey: .currentNodeId)
        choiceHistory = try container.decode([ChoiceRecord].self, forKey: .choiceHistory)
        alignmentScore = try container.decode(Int.self, forKey: .alignmentScore)
        visitedArrivalNodeIds = try container.decodeIfPresent(Set<NodeID>.self, forKey: .visitedArrivalNodeIds) ?? []
        visitedNodeIds = try container.decodeIfPresent([NodeID].self, forKey: .visitedNodeIds) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentNodeId, forKey: .currentNodeId)
        try container.encode(choiceHistory, forKey: .choiceHistory)
        try container.encode(alignmentScore, forKey: .alignmentScore)
        try container.encode(visitedArrivalNodeIds, forKey: .visitedArrivalNodeIds)
        try container.encode(visitedNodeIds, forKey: .visitedNodeIds)
    }

    private enum CodingKeys: String, CodingKey {
        case currentNodeId, choiceHistory, alignmentScore, visitedArrivalNodeIds, visitedNodeIds
    }
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
