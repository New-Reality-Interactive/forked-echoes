---
baseline_commit: c66a534ff78e8e52804b20f307e0b415afc4fa1d
---

# Story 3.7: Run-Progress Refresh-on-Dismiss — Test Coverage & Consolidation Audit

Status: done

## Story

As a developer,
I want Home/Tutorial's "Resume Story" vs. "Start Story" label refresh logic covered by an automated test, with its two current triggers either justified as genuinely distinct or consolidated,
so that future screens don't have to rediscover this wiring's fragility from scratch, and a future regression is caught by a test instead of manual Simulator inspection.

## Acceptance Criteria

1. **Given** `RootView.swift`'s `.onChange(of: isPresentingStorySession)` refresh and `HomeView.swift`/`TutorialView.swift`'s own `.onAppear` refresh, **when** both are audited together against this project's supported iOS range's actual dismissal/navigation-appear semantics, **then** the audit's conclusion (both genuinely necessary for distinct events, or one subsumes the other) is documented in this story's Dev Notes. [Source: epics.md#Story-3.7, AC1]
2. **Given** the audit's conclusion, **when** implemented, **then** any now-redundant refresh call site is removed — but only if the audit confirms redundancy; two triggers for two genuinely distinct navigation events is not itself a defect. [Source: epics.md#Story-3.7, AC2]
3. **Given** `RunProgressObserver.refresh()`, **when** this story completes, **then** an automated Swift Testing case asserts a `RunSnapshot` write occurring after the observer's construction becomes visible once `refresh()` is called explicitly — closing the "no test asserting the wiring" gap the Story 2.7 code review flagged. [Source: epics.md#Story-3.7, AC3 — AD-7]
4. **And** a manual-verification AC: in Xcode/Simulator, confirm the Home "Start Story"/"Resume Story" label updates correctly after (a) exiting a run to Home via the run-options sheet, (b) completing a run through Memory's "Return Home", and (c) navigating Home → Tutorial → back — no stale label in any path. Result + date recorded in the story's Completion Notes List. [Source: epics.md#Story-3.7, AC4 — project-context.md Process Agreement]

## Background: Why This Story Exists

Added via deferred-work review, 2026-08-06 — see `deferred-work.md`'s "code review of 2-7-run-options-action-sheet" entry. That entry originally implied a live bug: "`RootView`'s 'Exit to Home' refresh relies on an implicit `.onChange(of: isPresentingStorySession)` refresh path with no test asserting the wiring." On inspection during this deferred-work review, `RootView.swift` already carries a deliberate, well-commented fix (`.onChange(of: isPresentingStorySession)`, added post-Story-2.7) alongside `HomeView.swift`/`TutorialView.swift`'s own `.onAppear { runProgress.refresh() }` — **each covers a different navigation trigger** (Story-session dismissal vs. Home↔Tutorial `NavigationStack` push/pop), so this is **not a live bug** as the original deferred note implied. What's actually missing is automated coverage of the refresh mechanism and a documented rationale for why both call sites exist — not a broken mechanism needing a fix.

Sequenced after Story 3.5 since it's Home/Tutorial infra debt, not part of Epic 3's Ending/Memory/accessibility scope — added per user decision 2026-08-06 to close out Epic 2-era deferred items now rather than reopen the closed epic.

## ⚠️ Critical Context: Both the Audit and the Test May Already Be Done — Read Before Coding

This story's two "hard" ACs (#1's audit and #3's test) have almost certainly already been satisfied by prior work. Your job is largely to **verify and document that**, not to redo it from scratch — read this section fully before touching code.

### AC #1/#2 — the audit conclusion is already written down in the code you're auditing

`RootView.swift`'s own comments (lines ~63-80, code review dated 2026-08-01) already state the reasoning explicitly:

> "HomeView/TutorialView's own `.onAppear` refresh does NOT reliably fire when this fullScreenCover dismisses back to them (confirmed: it does fire on NavigationStack push/pop between Home and Tutorial, but not on cover dismissal) ... RootView owns `isPresentingStorySession` directly and knows the exact moment the session ends, so this is the deterministic fix: refresh whenever it flips to false, regardless of which button/path caused the dismissal."

So the two triggers cover two disjoint event classes:

| Trigger | Fires on | Does NOT fire on |
|---|---|---|
| `RootView.swift`'s `.onChange(of: isPresentingStorySession)` (only refreshes on the `false` transition) | `.fullScreenCover` dismissal (Story session ending via Memory's "Return Home"/"Start New Run", or the run-options sheet's "Exit to Home"/"Exit and Clear Progress") | Home↔Tutorial `NavigationStack` push/pop |
| `HomeView.swift`/`TutorialView.swift`'s `.onAppear { runProgress.refresh() }` | Home↔Tutorial `NavigationStack` push/pop | `.fullScreenCover` dismissal (confirmed by the same 2026-08-01 Simulator testing that produced the `RootView` fix) |

**This is genuinely two distinct navigation-event classes, not one mechanism duplicated** — SwiftUI's `.fullScreenCover` dismissal and a `NavigationStack` destination's `.onAppear` are unrelated lifecycle events in this app's navigation model (AD-5: the Story session is a modal presentation, never a `NavigationStack` push). Your Task 1 is to re-confirm this reasoning holds (read both files, trace the actual call sites, don't just take the comment's word for it — the comment could itself be stale) and transcribe the confirmed conclusion into this story's Dev Notes/Completion Notes in your own words. **Expect AC #2 to be a no-op** (no removal) unless your re-audit finds the existing comment's claim doesn't hold up — if you do find a genuine subsumption, that's a real and reportable finding, not something to force to match this expectation.

### AC #3 — a Swift Testing case matching this exact description already exists

`ForkedEchoesTests/RunSnapshotPresenceTests.swift` already contains `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` (added in Story 2.4's code review, commit `3a07a1a`, predating this story):

```swift
@Test func observerRefreshPicksUpASnapshotWrittenAfterConstruction() {
    let (defaults, suiteName) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let observer = RunProgressObserver(defaults: defaults)
    #expect(observer.hasInProgressRun == false)

    let snapshot = RunSnapshot(currentNodeId: .firstChoice, choiceHistory: [], alignmentScore: 0, tutorialSeen: false)
    defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)
    observer.refresh()

    #expect(observer.hasInProgressRun == true)
}
```

This is word-for-word what AC #3 asks for: "a `RunSnapshot` write occurring after the observer's construction becomes visible once `refresh()` is called explicitly." **Do not write a duplicate test.** Your Task 3 is to confirm this test still exists, still passes, and still genuinely covers AC #3's claim (re-read it critically — don't just trust the name) — and if so, credit it explicitly in this story's Dev Notes/Completion Notes as satisfying AC #3, rather than silently skipping the AC or adding a redundant near-identical case. If you judge it insufficient (e.g., it doesn't cover something AC #3 implies), say exactly what's missing and add only that gap, not a parallel test.

`deferred-work.md` line 81 already independently confirms this: `"[RESOLVED — Story 2.4 + Story 3.7, 2026-08-06] ~~hasInProgressRun isn't reactively tied to future snapshot writes~~ — Story 2.4 shipped the real @Observable RunProgressObserver/refresh() wiring; Story 3.7 (Run-Progress Refresh-on-Dismiss) now formalizes and test-covers exactly when refresh() is called."`

## Tasks / Subtasks

- [x] Task 1: Re-audit both refresh triggers and document the conclusion (AC: #1)
  - [x] Read `RootView.swift`'s `.onChange(of: isPresentingStorySession)` block (body's tail, ~lines 63-81) and its surrounding comments in full.
  - [x] Read `HomeView.swift` and `TutorialView.swift`'s `.onAppear { runProgress.refresh() }` call sites and their surrounding comments in full.
  - [x] Trace every path that can dismiss the Story session (`StoryChoiceView`'s run-options sheet "Exit to Home"/"Exit and Clear Progress", Memory's "Return Home"/"Start New Run") and confirm each flips `isPresentingStorySession` to `false`, which is what `RootView`'s `.onChange` keys on.
  - [x] Trace the Home↔Tutorial `NavigationLink`/pop path (`HomeDestination.tutorial`, `RootView`'s `NavigationStack`) and confirm it triggers `.onAppear` on the view being navigated to, independent of `isPresentingStorySession`.
  - [x] Write the confirmed conclusion into this story's Dev Notes (below) and Completion Notes: state plainly whether the two triggers are genuinely distinct (expected outcome per "Critical Context" above) or whether one subsumes the other.

- [x] Task 2: Act on the audit conclusion (AC: #2)
  - [x] If Task 1 confirms both triggers are genuinely necessary for distinct events (the expected outcome), make no code change — record that explicitly in Completion Notes rather than silently doing nothing.
  - [ ] If Task 1 finds genuine redundancy, remove only the subsumed call site and document why in Completion Notes/Change Log.

- [x] Task 3: Confirm (or close the gap in) Swift Testing coverage for `RunProgressObserver.refresh()` (AC: #3)
  - [x] Re-read `ForkedEchoesTests/RunSnapshotPresenceTests.swift`'s existing `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` test critically against AC #3's exact wording.
  - [x] Run `swift test` and confirm this test (and the full suite) passes.
  - [x] If it fully satisfies AC #3 (expected outcome), document that explicitly in Dev Notes/Completion Notes — do not add a duplicate test.
  - [ ] If a genuine gap exists (e.g., AC #3 implies something this test doesn't actually assert), add the minimal test needed to close only that gap, following this file's existing `freshDefaults()`/`.serializesUserDefaultsAccess` conventions (see `TestSupport.swift`).

- [x] Task 4: Manual Xcode/Simulator verification (AC: #4) — record results in Completion Notes (project-context.md Process Agreement: actively request this, report inline when it happens)
  - [x] (a) Start a run from Home, exit to Home via the run-options sheet mid-run — confirm Home's label reads "Resume Story" immediately on return (no stale "Start Story").
  - [x] (b) Complete a run through to Memory, tap "Return Home" — confirm Home's label reads "Start Story" immediately on return (no stale "Resume Story" from the just-finished run).
  - [x] (c) With a run in progress (or not), navigate Home → Tutorial → back to Home — confirm Tutorial's own label reflects `hasInProgressRun` correctly on arrival, and Home's label is still correct on return (this exercises the `.onAppear` trigger specifically, independent of the Story session).
  - [x] Record the date and a one-line result for each of (a)/(b)/(c) in Completion Notes.

## Dev Notes

### Audit conclusion (Task 1/AC #1, re-confirmed 2026-08-08)

Re-traced both triggers end to end, not just the existing code comments:

- **`RootView.swift`'s `.onChange(of: isPresentingStorySession)`** fires only on the `true → false` transition and calls `runProgress.refresh()`. Every dismissal path of the Story session (`.fullScreenCover`) ultimately flips `isPresentingStorySession` to `false` via the `onExitToHome` closure chain: `RunOptionsButton`'s "Exit to Home" and "Exit and Clear Progress" (`StoryChoiceView.swift:187-197`, calling `engine.exitToHome()`/`engine.exitAndClearProgress()` then `onExitToHome()`) and `MemoryView`'s "Return Home" button (`MemoryView.swift:113-116`, `engine.exitToHome()` then `onExitToHome()`) all route through the same closure RootView passed into `StoryChoiceView` (`RootView.swift:52-55`: `navigationPath = NavigationPath(); isPresentingStorySession = false`). Memory's "Start New Run" button (`MemoryView.swift:125-127`) deliberately does **not** call `onExitToHome()` — it stays inside the same `.fullScreenCover` session (`engine.startNewRun()` alone re-derives `engine.phase` back to `.reading`), so it correctly does not trigger this refresh path; there is nothing for it to refresh since the session never dismisses.
- **`HomeView.swift`/`TutorialView.swift`'s `.onAppear { runProgress.refresh() }`** fires when either view appears under `RootView`'s single `NavigationStack` — concretely, Home's `NavigationLink(value: HomeDestination.tutorial)` push and the system back-swipe/back-button pop between them (`RootView.swift:41-48`, `.navigationDestination(for: HomeDestination.self)`). This is a completely separate SwiftUI lifecycle event from `.fullScreenCover` presentation/dismissal (AD-5: the Story session was deliberately pulled out of `NavigationStack` in Story 2.2 specifically because it conflicts with `interactivePopGestureRecognizer`; see project-context.md's Navigation section) — a full-screen cover dismissing does not re-fire `.onAppear` on the presenting view underneath it, only `.onChange` on state it owns directly.

**Conclusion: the two triggers are genuinely necessary for two disjoint event classes (modal dismissal vs. NavigationStack push/pop), confirming the existing `RootView.swift` code comment's claim rather than finding it stale.** No redundancy exists — AC #2 is a no-op, no call site removed.

### Test coverage conclusion (Task 3/AC #3, re-confirmed 2026-08-08)

`ForkedEchoesTests/RunSnapshotPresenceTests.swift`'s `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` (added Story 2.4 code review, predates this story) asserts exactly what AC #3 asks for: constructs a `RunProgressObserver`, confirms `hasInProgressRun == false`, writes a valid `RunSnapshot` directly to the same `UserDefaults` suite, calls `observer.refresh()`, and confirms `hasInProgressRun` flips to `true` — i.e., a snapshot write occurring strictly after construction becomes visible only once `refresh()` is called. Ran `swift test` (full suite, 89/89 passed) and `swift test --filter observerRefreshPicksUpASnapshotWrittenAfterConstruction` (1/1 passed) on 2026-08-08 to confirm it still exists and is still green. This fully satisfies AC #3 — no new test added, no gap found.

### This is an audit-and-test story, not a feature story

No new engine logic and (expected) no new view logic — Tasks 1-2 are read/confirm/document, Task 3 is expected to confirm existing coverage rather than add much, Task 4 is the load-bearing verification. If Task 1 or Task 3 surfaces a real gap (redundant trigger, or a genuine hole in test coverage), fix exactly that gap — do not expand scope beyond what the audit actually finds.

### Swift Testing scope (AD-7)

Engine-logic-adjacent: `RunProgressObserver` lives in `ForkedEchoes/Engine/RunSnapshotPresence.swift`, which is exactly the kind of code AD-7 scopes Swift Testing coverage to (already covered by `ForkedEchoesTests/RunSnapshotPresenceTests.swift`, which runs for real under `swift test` in this devcontainer — see project-context.md Environment section). No UI/view-layer test is expected or wanted here; this project has no UI test target and no UI-test pattern (project-context.md Testing section) — the `.onAppear`/`.onChange` wiring itself is exercised only via Task 4's manual Simulator pass, consistent with every other SwiftUI view-correctness check in this project.

### Architecture citations

- **AD-3** (`StoryRunEngine` sole mutator of run state; `RunProgressObserver`/`engine` both single shared instances injected via `@Environment`, same DRY pattern): unaffected — this story doesn't touch engine intents, only confirms/tests the existing observer-refresh wiring.
- **AD-5** (Story session is a `.fullScreenCover` modal, never a `NavigationStack` push; `NavigationStack` is reserved for Home↔Tutorial only): this is the architectural reason the two refresh triggers are genuinely distinct — a modal dismissal and a stack push/pop are different SwiftUI lifecycle events by construction, not two code paths that happen to overlap.
- **AD-7** (Swift Testing scoped to engine logic): `RunProgressObserver` qualifies; see Swift Testing scope above.

### Project Structure Notes

Files expected to be read/audited (Task 1), likely unchanged (Task 2's expected no-op outcome):
- `ForkedEchoes/Views/RootView.swift` — `.onChange(of: isPresentingStorySession)` block.
- `ForkedEchoes/Views/Home/HomeView.swift` — `.onAppear { runProgress.refresh() }`.
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` — `.onAppear { runProgress.refresh() }`.
- `ForkedEchoes/Engine/RunSnapshotPresence.swift` — `RunProgressObserver` definition, no change anticipated.

Files expected to be read/confirmed (Task 3), likely unchanged given the existing test already matches AC #3:
- `ForkedEchoesTests/RunSnapshotPresenceTests.swift` — confirm `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` still exists and passes.
- `ForkedEchoesTests/TestSupport.swift` — reuse `freshDefaults()`/`.serializesUserDefaultsAccess` if any new test is genuinely needed; do not invent a parallel helper.

If Task 1's re-audit finds a genuine redundancy (contrary to the expected outcome), the removal is confined to whichever of `RootView.swift`'s `.onChange` or `HomeView.swift`/`TutorialView.swift`'s `.onAppear` is subsumed — do not touch `RunProgressObserver` itself in that case, its `refresh()` contract is correct either way.

### Testing Standards Summary

- `swift test` from repo root — this is the actual verification for AC #3; confirm the existing suite (last known count: 89/89 as of Story 3.6) still passes, and specifically that `RunSnapshotPresenceTests.observerRefreshPicksUpASnapshotWrittenAfterConstruction` is present and green.
- `swiftc -parse` on any `.swift` file you do end up touching, for syntax verification (no Xcode/UIKit in this devcontainer — project-context.md Environment section).
- Task 4's manual Xcode/Simulator pass is required, not optional, and is this story's primary verification mechanism for the view-layer behavior — actively request it from the user rather than noting it as unverified (project-context.md Process Agreement).
- Per project-context.md's process rule (added after Story 3.4's code review): if any code review after Task 4's verification patches `.swift` code, do not advance status to `done` on the strength of the pre-patch verification — leave at `review` and re-request Task 4's specific checks.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- 2026-08-08: Task 1/AC #1 — re-audited both refresh triggers by tracing actual call sites (not just trusting existing code comments): `RootView.swift`'s `.onChange(of: isPresentingStorySession)` covers `.fullScreenCover` dismissal (all paths: `RunOptionsButton`'s Exit to Home/Exit and Clear Progress, `MemoryView`'s Return Home — all route through the same `onExitToHome` closure chain into `RootView.swift:52-55`); `HomeView`/`TutorialView`'s `.onAppear` covers Home↔Tutorial `NavigationStack` push/pop only. Confirmed genuinely distinct, disjoint event classes — see Dev Notes "Audit conclusion" above for the full trace.
- 2026-08-08: Task 2/AC #2 — no redundancy found; no code change made, per the expected outcome. Both call sites are load-bearing and stay as-is.
- 2026-08-08: Task 3/AC #3 — confirmed `RunSnapshotPresenceTests.swift`'s existing `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` (Story 2.4 code review) fully satisfies AC #3's exact wording. Ran `swift test` (89/89 passed) and a filtered run of just this test (1/1 passed) on 2026-08-08. No new test added — none needed.
- 2026-08-08: Task 4/AC #4 — user ran manual Xcode/Simulator verification, all three checks passed: (a) exit-to-Home mid-run via run-options sheet showed "Resume Story" immediately, no staleness; (b) completing a run through Memory and tapping "Return Home" showed "Start Story" immediately, no staleness; (c) Home → Tutorial → back to Home showed correct labels on both Tutorial's arrival and Home's return. No issues found.

### File List

No files changed — this story's audit (Task 1/2) confirmed the existing `RootView.swift`/`HomeView.swift`/`TutorialView.swift` wiring is correct as-is, and its test-coverage check (Task 3) confirmed `ForkedEchoesTests/RunSnapshotPresenceTests.swift`'s existing test already satisfies AC #3. Only this story file itself was edited.
