import Foundation
import Testing
@testable import ForkedEchoes

struct RunSnapshotTests {

    @Test func encodeDecodeRoundTripPreservesAllFields() throws {
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .intro, chosenOptionId: .boat)],
            alignmentScore: 3,
            tutorialSeen: false,
            visitedArrivalNodeIds: [.shoreArrival]
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: data)

        #expect(decoded == snapshot)
    }

    // Story 2.9 (Task 1): a snapshot written by a pre-2.9 build has no `visitedArrivalNodeIds`
    // key at all. This must decode cleanly with an empty set, not fail — a missing key isn't a
    // malformed snapshot (NFR4's "no crash, fresh Home fallback" contract, Story 2.4 AC #3 — a
    // decode failure here would incorrectly discard an otherwise-valid in-progress run).
    @Test func decodingASnapshotWithoutTheVisitedArrivalNodeIdsKeyDefaultsToEmpty() throws {
        let legacyJSON = """
        {
            "currentNodeId": {"firstChoice": {}},
            "choiceHistory": [],
            "alignmentScore": 0,
            "tutorialSeen": false
        }
        """
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: Data(legacyJSON.utf8))

        #expect(decoded.currentNodeId == .firstChoice)
        #expect(decoded.visitedArrivalNodeIds.isEmpty)
    }

    @Test func loadValidReturnsNilWhenKeyIsMissing() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(RunSnapshot.loadValid(from: defaults) == nil)
    }

    @Test func loadValidReturnsNilOnMalformedData() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshot.loadValid(from: defaults) == nil)
    }

    // NodeID/ChoiceOptionID are closed Swift enums (AD-1) — a JSON-level decode can only fail on
    // a raw string that doesn't match any existing case, so there's no way to construct a
    // "decodes fine but currentNodeId is unresolvable" case purely via Codable. What's actually
    // reachable and tested here instead: a choiceHistory entry recording an option id that its
    // node no longer offers (simulating a content-tree edit since the snapshot was written).
    @Test func loadValidReturnsNilWhenChoiceHistoryEntryNoLongerResolves() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // .intro is a reading node, not a choice node — so a choiceHistory entry claiming it was
        // decided is unresolvable against the current content tree.
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .intro, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        let data = try! JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshot.loadValid(from: defaults) == nil)
    }

    @Test func loadValidReturnsSnapshotWhenEverythingResolves() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        let data = try! JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshot.loadValid(from: defaults) == snapshot)
    }

    // Code review, 2026-08-01: a snapshot pointing at a now-.ending node has nothing to resume
    // (AC #5's intent) — this can happen if a content-tree edit reclassifies a node's kind after
    // the snapshot was written. loadValid must reject it, not treat it as fully valid.
    @Test func loadValidReturnsNilWhenCurrentNodeIdIsAnEndingNode() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = RunSnapshot(
            currentNodeId: .endingHomeward,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        let data = try! JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshot.loadValid(from: defaults) == nil)
    }
}
