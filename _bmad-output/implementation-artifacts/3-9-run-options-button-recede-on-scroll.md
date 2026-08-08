---
baseline_commit: dc4253939621ee1f142219b82fb3a7e0ea7671b7
---

# Story 3.9: Run-Options Button Recede-on-Scroll

Status: ready-for-dev

## Story

As a developer,
I want `RunOptionsButton` to recede to a low-opacity state while the reading content is actively scrolling, returning to full opacity once scrolling stops,
so that the button never visually collides with scrolled prose at accessibility Dynamic Type sizes, and so it reads as quieter chrome during ordinary reading rather than a persistent, full-opacity distraction.

## Acceptance Criteria

1. **Given** `RunOptionsButton` is visible on a Story/Choice reading page at an accessibility Dynamic Type size (where `readingComposition` wraps `content` in `accessibilitySizeFramedScroll()`'s `ScrollView`), **when** the user scrolls the reading content, **then** the button's opacity recedes to `LayoutMetrics.runOptionsButtonOpacityReceded` (0.35, DESIGN.md `components.run-options-button.opacity-receded`) via a `LayoutMetrics.runOptionsButtonRecedeDuration` (200ms, DESIGN.md `.recede-transition-duration`) cross-fade. [Source: epics.md#Story-3.9, AC1]
2. **Given** the button has receded during scrolling, **when** scrolling comes to rest, **then** the button returns to full opacity (1.0) via the same cross-fade. [Source: epics.md#Story-3.9, AC2]
3. **Given** Reduce Motion is enabled (NFR5), **when** the button transitions between resting and receded opacity, **then** the transition is an instant snap, not an animated cross-fade — matching this codebase's existing `reduceMotion`-gated `.animation(...)` convention. [Source: epics.md#Story-3.9, AC3]
4. **Given** the button is in its receded (0.35 opacity) state, **when** the user taps it, **then** it still opens the run-options `.confirmationDialog` exactly as before — hit-testing and the 44pt tap target are unaffected by the opacity change (FR-11: no gesture-only interaction; this is a visual-only state, never a disabled or hidden one). [Source: epics.md#Story-3.9, AC4]
5. **Given** a Story/Choice reading page at an ordinary (non-accessibility) Dynamic Type size, where `readingComposition` never wraps `content` in a `ScrollView` and nothing scrolls, **when** the page renders, **then** `RunOptionsButton` stays at its existing full-opacity resting appearance — this story's recede behavior is explicitly scoped to sizes where scrolling can actually occur. [Source: epics.md#Story-3.9, AC5 — see Dev Notes' "Scope boundary" note]
6. **And** a manual-verification AC: in Xcode/Simulator, at an accessibility Dynamic Type size, confirm (a) the button visibly recedes while actively scrolling reading content that previously collided with it, (b) it returns to full opacity once scrolling stops, (c) tapping it while receded still opens the run-options menu, and (d) with Reduce Motion enabled, the opacity change snaps instantly rather than fading. Result + date recorded in the story's Completion Notes List. [Source: epics.md#Story-3.9, AC6 — project-context.md Process Agreement]

## Background: Why This Story Exists

Added via a UX design session with the user (Sally, 2026-08-08). The user reported that at larger Dynamic Type sizes, `RunOptionsButton` (the top-right ellipsis) overlaps reading text once the user has scrolled up or down. Root cause, confirmed by direct code read: `readingComposition` (`StoryChoiceView.swift`) only wraps `content` in a real `ScrollView` at accessibility Dynamic Type sizes, via `View.accessibilitySizeFramedScroll()` (`LayoutMetrics.swift`). `RunOptionsButton` is attached as a fixed `.overlay(alignment: .topTrailing)` on `readingComposition` as a whole (`StoryChoiceView.swift:185-199`) — outside that scroll wrapper, so it never moves. `LayoutMetrics.runOptionsButtonClearance` reserves top padding via `readingCardPadding(top:)`, but that padding only shapes `content`'s *initial* layout (`StoryChoiceView.swift:287`, `:320`); once the user scrolls, the text moves up past that reserved clearance and can pass underneath the fixed button.

The user also separately raised that the button "feels like clutter" and "a bit distracting" present at full visual weight on every page regardless of reading activity.

During the same session, a shake-gesture alternative (replacing the tap trigger entirely) was proposed and explicitly rejected: it collides with iOS's system-reserved "Shake to Undo" convention (`UIEvent.EventSubtype.motionShake`/`UndoManager`), has no visual affordance for discovery, risks accidentally triggering a destructive menu item (this button's own `.exitAndClearProgress` row) from ordinary phone motion, and has no tap equivalent — violating FR-11 ("every gesture has a standard tap equivalent"). That direction is not part of this story's scope and should not be revisited without a fresh product decision.

The agreed direction instead: a scroll-driven opacity recede, the same "chrome recedes while reading, returns on demand" pattern used by Kindle/Apple Books/Safari. This directly resolves the overlap (the button is visually out of the way during the exact window scrolled text could reach it) and reduces its visual weight during active reading, without touching the fragile `GeometryReader`/`ScrollView`/safe-area geometry `accessibilitySizeFramedScroll()` already encodes (project-context.md: that geometry cost Story 3.6 roughly nine rounds — do not perturb it as a side effect of this story).

DESIGN.md's `components.run-options-button` token block (`_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md`) was updated ahead of this story with the full spec: `opacity-resting: 1.0`, `opacity-receded: 0.35`, `recede-trigger: 'reading content is actively scrolling'`, `return-trigger: 'scroll comes to rest, or any tap within the reading area'`, `recede-transition-duration: 200ms`, plus a note on the Reduce Motion requirement and the FR-11 rationale. Read that token block before starting.

## Tasks / Subtasks

- [ ] Task 1: Add the two new named constants to `LayoutMetrics.swift` (AC: #1, #2, #3)
  - [ ] Add `static let runOptionsButtonOpacityReceded: Double = 0.35` inside `enum LayoutMetrics`, with a doc comment citing `DESIGN.md components.run-options-button.opacity-receded` (project-context.md's Design Tokens rule: numeric literals must trace to a DESIGN.md token or a named constant — do not inline `0.35` at the call site).
  - [ ] Add `static let runOptionsButtonRecedeDuration: Duration = .milliseconds(200)` alongside it, citing `DESIGN.md components.run-options-button.recede-transition-duration`. Follow `choiceChargeDuration`/`choiceUndoWindow`'s existing `Duration` pattern in this same file (including the `.timeInterval` extension already defined below them for feeding `.animation(.easeInOut(duration:))`, which takes `TimeInterval`, not `Duration`).

- [ ] Task 2: Wire scroll-phase detection through `accessibilitySizeFramedScroll()` (AC: #1, #2, #5)
  - [ ] In `LayoutMetrics.swift`'s `View.accessibilitySizeFramedScroll()` (currently lines 189-202), add an optional parameter: `func accessibilitySizeFramedScroll(isScrolling: Binding<Bool>? = nil) -> some View`. Defaulting to `nil` means `EndingView.content` (the pattern's other call site — it has no `RunOptionsButton` and must not change behavior) needs zero changes.
  - [ ] Attach `.onScrollPhaseChange { _, newPhase in isScrolling?.wrappedValue = newPhase.isScrolling }` to the `ScrollView` inside this function. `ScrollPhase` (iOS 18+, this project's minimum deployment target — see project-context.md's Technology Stack table) has an `isScrolling` computed property that is `true` for every phase except `.idle` (i.e. `.tracking`, `.interacting`, `.decelerating`, `.animating` all count as scrolling) — use that property directly rather than hand-rolling an equivalent `switch`.
  - [ ] Do not touch this function's existing `GeometryReader`/inset/`.clipped()` geometry (the Story 3.6 history documented in its doc comment) — this task only adds the phase-observation modifier and the new parameter; the viewport math is unrelated and must not change.

- [ ] Task 3: Thread the scroll state from `StoryChoiceView` into `RunOptionsButton` (AC: #1, #2, #5)
  - [ ] In `StoryChoiceView.swift`, add `@State private var isReadingContentScrolling = false` near the view's other `@State` properties (e.g. alongside `activeChoiceOptionID`).
  - [ ] At the accessibility-size call site only (`readingComposition`, the `if dynamicTypeSize.isAccessibilitySize` branch, currently `content.accessibilitySizeFramedScroll().id(engine.currentNodeId).transition(.opacity)` around line 141-144), pass the binding: `.accessibilitySizeFramedScroll(isScrolling: $isReadingContentScrolling)`. Do **not** pass it at the ordinary-size branch (there is no `ScrollView` there to report phase changes from) — this is what makes AC #5 hold structurally rather than needing a separate `if` check.
  - [ ] Reset `isReadingContentScrolling` to `false` in the existing `.onChange(of: engine.currentNodeId)` handler (`StoryChoiceView.swift:206-212`, which already resets `activeChoiceOptionID` on page-turn) — a page-turn tears down and rebuilds the `ScrollView` (per the `.id(engine.currentNodeId)` on the framed-scroll container, Story 3.5 finding cited in that code's own comment), so a stale `true` left over from the previous page must not carry forward and leave the button incorrectly receded on a fresh page.

- [ ] Task 4: Add the opacity behavior to `RunOptionsButton` (AC: #1, #2, #3, #4)
  - [ ] Add a new parameter to `RunOptionsButton`: `var isReceded: Bool = false` (default `false` so the existing `#Preview` and the button's overall call-site shape are unaffected unless a caller opts in).
  - [ ] Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `RunOptionsButton` (it does not currently read this environment value — `StoryChoiceView` does, but `RunOptionsButton` is a separate `View` struct and needs its own).
  - [ ] Apply `.opacity(isReceded ? LayoutMetrics.runOptionsButtonOpacityReceded : 1.0)` to the button, and gate its transition with `.animation(reduceMotion ? nil : .easeInOut(duration: LayoutMetrics.runOptionsButtonRecedeDuration.timeInterval), value: isReceded)` — mirror `StoryChoiceView.swift`'s existing `.animation(reduceMotion ? nil : .easeInOut, value: engine.phase)` gating shape (same file's Reduce Motion convention, just with an explicit duration here since DESIGN.md specifies one).
  - [ ] Apply the opacity via a plain `.opacity(...)` modifier, not `.disabled(isReceded)` or any hit-testing change — AC #4 requires the tap target to stay fully live at 0.35 opacity. SwiftUI's `.opacity()` does not disable hit-testing at any non-zero value, so no extra `.allowsHitTesting(true)` override is needed, but do not introduce one that accidentally sets it `false`.
  - [ ] At `StoryChoiceView.swift`'s `RunOptionsButton(...)` call site (`:186-198`), pass `isReceded: isReadingContentScrolling`.

- [ ] Task 5: Manual Xcode/Simulator verification (AC: #6) — record results in Completion Notes (project-context.md Process Agreement: actively request this, report inline when it happens)
  - [ ] At an accessibility Dynamic Type size, on a reading page long enough to scroll, confirm the button visibly fades toward transparent while actively scrolling and that scrolled text no longer visually collides with it during the fade.
  - [ ] Confirm the button returns to full opacity once scrolling stops (finger lifted and deceleration settles).
  - [ ] While the button is in its receded state (mid-scroll or immediately after), tap it and confirm the run-options menu still opens normally.
  - [ ] Enable Reduce Motion (Settings > Accessibility > Motion) and confirm the opacity change snaps instantly with no visible fade.
  - [ ] Confirm an ordinary (default) Dynamic Type size page shows no change in behavior — button stays fully opaque, since nothing scrolls there.
  - [ ] Record the date and a one-line result for each check in Completion Notes.

## Dev Notes

### Scope boundary — this fix does not reduce clutter at ordinary Dynamic Type sizes

AC #5 states this explicitly and it's worth restating here: `readingComposition` only ever wraps content in a `ScrollView` at accessibility Dynamic Type sizes (`dynamicTypeSize.isAccessibilitySize`). At ordinary sizes there is no scroll signal to recede on, so `RunOptionsButton` will remain at full opacity on every ordinary-size page exactly as it does today. This story fully resolves the reported overlap bug (which is itself only reachable at accessibility sizes, since that's the only place scrolling occurs) and reduces visual weight during the reading sessions where scrolling actually happens, but if the "distracting at default text size" complaint persists after this ships, that's a separate, not-yet-scoped follow-up (e.g. a persistent lower resting opacity, or a different declutter mechanism) — do not expand this story's scope to cover it without a new product decision.

### `ScrollPhase.isScrolling` — the mechanism this story relies on

`ScrollPhase` is a SwiftUI enum (iOS 18+) with cases `.idle`, `.tracking`, `.interacting`, `.decelerating`, `.animating`, exposed via the `.onScrollPhaseChange(_:)` `ScrollView` modifier (`{ oldPhase, newPhase in ... }`). It has a computed `isScrolling` property that is `true` for every case except `.idle`. This project's minimum deployment target is iOS 18.0 (project-context.md Technology Stack), so the API is available without any availability check. Confirmed via web research during story creation (Apple's WWDC24 ScrollView APIs, covered by multiple third-party SwiftUI references) since this devcontainer cannot typecheck SwiftUI/UIKit-dependent code at all (project-context.md Environment section) — there is no way to verify this API surface locally; treat it as correct per that research, but if `swiftc`/Xcode surfaces a different actual signature, trust the compiler over this note.

### Reduce Motion gating — match the existing convention exactly

`StoryChoiceView.swift` already has two instances of the `reduceMotion ? nil : .easeInOut` gating shape (its `.animation(value: engine.phase)` and `.animation(value: engine.currentNodeId)`, lines ~102 and ~159) — both collapse to an instant cut under Reduce Motion rather than skipping the animation modifier's *value* tracking (which would leave the transition silently un-gated). `RunOptionsButton`'s new animation must use the identical shape: gate the `.animation(...)` call itself with the ternary, not wrap the whole modifier in an `if reduceMotion`. This is the same pattern `FrameView`'s power-up transition and the interstitial's phase-keyed transition use — see EXPERIENCE.md's Accessibility Floor for the underlying rule (NFR5).

### Why the binding is optional, not a required parameter

`accessibilitySizeFramedScroll()` is shared by `readingComposition` (`StoryChoiceView.swift`) and `EndingView.content` (`EndingView.swift`) — per prior research, `EndingView` deliberately has no `RunOptionsButton` at all ("nothing meaningful to act on once `RunSnapshot` is already cleared"). Making the new parameter `Binding<Bool>? = nil` means `EndingView.content`'s existing call site needs zero changes and its behavior is provably unaffected by this story — do not go add a scroll-state binding to `EndingView` speculatively; it has no consumer for it.

### Architecture / design citations

- **DESIGN.md `components.run-options-button`**: the authoritative token spec for this story's exact values (`opacity-resting`/`opacity-receded`/`recede-trigger`/`return-trigger`/`recede-transition-duration`) — added ahead of this story during the UX design session; read it directly rather than relying solely on this story's restatement.
- **FR-11** (every gesture has a standard tap equivalent; Dynamic Type is non-negotiable): governs Task 4's requirement that opacity-receded never becomes hit-testing-disabled.
- **NFR5** (Reduce Motion): governs Task 4's animation gating.
- **project-context.md's SwiftUI gesture arbitration section**: not directly triggered by this story (no new `DragGesture`/`ScrollView` interaction is introduced — `.onScrollPhaseChange` observes the existing `ScrollView`'s own phase, it does not add a competing gesture recognizer), but worth rereading before touching `accessibilitySizeFramedScroll()` given that section's general caution around this exact function's geometry.
- **project-context.md's Design tokens rule**: governs Task 1 — both new constants must be named, not inline literals.

### Project Structure Notes

Files expected to change:
- `ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` — Task 1 (two new constants), Task 2 (`accessibilitySizeFramedScroll()`'s new parameter and `.onScrollPhaseChange`).
- `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` — Task 3 (`@State`, call-site binding, `.onChange` reset, `RunOptionsButton(...)` call site's new `isReceded:` argument).
- `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` — Task 4 (`isReceded` parameter, `reduceMotion` environment read, `.opacity`/`.animation`).

No other files should need changes. `EndingView.swift` is explicitly **not** in scope (see Dev Notes above) — if you find yourself editing it, stop and re-read the Dev Notes.

### Testing Standards Summary (AD-7)

- This is a pure SwiftUI view-layer change — no `StoryRunEngine`/engine-logic surface is touched, so no new Swift Testing case is required or expected (AD-7 scope is engine logic only; there is no UI test target in this project — project-context.md Testing section).
- `swiftc -parse` each touched `.swift` file for syntax verification only — this devcontainer cannot resolve `SwiftUI`/`UIKit` imports at all (project-context.md Environment section), so it cannot confirm `ScrollPhase`/`.onScrollPhaseChange` actually compile against the real SDK. Task 5's manual Xcode/Simulator pass is the only real verification available for this story and is not optional.
- Per project-context.md's process rule: if any code review after Task 5's verification patches `.swift` code, do not advance status to `done` on the strength of the pre-patch verification — leave at `review` and re-request Task 5's specific checks.

## Previous Story Intelligence (Story 3.8)

Story 3.8 was Epic 3's prior story, a three-item cleanup bundle with no relation to this story's scope. Two of its process patterns carry forward directly: (1) Completion Notes should be itemized per task, dated, one line per check, not a single paragraph; (2) manual Simulator verification is the primary correctness gate here too, since this is a view-layer-only change `swift test` cannot meaningfully cover (Story 3.8's Task 1/4 were in the same position for its Memory sign-display fix).

## Git Intelligence Summary

Most recent commits are Story 3.7/3.8 merges and doc updates — no new library dependencies, no `Package.swift` changes. No existing commit touches `RunOptionsButton.swift` or `accessibilitySizeFramedScroll()` beyond their original authoring (Story 2.7/2.12 and Story 3.6 respectively, per those files' own header comments) and Story 3.6's code-review consolidation — this story is the first to modify either since.

## Project Context Reference

Full rules loaded from `_bmad-output/project-context.md` (55 rules, last updated 2026-08-07) as a persistent fact for this workflow run — see especially: the Environment section (no SwiftUI/UIKit resolution in this devcontainer, so this story's new iOS-18-only API cannot be locally typechecked — Task 5's manual verification is load-bearing), the SwiftUI gesture arbitration section (general caution around `accessibilitySizeFramedScroll()`'s geometry, even though this story doesn't touch the geometry itself), the Design tokens section (Task 1's named-constant requirement), and the Dynamic Type & Accessibility section (this story's `isAccessibilitySize`-gated behavior follows the same accessibility-size-conditional precedent already established for `ScrollView` usage in this codebase).

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
