import Foundation
import Testing
@testable import ForkedEchoes

struct RunSnapshotTests {

    private func freshDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "RunSnapshotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    @Test func encodeDecodeRoundTripPreservesAllFields() throws {
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .intro, chosenOptionId: .boat)],
            alignmentScore: 3,
            tutorialSeen: false
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: data)

        #expect(decoded == snapshot)
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
            currentNodeId: .endingHomeward,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        let data = try! JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshot.loadValid(from: defaults) == snapshot)
    }
}
