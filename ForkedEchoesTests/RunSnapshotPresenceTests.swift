import Foundation
import Testing
@testable import ForkedEchoes

struct RunSnapshotPresenceTests {

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

    // Code review, 2026-08-01: user-confirmed Simulator bug — Home/Tutorial's Resume/Start label
    // went stale after exiting a Story session, since reading UserDefaults directly inside `body`
    // isn't something SwiftUI's diffing tracks. RunProgressObserver.refresh() is the fix's
    // engine-level half; these tests pin down that refresh() actually re-reads `defaults` rather
    // than caching its constructor-time value.
    @Test func observerReflectsConstructionTimeState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let observer = RunProgressObserver(defaults: defaults)

        #expect(observer.hasInProgressRun == false)
    }

    @Test func observerRefreshPicksUpASnapshotWrittenAfterConstruction() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let observer = RunProgressObserver(defaults: defaults)
        #expect(observer.hasInProgressRun == false)

        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [],
            alignmentScore: 0,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)
        observer.refresh()

        #expect(observer.hasInProgressRun == true)
    }

    @Test func observerRefreshPicksUpASnapshotClearedAfterConstruction() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [],
            alignmentScore: 0,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)
        let observer = RunProgressObserver(defaults: defaults)
        #expect(observer.hasInProgressRun == true)

        defaults.removeObject(forKey: RunSnapshotPresence.runSnapshotKey)
        observer.refresh()

        #expect(observer.hasInProgressRun == false)
    }
}
