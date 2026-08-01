import Foundation

/// Creates an isolated `UserDefaults` suite so a test never writes to the real `.standard`
/// domain (which pollutes real app state and races other tests — code review, 2026-08-01,
/// Story 2.4). Callers must clean up when done, typically via `defer { defaults.removePersistentDomain(forName: suiteName) }`.
func freshDefaults() -> (defaults: UserDefaults, suiteName: String) {
    let suiteName = "ForkedEchoesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, suiteName)
}
