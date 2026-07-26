# Deferred Work

## Deferred from: code review of 1-4-home-and-tutorial-visual-identity-and-accessibility-pass (2026-07-26)

- `.background(Color.surfaceBase.ignoresSafeArea())` is duplicated per-screen (`HomeView.swift`, `TutorialView.swift`) rather than centralized (e.g. on `RootView`'s `NavigationStack`). Pre-existing pattern, not a bug: centralizing was out of this story's declared scope (its own Dev Notes explicitly forbid touching `RootView.swift`), and only two screens currently need the background. Revisit once a third frame-free screen (if any) needs the same treatment.

## Deferred from: code review of 1-1-project-scaffold (2026-07-26)

- No `DEVELOPMENT_TEAM` set in any build configuration (`CODE_SIGN_STYLE = Automatic`) — blocks device/Archive builds; Simulator builds are unaffected. Pre-existing: the story's own Dev Notes already defer the Apple Developer Program/team decision until the account type is chosen (epics.md Pre-Submission Checklist).
- `AppIcon.appiconset` declares a 1024x1024 slot with no image asset — will fail Release Archive/App Store validation once attempted. Pre-existing: real app icon art is Epic 4's job (Story 4.6, App Store listing/submission assets), not this scaffold story.

## Deferred from: code review of 1-2-home-screen-start-resume-story-and-start-tutorial (2026-07-26)

- `hasInProgressRun` is computed fresh in `HomeView.body` and isn't reactively tied to future snapshot writes while Home stays mounted. Properly solved by Story 2.4's real `@Observable` engine wiring; building ad hoc observation now would violate 1.2's explicit scope ban on Engine-level state.
- `RunSnapshotPresence.hasInProgressRun` is a bare presence check with no validation/invalidation (a stray value under the key would permanently show "Resume Story"). Explicitly Story 2.4's job per Story 1.2's own Dev Notes (decode-success check).
- No bound `NavigationPath` on `RootView`'s `NavigationStack` for future programmatic pop-to-root. Appropriately Story 1.3's concern when it adds the first "Back home" button (AD-5's rationale explicitly avoids relying on default back-gesture chrome).
- `NavigationLink` taps on Home have no re-entrancy guard against rapid double-taps (could push a destination twice). Minor, generic SwiftUI concern applying broadly across the app; better addressed systematically (e.g. a Story 1.4 polish pass) than patched ad hoc here.

## Deferred from: code review of 5-2-landscape-architecture-decision-and-orientation-unlock (2026-07-26)

- `sprint-status.yaml` flips `5-1-landscape-ux-design-pass` to `done` and `epic-5` to `in-progress` with no corresponding `5-1-*.md` story file, breaking the tracker's usual file-per-status-change convention. Pre-existing: Story 5.1's design work was completed and merged directly, outside the `create-story`/`dev-story` flow, before Story 5.2 began. The status correction reflects the user's own confirmation that 5.1 is done and merged, not new work Story 5.2 performed.
- Lifting the OS-level orientation lock ships ahead of the Home/Tutorial landscape layout retrofit (Story 5.3), creating a window where a build could show stretched/un-retrofitted landscape UI. Pre-existing/inherent: this is the deliberate two-story split `epics.md` specifies (5.2 unlock, then 5.3 retrofit, back-to-back next in the sprint), and there is no active TestFlight/App Store distribution channel yet (Apple Developer Program enrollment remains an open blocking dependency).

## Deferred from: code review of 5-3-home-and-tutorial-landscape-retrofit (2026-07-26)

- `StoryChoicePlaceholderView.swift` (Home's third destination, reached via "Start Story"/"Resume Story") still has no `.frame(maxWidth: .infinity, maxHeight: .infinity)` centering treatment, unlike `TutorialPlaceholderView.swift` which this story updated — landscape behavior is now inconsistent between Home's two sibling destinations. Pre-existing gap, out of this story's declared scope (file list: `HomeView.swift`, `TutorialPlaceholderView.swift` only); Story 2.1 replaces this placeholder with real content backed by `StoryRunEngine`.

## Deferred from: code review of 1-3-tutorial-screen (2026-07-26)

- No VoiceOver-specific alternative wording for the gesture-only page-turn mechanic (`tutorial.mechanic.pageTurn` describes swipe/tap-edge only). Pre-existing/by design: full VoiceOver-label and Dynamic-Type-at-accessibility-sizes validation is explicitly Story 1.4's scope per this story's own Dev Notes.
- No `tutorialSeen` persistence flag written when Tutorial is dismissed/completed. Blocked, not skipped: `tutorialSeen` would live on the real `RunSnapshot` (AD-4), which doesn't exist yet — only the presence-check stub `RunSnapshotPresence` does. The Codable `RunSnapshot` model is Story 2.4's job.
- Rapid double-tap on the "Start Story" `NavigationLink` before the push transition completes could in theory push a duplicate destination. Pre-existing, generic: identical risk already exists in `HomeView`'s already-shipped `NavigationLink(value: HomeDestination.storyChoice)` (Story 1.2); not introduced by this diff, already noted as a Story 1.2 deferred item above.

## Deferred from: user testing during 1-3-tutorial-screen (2026-07-26) — app-wide bug, not scoped to this story

- **Cold-launch orientation mismatch:** if the Simulator is already rotated to landscape *before* the app launches, both Home and Tutorial render their portrait layout initially; rotating once (either direction) afterward makes them correct themselves immediately. Confirmed by the user to reproduce on Home too, so this predates Story 1.3 — traced to Epic 5's orientation-unlock work (Story 5.2 lifted the OS-level portrait lock; `Info.plist`'s `UISupportedInterfaceOrientations` lists Portrait first). Likely a known class of SwiftUI/Simulator cold-launch bug where the initial layout pass reflects the first-listed supported orientation before the actual device orientation propagates, and `GeometryReader`'s `proxy.size` (used by both `HomeView` and `TutorialView` for centering) isn't recomputed until the next layout-invalidating event (a rotation). Not fixed here: needs a developer who can actually run Simulator to iterate — this session has no Xcode/Swift toolchain available. Candidate owner: Epic 5 (5.2/5.3), both already marked `done`; may need a small standalone fix rather than reopening either story formally.
