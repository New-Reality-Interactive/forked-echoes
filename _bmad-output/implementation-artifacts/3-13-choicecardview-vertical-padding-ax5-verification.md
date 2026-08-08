---
baseline_commit: 6f2ed9df9ba9b7663ba81aedae8d25af4d775b29
---

# Story 3.13: ChoiceCardView Vertical Padding — AX5 Verification

Status: ready-for-dev

## Story

As a developer,
I want `ChoiceCardView`'s choice-card label to reserve real vertical breathing room around its text at the largest accessibility Dynamic Type size,
so that no choice card's text ever crowds its own top/bottom edge, matching the fix Story 3.5 and Story 3.10 already applied to the interstitial Continue button and Home/Tutorial's action buttons.

## Acceptance Criteria

1. **Given** `ChoiceCardView`'s choice-card label (`ChoiceCardView.swift`) at the largest accessibility Dynamic Type size (AX5), **when** inspected in Xcode/Simulator, **then** confirm the label crowds the card's own top/bottom edge with no breathing room (already reported by the user) — apply `.padding(.vertical, Spacing.small)` positioned before the existing `.frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)` call, matching the established padding-before-frame pattern from `BranchArrivalInterstitialView.swift`/`HomeView.swift`/`TutorialView.swift`. [Source: epics.md#Story-3.13, AC1]
2. **And** a consistency-check AC: confirm whether the existing `.padding(.horizontal, Spacing.medium)` (currently applied AFTER `.frame(...)`, not before) should be reordered to match the established pattern — if reordering changes the card's visual result (checkmark/chevron overlay alignment, charge-fill background sizing, tap target width) confirm the new result is still correct in Simulator before committing to the reorder; if it introduces a regression, leave the horizontal padding's existing position as-is and record why. [Source: epics.md#Story-3.13, AC2]
3. **And** a regression-guard AC: confirm the checkmark/chevron trailing overlay, the charge-fill background (`GeometryReader`-sized to the card's width), and the card's `LayoutMetrics.choiceCardBorderWidth` border still render correctly around the taller AX5 card after the padding change — these all key off the same `Text`'s frame this story modifies. [Source: epics.md#Story-3.13, AC3]
4. **And** a manual-verification AC: in Xcode/Simulator, record the AX5 choice-card check (and the horizontal-padding consistency check) as dated results in the story's Completion Notes List, regardless of whether the horizontal padding was reordered. [Source: epics.md#Story-3.13, AC4 — project-context.md Process Agreement]
5. **And** a DRY AC, closing the deferred finding from Story 3.10's code review: with this story's fix, the `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` pair is now duplicated verbatim across 4 call sites (`BranchArrivalInterstitialView`'s Continue button, `HomeView`'s two action buttons, `TutorialView`'s action button) plus this story's `ChoiceCardView` label — factor the pair into a single shared `ViewModifier` (e.g. `.actionLabelBreathingRoom()` or similar) and apply it at all 5 call sites, replacing the duplicated inline pairs. If `ChoiceCardView`'s structural differences (overlay/background/border dependents, AC #2/#3 above) make sharing the modifier unsafe or awkward there, apply it to the other 4 call sites only and record why `ChoiceCardView` was left inline. [Source: `deferred-work.md`, "Deferred from: code review of 3-10-action-button-padding-ax5-and-compact-height-verification (2026-08-08)"]

## Background: Why This Story Exists

Reported directly by the user, 2026-08-08, immediately after Story 3.10's code review — the same vertical-crowding bug class Story 3.5 fixed on the branch-arrival interstitial's Continue button and Story 3.10 fixed on Home/Tutorial's action buttons is also present on the choice-page cards (`ChoiceCardView.swift`).

`ChoiceCardView.swift`'s label currently reads:

```swift
Text(LocalizedStringKey(option.labelKey))
    .choiceLabelStyle()
    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)
    .padding(.horizontal, Spacing.medium)
```

Two things distinguish this from the three already-fixed buttons:

1. **No `.padding(.vertical, ...)` at all** — the interstitial/Home/Tutorial buttons all had this gap and got `.padding(.vertical, Spacing.small)` as their fix; this card never had any vertical padding to begin with.
2. **The existing horizontal padding is applied AFTER `.frame(...)`, not before.** The established pattern (interstitial/Home/Tutorial) applies padding *before* `.frame(...)` specifically so the padding is included in the label's intrinsic size before the frame's minimums apply — this matters at AX5, where the label's intrinsic height can exceed `minHeight` and padding-before-frame is what reserves the breathing room. `ChoiceCardView`'s horizontal padding, applied after the frame, sits outside the frame's sizing entirely — a structurally different arrangement that was never covered by Story 3.5's or Story 3.10's AX5 checks (both only looked at `BranchArrivalInterstitialView.swift`/`HomeView.swift`/`TutorialView.swift`).

## Tasks / Subtasks

- [ ] Task 1: Manual Xcode/Simulator check — ChoiceCardView label at AX5 (AC: #1, #4)
  - [ ] Set the Simulator to the largest accessibility Dynamic Type category (AX5).
  - [ ] Reach a choice page and inspect the choice card(s)' label text — confirm the crowding symptom (already reported by the user) reproduces: label text filling the card's frame with no visible top/bottom margin.
  - [ ] Apply `.padding(.vertical, Spacing.small)` to the label, positioned before the existing `.frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)` call.
  - [ ] Confirm in Simulator that the crowding is resolved post-fix.
  - [ ] Record the dated finding (pre-fix confirmation + post-fix confirmation) in Completion Notes per AC #4.

- [ ] Task 2: Horizontal padding consistency check (AC: #2, #4)
  - [ ] Evaluate whether moving `.padding(.horizontal, Spacing.medium)` to before `.frame(...)` (matching the established pattern) changes the card's rendered result — pay particular attention to the checkmark/chevron trailing `.overlay`, the charge-fill `GeometryReader` background, and overall card width.
  - [ ] If reordering is safe (no visual regression), apply it and confirm in Simulator.
  - [ ] If reordering introduces a regression, leave the horizontal padding's existing position as-is and record why in Completion Notes.
  - [ ] Record the dated finding in Completion Notes per AC #4.

- [ ] Task 3: Regression-guard check — overlay/background/border after the padding change (AC: #3, #4)
  - [ ] Confirm the checkmark overlay (selected state) and chevron overlay (idle/charging state) still align correctly on the trailing edge of the taller AX5 card.
  - [ ] Confirm the charge-fill background (`GeometryReader`-sized to `proxy.size.width`) still fills correctly during a press-and-hold charge on the taller card.
  - [ ] Confirm the `LayoutMetrics.choiceCardBorderWidth` border still traces the full card edge with no clipping or misalignment.
  - [ ] Record the dated finding in Completion Notes per AC #4.

- [ ] Task 4: Factor the padding pair into a shared `ViewModifier` (AC: #5)
  - [ ] Create a shared `ViewModifier` (e.g. `ActionLabelBreathingRoom` / `.actionLabelBreathingRoom()`, in `ForkedEchoes/Views/DesignSystem/`) that applies `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)`.
  - [ ] Replace the inline padding pair at `BranchArrivalInterstitialView.swift`, `HomeView.swift` (both buttons), and `TutorialView.swift` with the shared modifier.
  - [ ] If Task 1/Task 2 landed `ChoiceCardView.swift` on the same padding-before-frame order safely, replace its padding pair with the shared modifier too; otherwise leave it inline and record why in Completion Notes.
  - [ ] `swiftc -parse` all touched files and run `swift test` to confirm no regression.
  - [ ] Record the dated finding in Completion Notes per AC #4.

## Dev Notes

### This is a verification-first story, same pattern as Story 3.10

Do not assume the fix is purely "copy Story 3.10's two padding lines" — Task 2's consistency check is a genuine open question (the existing horizontal padding's placement is structurally different here, unlike Home/Tutorial's buttons which already matched the established order before this story). Confirm in Simulator, don't guess.

### The exact padding pattern to replicate (Task 1)

`BranchArrivalInterstitialView.swift:120-134` / `HomeView.swift`/`TutorialView.swift` (Story 3.10):

```swift
Text(...)
    .padding(.horizontal, Spacing.medium)
    .padding(.vertical, Spacing.small)
    .frame(...)
```

`ChoiceCardView.swift`'s label currently looks like:

```swift
Text(LocalizedStringKey(option.labelKey))
    .choiceLabelStyle()
    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)
    .padding(.horizontal, Spacing.medium)
```

Task 1's minimum fix is inserting `.padding(.vertical, Spacing.small)` before `.frame(...)`. Task 2 separately evaluates whether the existing `.padding(.horizontal, Spacing.medium)` should move to join it before `.frame(...)`, per the established order — this is not automatic, since ChoiceCardView's structure (overlay-based checkmark/chevron, `GeometryReader` charge-fill background keyed to the label's frame) is more complex than the other three buttons' plain `Button` labels, and moving the horizontal padding could change the frame's measured width in ways the other buttons don't have to account for.

### Why this card is structurally riskier to touch than Story 3.10's buttons

`ChoiceCardView`'s `Text` isn't a standalone `Button` label — it's the base layer of a stack that also has a trailing `.overlay` (checkmark/chevron), a `.background` `GeometryReader` (charge-fill), a second `.background` (surface-raised), a border `.overlay`, `.contentShape(Rectangle())`, and `.accessibilityElement(children: .ignore)` collapsing everything into one element. Changing the label's frame/padding changes the sizing baseline all of those key off. Task 3 exists specifically because Story 3.10's buttons had no such dependents.

### Architecture / design citations

- **Story 3.5** (`3-5-end-to-end-accessibility-validation.md`): originating context for the padding-before-frame fix pattern.
- **Story 3.10** (`3-10-action-button-padding-ax5-and-compact-height-verification.md`): most recent application of the same pattern, including its own Completion Notes documenting per-button/per-axis findings — follow the same itemization convention here.
- **`ChoiceCardView.swift`**: the file under investigation — label composition ~lines 103-121, overlay/background/border ~lines 108-138.
- **`LayoutMetrics.swift`**: `minTapTarget`, `choiceCardBorderWidth`, `Spacing.medium`/`Spacing.small`.
- **project-context.md's Design tokens section**: no new numeric literal is introduced by this story — reuses `Spacing.small`/`Spacing.medium`, already-named constants.

### Project Structure Notes

Files expected to change:
- `ForkedEchoes/Views/StoryChoice/ChoiceCardView.swift` — Task 1's vertical padding addition (confirmed necessary), Task 2's possible horizontal-padding reorder (only if Simulator confirms it's safe), Task 4's shared-modifier adoption (if safe there).
- `ForkedEchoes/Views/StoryChoice/BranchArrivalInterstitialView.swift`, `ForkedEchoes/Views/Home/HomeView.swift`, `ForkedEchoes/Views/Tutorial/TutorialView.swift` — Task 4, replacing their existing inline padding pair with the new shared `ViewModifier`. No behavior change expected at these 3 sites (same two `.padding(...)` calls, just factored out).
- `ForkedEchoes/Views/DesignSystem/` — Task 4, new `ViewModifier` file (or added to an existing DesignSystem file, dev's judgment).

### DRY finding this story closes (AC #5 / Task 4)

Story 3.10's code review deferred a finding: the `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` pair was duplicated verbatim across 4 call sites with no shared abstraction, "worth factoring out if a 5th call site appears" (`deferred-work.md`). This story adds exactly that 5th call site (`ChoiceCardView`), so Task 4 closes the deferred item directly rather than letting it accumulate further. Mark the `deferred-work.md` entry resolved once Task 4 lands.

### Testing Standards Summary (AD-7)

- This is a pure SwiftUI view-layer verification story — no `StoryRunEngine`/engine-logic surface is touched, so no new Swift Testing case is required (AD-7 scope is engine logic only).
- This devcontainer cannot render SwiftUI/UIKit at all — every AC here is manual-verification by nature, same as Story 3.5/3.10.
- After the fix, `swiftc -parse ChoiceCardView.swift` for syntax verification, and run `swift test` to confirm no incidental regression to the engine-logic suite.
- Per project-context.md's process rule: if a code review after this story's manual verification patches `.swift` code, do not advance status to `done` on the strength of the pre-patch verification — leave at `review` and re-request the specific patched check.

## Previous Story Intelligence (Story 3.10)

Story 3.10 is the immediately prior application of this exact bug fix pattern to a different set of buttons — its Completion Notes (itemized per-button, per-axis, after a code-review round asked for that level of detail) are the template to follow here: don't summarize with one generic sentence, itemize each task's finding with its date. Story 3.10 also established that "apply the padding pattern" and "was it actually needed on this axis" are separate questions worth recording separately — Task 1 here should record whether the crowding was vertical-only (matching Story 3.10's finding on Home/Tutorial) or something else.

## Git Intelligence Summary

`ChoiceCardView.swift` last received an accessibility-audit fix in Story 3.5 (2026-08-08, `LocalizedStringKey` type annotation and `.accessibilityElement(children: .ignore)` collapsing) — no story since has touched its padding/frame layout. This story is the first to address the vertical-crowding bug class on this specific file.

## Project Context Reference

Full rules loaded from `_bmad-output/project-context.md` as a persistent fact for this workflow run — see especially: the Environment section (no SwiftUI/UIKit rendering in this devcontainer), the Design tokens section (reuse named constants, no inline literals), the Dynamic Type & Accessibility section (44pt minimum tap target must not shrink), and the "code review patches after verification" Process Agreement.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
