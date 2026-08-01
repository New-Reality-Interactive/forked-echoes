import Foundation
import Observation

enum RunSnapshotPresence {
    static let runSnapshotKey = "com.forkedechoes.runSnapshot"

    // AC #4: Home's Resume/Start label is driven by decode *success*, not mere key presence — a
    // corrupted snapshot must fall back to "Start Story," never "Resume Story" into a fresh run.
    static func hasInProgressRun(in defaults: UserDefaults = .standard) -> Bool {
        RunSnapshot.loadValid(from: defaults) != nil
    }
}

// Code review, 2026-08-01: user-confirmed Simulator bug — Home/Tutorial's Resume/Start label
// (AC #4) went stale after exiting a Story session back to Home. `hasInProgressRun()` reads
// `UserDefaults` directly, a data source SwiftUI's diffing engine has no way to observe; a plain
// `let hasInProgressRun = RunSnapshotPresence.hasInProgressRun()` inside `body` is only correct
// the moment `body` happens to re-run for some unrelated tracked-property reason, not reliably
// on returning from the fullScreenCover-presented session. This @Observable wrapper gives each
// view something SwiftUI *does* track, explicitly refreshed via `.onAppear` (which reliably
// re-fires when a fullScreenCover presented over a view is dismissed).
@Observable
final class RunProgressObserver {
    private(set) var hasInProgressRun: Bool
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasInProgressRun = RunSnapshotPresence.hasInProgressRun(in: defaults)
    }

    func refresh() {
        hasInProgressRun = RunSnapshotPresence.hasInProgressRun(in: defaults)
    }
}
