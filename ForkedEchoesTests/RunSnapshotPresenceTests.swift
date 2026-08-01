import Foundation
import Testing
@testable import ForkedEchoes

struct RunSnapshotPresenceTests {

    private func freshDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "RunSnapshotPresenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    @Test func noSnapshotMeansNoRunInProgress() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == false)
    }

    // AC #4: presence alone is no longer enough — garbage data (the old test's stand-in for "any
    // snapshot") must now report no run in progress, since it doesn't decode.
    @Test func malformedSnapshotMeansNoRunInProgress() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data(), forKey: RunSnapshotPresence.runSnapshotKey)
        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == false)
    }

    @Test func validDecodableSnapshotMeansRunInProgress() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [],
            alignmentScore: 0,
            tutorialSeen: false
        )
        let data = try! JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)

        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == true)
    }
}
