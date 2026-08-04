---
baseline_commit: fbdfd3c
---

# Story 2.13: Run-Options Sheet — Exit and Clear Progress

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player mid-run,
I want a single action that clears my progress and returns me to a clean Home screen,
so I don't have to Restart and then separately Exit just to fully bail on a run.

*(UX design pass with Sally, 2026-08-03 — resolves the second of two open design questions logged in `deferred-work.md`'s "2-7-run-options-action-sheet" entry and `sprint-status.yaml`'s epic-2 action items, 2026-08-02. Today's two options — "Exit to Home" (non-destructive, preserves `RunSnapshot`, stays where left off) and "Restart This Run" (destructive, clears progress, but resets in place at the intro rather than leaving the run) — cover stay+keep, stay+clear, and leave+keep, but not leave+clear. The companion open question (whether the branch-arrival interstitial should also carry the run-options control) was discussed and closed with no code change needed: Story 2.9's first-visit-only gate means a revisited interstitial already behaves like an ordinary page, so the "no escape hatch" concern only ever applied to a true first-visit interstitial, which the user confirmed should stay a pure art moment. Amends UX-DR11 — see that entry's 2026-08-03 addendum.)*

## Acceptance Criteria

1. **Given** the run-options action sheet (`RunOptionsButton`)
   **When** invoked
   **Then** it presents four rows in order: "Exit to Home", "Restart This Run", "Exit and Clear Progress", "Cancel"

2. **Given** "Exit and Clear Progress" is selected
   **When** activated
   **Then** a second explicit confirmation is required before anything clears, styled and worded consistently with "Restart This Run"'s existing confirmation (destructive role, same interaction pattern)

3. **Given** the "Exit and Clear Progress" confirmation is confirmed
   **When** the action completes
   **Then** progress and alignment score are cleared (same *fields* reset performed by `restartRun()`) and the app navigates to Home, landing on Home's fresh-install state — not the "Resume Story" state

4. **Given** the "Exit and Clear Progress" action and its confirmation dialog's labels
   **When** rendered
   **Then** every label is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2), following the same `runOptions.*` naming convention as the sheet's existing options

5. **Given** the run-options action sheet's four rows
   **When** their order is verified
   **Then** it is fixed as "Exit to Home", "Restart This Run", "Exit and Clear Progress", "Cancel" — in that sequence, never reordered by role/destructive styling — and this ordering is asserted by an automated test (closing the gap 2.7's code review flagged: no automated coverage existed for `RunOptionsButton`'s button ordering)

6. **Given** Story 2.12 (popover-presentation/missing-Cancel bug fix)
   **When** this story lands
   **Then** it builds on the corrected bottom-action-sheet presentation from 2.12 — this story does not independently re-fix the presentation bug, only adds the new row and confirmation to the already-corrected sheet

7. **And** a manual-verification AC: in Xcode/Simulator, start a run, advance a few pages, invoke run options, select "Exit and Clear Progress," confirm, and verify (1) the app lands on Home in its fresh-install state, (2) a new run starts clean with no carried-over progress or score, (3) VoiceOver announces the new option and its confirmation correctly. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

## Tasks / Subtasks

