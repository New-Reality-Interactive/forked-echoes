import Foundation

// Story 2.4 owns the real Codable RunSnapshot and must reuse `runSnapshotKey` when it lands,
// upgrading `hasInProgressRun` from a presence check to a decode-success check.
enum RunSnapshotPresence {
    static let runSnapshotKey = "com.forkedechoes.runSnapshot"

    static func hasInProgressRun(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: runSnapshotKey) != nil
    }
}
