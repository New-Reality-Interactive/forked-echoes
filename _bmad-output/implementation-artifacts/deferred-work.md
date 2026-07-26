# Deferred Work

## Deferred from: code review of 1-1-project-scaffold (2026-07-26)

- No `DEVELOPMENT_TEAM` set in any build configuration (`CODE_SIGN_STYLE = Automatic`) — blocks device/Archive builds; Simulator builds are unaffected. Pre-existing: the story's own Dev Notes already defer the Apple Developer Program/team decision until the account type is chosen (epics.md Pre-Submission Checklist).
- `AppIcon.appiconset` declares a 1024x1024 slot with no image asset — will fail Release Archive/App Store validation once attempted. Pre-existing: real app icon art is Epic 4's job (Story 4.6, App Store listing/submission assets), not this scaffold story.

## Deferred from: code review of 1-2-home-screen-start-resume-story-and-start-tutorial (2026-07-26)

- `hasInProgressRun` is computed fresh in `HomeView.body` and isn't reactively tied to future snapshot writes while Home stays mounted. Properly solved by Story 2.4's real `@Observable` engine wiring; building ad hoc observation now would violate 1.2's explicit scope ban on Engine-level state.
- `RunSnapshotPresence.hasInProgressRun` is a bare presence check with no validation/invalidation (a stray value under the key would permanently show "Resume Story"). Explicitly Story 2.4's job per Story 1.2's own Dev Notes (decode-success check).
- No bound `NavigationPath` on `RootView`'s `NavigationStack` for future programmatic pop-to-root. Appropriately Story 1.3's concern when it adds the first "Back home" button (AD-5's rationale explicitly avoids relying on default back-gesture chrome).
- `NavigationLink` taps on Home have no re-entrancy guard against rapid double-taps (could push a destination twice). Minor, generic SwiftUI concern applying broadly across the app; better addressed systematically (e.g. a Story 1.4 polish pass) than patched ad hoc here.