- [x] Task 1: Add `StoryRunEngine.exitAndClearProgress()` — the real reset (AC #3)
  - [x] Read `ForkedEchoes/Engine/StoryRunEngine.swift` in full (already loaded — see Dev Notes) before editing
  - [x] **Do not simply call `restartRun()` for this action.** `restartRun()` resets state via `resetRunState()` and then calls `persistOrClearSnapshot()`, which — since the reset lands `currentNodeId` at `StoryTree.root` (not `.ending`) — writes a *fresh* `RunSnapshot` to disk. `RunSnapshotPresence.hasInProgressRun` reads snapshot presence directly, so a fresh-but-persisted snapshot would make Home show "Resume Story," not the fresh-install "Start Story" state AC #3 requires. This is the one place this story's naive reading of "same reset as `restartRun()`" is wrong — the *field* reset is identical, the *persistence* outcome must differ.
  - [x] Add a new intent method, `exitAndClearProgress()`, next to `restartRun()`: call the existing private `resetRunState()` (unchanged, already resets `currentNodeId`/`choiceHistory`/`alignmentScore`/`visitedNodeIds`/`dismissedInterstitialNodeIds`), then explicitly remove the persisted snapshot — `defaults.removeObject(forKey: RunSnapshotPresence.runSnapshotKey)` — instead of calling `persistOrClearSnapshot()`. Document why in a doc comment (same rationale as above), mirroring the existing doc-comment density on `restartRun()`/`exitToHome()`.
  - [x] Do **not** touch `resetRunState()`, `restartRun()`, `exitToHome()`, or `persistOrClearSnapshot()` — this is additive, not a refactor of existing intents
  - [x] Amend `ARCHITECTURE-SPINE.md`'s AD-3 entry (`_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md`) to add `exitAndClearProgress()` to its enumerated intent-method list, in-place, the same way prior stories amended AD-4/AD-5 when they changed — AD-3's list (`selectChoice(_:)`, `advancePage()`, `goBack()`, `exitToHome()`, `restartRun()`, `startNewRun()`) is treated as the canonical, exhaustive intent surface elsewhere in this codebase's own comments (e.g. `StoryRunEngineTests.swift` line 613's "exitToHome()/restartRun() complete AD-3's intent surface"), so a 7th intent left unlisted would silently break that invariant

