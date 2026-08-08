---
baseline_commit: 7c460365f30acb0aa48150d916a9519613c1d954
---

# Story 3.12: Ending Page Tap-to-Advance Regression

Status: ready-for-dev

## Story

As a player,
I want tapping anywhere on an Ending page to reliably advance me to the Memory recap,
so that reaching an ending doesn't strand me on a page with no working way forward.

## Acceptance Criteria

1. **Given** a player has reached an Ending page (any of the four `EndingKind` flavors), **when** they tap anywhere on the screen (per `EndingView.swift`'s AC #3 tap-anywhere contract from Story 3.2), **then** `engine.advancePage()` fires and the phase transitions to `.memory`, rendering `MemoryView` — matching `StoryRunEngine`'s existing (and still test-covered) `advancePageFromEndingTransitionsPhaseToMemory` behavior. [Source: epics.md#Story-3.12, AC1]
2. **And** a root-cause investigation AC: in Xcode/Simulator, diagnose why the tap is not currently reaching `engine.advancePage()` — candidates to rule in/out include gesture-recognition conflict with `backSwipeGesture`'s `DragGesture`, `.accessibilityElement(children: .combine)` altering hit-testing, or another Views-layer cause — and record the confirmed root cause in the story's Completion Notes before applying a fix. [Source: epics.md#Story-3.12, AC2]
3. **And** a regression-guard AC: swipe-back navigation from the Ending page (restored Story 3.3 Task 7) continues to work after this story's fix — the fix must not trade the tap regression for a swipe regression. [Source: epics.md#Story-3.12, AC3]
4. **And** a manual-verification AC: in Xcode/Simulator, confirm tap-to-advance works on at least one Ending page of each of the four `EndingKind` flavors post-fix, and record the dated result in the story's Completion Notes List. [Source: epics.md#Story-3.12, AC4 — project-context.md Process Agreement]

## Background: Why This Story Exists

Reported by the user during Story 3.10's dev-story session (manual Simulator testing, 2026-08-08): tapping an Ending page no longer navigates to the Memory recap. This is unrelated to Story 3.10's own scope (Home/Tutorial button padding, interstitial compact-height headroom) — no file Story 3.10 touched (`HomeView.swift`, `TutorialView.swift`) is anywhere near `EndingView.swift`'s navigation wiring, and Story 3.10's `swift test` run (89 tests, 6 suites) passed clean, including `StoryRunEngineTests`'s `advancePageFromEndingTransitionsPhaseToMemory` — so the engine-logic layer (`StoryRunEngine.advancePage()`) is confirmed still correct. The bug is scoped to the Views layer, specifically `EndingView.swift`.

`EndingView.swift`'s AC #3 (Story 3.2) is a full-surface "tap anywhere" gesture:

```swift
.contentShape(Rectangle())
.onTapGesture {
    engine.advancePage()
}
```

Story 3.3 Task 7 (2026-08-06) later restored swipe-back navigation on this same view, adding a second gesture to the same surface:

```swift
.gesture(backSwipeGesture)
```

where `backSwipeGesture` is a `DragGesture(minimumDistance: LayoutMetrics.pageSwipeThreshold)`. No commit since Story 3.6 (`aea3e0d`) has touched `EndingView.swift`, so this is not a fresh regression from recent work — it has likely been broken (or is intermittently broken) since Story 3.3's swipe-back restoration, undetected until now because no story since then exercised the full tap-to-advance path in Simulator end-to-end (Story 3.5's AX5 walkthrough covered clipping/truncation and interstitial padding, not this specific interaction).

Compare with `StoryChoiceView.swift`'s equivalent reading-page pattern (`pageTapZones`, lines ~397-418): there, forward/back taps are two separate `Color.clear` zones (left third / right third) each with their own `.onTapGesture`, and the full-surface `pageTurnGesture` `DragGesture` is a *sibling* gesture, not stacked with a tap gesture on the exact same full-surface `contentShape`. `EndingView.swift` is structurally different: one full-surface tap gesture and one full-surface drag gesture both attached to the same `contentShape(Rectangle())`. This structural difference is the leading hypothesis for why `EndingView` might have a live gesture-recognition conflict that `StoryChoiceView` does not — but this is unconfirmed without Simulator testing (this devcontainer cannot render SwiftUI/UIKit).

## Tasks / Subtasks

- [ ] Task 1: Root-cause investigation in Xcode/Simulator (AC: #2)
  - [ ] Reach an Ending page in Simulator (any `EndingKind`) and tap the screen; confirm the regression reproduces (no transition to Memory).
  - [ ] Add temporary debug logging (or use the Xcode view debugger / breakpoint) to confirm whether `EndingView.body`'s `.onTapGesture` closure fires at all on tap.
  - [ ] If the tap gesture never fires: investigate gesture-recognition conflict with `backSwipeGesture`'s `DragGesture` sharing the same `contentShape(Rectangle())` — try `.simultaneousGesture(backSwipeGesture)` in place of `.gesture(backSwipeGesture)`, or reordering the modifier chain, and confirm whether that restores the tap.
  - [ ] If the tap gesture does fire but `engine.advancePage()` doesn't produce the expected transition: investigate further up the call chain (`StoryChoiceView`'s `.ending`-phase branch, `engine.phase`/`engine.currentNodeId` state at the time of the tap).
  - [ ] Record the confirmed root cause in Completion Notes before proceeding to Task 2.

- [ ] Task 2: Apply the fix (AC: #1, #3)
  - [ ] Based on Task 1's confirmed root cause, apply the minimal fix to `EndingView.swift` (e.g. `.simultaneousGesture` instead of `.gesture` for `backSwipeGesture`, or whatever Task 1 identifies as the actual cause).
  - [ ] Confirm in Simulator that tap-to-advance now works.
  - [ ] Confirm in Simulator that swipe-back still works (AC #3 — do not fix the tap regression by breaking swipe-back).

- [ ] Task 3: Manual Xcode/Simulator verification across all EndingKind flavors (AC: #4)
  - [ ] Reach an ending of each of the four `EndingKind` flavors (`.home`, `.stay`, `.limbo`, `.hardFail`) and confirm tap-to-advance works on each.
  - [ ] Record the dated result in Completion Notes per AC #4.

## Dev Notes

### This devcontainer cannot render SwiftUI — Task 1 and Task 3 require the user's own Simulator session

Same constraint as Story 3.10: there is no way to observe or diagnose SwiftUI gesture behavior from this environment. Task 1's root-cause investigation must happen in the user's Xcode/Simulator session; report findings back so the fix (Task 2) can be applied with a confirmed cause rather than a guess. If Task 1 rules out the gesture-conflict hypothesis, do not apply the `.simultaneousGesture` change speculatively — keep investigating until the actual cause is confirmed.

### Leading hypothesis (unconfirmed): `.gesture` vs `.simultaneousGesture`

SwiftUI's `.gesture(_:)` modifier can take exclusive priority over other gestures/interactions on the same view when both could plausibly recognize the same touch sequence, whereas `.simultaneousGesture(_:)` lets both recognize concurrently. `EndingView.swift`'s `.onTapGesture` and `.gesture(backSwipeGesture)` are both attached to the same `contentShape(Rectangle())` — if the `DragGesture` is capturing all touches on this surface (even ones that never move far enough to satisfy its `minimumDistance`), that would fully explain a "tap never registers" symptom while swipe-back still works. This is the story's leading hypothesis, not a confirmed diagnosis — Task 1 must confirm before Task 2 acts on it.

### Compare `StoryChoiceView.swift`'s equivalent pattern (does NOT stack tap+drag on the same surface)

`StoryChoiceView.swift:397-419`'s `pageTapZones` keeps its `onTapGesture` calls on separate `Color.clear` zone views, with `pageTurnGesture`'s `DragGesture` attached elsewhere as a sibling — not stacked on the exact same `contentShape`. If Task 1 confirms the gesture-conflict hypothesis, this existing pattern is worth knowing about as prior art, though `EndingView`'s "tap anywhere" contract (AC #3, Story 3.2) is intentionally different from `StoryChoiceView`'s zoned taps and shouldn't be changed to zones — a `.simultaneousGesture` fix (or equivalent) that preserves full-surface tap-anywhere is preferred over restructuring to zones.

### Architecture / design citations

- **`EndingView.swift`**: the view under investigation — `body`'s `.onTapGesture`/`.gesture(backSwipeGesture)` chain (~lines 30-58) and `backSwipeGesture`'s `DragGesture` definition (~lines 61-68).
- **`StoryRunEngine.swift`**: `advancePage()` — confirmed still correct via `swift test`'s `advancePageFromEndingTransitionsPhaseToMemory`; not expected to need changes for this story.
- **Story 3.2** (`3-2-*.md`, if present, else epics.md#Story-3.2): originating AC #3 "tap anywhere advances past Ending" contract.
- **Story 3.3** (`3-3-*.md`, if present, else epics.md#Story-3.3): Task 7 (2026-08-06) restored `backSwipeGesture` onto `EndingView` — the likely point this regression was introduced, per the Dev Notes hypothesis above (though Git Intelligence below shows no commit since Story 3.6 touched this file, meaning the regression predates even Story 3.6's later edits and was simply never caught until now).

### Project Structure Notes

Files expected to change:
- `ForkedEchoes/Views/Ending/EndingView.swift` — the fix, once Task 1 confirms the actual cause.

No other file is expected to need changes; `StoryRunEngine.swift` and its tests are already confirmed correct.

### Testing Standards Summary (AD-7)

- This devcontainer cannot render SwiftUI/UIKit — Task 1 (root-cause diagnosis) and Task 3 (post-fix verification) are both manual Simulator work, same constraint as Story 3.10.
- After Task 2's fix, `swiftc -parse EndingView.swift` for syntax verification, and `swift test` to reconfirm the engine-logic suite (89 tests / 6 suites as of Story 3.10) has no regression — this story's fix is Views-layer only and should not need any engine-logic test changes, but re-run the suite anyway per this codebase's existing convention.
- No new Swift Testing case is required or possible for the gesture-conflict fix itself (AD-7 scope is engine logic only, and there is no UI test target in this project).

## Previous Story Intelligence (Story 3.10)

Story 3.10 (Action Button Padding — AX5 & Compact-Height Verification) is the story during whose dev-story session this regression was discovered — see its Completion Notes for the exact user-reported observation. Story 3.10 itself made no change anywhere near `EndingView.swift` (its touched files were `HomeView.swift`/`TutorialView.swift`), so this story's regression is unrelated to Story 3.10's own work, not a Story 3.10 side-effect. Process pattern carried forward: Completion Notes should be itemized per task/check, dated, one line per confirmed item (project-context.md's "no generic all-good sentence" Process Agreement) — this story has three distinct manual-verification points (Task 1's root cause, Task 2's fix confirmation, Task 3's four-flavor sweep) and each should get its own dated entry, not one combined summary.

## Git Intelligence Summary

`EndingView.swift`'s last commit is `aea3e0d` ("Story 3.6 code review: safe-area scroll geometry fix, dedup, process guardrail"), predating Story 3.9 and 3.10 entirely. The `backSwipeGesture` addition (Story 3.3 Task 7, 2026-08-06) predates that. No commit in the intervening history reverted or altered the gesture-stacking structure described in this story's Background — meaning if the gesture-conflict hypothesis is correct, this bug has likely existed, unnoticed, since Story 3.3 Task 7 landed (2026-08-06), and no story since has manually exercised Ending's tap-to-advance path in Simulator until Story 3.10's session surfaced it incidentally.

## Project Context Reference

Full rules loaded from `_bmad-output/project-context.md` as a persistent fact for this workflow run — see especially: the Environment section (no SwiftUI/UIKit rendering in this devcontainer, so Task 1 and Task 3 are Simulator-only and cannot be locally verified beyond `swiftc -parse`), and the "no generic all-good sentence" Process Agreement governing how Completion Notes should be itemized.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
