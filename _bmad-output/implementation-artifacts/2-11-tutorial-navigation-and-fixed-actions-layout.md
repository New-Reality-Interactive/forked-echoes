---
baseline_commit: cdd803f
---

# Story 2.11: Tutorial Navigation & Fixed-Actions Layout

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want a single, obvious way back to Home from Tutorial, the "Start Story" button always reachable without scrolling, and no run-management controls on a screen where there's no run yet to manage,
so the screen isn't cluttered with two overlapping exits, an escape hatch for a run that may not exist, and I'm never stuck scrolling past the mechanics copy just to start the story.

*(UX design pass with Sally, 2026-08-02, prompted by user observation on this branch — see `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md` for the full discussion and rationale, including its 2026-08-02 addendum. Amends UX-DR10, UX-DR11, and Story 1.3/2.7's shipped ("done") implementations; those stories are left historically intact per the Story 2.6→2.9 precedent.)*

## Acceptance Criteria

1. **Given** the Tutorial screen as it ships today (Story 1.3/1.4)
   **When** this story lands
   **Then** the in-content "Back Home" button is removed; leaving Tutorial is via the standard `NavigationStack` back button (top-left nav bar) and its default edge-swipe gesture — no `.navigationBarBackButtonHidden` suppression, no replacement in-content exit control

2. **Given** the Tutorial screen's "Start Story" / "Resume Story" action
   **When** rendered in either portrait or landscape, and regardless of Dynamic Type category
   **Then** the button is pinned outside the scrollable region (fixed position, always visible without scrolling) — only the mechanic-explanation copy scrolls, using a restructure of the shared `GeometryReader`/`ScrollView` centering pattern (project-context.md's "Never use `Spacer()` inside this pattern" rule still applies to whatever internal layout replaces it)

3. **Given** `TutorialView.swift`'s `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` (added by Story 2.7 per UX-DR11)
   **When** this story lands
   **Then** the run-options button and its `onExitToHome`/`onRestartRun` closures are removed from `TutorialView.swift` entirely — Tutorial is a pre-run explainer screen, not a page within a run, and its "Exit to Home"/"Restart This Run" actions duplicated exits/state-mutation already covered by Tutorial's own back navigation and the fact that no run is guaranteed to exist yet (Story 2.7's own `onRestartRun` guard, `guard runProgress.hasInProgressRun else { return }`, was already a sign this control didn't fully fit the screen it was retrofitted onto)

4. **Given** this is a Tutorial-only change
   **When** implemented
   **Then** `HomeView.swift` and its `GeometryReader`/`ScrollView` centering pattern are untouched — Home is not in scope for this story; the run-options button's presence on Story/Choice pages (UX-DR11) is also untouched — only Tutorial loses it

5. **And** a manual-verification AC: in Xcode/Simulator, confirm (1) tapping the nav-bar back chevron and (2) an edge-swipe-back gesture both return to Home from Tutorial; (3) "Start Story"/"Resume Story" is reachable with zero scrolling in landscape at both default and an accessibility Dynamic Type size; (4) the mechanic-explanation text still scrolls independently when it overflows; (5) no run-options icon renders anywhere on Tutorial, regardless of `hasInProgressRun` state. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

## Tasks / Subtasks

- [x] Task 1: Remove the in-content "Back Home" button (AC #1)
  - [x] Delete the `Button { dismiss() } label: { Text("tutorial.action.backHome") ... }` block and its containing `VStack(spacing: Spacing.medium)` wrapper in `TutorialView.swift` (currently lines 53-69) — but see Task 3, this `VStack` also currently holds the "Start Story" button, which stays (just relocated per Task 2, not deleted)
  - [x] Remove the `"tutorial.action.backHome"` entry from `Resources/Localizable.xcstrings` (currently line 319 — `"Back Home"`, comment: "Tutorial screen: secondary action label, returns to Home")
  - [x] Repo-wide grep for `tutorial.action.backHome` and `backHome` after deleting, per project-context.md's Pre-Completion Self-Check — confirm zero remaining references in both `ForkedEchoes/` and `ForkedEchoesTests/` (only this story file and historical story/retro docs referencing the old key are expected to remain)
  - [x] Do **not** add `.navigationBarBackButtonHidden` or any replacement exit control — verified via repo-wide grep that no such modifier exists on `TutorialView` today (standard back chevron + edge-swipe already work for free, nothing to change here beyond removing the redundant in-content button)

- [x] Task 2: Restructure Tutorial's layout so "Start Story"/"Resume Story" is fixed outside the scrollable region (AC #2)
  - [x] Replace the current single `ScrollView` containing both the mechanics-copy `VStack` and the actions `VStack` (today: one `GeometryReader { ScrollView { VStack(spacing: .large) { textBlock; actionsBlock } .frame(maxWidth: .infinity, minHeight: proxy.size.height) } }`) with a structure where only the mechanics-copy text scrolls and the action button sits in a sibling position outside the `ScrollView`, always visible
  - [x] The `GeometryReader`/`ScrollView`/`minHeight: proxy.size.height` centering trick is still the right tool for centering the *text block alone* when it's short enough to fit — apply it only to that block, not to the action button
  - [x] **Do not use `Spacer()` anywhere in this restructure** — project-context.md documents this measured zero/`minLength` during layout inside this exact pattern and caused a real shipped bug (Story 1.3, "Start Story" unreachable in landscape). A `ScrollView` given flexible sizing as a sibling of a fixed-size button in an outer `VStack` does not have this problem — that's a different mechanism than a `Spacer` inside the ScrollView's own content, and is the direction to take
  - [x] One view hierarchy for both orientations — this is a geometry-only reflow (AD-8), never a `verticalSizeClass` branch and never a second `*LandscapeView` type. The button-outside-scroll structure must hold identically in portrait and landscape (sprint-change-proposal's decision record: "applies in both portrait and landscape, not landscape-only")
  - [x] Keep the existing `.frame(maxWidth: LayoutMetrics.readingColumnMaxWidthLandscape, alignment: .leading)` / `.frame(maxWidth: .infinity)` column-capping on the text block, and `.frame(maxWidth: LayoutMetrics.actionStackMaxWidth)` on the action button — both existing `LayoutMetrics` constants, don't introduce new literals (project-context.md's Design Tokens rule)
  - [x] The action stack was previously a `VStack(spacing: Spacing.medium)` holding two buttons; after Task 1/3 remove the other two, only one button (`primaryActionLabel`) remains here — simplify accordingly, don't leave a single-child `VStack` wrapper with no purpose

- [x] Task 3: Remove the run-options control from Tutorial (AC #3)
  - [x] Delete `.overlay(alignment: .topTrailing) { RunOptionsButton(onExitToHome:, onRestartRun:) }` from `TutorialView.swift` (currently lines 86-108), including both closures in full
  - [x] After deletion, `@Environment(StoryRunEngine.self) private var engine` (currently line 10) becomes fully unused in this file — remove it. Verify first: `engine` is referenced only inside the two closures being deleted (`engine.exitToHome()`, `engine.restartRun()`) — nothing else in `TutorialView.swift` touches it
  - [x] After Task 1 + this task both land, `@Environment(\.dismiss) private var dismiss` (currently line 4) also becomes fully unused — the "Back Home" button's `dismiss()` (Task 1) and the run-options `onExitToHome` closure's `dismiss()` (this task) were its only two call sites in this file. Remove it
  - [x] `@Environment(RunProgressObserver.self) private var runProgress` (line 22) **stays** — still needed for `primaryActionLabel`'s `hasInProgressRun` check and the `.onAppear { runProgress.refresh() }` call, neither of which this story touches
  - [x] Do not touch `RunOptionsButton.swift` itself or its use on Story/Choice pages (`StoryChoiceView.swift`) — Story/Choice retains the control exactly as Story 2.7 shipped it (AC #4); this task only removes Tutorial's retrofit of it

- [x] Task 4: Confirm Home is untouched (AC #4)
  - [x] `HomeView.swift` has no run-options control today (never had one — UX-DR11 was Story/Choice/Tutorial only, never Home) and its own `GeometryReader`/`ScrollView` pattern already centers two buttons with no scrolling-to-reach problem reported — leave the file untouched. Diff review before completion: `git diff --stat` should show zero changes to `Views/Home/HomeView.swift`

- [x] Task 5: Manual verification (AC #5)
  - [x] Request from user per project-context.md's Process Agreement (this devcontainer has no Xcode/Simulator) — the 5-point checklist in AC #5 is the exact list to hand off
  - [x] Record result + date in Completion Notes List once reported back

### Review Findings

- [x] [Review][Patch] `RootView.swift`'s NavigationStack-level `.environment(engine)` (line 68) and its accompanying comment are now stale — this story removed `TutorialView`'s only need for `StoryRunEngine` via environment, and `HomeView.swift` never consumed it either, so nothing under the `NavigationStack` reads it anymore (the `fullScreenCover`'s own explicit `.environment(engine)` at line 74 is the one that's actually load-bearing, per the 2026-08-02 bug comment already in that file). Removed the now-unnecessary `.environment(engine)` application at the `NavigationStack` level and its stale comment; the `fullScreenCover`'s own `.environment(engine)` (with its bug-explanation comment condensed) is retained as the sole, correct application. Verified via `swiftc -parse`. [ForkedEchoes/Views/RootView.swift:50-58]

## Dev Notes

### What already exists — do not re-create any of this

This is a narrowly-scoped, Tutorial-only UI story with **no engine-logic changes** — `StoryRunEngine`, `RunSnapshot`, and all of `ForkedEchoes/Engine/` are untouched. The only touched file is `ForkedEchoes/Views/Tutorial/TutorialView.swift`, plus `Resources/Localizable.xcstrings` (one key removed).

`ForkedEchoes/Views/Tutorial/TutorialView.swift` — current shape (127 lines), read in full before editing:
- Line 4: `@Environment(\.dismiss) private var dismiss` — becomes unused after Tasks 1+3, remove it (see Task 3)
- Line 10: `@Environment(StoryRunEngine.self) private var engine` — added by Story 2.7 solely for the `RunOptionsButton` closures; becomes unused after Task 3, remove it
- Line 15: `@Binding var isPresentingStorySession: Bool` — **keep**, this is the "Start Story"/"Resume Story" button's action (AD-5: Story session is a `.fullScreenCover` flipped by this binding, owned by `RootView`), untouched by this story
- Line 22: `@Environment(RunProgressObserver.self) private var runProgress` — **keep**, drives `primaryActionLabel` and the `.onAppear` refresh, both untouched
- Lines 24-83: the current `GeometryReader { ScrollView { VStack { textBlock; actionsBlock } } }` structure — this is what Task 2 restructures. The text block (lines 30-42, eyebrow + 3 `bodyStyle()` paragraphs) is unaffected in content, only in its containing layout. The actions block (lines 53-69) currently holds two buttons; Task 1 removes the "Back Home" one, leaving only "Start Story"/"Resume Story" (lines 62-68) to relocate per Task 2
- Lines 86-108: `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` — Task 3 deletes this whole block
- Line 109: `.correctColdLaunchOrientation()` — **keep unchanged**, unrelated to this story (Story 5.4's cold-launch fix, applies at the view root regardless of internal layout)
- Line 110: `.onAppear { runProgress.refresh() }` — **keep unchanged**
- Lines 114-126: `#Preview` — update if its structure no longer matches (e.g. it currently constructs `.environment(StoryRunEngine())` only because the removed `RunOptionsButton` overlay needed it; after Task 3, `StoryRunEngine` is no longer referenced anywhere in this file, so the `#Preview`'s `.environment(StoryRunEngine())` becomes dead weight — remove it too, and repo-grep to confirm nothing else in this file's preview needs it). This is exactly the kind of missed cleanup project-context.md's Pre-Completion Self-Check exists to catch (a prior incident: `StoryChoicePlaceholderView`'s own `#Preview` was the one call site missed during a Story 2.1 deletion)

`ForkedEchoes/Views/Home/HomeView.swift` — read for contrast only, **do not modify** (AC #4). It already demonstrates the "just the actions block, no run-options control, no Back-equivalent button" shape this story is converging Tutorial toward for the exit/run-options parts — but its `GeometryReader`/`ScrollView` centering pattern still keeps everything (title block + actions) inside one scrolled/centered group, which is intentionally *not* what Tutorial should do after this story (Home has no reported scroll-to-reach problem, per the sprint-change-proposal's "Screen scope: Tutorial only" decision).

`ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` — reuse existing constants, do not add new ones for this story: `LayoutMetrics.minTapTarget` (44pt tap targets), `LayoutMetrics.readingColumnMaxWidthLandscape` (680pt text column cap), `LayoutMetrics.actionStackMaxWidth` (320pt action-button cap, already shared with `HomeView.swift` — do not fork a Tutorial-only duplicate), `Spacing.large`/`Spacing.medium` (24pt/16pt).

`Resources/Localizable.xcstrings` — existing keys are alphabetically ordered (project-context.md's Localization rule). Deleting `tutorial.action.backHome` (currently between `home.storyTitle` and `runOptions.accessibilityLabel` alphabetically... actually between `home.storyTitle` and `tutorial.action.startStory` — it's the first `tutorial.*` key) needs no reordering of neighbors, just removal of its own JSON object. Confirmed via repo-wide grep (see Task 1) that `TutorialView.swift` is the only code reference; the catalog entry is the only other place it exists.

### Architecture compliance (AD-3, AD-5, AD-8)

- **AD-3**: `StoryRunEngine` remains the sole mutator of run state; this story removes a *View-layer* control that called into it (`RunOptionsButton`'s closures), it does not add any new engine interaction. No View-layer code will construct or mutate `RunSnapshot`/engine state directly.
- **AD-5**: the Story session is presented via `.fullScreenCover` (owned by `RootView`), flipped by `isPresentingStorySession` — untouched by this story. Tutorial's own navigation (`NavigationStack` push from Home, per `HomeDestination`) is the one place in the app that still uses stock push/pop, and after this story it's relied on more directly (as the *only* way to leave Tutorial) rather than less — confirm no code path anywhere adds `.navigationBarBackButtonHidden` to Tutorial's push destination, which would break AC #1.
- **AD-8**: landscape is a continuous reflow via `verticalSizeClass`, never a second view type. This story's fixed-action-button restructure is explicitly a **structural** layout change (per project-context.md's "Two different fixes for two different problems" callout — a stack becoming fixed-vs-scrolling is structural, not geometry-only) but per the sprint-change-proposal's decision record, it applies **identically in both orientations** (not a portrait/landscape branch) — so it still doesn't need a `verticalSizeClass` conditional, it's just a different one-hierarchy-for-both-orientations structure than before, same as AD-8 requires.

### Testing standards summary

- No engine-logic code is touched (AD-7 scope is `StoryRunEngine`/`RunSnapshot` and similar `Engine/` types) — this story adds **zero** Swift Testing cases. `swift test`'s existing suite (58/58 as of Story 2.10) should be unaffected; run it anyway to confirm nothing broke (SwiftPM's target only covers `Engine`/`Content`, not `Views/`, so a Tutorial-only change shouldn't touch its build at all, but the check is free and catches an unexpected miss).
- No UI test target exists in this project (project-context.md's Testing section) — SwiftUI layout/VoiceOver/Dynamic Type correctness for this story is verified manually in Simulator only (AC #5). Don't add a UI test as a side effect of this story.
- `swiftc -parse` on the edited `TutorialView.swift` for genuine syntax verification (this devcontainer has no Xcode/SwiftUI module resolution, so this is the only automated check available here for the View-layer edit itself).
- `python3 -m json.tool` on `Localizable.xcstrings` after editing, to confirm the catalog is still valid JSON post-deletion.

### Project Structure Notes

- Modified (expected, no new files): `ForkedEchoes/Views/Tutorial/TutorialView.swift`, `ForkedEchoes/Resources/Localizable.xcstrings`.
- Explicitly **not** modified: `ForkedEchoes/Views/Home/HomeView.swift` (AC #4), `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` (Story/Choice's copy of the control is unaffected — Tutorial only stops *using* it), any `Engine/` file, `ForkedEchoesTests/` (no new tests expected — see Testing standards above).
- No new files anticipated. `Package.swift` unaffected — this story touches no `Engine`/`Content` source.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.11: Tutorial Navigation & Fixed-Actions Layout]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR10] (amended 2026-08-02 — fixed "Start Story", standard iOS back nav, no in-content "Back Home")
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR11] (amended 2026-08-02 — narrowed to Story/Choice only, Tutorial's retrofit removed)
- [Source: _bmad-output/planning-artifacts/sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md] (full rationale, decision record, and the 2026-08-02 addendum removing the run-options control specifically)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md#Component Patterns — "Tutorial actions" and "Run options button" rows] (both amended 2026-08-02, matching the epics.md UX-DR changes above)
- [Source: _bmad-output/project-context.md#The `GeometryReader` + `ScrollView` centering pattern] (the `Spacer()` prohibition and why — Story 1.3's original landscape bug)
- [Source: _bmad-output/project-context.md#Navigation] (`NavigationStack` reserved for Home ↔ Tutorial only, AD-5)
- [Source: _bmad-output/project-context.md#Landscape / Orientation (AD-8)] (structural-vs-geometry-only distinction, `verticalSizeClass` rule)
- [Source: _bmad-output/project-context.md#Pre-Completion Self-Check] (repo-wide grep requirement for deleted symbols/keys — direct precedent: a missed `#Preview` reference broke a build in Story 2.1)
- [Source: ForkedEchoes/Views/Tutorial/TutorialView.swift] (current 127-line implementation, read in full before editing)
- [Source: ForkedEchoes/Views/Home/HomeView.swift] (contrast reference only — do not modify, AC #4)
- [Source: ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift] (the control being removed from Tutorial's overlay — file itself is not modified)
- [Source: ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift] (existing constants to reuse: `minTapTarget`, `readingColumnMaxWidthLandscape`, `actionStackMaxWidth`, `Spacing.large`/`Spacing.medium`)
- [Source: ForkedEchoes/Resources/Localizable.xcstrings] (`tutorial.action.backHome` entry, line 319, to be removed; alphabetical-order convention)
- [Source: _bmad-output/implementation-artifacts/2-10-persist-back-navigation-across-app-relaunch.md] (previous story in Epic 2 — no direct technical overlap, but confirms current process conventions: Completion Notes manual-verification format, Change Log structure, repo-wide grep discipline)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-5, AD-8]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swiftc -parse` on the edited `TutorialView.swift` — clean, no syntax errors.
- `python3 -m json.tool Localizable.xcstrings` — clean, valid JSON post-deletion.
- `swift test` from repo root — 60/60 passing (net +2 over the 58 baseline noted in Story 2.10's Dev Notes, from other work already merged to `main`; nothing added or removed by this story since it touches no `Engine`/`Content` code).
- Repo-wide `grep -rn "tutorial.action.backHome\|backHome"` across `ForkedEchoes/` and `ForkedEchoesTests/` — zero hits.
- Repo-wide `grep -n "RunOptionsButton"` across `Views/` — confirms only `RunOptionsButton.swift` itself and `StoryChoiceView.swift` still reference it; `TutorialView.swift` no longer does.
- `git diff --stat -- ForkedEchoes/Views/Home/HomeView.swift ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` — empty, confirming both are untouched (AC #4 / Task 3's "do not touch `RunOptionsButton.swift`").

### Completion Notes List

- Task 1: deleted the in-content "Back Home" button and its `VStack(spacing: Spacing.medium)` wrapper, and removed the `tutorial.action.backHome` catalog entry from `Localizable.xcstrings`. No `.navigationBarBackButtonHidden` exists anywhere on `TutorialView` — confirmed via grep before and after — so the standard nav-bar back chevron and edge-swipe gesture are unaffected and now the only way to leave Tutorial.
- Task 2: restructured `TutorialView.body` from a single `GeometryReader { ScrollView { textBlock; actionsBlock } }` into an outer `VStack(spacing: .large) { GeometryReader { ScrollView { textBlock } }; actionButton }`. The `GeometryReader`/`ScrollView`/`minHeight: proxy.size.height` centering trick now applies to the text block alone (still capped at `LayoutMetrics.readingColumnMaxWidthLandscape`); the action button is a sibling outside the `ScrollView`, capped at `LayoutMetrics.actionStackMaxWidth`, and always visible without scrolling. No `Spacer()` introduced anywhere. Single view hierarchy, no `verticalSizeClass` branch — holds identically in portrait and landscape per AD-8. The two-button action `VStack` collapsed to a single `Button` once "Back Home" (Task 1) was gone, so the now-single-child wrapper `VStack` was removed rather than left as dead wrapping.
- Task 3: deleted the `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` block and both its closures in full. `@Environment(StoryRunEngine.self) private var engine` was referenced only inside those closures, so it was removed. `@Environment(\.dismiss) private var dismiss` lost its only two call sites (the "Back Home" button in Task 1, and `onExitToHome`'s `dismiss()` here) and was removed too. `@Environment(RunProgressObserver.self) private var runProgress` was left untouched — still drives `primaryActionLabel` and the `.onAppear` refresh. `RunOptionsButton.swift` itself and its use on `StoryChoiceView.swift` were not modified.
- Task 4: `HomeView.swift` was not opened for editing; `git diff --stat` confirms zero changes to it.
- Task 5: manual verification requested from user — this devcontainer has no Xcode/Simulator, so the 5-point AC #5 checklist was handed off for a real Simulator check. Result, 2026-08-04: build and `swift test` both passed in Xcode, and all 5 AC #5 checks passed in Simulator (nav-bar back chevron, edge-swipe-back, "Start Story"/"Resume Story" reachable with zero scrolling in landscape at default and an accessibility Dynamic Type size, mechanics text still scrolls independently when it overflows, no run-options icon renders anywhere on Tutorial) — confirmed by user.
- Pre-Completion Self-Check run against project-context.md's list: no `tracking()`/letter-spacing, no transparent-background button needing `.contentShape`, no custom `ButtonStyle` touched, the one ternary-selected `LocalizedStringKey` (`primaryActionLabel`) already carries its explicit type annotation (untouched by this story), and `Font.system(size:)`/`.lineLimit()`/`.fixedSize()` grep across the edited file returns nothing new.

### File List

- Modified: `ForkedEchoes/Views/Tutorial/TutorialView.swift`
- Modified: `ForkedEchoes/Resources/Localizable.xcstrings`

## Change Log

- 2026-08-03: Story 2.11 created via create-story workflow, on branch to be named at dev-story time. Scoped to `TutorialView.swift` only (plus one `Localizable.xcstrings` key removal): drop the in-content "Back Home" button in favor of standard iOS back navigation, restructure the layout so "Start Story"/"Resume Story" is fixed outside the scrollable mechanics-copy region, and remove the Story 2.7 `RunOptionsButton` retrofit entirely (including the `dismiss`/`engine` environment values that become unused once both its call sites are gone). No engine-logic changes; Home is explicitly out of scope.
- 2026-08-03: Implemented via dev-story on branch `2-11-tutorial-navigation-and-fixed-actions-layout`. Tasks 1-4 complete: "Back Home" button and its localization key removed; layout restructured with the action button as a fixed sibling of the mechanics-copy `ScrollView`; `RunOptionsButton` overlay and its now-unused `engine`/`dismiss` environment values removed; Home and `RunOptionsButton.swift` confirmed untouched. `swift test` 60/60 passing, no regressions. Task 5 (manual Simulator verification) requested from user; status set to review pending that result.
- 2026-08-04: Task 5 complete — user confirmed build/`swift test` passed in Xcode and all 5 AC #5 manual-verification points passed in Simulator. All tasks now complete.
- 2026-08-04: Code review complete (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Acceptance Auditor found zero AC violations. 1 patch applied: `RootView.swift`'s stale NavigationStack-level `.environment(engine)` (left over from Story 2.7's Tutorial retrofit, now unread by anything) removed, verified via `swiftc -parse`. 11 other findings reviewed and dismissed (spec-intended behavior, verified non-issues, or process commentary out of code-review scope). Status set to done.