- [x] Task 2: Add localization keys (AC #4)
  - [x] In `ForkedEchoes/Resources/Localizable.xcstrings`, insert two new keys in alphabetical order. Existing `runOptions.*` keys sort as: `accessibilityLabel`, `cancel`, `exitToHome`, `restartConfirmation.title`, `restartRun`. Both new keys sort between `cancel` and `exitToHome` (`exitAndClear...` < `exitToHome` alphabetically), in this order: `runOptions.exitAndClearConfirmation.title`, then `runOptions.exitAndClearProgress` — insert both immediately after `runOptions.cancel` and before `runOptions.exitToHome`:
    - `runOptions.exitAndClearConfirmation.title` — the second dialog's explanatory title, worded consistently with `runOptions.restartConfirmation.title`'s "This clears your progress and score. This can't be undone." pattern, but reflecting that this also leaves the run (e.g. something like "This clears your progress and score, and returns you to Home. This can't be undone.") — final copy is a judgment call, keep it terse and consistent in tone with the existing string
    - `runOptions.exitAndClearProgress` — the sheet row / confirmation-dialog destructive-button label, e.g. "Exit and Clear Progress" (matches the epics.md row name exactly)
  - [x] Each entry needs `comment` (describing where/how used, matching the density of the existing `runOptions.*` comments), `extractionState: "manual"`, one `en` `stringUnit` with `state: "translated"` — copy the shape of the existing `runOptions.restartRun`/`runOptions.restartConfirmation.title` entries exactly
  - [x] Verify `python3 -m json.tool` on the edited `.xcstrings` file after editing (project-context.md's Environment section — this devcontainer has no Xcode to catch a malformed catalog otherwise)

- [x] Task 3: Add the row + confirmation to `RunOptionsButton.swift`, as ordered testable data (AC #1, #2, #5, #6)
  - [x] Read `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` in full (already loaded — see Dev Notes) before editing
  - [x] AC #5 requires an *automated* test of the sheet's row order. This project's Testing standard (project-context.md) scopes Swift Testing to non-UI logic and explicitly has no UI test target/pattern — a rendered-view assertion isn't available here. The fix is to make row order a plain, testable Swift value rather than only an implicit ordering of `Button` calls inside a `ViewBuilder` closure: add a small ordered data shape (e.g. `enum RunOptionsRow: CaseIterable { case exitToHome, restartRun, exitAndClearProgress, cancel }`, `CaseIterable`'s synthesized `allCases` giving the fixed order for free) that both (a) the options `confirmationDialog`'s `ViewBuilder` iterates/switches over to render the exact same three-row-plus-Cancel body as today, and (b) a Swift Testing case in `ForkedEchoesTests` can assert directly against, with zero SwiftUI rendering involved. Keep this proportional — this is a small, four-case ordering fact, not a general-purpose menu-configuration system; don't over-engineer it into a bigger abstraction than the four rows need.
  - [x] **This type must live under `ForkedEchoes/Engine/` (e.g. a new small file, or appended to an existing non-SwiftUI Engine file), not inside `RunOptionsButton.swift`/`Views/DesignSystem/`.** `Package.swift` builds `ForkedEchoesTests` against a SwiftPM target whose `sources` are only `["Content", "Engine"]` — it explicitly `exclude`s `Views` (see that file's own comment on why: this devcontainer's SwiftPM package is a testing convenience over the real single-module Xcode app, not a second source of truth, per project-context.md's "General principle" note in the Environment section). A type defined inside `RunOptionsButton.swift` is invisible to `swift test` and Task 5's test case will fail to build, not just fail to pass. Since Engine/ and Views/ share one Xcode module (no cross-import needed there, per project-context.md), `RunOptionsButton.swift` can reference the Engine-housed type directly with zero import — only its placement on disk matters, purely for this devcontainer's parallel SwiftPM build.
  - [x] Add `isPresentingExitAndClearConfirmation: Bool` state (sibling to `isPresentingRestartConfirmation`) and a third `.confirmationDialog`, modeled exactly on the existing restart-confirmation dialog: title `"runOptions.exitAndClearConfirmation.title"`, `titleVisibility: .visible`, one `Button("runOptions.exitAndClearProgress", role: .destructive)` calling a new `onExitAndClearProgress: () -> Void` closure parameter, and the existing `Button("runOptions.cancel", role: cancelButtonRole) {}` pattern (reuse `cancelButtonRole` — do not duplicate the iOS-26-availability branching)
  - [x] Add the `"runOptions.exitAndClearProgress"` row to the *options* `confirmationDialog` (the first one, `isPresented: $isPresentingOptions`) as the third row, `role: .destructive`, action sets `isPresentingExitAndClearConfirmation = true` — same shape as how "Restart This Run" opens its own confirmation today
  - [x] Add `onExitAndClearProgress: () -> Void` as a new `let` closure parameter on `RunOptionsButton`, alongside `onExitToHome`/`onRestartRun` — do not collapse it into either existing closure; the three actions have three distinct effects
  - [x] Update `RunOptionsButton`'s `#Preview` to pass a no-op closure for the new parameter (same as the other two)
  - [x] AC #6: do not touch the `cancelButtonRole`/`#available(iOS 26, *)` logic, the popover-vs-sheet presentation, or the header comment's iOS 26 narrative — that is Story 2.12's already-landed, already-verified fix; this story only adds a row and a confirmation dialog to the existing structure

- [x] Task 4: Wire the new closure at the call site (AC #3)
  - [x] In `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (around line 154's `RunOptionsButton(...)` call), add `onExitAndClearProgress:` alongside the existing `onExitToHome:`/`onRestartRun:` arguments
  - [x] Its body must do two things, in order: call `engine.exitAndClearProgress()` (Task 1's new intent — clears state and the on-disk snapshot), then call `onExitToHome()` (the same closure the existing `onExitToHome:` case invokes to close the `.fullScreenCover` and reset `RootView`'s `NavigationPath`, per project-context.md's Navigation section) — mirroring exactly how the existing `onExitToHome:` case both calls its engine intent and then the View-layer closure
  - [x] Do not call `engine.exitToHome()` (the existing no-op intent) as part of this wiring — it's unrelated to this new action and calling it adds nothing (see its doc comment: it exists purely as a named intent for the *non-destructive* Exit to Home case)
  - [x] Update `StoryChoiceView`'s `#Preview`s (there are several, all currently only passing `onExitToHome:`) if the compiler requires the new parameter — confirm whether `RunOptionsButton`'s new closure needs a matching addition anywhere else in `StoryChoiceView.swift`'s own preview provider chain (confirmed: `RunOptionsButton` is instantiated inside `StoryChoiceView`'s own body, not passed in from outside, so none of `StoryChoiceView`'s `#Preview`s — which only ever pass `onExitToHome:` — needed any change)

- [x] Task 5: Automated test coverage (AC #5)
  - [x] Add a new Swift Testing case (new file `ForkedEchoesTests/RunOptionsButtonTests.swift`, or append to an existing suite if a more natural home exists — check `ForkedEchoesTests/` for precedent first) asserting Task 3's ordered data structure equals `["Exit to Home", "Restart This Run", "Exit and Clear Progress", "Cancel"]` in that exact sequence — or equivalent, if the chosen data shape represents rows by case/identifier rather than label string; the point is a compiler-checked, `swift test`-executed assertion that the order can't silently drift
  - [x] In `ForkedEchoesTests/StoryRunEngineTests.swift`, add tests for `exitAndClearProgress()` modeled directly on the existing `restartRun()` test trio just above it (`restartRunResetsAllRunStateMidRun`, `restartRunClearsDismissedArrivalNodeState`, `restartRunImmediatelyOverwritesTheStaleMidRunSnapshot`):
    - Field reset: mid-run (e.g. `selectChoice(.boat)`), call `exitAndClearProgress()`, assert `currentNodeId == StoryTree.root`, `choiceHistory.isEmpty`, `alignmentScore == 0`, and that `goBack()` afterward stays at root (back-stack cleared)
    - Dismissed-arrival-node state cleared too (same shape as `restartRunClearsDismissedArrivalNodeState`)
    - **The behavior that actually differs from `restartRun()`, and the one most worth a dedicated test:** after `exitAndClearProgress()`, `RunSnapshot.loadValid(from: defaults)` must be `nil` (no persisted snapshot) — contrast with `restartRun()`, which leaves a valid fresh snapshot on disk. Equivalently, `RunSnapshotPresence.hasInProgressRun(in: defaults)` must be `false` afterward. This is the regression this story exists to prevent, per Task 1's note above.
  - [x] Run `swift test` from the repo root — confirm the full suite passes (60/60 before this story; expect that count to grow by this story's new cases, all green) — **64/64 passed** (4 new: `runOptionsRowOrderIsFixed`, `exitAndClearProgressResetsAllRunStateMidRun`, `exitAndClearProgressClearsDismissedArrivalNodeState`, `exitAndClearProgressLeavesNoPersistedSnapshot`)

- [x] Task 6: Manual verification (AC #7)
  - [x] Request from user per project-context.md's Process Agreement (this devcontainer has no Xcode/Simulator) — start a run, advance a few pages, invoke run options, select "Exit and Clear Progress," confirm, and verify: (1) lands on Home in fresh-install state ("Start Story," not "Resume Story"), (2) a subsequently-started new run has no carried-over progress/score, (3) VoiceOver announces the new row and its confirmation correctly, in both portrait and landscape
  - [x] Record result + date in Completion Notes List once reported back

### Review Findings

- [x] [Review][Patch] Cancel-button construction (`Button("runOptions.cancel", role: cancelButtonRole) {}`) is now hand-written three times across the options sheet and two confirmation dialogs — extract a small shared helper so a future edit can't let the three copies drift [ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift:81,93,103] — fixed: added private `cancelButton` computed property, all three call sites now reference it
- [x] [Review][Patch] `exitAndClearProgress()` called with no snapshot ever persisted (e.g. from `StoryTree.root` before any choice) is untested — `defaults.removeObject(forKey:)` on an already-absent key is assumed to be a harmless no-op but that assumption isn't asserted [ForkedEchoes/Engine/StoryRunEngine.swift:242] — fixed: added `exitAndClearProgressIsHarmlessWithNoPriorSnapshot()` test
- [x] [Review][Defer] `runOptionsRowOrderIsFixed()` only asserts `RunOptionsRow.allCases`'s order — it doesn't prove `RunOptionsButton`'s `switch` maps each case to the correct label/action, so a swapped `case` body would still pass this test. No automated fix is available without SwiftUI-rendering test infra this project deliberately doesn't have (see Task 3's own note) — deferred, pre-existing testing-approach constraint [ForkedEchoesTests/RunOptionsButtonTests.swift:11; ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift:66-83]
- [x] [Review][Defer] `StoryChoiceView`'s `onExitAndClearProgress` closure calling `engine.exitAndClearProgress()` then `onExitToHome()`, in that order, has no automated regression coverage — a future accidental reordering would only surface via manual QA, same UI-test-infra gap as above — deferred, pre-existing testing-approach constraint [ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift:162-165]
- [x] [Review][Defer] Story 2.14 treats the `UserDefaults(suiteName:)` write-then-read race as test-infrastructure-only, but `StoryRunEngine.resumingFromSnapshot(defaults:)` (production code) has the identical write-then-immediate-read access shape against real `UserDefaults` — if the eventual root cause turns out to be a genuine synchronization issue rather than a Linux `swift-corelibs-foundation` test artifact, it could be reachable in the shipped app, not just `swift test`. Story 2.14's own scope notes already include a safety valve for this ("stop and reconsider scope" if production code is implicated) — deferred to that story, flagging here so it isn't lost — deferred, tracked in Story 2.14

## Dev Notes

### What already exists — do not re-create any of this

This adds one new sheet row + one new confirmation dialog + one new engine intent to an already-shipped, already-corrected control. It does not touch presentation style (Story 2.12), the Cancel-role/iOS-26 branching (Story 2.12), or `StoryRunEngine`'s existing intents (`exitToHome()`, `restartRun()`, `resetRunState()`, `persistOrClearSnapshot()`) — those are all read-only context for this story, not edit targets.

`ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` (95 lines as of Story 2.12, read in full before editing):
- Lines 30-42: `RunOptionsButton` struct — two closure params today (`onExitToHome`, `onRestartRun`), two `@State` presentation flags, `cancelButtonRole` computed property (iOS-26-gated, Story 2.12 — reuse as-is for the new dialog's Cancel row)
- Lines 61-69: the options `confirmationDialog` (`isPresented: $isPresentingOptions`) — currently two action rows + Cancel; this story inserts a third action row between "Restart This Run" and "Cancel"
- Lines 70-79: the restart-confirmation `confirmationDialog` (`isPresented: $isPresentingRestartConfirmation`) — the structural template for this story's new exit-and-clear-confirmation dialog (same `titleVisibility: .visible`, same destructive-button + Cancel-row shape)

`ForkedEchoes/Engine/StoryRunEngine.swift` (lines 208-263 as of this story, read in full before editing):
- `exitToHome()` (line 218): intentionally a no-op, exists only as a named intent for the *non-destructive* exit — do not call this from the new action
- `restartRun()` (line 226): `resetRunState()` + `persistOrClearSnapshot()` — the field-reset template, but its persistence behavior is *not* what this story wants (see Task 1)
- `resetRunState()` (line 257, `private`): the shared reset shape — reuse directly, do not duplicate its field list
- `persistOrClearSnapshot()` (line 277, `private`): writes a snapshot unless the current node is `.ending` — this is exactly why calling it (via `restartRun()` or directly) after a reset-to-root would leave a "resumable" snapshot on disk; this story's new intent must bypass it and clear the key directly instead

`ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` lines 153-163: the one production call site (`.overlay(alignment: .topTrailing) { RunOptionsButton(...) }`), itself only reached when `engine.phase != .interstitial` — unchanged scope, this story doesn't touch when/where the button appears, only what one of its rows does.

### The one non-obvious design decision this story requires (AC #3)

AC #3's own wording — "same reset performed by `restartRun()`" — describes the *field* reset (`currentNodeId`/`choiceHistory`/`alignmentScore`/`visitedNodeIds`/`dismissedInterstitialNodeIds`), which is genuinely identical and should be reused via the existing `resetRunState()`. It does **not** mean "call `restartRun()`" — doing so would persist a fresh, resumable snapshot to disk (see `persistOrClearSnapshot()`'s `.ending`-only-clears logic above), and AC #3's second half is explicit that Home must land in its "fresh-install state — not the 'Resume Story' state," which `RunSnapshotPresence.hasInProgressRun` derives purely from snapshot presence (`RunSnapshot.loadValid(from:) != nil`). The new `exitAndClearProgress()` intent (Task 1) must reset fields the same way but clear the on-disk key instead of writing to it. Get this specific point wrong and the story will pass a superficial glance (state fields all zero, in-memory) while still shipping a Home screen that incorrectly reads "Resume Story."

### AC #5's automated-order-test tension with project-context.md's Testing rule

project-context.md states plainly: "There is no UI test target and no UI-test pattern in this project... Don't add UI tests as a side effect of a view-only story." AC #5 (written into epics.md at story-scoping time) nonetheless requires automated coverage of the sheet's row order, closing a gap Story 2.7's code review explicitly flagged. These aren't actually in conflict once the row order is represented as a plain Swift value (Task 3) rather than only implicit in a `ViewBuilder` closure's line order — a Swift Testing case over that plain value is data-logic testing (squarely within AD-7/this project's existing Swift Testing scope, same category as `StoryRunEngineTests.swift`), not view-rendering testing. Don't reach for a UI test framework to satisfy AC #5; reach for a small, testable data shape instead.

### Architecture compliance

- **AD-3**: `StoryRunEngine` remains the sole mutator of run state — `exitAndClearProgress()` is a new named intent on the engine, exactly like every other player action; the View layer never reaches into engine state directly.
- **AD-5**: no change to the Story session's `.fullScreenCover` presentation mechanism (owned by `RootView`) or to the confirmationDialog presentation style corrected by Story 2.12 — this story only adds a row and a dialog within the existing structure.
- **AD-2**: every new label sourced from `Localizable.xcstrings` via its dot-path key (this project has no compiler-generated symbol codegen despite AD-2's aspirational language — confirmed empirically, see project-context.md's Localization section — so "generated symbols" in this story's AC #4 language means the existing `Text("runOptions.xxx")` dot-path convention, not literal Swift-generated accessors).

### Testing standards summary

- Engine-logic change (`StoryRunEngine.exitAndClearProgress()`) is squarely within AD-7/Swift Testing scope — add real `@Test` cases in `StoryRunEngineTests.swift`, modeled on the adjacent `restartRun()` test trio (see Task 5).
- The new row-order data structure (Task 3) is also plain-value, non-UI, and Swift-Testing-appropriate — see the AC #5 note above. This is the one addition to this project's established "no UI tests" pattern that is *not* actually a UI test.
- Everything else about the view-layer change (dialog presentation, VoiceOver announcement, label rendering) is manual-Simulator-only, per this project's existing pattern — do not attempt to add SwiftUI view rendering tests.
- Run `swift test` from the repo root (not `xcodebuild test`) — see project-context.md's Environment section for why.
- `swiftc -parse` on every edited `.swift` file for genuine syntax verification (this devcontainer has no Xcode/SwiftUI module resolution — `swiftc -typecheck` fails with "no such module" on any file importing SwiftUI, so `-parse` is the ceiling here for `RunOptionsButton.swift`/`StoryChoiceView.swift`; the `Engine/`-scoped changes and their tests are the ones that genuinely build and run via `swift test`).
- `python3 -m json.tool` on `Localizable.xcstrings` after editing, to catch a malformed catalog (no parser-level tool covers `.xcstrings` otherwise).

### Project Structure Notes

- Expected modified: `ForkedEchoes/Engine/StoryRunEngine.swift`, `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift`, `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`, `ForkedEchoes/Resources/Localizable.xcstrings`, `ForkedEchoesTests/StoryRunEngineTests.swift`.
- Expected new: one test file (e.g. `ForkedEchoesTests/RunOptionsButtonTests.swift`) for the row-order assertion, unless an existing suite is a more natural home — check `ForkedEchoesTests/` first per Task 5.
- Explicitly **not** modified: `ForkedEchoes/Views/RootView.swift` (the `onExitToHome` closure it already passes into `StoryChoiceView` is reused as-is — Task 4 calls it, doesn't change its definition), `RunSnapshot.swift`/`RunSnapshotPresence.swift` (read, not edited — `exitAndClearProgress()` uses `RunSnapshotPresence.runSnapshotKey` and `UserDefaults.removeObject(forKey:)`, both already public/available, no new API needed there), `TutorialView.swift` (no `RunOptionsButton` call site since Story 2.11 — out of scope, don't reintroduce one).

### Previous Story Intelligence (Story 2.12)

- `RunOptionsButton.swift`'s current shape (as of 2.12, done) is the accurate baseline this story builds on — see the "What already exists" section above for exact line references.
- Story 2.12's Completion Notes documents a hard-won process lesson worth re-reading before this story's own manual-verification handoff (Task 6): an unverified fix reported as "done" and later disproven by the user's own Simulator screenshot. This story's Task 6 should request verification and wait for the actual result, not assume success.
- Story 2.12 touched only `RunOptionsButton.swift` + docs, confirming `StoryChoiceView.swift`'s call site (line 153-163) was untouched by that story — this story is the first to add a parameter to that call site since Story 2.7 originally wired it.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.13: Run-Options Sheet — Exit and Clear Progress]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR11] (2026-08-03 addendum — the four-row spec this story implements)
- [Source: _bmad-output/project-context.md#Navigation] (`.fullScreenCover`/`onExitToHome` mechanism, AD-5)
- [Source: _bmad-output/project-context.md#Localization] (`Localizable.xcstrings` conventions — alphabetical key order, comment/extractionState/stringUnit shape)
- [Source: _bmad-output/project-context.md#Testing] (Swift Testing scope, no UI test target/pattern — see this story's AC #5 note for how the row-order test stays compliant)
- [Source: _bmad-output/project-context.md#Process Agreements] (actively request user's Xcode/Simulator verification)
- [Source: ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift] (edit target — both existing `confirmationDialog`s are the templates for this story's additions)
- [Source: ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift] (edit target — the one production call site, lines 153-163)
- [Source: ForkedEchoes/Engine/StoryRunEngine.swift] (edit target — `restartRun()`/`resetRunState()`/`persistOrClearSnapshot()`/`exitToHome()`, lines 208-298)
- [Source: ForkedEchoes/Engine/RunSnapshotPresence.swift] (`hasInProgressRun`/`runSnapshotKey` — why persistence, not just field state, determines Home's label)
- [Source: ForkedEchoesTests/StoryRunEngineTests.swift] (lines 613-705 — the `exitToHome()`/`restartRun()` test precedent this story's new tests should mirror)
- [Source: _bmad-output/implementation-artifacts/2-12-run-options-sheet-fix-popover-presentation-and-missing-cancel.md] (previous story in Epic 2 — confirms `RunOptionsButton.swift`'s current baseline shape and the process lesson re: unverified fixes)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-3] (engine as sole state mutator)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-5]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swift build` — clean after each Engine-layer edit (Tasks 1, 3)
- `swiftc -parse` — clean on `RunOptionsButton.swift` and `StoryChoiceView.swift` (Tasks 3, 4)
- `python3 -m json.tool` — valid JSON on `Localizable.xcstrings` after Task 2's edit
- `swift test` — 64/64 passed (60 pre-existing + 4 new from this story). Note: repeated runs surfaced pre-existing flakiness unrelated to this story's changes — `observerRefreshPicksUpASnapshotWrittenAfterConstruction`, `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, and `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately` (none touched by this story, none new) intermittently failed in isolation under Swift Testing's parallel execution, always passing on rerun. Confirmed pre-existing by stashing this story's changes and rerunning the baseline suite. None of this story's 4 new tests ever failed across ~10 repeated runs. Flagging for awareness, not fixing — out of this story's scope.

### Completion Notes List

- Tasks 1-5 implemented and verified via the devcontainer's available tooling (see Debug Log References).
- **Task 6 manual verification confirmed by user, 2026-08-04:** Xcode build succeeded, `swift test` passed in Xcode, and Simulator verification of AC #7 was successful — (1) Home lands on its fresh-install "Start Story" state (not "Resume Story") after "Exit and Clear Progress" is confirmed, (2) a subsequently-started new run carries over no progress or score, (3) VoiceOver correctly announces the new row and its confirmation dialog — confirmed in both portrait and landscape.
- Design decision confirmed correct via the new `exitAndClearProgressLeavesNoPersistedSnapshot` test: `exitAndClearProgress()` reuses `resetRunState()` for field parity with `restartRun()`, but removes the persisted `RunSnapshot` key directly instead of calling `persistOrClearSnapshot()`, since the latter would re-persist a fresh, resumable snapshot the moment `currentNodeId` lands back at `StoryTree.root`.
- `RunOptionsRow` (new `ForkedEchoes/Engine/RunOptionsRow.swift`) makes the sheet's four-row order a plain, `CaseIterable` value that both `RunOptionsButton`'s options `confirmationDialog` (via `ForEach(RunOptionsRow.allCases, id: \.self)`) and `RunOptionsButtonTests.runOptionsRowOrderIsFixed()` consume — closes the automated-coverage gap Story 2.7's code review flagged, without adding a UI test target/pattern (project-context.md's Testing rule stays intact).
- `ARCHITECTURE-SPINE.md`'s AD-3 intent-method list and `StoryRunEngineTests.swift`'s line-613 doc comment both updated in place to include `exitAndClearProgress()`, keeping the "AD-3's intent surface is exhaustively enumerated" invariant true.
- **Code review verification confirmed by user, 2026-08-04:** after the review's two patches (shared `cancelButton` helper in `RunOptionsButton.swift`, new `exitAndClearProgressIsHarmlessWithNoPriorSnapshot()` test), the user rebuilt and retested the whole app in Xcode — build, `swift test` in Xcode, and Simulator verification all passed as expected. Story remains `done`.

### File List

- `ForkedEchoes/Engine/StoryRunEngine.swift` (modified — new `exitAndClearProgress()` intent)
- `ForkedEchoes/Engine/RunOptionsRow.swift` (new — ordered, testable row-order data shape)
- `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` (modified — third sheet row, third confirmation dialog, `onExitAndClearProgress` closure param, row rendering switched to iterate `RunOptionsRow.allCases`)
- `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (modified — wires `onExitAndClearProgress:` at the `RunOptionsButton` call site)
- `ForkedEchoes/Resources/Localizable.xcstrings` (modified — `runOptions.exitAndClearConfirmation.title`, `runOptions.exitAndClearProgress`)
- `ForkedEchoesTests/StoryRunEngineTests.swift` (modified — three new `exitAndClearProgress()` tests, one doc-comment update)
- `ForkedEchoesTests/RunOptionsButtonTests.swift` (new — row-order assertion)
- `_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md` (modified — AD-3 intent-method list amended)

## Change Log

- 2026-08-04: Story 2.13 created via create-story workflow. Scoped to adding a fourth "Exit and Clear Progress" row to `RunOptionsButton`'s options sheet, its own destructive-confirmation dialog, a new `StoryRunEngine.exitAndClearProgress()` intent that resets run state like `restartRun()` but clears (rather than re-persists) the on-disk `RunSnapshot` so Home lands in its fresh-install state, two new `runOptions.*` localization keys, and an automated test of the sheet's fixed four-row order via a new testable data shape (closing a gap flagged in Story 2.7's code review). Builds on Story 2.12's corrected presentation without re-touching it.
- 2026-08-04: Tasks 1-5 implemented. `StoryRunEngine.exitAndClearProgress()` added (Engine); `RunOptionsRow` ordered-data shape added (Engine, new file) and wired into `RunOptionsButton`'s options sheet via `ForEach`; new confirmation dialog + closure param added to `RunOptionsButton`; call site wired in `StoryChoiceView`; two localization keys added; four new Swift Testing cases added (`RunOptionsButtonTests.swift` new, `StoryRunEngineTests.swift` extended); `ARCHITECTURE-SPINE.md` AD-3 amended. `swift test` 64/64 green. Task 6 (manual Simulator verification) awaits the user per project-context.md's Process Agreement.
- 2026-08-04: Task 6 manual verification confirmed by user — Xcode build, `swift test`, and Simulator check of AC #7 all successful (fresh-install Home state, clean new run, correct VoiceOver announcements, portrait and landscape). All tasks complete, status updated to review.
