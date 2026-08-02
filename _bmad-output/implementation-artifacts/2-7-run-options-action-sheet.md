---
baseline_commit: efaafda
---

# Story 2.7: Run Options Action Sheet

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player mid-run,
I want to exit to Home or restart my run from a run-options control,
so that I have an escape hatch without losing progress unintentionally.

## Acceptance Criteria

1. **Given** a Story/Choice or Tutorial page (`StoryChoiceView`, `TutorialView`)
   **When** rendered
   **Then** a run-options `ellipsis.circle` SF Symbol icon appears top-right of the reading/content area (UX-DR11, `DESIGN.md.components.run-options-button`) — absent from Home and from the branch-arrival interstitial (`StoryChoiceView`'s existing `phase == .interstitial` branch, unchanged by this story). This is the first time Tutorial gets this control — Story 1.3 shipped Tutorial without one, and this story explicitly retrofits it (epics.md's own note on this AC).

2. **Given** the run-options icon is activated
   **When** tapped
   **Then** a native `.confirmationDialog` (the modern, non-deprecated replacement for `ActionSheet` — still renders as an action sheet on iPhone) presents exactly three options, in this order: "Exit to Home", "Restart This Run" (destructive-styled via `role: .destructive`, which also gives it native red styling for free — no custom color), "Cancel" (`role: .cancel`).

3. **Given** "Exit to Home" is selected
   **When** activated
   **Then** `engine.exitToHome()` is called and the app returns to Home; the in-progress `RunSnapshot` is left completely untouched (non-destructive) — see Dev Notes for why `exitToHome()` is a real, intentionally-empty engine method rather than a bare view-layer action.

4. **Given** "Restart This Run" is selected
   **When** activated
   **Then** a second, explicit `.confirmationDialog` confirmation is presented before anything clears — selecting "Cancel" on either dialog leaves the run completely untouched. Only confirming the second dialog calls `engine.restartRun()`, which resets `currentNodeId` to `StoryTree.root`, clears `choiceHistory`/`alignmentScore`/the back-navigation stack/the dismissed-arrival-node set, and **immediately persists the reset state** (AD-4) — see Dev Notes for why this must persist immediately rather than waiting for the next mutating intent, unlike the existing `startFreshRunIfCurrentRunHasEnded()`. The player stays on the current screen; restarting does not navigate to Home.

5. **Given** the run-options button
   **When** inspected with VoiceOver
   **Then** it carries an explicit `accessibilityLabel` of "Run options" (UX-DR12), not the SF Symbol's default name.

6. **Given** the run-options control's labels ("Exit to Home", "Restart This Run", "Cancel", plus the second confirmation's explanatory text)
   **When** rendered
   **Then** every label is sourced from `Localizable.xcstrings` via a stable dot-path key, never hardcoded (AD-2).

