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

    @Test func presentSnapshotMeansRunInProgress() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data(), forKey: RunSnapshotPresence.runSnapshotKey)
        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == true)
    }
}
