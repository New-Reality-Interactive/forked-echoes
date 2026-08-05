// Story 2.13 (AC #5): the run-options action sheet's fixed row order, expressed as a plain,
// testable Swift value rather than only implicit in a ViewBuilder closure's line order. Lives
// under Engine/ (not Views/DesignSystem/, where RunOptionsButton.swift itself lives) because
// this devcontainer's SwiftPM package only builds ForkedEchoesTests against Content/Engine
// sources (Package.swift excludes Views) — a type defined inside RunOptionsButton.swift would be
// invisible to `swift test`. Engine/ and Views/ share one Xcode module in the real app, so
// RunOptionsButton.swift references this type directly, no import needed.
enum RunOptionsRow: CaseIterable, Hashable {
    case exitToHome
    case restartRun
    case exitAndClearProgress
    case cancel
}