7. **And** a Swift Testing case verifies `StoryRunEngine`'s two new intent methods directly (AD-7, AD-3's fixed intent-surface list): `exitToHome()` mutates no engine state and leaves an existing persisted `RunSnapshot` byte-for-byte in place; `restartRun()` called mid-run (after at least one choice/page advance) resets `currentNodeId`/`choiceHistory`/`alignmentScore` to their fresh-run values, makes a subsequent `goBack()` a no-op (back-navigation stack cleared), clears any dismissed-arrival-node state (mirroring Story 2.9's `visitedArrivalNodeIds` reset), and — the regression this AC exists to pin down — **immediately overwrites the on-disk `RunSnapshot`**, so a freshly-constructed engine built via `resumingFromSnapshot(defaults:)` right after `restartRun()` (simulating a force-quit before any further action) resumes at `StoryTree.root` with empty history, not the pre-restart mid-run state.

8. **Given** this story adds a new interactive control this devcontainer cannot render, screenshot, or Simulator-test — including a genuinely new SwiftUI-environment-propagation change (Task 6) that fails at runtime, not compile time, if wrong
   **When** implementation is complete
   **Then** the user is asked to confirm in Xcode/Simulator: the ellipsis icon appears top-right on both a Story/Choice page and the Tutorial page; tapping it opens the three-option sheet in the correct order with correct labels; "Exit to Home" returns to Home and "Resume Story" (not "Start Story") is offered afterward, proving the snapshot survived; re-entering the run continues exactly where it left off; "Restart This Run" requires a second confirmation, "Cancel" on either dialog changes nothing, and confirming resets the run in place (still on the Story session, now showing the intro page) with the alignment score cleared; performing the same Restart flow from the Tutorial page also works and does not crash (this is the environment-propagation risk — a missing `@Environment(StoryRunEngine.self)` object is a hard runtime crash); VoiceOver announces "Run options" for the icon, not a generic name; rotating the device mid-sheet doesn't break anything. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement).

## Tasks / Subtasks

- [x] Task 1: Add `exitToHome()` and `restartRun()` intent methods to `StoryRunEngine` (AC #3, #4, #7)
  - [x] Add `func exitToHome() {}` (with a doc comment, not a bare stub) directly after `goBack()` in `ForkedEchoes/Engine/StoryRunEngine.swift`. Nothing needs to mutate: `RunSnapshot` already reflects current state synchronously (AD-4 — every prior mutating intent already persisted it), and leaving for Home changes neither `currentNodeId` nor any other engine field. This method exists purely so "Exit to Home" routes through the engine's fixed intent surface (AD-3's explicit list names `exitToHome()`) instead of being the one user action in this app that bypasses it entirely — document this reasoning in the doc comment so a future reader doesn't "clean up" an apparently-pointless empty method. The actual Home navigation stays a View-layer concern: `StoryChoiceView`'s existing `onExitToHome: () -> Void` closure parameter (RootView-injected, resets both the `fullScreenCover` and the `NavigationStack` path together) and `TutorialView`'s existing `@Environment(\.dismiss)` — the engine has no navigation state to own (AD-5).
  - [x] Add `func restartRun()`: resets `currentNodeId = StoryTree.root`, `choiceHistory = []`, `alignmentScore = 0`, the back-navigation stack (`visitedNodeIds`), and `dismissedInterstitialNodeIds`, then calls `persistOrClearSnapshot()` explicitly at the end. **This last call is the one deliberate behavioral difference from the existing `startFreshRunIfCurrentRunHasEnded()`, which does NOT call it** — read that method's own doc comment (line ~212) before writing this one: `startFreshRunIfCurrentRunHasEnded()` only ever fires once the current node has already reached `.ending`, which already cleared any snapshot (nothing stale to overwrite), and the freshly-reset run isn't persisted until its own first real mutating intent completes anyway. `restartRun()` is different: it fires **mid-run**, when a real `RunSnapshot` of the *old*, about-to-be-discarded run is already sitting on disk. Skipping the persist call here would leave that stale snapshot in place — force-quitting the app immediately after confirming "Restart This Run" (before any further page turn) would then resurrect the pre-restart run on relaunch instead of the fresh one the player just confirmed. AC #7's regression test exists specifically to pin this down.
  - [x] DRY refactor (this codebase's established convention — e.g. `Self.option(withId:in:)`'s shared-lookup precedent, Story 2.4/2.9's reset-state precedents): factor the five reset assignments (`currentNodeId`, `choiceHistory`, `alignmentScore`, `visitedNodeIds`, `dismissedInterstitialNodeIds`) shared between `startFreshRunIfCurrentRunHasEnded()` and `restartRun()` into one small private helper (e.g. `resetRunState()`), called by both; only the guard condition and whether `persistOrClearSnapshot()` follows differ between the two call sites.

- [x] Task 2: Swift Testing coverage for both new engine methods (AC #7)
  - [x] Extend `ForkedEchoesTests/StoryRunEngineTests.swift` (existing scope — these are `StoryRunEngine` intent-method additions, not a new type, same precedent as every prior Epic 2 story's engine tests).
  - [x] `exitToHome()`: a test that calls it after at least one prior mutating intent (so a real `RunSnapshot` already exists in a `freshDefaults()` suite) and asserts `currentNodeId`/`choiceHistory`/`alignmentScore` are all unchanged, AND that `RunSnapshot.loadValid(from:)` still decodes to the exact same values afterward (proving `exitToHome()` didn't touch the persisted snapshot at all, not just the in-memory engine).
  - [x] `restartRun()`: a test that drives the engine mid-run (at least one `selectChoice(_:)`/`advancePage()` past root), calls `restartRun()`, and asserts `currentNodeId == StoryTree.root`, `choiceHistory.isEmpty`, `alignmentScore == 0`, and that a subsequent `goBack()` is a no-op (mirrors `startFreshRunIfCurrentRunHasEndedResetsAFinishedRunToRoot`'s existing assertion shape).
  - [x] `restartRun()` + arrival state: drive the engine through `.shoreArrival` and dismiss it (so `dismissedInterstitialNodeIds`/the persisted `visitedArrivalNodeIds` is non-empty), call `restartRun()`, and assert a fresh run's own first visit to `.shoreArrival` re-gates (`engine.phase == .interstitial`) — mirrors Story 2.9's `startingAFreshRunAfterEndingClearsPersistedArrivalVisitationOnNextSnapshotWrite`, but triggered mid-run via `restartRun()` instead of via `.ending` + `startFreshRunIfCurrentRunHasEnded()`.
  - [x] **The regression test AC #7 exists for**: mid-run, call `restartRun()`, then — WITHOUT any further engine call on that instance — construct a **second, independent** `StoryRunEngine` via `resumingFromSnapshot(defaults:)` on the same `UserDefaults` suite (simulating a force-quit immediately after confirming Restart) and assert it resumes at `StoryTree.root` with empty `choiceHistory`, not the pre-restart node/history. This is the test that would fail if Task 1's `persistOrClearSnapshot()` call were accidentally omitted.
  - [x] Run `swift test` from repo root; current baseline is 49/49 (confirmed at story-creation time) — report the new total. Note: a pre-existing, documented flake (`anEngineResumedOntoTheEchoNodeReportsIsEchoActiveImmediately` under full-suite parallel execution, a Linux `UserDefaults(suiteName:)` isolation quirk, not a regression) may still appear under `swift test`'s default parallel mode — `swift test --no-parallel` passes reliably; use it to confirm a genuine 100% pass rate if the parallel run shows any failure, same as Story 2.9's own verification note.

- [x] Task 3: Build a reusable `RunOptionsButton` view component (AC #1, #2, #4, #5, #6)
  - [x] New file: `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` (design-system-level, not `Views/StoryChoice/`, because both `StoryChoiceView` and `TutorialView` need it — same reasoning `ButtonStyles.swift`/`LayoutMetrics.swift` already live in `DesignSystem/`).
  - [x] Accepts two closures, `onExitToHome: () -> Void` and `onRestartRun: () -> Void` — kept reusable and free of hardcoded navigation, matching `StoryChoiceView`'s existing `onExitToHome` closure-injection precedent, since the two call sites (Task 4, Task 5) need genuinely different "go home" behavior (dismiss a `fullScreenCover` + reset a nav path vs. a plain `@Environment(\.dismiss)` pop) and different `runProgress` refresh needs.
  - [x] Icon: `Image(systemName: "ellipsis.circle")` per `DESIGN.md.components.run-options-button.icon`. Color: `DESIGN.md` specifies `{colors.trace-brass}` idle / `{colors.ink-primary}` pressed — **no `TraceBrass` color set exists yet** (confirmed current `Assets.xcassets` contents: `AccentColor`, `InkPrimary`, `InkSecondary`, `SelectedFill`, `SurfaceBase` — same list Stories 2.6/2.9 confirmed, unchanged). Following the established placeholder-color-reuse precedent (Stories 2.3/2.5/2.6/2.9), use `Color.inkPrimary` as a flat stand-in for the icon's foreground for now; Story 2.8 owns the full DESIGN.md palette pass for every Epic 2 reading-surface component at once (per those stories' own Scoping Notes) — do not add a new color asset in this story.
  - [x] Tap target: `.frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)` on the button label (matches the removed `exitButton`'s pattern) plus an explicit `.contentShape(Rectangle())` (Buttons rule, project-context.md — this button has a fully transparent background, so hit-testing needs the explicit shape or only the glyph's own pixels would be tappable).
  - [x] `.accessibilityLabel(Text("storyChoice.runOptions.accessibilityLabel"))` on the button — overrides the SF Symbol's default VoiceOver name (AC #5, UX-DR12).
  - [x] First `.confirmationDialog("storyChoice.runOptions.accessibilityLabel", isPresented: $isPresentingOptions, titleVisibility: .hidden)` (reusing that same key's text as the dialog's — hidden — title avoids adding a key nobody will ever see, since `titleVisibility: .hidden` is appropriate for pure chrome, no explanatory text needed for the first sheet) with three `Button`s in this exact order: `Button("storyChoice.runOptions.exitToHome") { onExitToHome() }`, `Button("storyChoice.runOptions.restartRun", role: .destructive) { isPresentingRestartConfirmation = true }` (does NOT call `onRestartRun()` directly — only flips local `@State` to show the second dialog), `Button("storyChoice.runOptions.cancel", role: .cancel) {}`.
  - [x] Second `.confirmationDialog("storyChoice.runOptions.restartConfirmation.title", isPresented: $isPresentingRestartConfirmation, titleVisibility: .visible)` with two buttons: `Button("storyChoice.runOptions.restartRun", role: .destructive) { onRestartRun() }` (reuses the same label text as the first sheet's destructive option — same real-world confirm-dialog pattern as e.g. "Delete Account" → confirm "Delete Account" again) and `Button("storyChoice.runOptions.cancel", role: .cancel) {}` (reuses the same Cancel key/text as the first dialog — one key, two call sites, per this codebase's DRY convention).
  - [x] This is a native destructive-action pattern end-to-end (`role: .destructive`/`.cancel` give native styling, VoiceOver announcement, and Dynamic Type support for free) — per EXPERIENCE.md's Accessibility Floor: "no custom-built confirmation dialog." Do not hand-roll button colors or a custom alert view.

- [x] Task 4: Wire `RunOptionsButton` into `StoryChoiceView`, replacing the temporary exit button (AC #1, #3, #4)
  - [x] Remove the `exitButton` computed property (`ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`, current lines ~141-150) entirely — its own doc comment already names this story as its replacement ("Story 2.7's run-options sheet... replaces it with the real, deliberate exit path").
  - [x] Replace the `.overlay(alignment: .topTrailing) { exitButton }` call site (`readingComposition`, current line ~107-109) with:
    ```swift
    .overlay(alignment: .topTrailing) {
        RunOptionsButton(
            onExitToHome: {
                engine.exitToHome()
                onExitToHome()
            },
            onRestartRun: {
                engine.restartRun()
            }
        )
    }
    ```
    No `runProgress.refresh()` call needed here (unlike Task 5's Tutorial call site) — `RootView`'s existing `.onChange(of: isPresentingStorySession)` already calls `runProgress.refresh()` whenever the `fullScreenCover` dismisses, which covers the "Exit to Home" path; "Restart This Run" doesn't dismiss anything, and a snapshot already existed before and after the restart (still "in progress," just reset), so `runProgress.hasInProgressRun` never actually changes value on this path — nothing to refresh.
  - [x] `#Preview` blocks (bottom of the file) already pass `onExitToHome: {}` — no signature change, no updates needed there.

- [x] Task 5: Wire `RunOptionsButton` into `TutorialView`, retrofitting the missing control (AC #1)
  - [x] Add `@Environment(StoryRunEngine.self) private var engine` to `ForkedEchoes/Views/Tutorial/TutorialView.swift` (alongside its existing `@Environment(\.dismiss)` and `@Environment(RunProgressObserver.self)`) — this view has never read `StoryRunEngine` before; Task 6 below is what makes this environment lookup actually resolve at runtime instead of crashing.
  - [x] Add `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` to the same `GeometryReader`/`ScrollView` composition `StoryChoiceView` uses (place it on the outermost `GeometryReader`, matching `StoryChoiceView`'s placement relative to its own content root):
    ```swift
    .overlay(alignment: .topTrailing) {
        RunOptionsButton(
            onExitToHome: {
                engine.exitToHome()
                dismiss()
            },
            onRestartRun: {
                engine.restartRun()
                runProgress.refresh()
            }
        )
    }
    ```
  - [x] The explicit `runProgress.refresh()` after `restartRun()` here is **required and different from Task 4's Story/Choice call site**: restarting from a fresh install's Tutorial page (no prior run at all) writes a `RunSnapshot` for the very first time, flipping `runProgress.hasInProgressRun` from `false` to `true` — but nothing dismisses this view to trigger `RootView`'s existing refresh-on-dismiss path, so without this explicit call, Tutorial's "Start Story"/"Resume Story" primary-action label (line ~19, `runProgress.hasInProgressRun ? "home.action.resumeStory" : "tutorial.action.startStory"`) would go stale until some other navigation event happened to refresh it.
  - [x] Update `TutorialView`'s `#Preview` (currently only injects `.environment(RunProgressObserver())`) to also inject a `StoryRunEngine` instance, e.g. `.environment(StoryRunEngine())` — the view now has a real `@Environment(StoryRunEngine.self)` dependency; an unsatisfied one is a runtime crash, not a compile error, so a `#Preview` that doesn't supply it would itself crash when rendered.

- [x] Task 6: Propagate `StoryRunEngine` to the whole navigation hierarchy, not just the `fullScreenCover` (AC #1, prerequisite for Task 5)
  - [x] In `ForkedEchoes/Views/RootView.swift`: `engine` is currently injected via `.environment(engine)` attached ONLY inside the `.fullScreenCover(isPresented:)` content closure (current line ~56) — `HomeView`/`TutorialView`, sitting in the outer `NavigationStack`, have never had it in their environment. Move `.environment(engine)` up to sit alongside the existing `.environment(runProgress)` (current line ~50), applied once to the whole `NavigationStack`, so it's inherited by `HomeView`, `TutorialView`, AND still flows into the `fullScreenCover`'s content (SwiftUI environment values propagate from a presenting view into its modally-presented content by default — this is standard, documented `@Observable`/environment behavior, not a corner case, but genuinely unverifiable without a real build in this devcontainer). Remove the now-redundant explicit `.environment(engine)` inside the `fullScreenCover` closure once the one at the `NavigationStack` level is confirmed to cover it — or, if the user's Xcode build surfaces any issue, keep both as a harmless double-application rather than leaving Tutorial without access. Flag this explicitly as the one structural risk this story introduces (Task 8's manual verification list).
  - [x] `HomeView` doesn't currently read `StoryRunEngine` directly (relies on `RunProgressObserver` + the `isPresentingStorySession` binding) — confirm this stays true; don't add a speculative `StoryRunEngine` dependency to `HomeView` as a side effect of this change, since nothing in this story's AC touches Home.

- [x] Task 7: `Localizable.xcstrings` additions and removal (AC #6)
  - [x] Remove the `storyChoice.action.exitToHome` entry — it was the temporary `exitButton`'s label (its own comment already named Story 2.7 as its replacement) and is now fully superseded by Task 3/4's real control. Per project-context.md's rename/delete self-check: `grep -rn "storyChoice.action.exitToHome"` across the whole repo both before and after removal, confirming zero remaining references (the `#Preview`s reference the `onExitToHome` *closure parameter*, an unrelated Swift identifier, not this string key — don't confuse the two while grepping).
  - [x] Add, alphabetically inserted immediately after `storyChoice.pager.previousPage` and before `tutorial.action.backHome` (existing keys are alphabetically ordered — see `python3 -c "import json; ..."` dump used at story-creation time), each matching every existing entry's exact shape (`comment`, `extractionState: "manual"`, one `en` `stringUnit` with `state: "translated"`):
    - `storyChoice.runOptions.accessibilityLabel` — "Run options" (doubles as the first `.confirmationDialog`'s hidden title, per Task 3)
    - `storyChoice.runOptions.cancel` — "Cancel" (shared by both confirmation dialogs)
    - `storyChoice.runOptions.exitToHome` — "Exit to Home"
    - `storyChoice.runOptions.restartConfirmation.title` — explanatory second-dialog copy, e.g. "This clears your progress and score. This can't be undone." (EXPERIENCE.md only specifies "a second explicit confirmation step," not exact wording — this is new, author-level microcopy; keep it plain and factual, not narrative voice, since it's system chrome, not story prose, matching "Back Home"/"Exit to Home"'s existing plain-chrome register)
    - `storyChoice.runOptions.restartRun` — "Restart This Run" (shared by both dialogs, per Task 3)
  - [x] `python3 -m json.tool` on `Localizable.xcstrings` afterward to confirm valid JSON (same static check every prior story's `.xcstrings` edit gets in this devcontainer).

- [x] Task 8: Manual verification (AC #8)
  - [x] This devcontainer cannot render SwiftUI, take a screenshot, exercise a real `.confirmationDialog`, or catch a runtime environment-propagation crash (Task 6's risk is invisible to `swiftc -parse`/`swift test` — it only ever fails, or doesn't, inside an actual Xcode/Simulator run). Request the user: build and run; on both a Story/Choice page and the Tutorial page, confirm the ellipsis icon appears top-right and is absent on Home and on the branch-arrival interstitial (choose the shore option, confirm no icon during the interstitial, confirm it reappears once dismissed); tap it and confirm the three-option sheet appears in order (Exit to Home / Restart This Run in red / Cancel); tap Cancel and confirm nothing happened; tap "Exit to Home" and confirm the app returns to Home with "Resume Story" now offered (not "Start Story"), then resume and confirm the run continues exactly where it left off; re-enter run-options, tap "Restart This Run," confirm a second confirmation appears, tap its Cancel and confirm the run is untouched, then repeat and confirm the second dialog's destructive action, confirming the Story session now shows the intro page with a cleared alignment score (no direct on-screen score display, but confirm via a subsequent full run that early alignment-affecting choices are back in play); repeat the full Restart flow from the Tutorial page specifically and confirm it does NOT crash (the environment-propagation risk) and that Tutorial's own "Start Story"/"Resume Story" label updates correctly afterward without needing to navigate away and back; turn on VoiceOver and confirm the icon announces "Run options," not a generic/default name; rotate the device with the sheet open and confirm nothing breaks. Result + date recorded in Completion Notes List (project-context.md Process Agreement).

### Review Findings

- [x] [Review][Patch] "Restart This Run" fires unconditionally in Tutorial with no run in progress, showing a destructive "can't be undone" confirmation for progress that doesn't exist and silently creating a persisted `RunSnapshot` — `engine.restartRun()` on `TutorialView`'s `onRestartRun` has no guard against `runProgress.hasInProgressRun` (the same signal already read on `TutorialView.swift:25` for the CTA label). User decision: guard the call in `onRestartRun` (no-op / hide the option when there's no run to restart). Fixed: added `guard runProgress.hasInProgressRun else { return }` in `TutorialView.swift`'s `onRestartRun`. [`ForkedEchoes/Views/Tutorial/TutorialView.swift:92-105`, `ForkedEchoes/Engine/StoryRunEngine.swift:218`]
- [x] [Review][Patch] UX-DR12's "focus traversal ... run-options last" requirement (epics.md:109, epics.md:575-577) is never implemented — no `.accessibilitySortPriority` anywhere on `RunOptionsButton`/`StoryChoiceView`, despite this story's own AC #5 narrowing UX-DR12 down to only the `accessibilityLabel` text. User decision: implement the traversal-order requirement in full, matching epics.md. Fixed: added `.accessibilitySortPriority(-1)` to `RunOptionsButton`. [`ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift:36-40`, `_bmad-output/planning-artifacts/epics.md:575-577`]
- [x] [Review][Patch] `RunOptionsButton` lives under `Views/DesignSystem/` (implying a generic, reusable primitive) but hardcodes every string to the `storyChoice.*` localization namespace even though `TutorialView` also uses it — rename the shared keys to a namespace-neutral prefix (e.g. `runOptions.*`). Fixed: renamed all five keys from `storyChoice.runOptions.*` to `runOptions.*` in `Localizable.xcstrings` and `RunOptionsButton.swift`. [`ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift:35-58`]
- [x] [Review][Defer] No automated test coverage (UI-test level) for `RunOptionsButton`'s chained `.confirmationDialog`s, button ordering, or role-to-closure wiring — only engine-level `restartRun()`/`exitToHome()` behavior is unit tested. Requires a UI-test target this project doesn't yet have; out of scope for a patch. — deferred, pre-existing gap in test infrastructure
- [x] [Review][Defer] `RootView`'s "Exit to Home" refresh relies on an implicit `.onChange(of: isPresentingStorySession)` refresh path with no test asserting the wiring; `TutorialView` needed its own explicit `runProgress.refresh()` workaround for the same underlying "dismissal doesn't reliably trigger a refresh" problem, suggesting the mechanism is fragile rather than fixed. — deferred, pre-existing pattern

## Dev Notes

### What already exists — do not re-create any of this

`ForkedEchoes/Engine/StoryRunEngine.swift` (primary edit target, Task 1):
- `goBack()` (~line 185), `startFreshRunIfCurrentRunHasEnded()` (~line 215), `persistOrClearSnapshot()` (~line 239) — read all three before writing `exitToHome()`/`restartRun()`; the new methods sit structurally right alongside these.
- `dismissedInterstitialNodeIds: Set<NodeID>` (~line 53), `visitedNodeIds: [NodeID]` (~line 66) — both need clearing in `restartRun()`'s reset, same fields `startFreshRunIfCurrentRunHasEnded()` already clears.
- AD-3's full intent-surface list (already written in `ARCHITECTURE-SPINE.md`, quoted here so this story doesn't have to re-derive it): `selectChoice(_:)`, `advancePage()`, `goBack()`, `exitToHome()` (non-destructive, preserves the snapshot), `restartRun()` (mid-run, destructive, requires confirmation), `startNewRun()` (from Memory, post-completion, no confirmation — **not this story's job**, Epic 3's). This story implements exactly the two methods AD-3 already named for it and nothing more.

`ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (primary view edit target, Task 4):
- `exitButton` (~line 141) and its call site inside `readingComposition`'s `.overlay(alignment: .topTrailing)` (~line 107) — both replaced, not extended.
- `onExitToHome: () -> Void` (~line 40) — the existing RootView-injected closure that resets both the `fullScreenCover` and `NavigationStack` path together; reused as-is inside the new `RunOptionsButton`'s `onExitToHome` closure (which also calls `engine.exitToHome()` first).
- The interstitial branch at the top of `body` (~line 44) already fully bypasses `readingComposition` — the new button, attached only inside `readingComposition`, is excluded from the interstitial by the same existing construction Story 2.6 established for the old `exitButton`. No new interstitial-exclusion logic needed.

`ForkedEchoes/Views/Tutorial/TutorialView.swift` (secondary view edit target, Task 5):
- Currently has zero `StoryRunEngine` dependency — Task 6 is the prerequisite that makes Task 5's new `@Environment(StoryRunEngine.self)` resolve instead of crash.
- `dismiss` (`@Environment(\.dismiss)`, line 4) and `runProgress` (`@Environment(RunProgressObserver.self)`, line 16) already exist and are reused directly in the new button's closures.
- The existing "Back Home" button (line ~48-54) just calls `dismiss()` — the new run-options "Exit to Home" path does the same plus `engine.exitToHome()`, so the two exits behave identically from Tutorial except for which engine intent fires first.

`ForkedEchoes/Views/RootView.swift` (Task 6):
- `.environment(runProgress)` (~line 50) and `.environment(engine)` (~line 56, currently only inside the `fullScreenCover`) — Task 6 is a small, surgical move of one modifier, not a restructuring of this file.

`ForkedEchoes/Views/DesignSystem/ButtonStyles.swift` / `LayoutMetrics.swift` (Task 3):
- `LayoutMetrics.minTapTarget` (44pt) and `Spacing.small` already exist and are reused as-is — no new numeric constants needed for this story. `RunOptionsButton` does NOT use `.primaryAction`/`.secondaryAction` (those are filled/bordered full-width action buttons for Home/Tutorial's main CTAs) — it's a plain icon `Button` with no custom `ButtonStyle`, matching the removed `exitButton`'s own styling level (a `.secondaryAction`-styled text button is being replaced by an icon button per DESIGN.md's actual spec, not kept).

`Assets.xcassets` — confirmed contents unchanged since Stories 2.6/2.9: `AccentColor`, `InkPrimary`, `InkSecondary`, `SelectedFill`, `SurfaceBase`. No `TraceBrass` — see Task 3's placeholder-color note.

`Localizable.xcstrings` — confirmed existing keys are alphabetically ordered; full current list dumped at story-creation time via `python3 -c "import json; ..."` (see Task 7 for exact insertion point).

### Why `exitToHome()` is a real (empty) method, not skipped

AD-3 states plainly: "Views never write engine state directly... every interaction path... invokes the *same* intent method." `exitToHome()` is explicitly named in that same sentence's method list. Nothing about leaving for Home actually needs to change engine state — the snapshot is already correct (AD-4's synchronous-write guarantee means whatever's on disk already matches `currentNodeId`/`choiceHistory`/`alignmentScore` as of the last real mutation). Skipping the method and just calling the View-layer closure directly would technically produce identical player-visible behavior, but it would make "Exit to Home" the one user-facing action in this entire app that doesn't route through the engine's intent surface — inconsistent with every other interaction (including this story's own `restartRun()`) and a trap for a future story that assumes `exitToHome()` exists and does something. Keep it, document why, don't second-guess it into "simplifying it away."

### Why `restartRun()` must call `persistOrClearSnapshot()` when `startFreshRunIfCurrentRunHasEnded()` doesn't

This is the one subtle correctness requirement in this story, worth re-reading before implementing Task 1. `startFreshRunIfCurrentRunHasEnded()` only ever runs when `StoryTree.node(for: currentNodeId)` is already `.ending` — and reaching `.ending` already cleared any `RunSnapshot` (`persistOrClearSnapshot()`'s own `.ending` branch calls `defaults.removeObject(forKey:)` instead of writing). So by the time that method resets state, there is nothing persisted to reconcile — a freshly-reset run correctly persists nothing until its own first real mutating intent (exactly like any other brand-new run). `restartRun()` is different in one crucial way: it fires **while a real, valid `RunSnapshot` of the pre-restart run is already sitting in `UserDefaults`**. If `restartRun()` reset in-memory state but didn't also call `persistOrClearSnapshot()`, that stale on-disk snapshot would survive untouched — and `StoryRunEngine.resumingFromSnapshot(defaults:)` (the cold-launch resume path) would happily resurrect it if the app were force-quit even one instant after the player confirmed "Restart This Run," silently undoing the very action they just confirmed. Calling `persistOrClearSnapshot()` at the end of `restartRun()` closes this gap by immediately overwriting the stale snapshot with one reflecting the reset state (root node, empty history) — AC #7's dedicated regression test (a second, independently-constructed engine resuming from the same `UserDefaults` suite right after `restartRun()`) is what actually proves this, not just an in-memory assertion on the same engine instance.

### Architecture compliance (AD-2, AD-3, AD-4, AD-5)

- **AD-2**: every new label (`Exit to Home`, `Restart This Run`, `Cancel`, the restart-confirmation explanatory text) goes through `Localizable.xcstrings` by stable key — no hardcoded strings in `RunOptionsButton`.
- **AD-3**: `exitToHome()`/`restartRun()` complete AD-3's previously-partially-implemented intent-surface list (only `startNewRun()`, Epic 3's job, remains). `StoryRunEngine` stays the sole mutator — `RunOptionsButton` never touches `currentNodeId`/`choiceHistory`/`alignmentScore` itself, only calls the two new intent methods via its closures.
- **AD-4**: `restartRun()`'s explicit `persistOrClearSnapshot()` call is a deliberate, documented AD-4 compliance point (see the dedicated Dev Notes section above) — the first engine method in this codebase where "should this call persist?" isn't simply "yes, always, uniformly" like every prior mutating intent, because it's the first intent to fire while a *stale* snapshot of a *different* (about-to-be-discarded) run state is already on disk.
- **AD-5**: no change to `phase` derivation — `restartRun()` resetting `currentNodeId` to `StoryTree.root` (a plain `.reading` node with no `arrival`) means `phase` derives `.reading` automatically, same as any fresh engine construction; no special-casing needed.

### Testing standards summary

- Swift Testing (`import Testing`), `@testable import ForkedEchoes`. Extend `StoryRunEngineTests.swift` (existing scope — `exitToHome()`/`restartRun()` are `StoryRunEngine` intent-method additions, same precedent as every prior Epic 2 story).
- No UI test target exists — `RunOptionsButton`'s actual `.confirmationDialog` presentation, button ordering, destructive styling, and VoiceOver label have no automated coverage; Task 8's manual Simulator check is the only verification for all of that, same pattern as every prior visual-only story (1.4, 2.5, 2.6, 5.3, 5.4).
- `swift test` from repo root genuinely builds/runs this suite in this devcontainer — 49/49 confirmed at story-creation time (re-verified via both default-parallel and `--no-parallel` runs; the one flake under parallel execution is a pre-existing, documented Linux `UserDefaults(suiteName:)` isolation quirk, not something this story needs to fix). Report the new total.

### Project Structure Notes

- New file: `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift`.
- Modified: `ForkedEchoes/Engine/StoryRunEngine.swift` (`exitToHome()`, `restartRun()`, `resetRunState()` helper), `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (`exitButton` removed, `RunOptionsButton` wired in), `ForkedEchoes/Views/Tutorial/TutorialView.swift` (new `StoryRunEngine` environment read, `RunOptionsButton` added, `#Preview` updated), `ForkedEchoes/Views/RootView.swift` (`.environment(engine)` moved/broadened), `ForkedEchoes/Resources/Localizable.xcstrings` (one key removed, five added), `ForkedEchoesTests/StoryRunEngineTests.swift` (new intent-method tests).
- `Views/` is a `PBXFileSystemSynchronizedRootGroup` (Story 1.1) — the new `RunOptionsButton.swift` needs zero `project.pbxproj` edits; Xcode auto-discovers it.
- No `Package.swift` change expected — `RunOptionsButton.swift`/`RootView.swift`/`TutorialView.swift`/`StoryChoiceView.swift` all land under `Views/`, which the SwiftPM manifest excludes (only `Content`/`Engine` are SwiftPM-covered); they get parse-check-only verification here. `StoryRunEngine.swift`'s two new methods ARE covered by the SwiftPM package and genuinely build/test via `swift test`.
- No conflicts detected against current on-disk structure.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.7: Run Options Action Sheet]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR11] (run-options action sheet spec: icon, position, three-option sheet, non-destructive Exit / destructive-confirmed Restart / Cancel)
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR12] (explicit "Run options" `accessibilityLabel` requirement; focus-traversal-last requirement)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-3] (full `StoryRunEngine` intent-surface list naming `exitToHome()`/`restartRun()`/`startNewRun()` explicitly, with their non-destructive/destructive/no-confirmation distinctions)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-4] (`RunSnapshot` represents an in-progress run only; `restartRun()`/`startNewRun()` clear it as part of resetting)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md] (Navigation section — "the only sanctioned exit from the Story session is a deliberate action... Memory's 'Return Home,' or a mid-run 'Exit to Home' (Story 2.7's run-options sheet)")
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md#components.run-options-button] (icon: `ellipsis.circle`, color tokens `trace-brass`/`ink-primary`, position, 44pt tap target)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md#Components] ("Run options button" summary paragraph — present on Story/Choice + Tutorial, absent from interstitial + Home)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md] (Information Architecture run-options row; State Patterns "Run in progress, options opened" row — second explicit confirmation required for Restart; Accessibility Floor — explicit `accessibilityLabel`, native destructive-action pattern, no custom-built confirmation dialog, tap-target and focus-traversal-order requirements)
- [Source: _bmad-output/project-context.md#Design tokens] (placeholder-color-reuse precedent, numeric-literal-traces-to-a-token rule)
- [Source: _bmad-output/project-context.md#Buttons] (`.contentShape(Rectangle())` requirement for transparent-background buttons)
- [Source: _bmad-output/project-context.md#Localization] (alphabetical key ordering, exact `.xcstrings` entry shape)
- [Source: _bmad-output/project-context.md#Pre-Completion Self-Check] (repo-wide grep requirement before/after any deletion — applies to Task 7's `storyChoice.action.exitToHome` removal)
- [Source: _bmad-output/implementation-artifacts/2-6-branch-arrival-interstitial-and-illustrations.md] (temporary `exitButton`'s own doc comment naming this story as its replacement; placeholder-color precedent)
- [Source: _bmad-output/implementation-artifacts/2-9-branch-arrival-interstitial-first-visit-only-gate.md] (`RunSnapshot` schema-extension precedent; `resetRunState()`-shaped reset-and-persist precedent via `dismissedInterstitialNodeIds`/`visitedArrivalNodeIds`; deferred backward-navigation-after-relaunch gap, unrelated to this story but touching the same engine methods)
- [Source: ForkedEchoes/Engine/StoryRunEngine.swift] (existing intents, `goBack()`/`startFreshRunIfCurrentRunHasEnded()`/`persistOrClearSnapshot()` to read before extending)
- [Source: ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift] (existing `exitButton`, `onExitToHome` closure, `readingComposition`'s overlay chain, interstitial-exclusion-by-construction)
- [Source: ForkedEchoes/Views/Tutorial/TutorialView.swift] (existing `dismiss`/`runProgress` environment reads, "Back Home" button precedent)
- [Source: ForkedEchoes/Views/RootView.swift] (current `.environment(engine)` scoping inside the `fullScreenCover` only — Task 6's edit target)
- [Source: ForkedEchoes/Views/DesignSystem/ButtonStyles.swift] (existing button styles — deliberately NOT reused for this plain icon button)
- [Source: ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift] (`minTapTarget`, `Spacing.small` reused as-is)
- [Source: ForkedEchoes/Resources/Localizable.xcstrings] (existing key shapes, alphabetical ordering, the `storyChoice.action.exitToHome` entry being removed)
- [Source: ForkedEchoesTests/StoryRunEngineTests.swift] (existing 35 `StoryRunEngine` tests to extend; `freshDefaults()` helper pattern from `TestSupport.swift`)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swiftc -parse` on every touched/new `Engine/`/`Views/` file and `StoryRunEngineTests.swift` — clean, no syntax errors.
- `python3 -m json.tool` on `Localizable.xcstrings` — valid JSON.
- `grep -rn "storyChoice.action.exitToHome"` and `grep -rn "exitButton"` repo-wide, before and after removal — zero remaining references.
- `swift build` — clean.
- `swift test --no-parallel` from repo root — 54/54 passed (49 prior + 5 new: `exitToHomeDoesNotMutateEngineState`, `exitToHomeLeavesAnExistingPersistedSnapshotUntouched`, `restartRunResetsAllRunStateMidRun`, `restartRunClearsDismissedArrivalNodeState`, `restartRunImmediatelyOverwritesTheStaleMidRunSnapshot`).

### Completion Notes List

- `exitToHome()` implemented as an intentionally-empty engine method per the story's own Dev Notes reasoning (AD-3 intent-surface consistency) — verified via a dedicated test that it leaves both in-memory state and the persisted `RunSnapshot` byte-for-byte unchanged.
- `restartRun()` implemented with an explicit `persistOrClearSnapshot()` call, unlike `startFreshRunIfCurrentRunHasEnded()` — the dedicated regression test (`restartRunImmediatelyOverwritesTheStaleMidRunSnapshot`) constructs a second, independent `StoryRunEngine` via `resumingFromSnapshot(defaults:)` on the same `UserDefaults` suite immediately after `restartRun()`, proving the stale pre-restart snapshot is genuinely overwritten, not just left stale in memory on the original instance.
- DRY-refactored the five-field reset shared by `startFreshRunIfCurrentRunHasEnded()` and `restartRun()` into one private `resetRunState()` helper, per the story's own instruction.
- `RunOptionsButton` built as a new shared `Views/DesignSystem/` component (not `Views/StoryChoice/`) since both `StoryChoiceView` and `TutorialView` need it. Uses two chained `.confirmationDialog`s (native action sheet on iPhone) rather than `ActionSheet` (deprecated) or a custom alert — `role: .destructive`/`.cancel` give native styling/VoiceOver/Dynamic Type support for free, satisfying EXPERIENCE.md's "no custom-built confirmation dialog" requirement.
- Used `Color.inkPrimary` as a placeholder for DESIGN.md's `trace-brass` icon color token (no `TraceBrass` color set exists yet — confirmed `Assets.xcassets` still only has `AccentColor`/`InkPrimary`/`InkSecondary`/`SelectedFill`/`SurfaceBase`), consistent with the placeholder-color-reuse precedent from Stories 2.3/2.5/2.6/2.9. Story 2.8 owns the real palette pass.
- Removed the temporary `exitButton`/`storyChoice.action.exitToHome` key entirely (not deprecated-in-place) and updated the now-stale doc comment above `onExitToHome` in `StoryChoiceView.swift` that referenced it as "temporary."
- Retrofitting Tutorial required broadening `RootView`'s `.environment(engine)` from being scoped only inside the `fullScreenCover` to covering the whole `NavigationStack` — `TutorialView` had never read `StoryRunEngine` before this story. This is the one change in this story invisible to `swiftc -parse`/`swift test` (a missing environment object is a runtime crash, not a compile error) — flagged prominently for the user's Xcode/Simulator check (AC #8).
- Added an explicit `runProgress.refresh()` call after `engine.restartRun()` in `TutorialView`'s `RunOptionsButton` closure specifically (not needed at the `StoryChoiceView` call site, where `RootView`'s existing dismiss-triggered refresh already covers it) — restarting from a fresh-install Tutorial page can flip `hasInProgressRun` from `false` to `true` with no dismissal event to trigger the existing refresh path.
- **User-reported Xcode/Simulator bug, 2026-08-02, fixed same session**: build/tests succeeded, but tapping "Start Story" (from both Home and Tutorial) crashed with `Fatal error: No Observable object of type StoryRunEngine found` — confirming the exact environment-propagation risk this story's own Dev Notes flagged as unverifiable here. Root cause: Task 6's assumption that a `.fullScreenCover`'s content closure automatically inherits `.environment(_:)` values applied earlier in the same modifier chain to the view the `.fullScreenCover` modifier decorates was wrong in practice — real Simulator testing showed the closure does NOT inherit it, only whatever's applied explicitly inside the closure itself. Fixed by keeping `.environment(engine)` in BOTH places: on the `NavigationStack` (for `HomeView`/`TutorialView`) AND re-added directly inside the `fullScreenCover`'s content closure (for `StoryChoiceView`) — the harmless-double-application fallback this story's own Task 6 had already flagged as the contingency if the single-application assumption didn't hold. `RootView.swift` updated accordingly; re-requested Xcode/Simulator confirmation from user.
- **Manual verification confirmed by user, 2026-08-02**: Xcode build and unit tests pass. "Start Story" works from both Home and Tutorial (environment-propagation crash resolved). Full AC #8 checklist confirmed on both Story/Choice and Tutorial pages: run-options icon placement/absence, three-option sheet ordering and labels, "Exit to Home" preserving the snapshot, "Restart This Run"'s second confirmation and in-place reset, VoiceOver "Run options" label, and rotation mid-sheet.
- **Post-code-review manual verification confirmed by user, 2026-08-02**: after the three review patches (Tutorial restart guard, `.accessibilitySortPriority(-1)` for UX-DR12 traversal order, `runOptions.*` key rename), Xcode build, unit tests, and Simulator testing all completed successfully — no regressions from the patches.

### File List

- Added: `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift`
- Modified: `ForkedEchoes/Engine/StoryRunEngine.swift`
- Modified: `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`
- Modified: `ForkedEchoes/Views/Tutorial/TutorialView.swift`
- Modified: `ForkedEchoes/Views/RootView.swift`
- Modified: `ForkedEchoes/Resources/Localizable.xcstrings`
- Modified: `ForkedEchoesTests/StoryRunEngineTests.swift`

## Change Log

- 2026-08-02: Story 2.7 created via create-story workflow, on `2-7-run-options-action-sheet` branch (off `main`, per this project's convention that Epic 2 implementation stories live on `main`/story branches, not `story-discovery`). Confirmed current baseline: 49/49 `swift test` passing (default-parallel run showed the pre-existing, documented `UserDefaults(suiteName:)` parallel-isolation flake; `--no-parallel` confirmed a genuine 49/49). Surfaced two design decisions not spelled out in epics.md/EXPERIENCE.md: (1) `exitToHome()` is an intentionally-empty engine method, kept for AD-3 intent-surface consistency rather than skipped; (2) `restartRun()` must call `persistOrClearSnapshot()` explicitly, unlike the existing `startFreshRunIfCurrentRunHasEnded()`, to avoid a stale mid-run snapshot surviving a force-quit immediately after confirming Restart. Also surfaced a real gap: `TutorialView` has never had `StoryRunEngine` in its environment (only injected inside `RootView`'s `fullScreenCover`) — retrofitting the run-options control onto Tutorial requires broadening that environment injection, which is a genuine runtime-crash risk this devcontainer cannot verify.
- 2026-08-02: Story 2.7 implemented — added `exitToHome()`/`restartRun()` engine intents (with a shared `resetRunState()` DRY helper), a new reusable `RunOptionsButton` view component (two chained native `.confirmationDialog`s), wired it into both `StoryChoiceView` (replacing the temporary `exitButton`) and `TutorialView` (a genuinely new capability for that screen), broadened `RootView`'s `.environment(engine)` to cover the whole `NavigationStack` so Tutorial can see `StoryRunEngine`, and updated `Localizable.xcstrings` (one key removed, five added). Extended Swift Testing coverage (54/54 passing, net +5 tests). Status set to `review`; Xcode/Simulator manual verification (AC #8, especially the Tutorial environment-propagation risk and the real `.confirmationDialog` interaction flow) requested from user, pending confirmation.
- 2026-08-02: User confirmed build/tests succeeded but reported a crash: tapping "Start Story" (from Home or Tutorial) fatal-errored with "No Observable object of type StoryRunEngine found," exactly the environment-propagation risk this story's Dev Notes flagged as unverifiable in this devcontainer. Root-caused to a wrong assumption in Task 6: a `fullScreenCover`'s content closure does NOT automatically inherit `.environment(_:)` applied earlier in the same chain to the view the modifier decorates. Fixed by keeping `.environment(engine)` in both places — the `NavigationStack` level (for Home/Tutorial) and re-added directly inside the `fullScreenCover` closure (for `StoryChoiceView`) — the double-application fallback the story's own Task 6 had already anticipated. `swift test` unaffected (54/54, view-layer-only fix). Re-requested Xcode/Simulator confirmation from user.
- 2026-08-02: **User confirmed all AC #8 manual verification checks pass in Xcode/Simulator** — build and unit tests pass; "Start Story" works from both Home and Tutorial (the environment-propagation crash is resolved); the full run-options flow (icon placement, three-option sheet ordering/labels, Exit to Home preserving the snapshot, Restart This Run's second confirmation and in-place reset, VoiceOver "Run options" label, rotation) confirmed working on both the Story/Choice and Tutorial pages. All of this story's own AC are now considered manually verified — ready for `code-review`.
