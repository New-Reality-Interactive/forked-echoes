import Foundation

enum RunSnapshotPresence {
    static let runSnapshotKey = "com.forkedechoes.runSnapshot"

    // AC #4: Home's Resume/Start label is driven by decode *success*, not mere key presence — a
    // corrupted snapshot must fall back to "Start Story," never "Resume Story" into a fresh run.
    static func hasInProgressRun(in defaults: UserDefaults = .standard) -> Bool {
        RunSnapshot.loadValid(from: defaults) != nil
    }
}
