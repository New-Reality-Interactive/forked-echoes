---
baseline_commit: 7c460365f30acb0aa48150d916a9519613c1d954
---

# Story 3.10: Action Button Padding — AX5 & Compact-Height Verification

Status: done

## Story

As a developer,
I want Home/Tutorial's action buttons and the branch-arrival interstitial's Continue button to reserve real breathing room around their label at the largest accessibility Dynamic Type size and in compact-height (landscape) layouts,
so that no action button's text ever crowds its own edge or forces content past its available headroom, matching the fix Story 3.5 already applied to this same button on the interstitial's gated path.

## Acceptance Criteria

1. **Given** Home and Tutorial's action buttons (`HomeView.swift`, `TutorialView.swift`) at the largest accessibility Dynamic Type size (AX5), **when** inspected in Xcode/Simulator, **then** confirm whether the button's label crowds the button's own edge with no breathing room (the same bug class Story 3.5 fixed on the interstitial Continue button) — if so, apply the same explicit `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` pattern Story 3.5 used there; if not, record the negative result and make no code change. [Source: epics.md#Story-3.10, AC1]
2. **Given** the branch-arrival interstitial's Continue button with Story 3.5's `.padding(.vertical, Spacing.small)` applied, **when** viewed on a compact-height (landscape) device at ordinary (non-accessibility) Dynamic Type, where the layout has no `ScrollView` escape route, **then** confirm the added padding's extra required height still fits within `illustrationMaxHeightFractionCompact`'s headroom without clipping or forcing the button off-screen — if it doesn't fit, adjust the illustration's height fraction or the button's padding to restore fit; if it does fit, record the confirmation and make no code change. [Source: epics.md#Story-3.10, AC2]
3. **And** a manual-verification AC: in Xcode/Simulator, record the AX5 Home/Tutorial button check and the compact-height/landscape Continue button check as two separate dated results in the story's Completion Notes List, regardless of whether either required a code change. [Source: epics.md#Story-3.10, AC3 — project-context.md Process Agreement]

## Background: Why This Story Exists

Added via code review of Story 3.5 (end-to-end accessibility validation), 2026-08-08 — see `deferred-work.md`'s two corresponding entries (lines 159-160), both now closed by this story.

Story 3.5's Task 2 found and fixed a real bug: the branch-arrival interstitial's Continue button (`BranchArrivalInterstitialView.swift:120-134`) had only `.frame(minWidth:, minHeight:)` around its label — at AX5, the heavy, uppercase text grows to fill that frame exactly, leaving no breathing room between the text and the button's background edges. The fix was explicit `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` inside the label, ahead of the `.frame(...)` call (see `BranchArrivalInterstitialView.swift:129-131` and its comment citing "found via Simulator AX5 walkthrough, Story 3.5").

That code review flagged two things Story 3.5 never actually checked, both instances of the same bug class:

1. **`HomeView.swift`/`TutorialView.swift`'s action buttons share the exact same unpadded shape** the interstitial button had *before* Story 3.5's fix — `.frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)` directly on the label `Text`, no explicit padding (see `HomeView.swift:43-45,49-51` and `TutorialView.swift:62-64`). Story 3.5's Task 2 checklist covered "clipped/truncated text" across every screen but never specifically checked for the *missing-breathing-room* variant of the bug — a button can render with zero clipping/truncation and still have its text crowding the edge, since these are two different symptoms of two different geometry problems. This has never actually been checked at AX5.
2. **Story 3.5's own fix was never checked against the interstitial's compact-height (landscape) layout path.** `BranchArrivalInterstitialView`'s `illustrationMaxHeightFraction` computed property (`BranchArrivalInterstitialView.swift:141-145`) already picks a smaller illustration-height fraction in compact height (`LayoutMetrics.interstitialIllustrationMaxHeightFractionCompact` = 0.35 vs. 0.5 ordinary) specifically to leave room for the caption+button below it — added in Story 2.9 to prevent the exact "button pushed off-screen" failure mode this view has no `ScrollView` fallback for at ordinary Dynamic Type (the `ScrollView` only mounts when `dynamicTypeSize.isAccessibilitySize`, see `BranchArrivalInterstitialView.swift:70-75`). Story 3.5's new vertical padding on the Continue button adds height requirements to that same non-scrolling layout, but nothing has confirmed the 0.35 fraction still leaves enough headroom now that the button is taller.

Both are framed as "verify, then apply Story 3.5's own padding pattern if actually broken" — this is not a known bug being fixed blind, it's confirming whether the gap Story 3.5 left unverified is actually a problem, per each AC's own "if not, record the negative result and make no code change" language.

## Tasks / Subtasks

- [x] Task 1: Manual Xcode/Simulator check — Home/Tutorial action buttons at AX5 (AC: #1, #3)
  - [x] Set the Simulator to the largest accessibility Dynamic Type category (AX5, same category used for Story 3.5's original interstitial-button finding).
  - [x] Inspect `HomeView`'s two action buttons ("Start Story"/"Resume Story" via `.primaryAction`, "Start Tutorial" via `.secondaryAction`) — confirm whether the label text crowds the button's edge with no visible breathing room, the same symptom Story 3.5 found and fixed on the interstitial Continue button (not truncation/clipping — this is specifically about the label filling the `.frame(minHeight:)` exactly with no margin around it).
  - [x] Inspect `TutorialView`'s single action button ("Start Story"/"Resume Story" via `.primaryAction`) the same way.
  - [x] If either screen's button(s) show the crowding symptom: apply `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` to the button's label `Text`, positioned before the existing `.frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)` call — mirror `BranchArrivalInterstitialView.swift:129-131`'s exact modifier order (padding first, then frame) so the padding is measured as part of the label's intrinsic size before the frame's minimums apply.
  - [x] If neither screen's buttons show the symptom: make no code change. Either way, record the dated finding in Completion Notes per AC #3 (both the check and its outcome, not just "looked fine").

- [x] Task 2: Manual Xcode/Simulator check — interstitial Continue button in compact-height (landscape) (AC: #2, #3)
  - [x] Rotate the Simulator to landscape (compact `verticalSizeClass`) at ordinary (default, non-accessibility) Dynamic Type — this is the specific layout path with no `ScrollView` escape route (`BranchArrivalInterstitialView.swift:70-75`'s `if dynamicTypeSize.isAccessibilitySize` branch only mounts `ScrollView` at accessibility sizes; this check is deliberately at an ordinary size where it stays a plain `VStack`).
  - [x] Trigger the gated (first-visit) branch-arrival interstitial so the Continue button renders (`onContinue` non-nil path — see `BranchArrivalInterstitialView.swift:115-135`).
  - [x] Confirm the illustration + caption-bar accent + caption + Continue button (with its existing `.padding(.vertical, Spacing.small)` from Story 3.5) all fit within the available height without clipping, without the button being pushed off-screen, and without content overflowing past `illustrationMaxHeightFractionCompact`'s (0.35) allotted headroom.
  - [x] If it doesn't fit: adjust either `LayoutMetrics.interstitialIllustrationMaxHeightFractionCompact` (reduce the fraction further) or the Continue button's padding to restore fit — record which adjustment was made and why in Completion Notes.
  - [x] If it does fit: make no code change. Either way, record the dated finding in Completion Notes per AC #3.

## Dev Notes

### This is a verification-first story — most of the work may be recording negative results

Both ACs are structured as "check first, fix only if actually broken." Do not preemptively apply Story 3.5's padding pattern to `HomeView`/`TutorialView` without first confirming the crowding symptom is actually present at AX5 in Simulator — this devcontainer cannot render SwiftUI at all (see Testing Standards Summary below), so there is no way to determine the outcome without the user's own Simulator check. If the check comes back clean, the correct action is a Completion Notes entry recording that, not a speculative code change.

### The exact padding pattern to replicate, if needed (Task 1)

`BranchArrivalInterstitialView.swift:120-134`:

```swift
Button(action: { ... }) {
    Text(LocalizedStringKey("storyChoice.interstitial.continue"))
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)
}
.buttonStyle(.continueAction)
```

`HomeView.swift`'s two buttons and `TutorialView.swift`'s one button currently look like:

```swift
Text(primaryActionLabel)
    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
```

If Task 1 finds the crowding symptom, the fix is inserting the same two `.padding(...)` calls between the `Text(...)` and its existing `.frame(...)` call — `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` — on whichever button(s) actually show it. Home/Tutorial's buttons use `maxWidth: .infinity` (not `minWidth:`, since they span the full action-stack width per `LayoutMetrics.actionStackMaxWidth`) — keep that difference; only add the padding, don't otherwise reshape the frame call.

### Why Home/Tutorial's buttons might behave differently than the interstitial's did

The interstitial's Continue button uses `minWidth`/`minHeight` (content can grow the frame past 44pt). Home/Tutorial's buttons use `maxWidth: .infinity` (fixed width, full row) with only `minHeight:` free to grow. It's possible the extra horizontal room from spanning the full row already gives the label enough incidental breathing room that the vertical-crowding symptom doesn't reproduce the same way — this is exactly why Task 1 is a genuine check, not a foregone conclusion. Don't assume the AC1 finding will mirror Story 3.5's; record whatever Simulator actually shows.

### `illustrationMaxHeightFractionCompact`'s headroom math (Task 2)

`LayoutMetrics.swift:105-111`'s doc comment explains why this constant exists and why it's smaller in compact height (0.35) than ordinary height (0.5) — Story 2.9 added it specifically because this view has no `ScrollView` fallback at ordinary Dynamic Type in any orientation, so the caption+button below the illustration must always fit in whatever height remains. Story 3.5's later addition of `.padding(.vertical, Spacing.small)` (8pt top + 8pt bottom = 16pt) to the Continue button is new required height inside that same fixed budget that didn't exist when 0.35 was chosen — this task confirms whether that 16pt still fits or has pushed the layout past its margin. If an adjustment is needed, prefer shrinking `interstitialIllustrationMaxHeightFractionCompact` over reducing the button's padding — the padding is itself Story 3.5's fix for a real found bug (button-text crowding) and shrinking it back would reopen that.

### Architecture / design citations

- **Story 3.5** (`3-5-end-to-end-accessibility-validation.md`): originating context for the Continue button's existing padding fix and this story's two verification gaps. Read its Task 2 for the original AX5 finding and fix.
- **`LayoutMetrics.swift`**: `minTapTarget`, `interstitialIllustrationMaxHeightFraction`/`...Compact`, `Spacing.medium`/`Spacing.small` — all referenced by this story's tasks.
- **project-context.md's Design tokens section**: any new/adjusted numeric literal (e.g. a changed height fraction) must trace to a named constant, not an inline literal — if Task 2 requires an adjustment, update the existing named constant rather than introducing a bare number at the call site.
- **project-context.md's Landscape/Orientation (AD-8) section**: Task 2's compact-height check is a `verticalSizeClass`-driven layout path, detected the same way this codebase always does (`.compact` = landscape) — no new orientation-detection mechanism is introduced by this story.

### Project Structure Notes

Files that may change (only if Task 1 or Task 2's check finds an actual problem):
- `ForkedEchoes/Views/Home/HomeView.swift` — Task 1, only if AX5 crowding is confirmed there.
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` — Task 1, only if AX5 crowding is confirmed there.
- `ForkedEchoes/Views/StoryChoice/BranchArrivalInterstitialView.swift` — Task 2, only if compact-height headroom is confirmed insufficient (button padding adjustment).
- `ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` — Task 2, only if the illustration height fraction needs adjusting (preferred fix over shrinking the button's padding).

It is entirely possible this story ships with zero `.swift` changes and two negative-result Completion Notes entries — that is a fully valid outcome per both ACs' own "if not... make no code change" language.

### Testing Standards Summary (AD-7)

- This is a pure SwiftUI view-layer verification story — no `StoryRunEngine`/engine-logic surface is touched or expected to be touched, so no new Swift Testing case is required (AD-7 scope is engine logic only; there is no UI test target in this project — project-context.md Testing section).
- This devcontainer cannot render SwiftUI/UIKit at all (project-context.md Environment section) — every AC here is manual-verification by nature, same as Story 3.5. There is no engine-logic path through either AC. Do not attempt to fabricate a Swift Testing case for either check.
- If Task 1 or Task 2 does make a code change, `swiftc -parse` the touched file(s) for syntax verification, and run `swift test` to confirm no incidental regression to the engine-logic suite (unrelated surface, but cheap to re-confirm per this codebase's existing convention).
- Per project-context.md's process rule: if a code review after this story's manual verification patches `.swift` code, do not advance status to `done` on the strength of the pre-patch verification — leave at `review` and re-request the specific patched check.

## Previous Story Intelligence (Story 3.9)

Story 3.9 (Run-Options Button Recede-on-Scroll) is Epic 3's immediately prior story — a different bug class (opacity/scroll-state, not padding/headroom) with no direct code overlap with this story's files. Two process patterns carry forward directly: (1) Completion Notes should be itemized per task/check, dated, one line per confirmed item, not a single generic paragraph (project-context.md's "no generic all-good sentence" Process Agreement, reinforced again by 3.9's own Completion Notes structure); (2) a code review that patches `.swift` code after manual verification already happened must not let the story advance to `done` on the strength of the pre-patch verification — 3.9 itself needed a re-verification round after its code review patched two files. This story is even more exposed to that risk than most, since both its ACs are explicitly "verify, maybe patch" in one pass — if Task 1 or Task 2 finds and fixes a real issue, make sure the recorded Completion Notes result reflects the *post-fix* Simulator check, not a pre-fix one.

## Git Intelligence Summary

Most recent commits are Story 3.9's merge (recede-on-scroll feature + code-review fixes) and a story-grooming update to `epics.md`/`sprint-status.yaml` adding Stories 3.10 and 3.11. No commit touches `HomeView.swift`, `TutorialView.swift`, or `BranchArrivalInterstitialView.swift` since Story 3.5 (`.padding(.vertical, Spacing.small)`) and Story 2.9 (interstitial height-fraction logic) respectively — this story is the first to potentially touch either area since those landed.

## Project Context Reference

Full rules loaded from `_bmad-output/project-context.md` as a persistent fact for this workflow run — see especially: the Environment section (no SwiftUI/UIKit rendering in this devcontainer, so both this story's ACs are Simulator-only and cannot be locally verified beyond `swiftc -parse`), the Design tokens section (any adjusted numeric literal must stay a named constant, not an inline literal), the Dynamic Type & Accessibility section (44pt minimum tap target is a day-one baseline; this story's padding work must not shrink the tap target below that if applied), and the "code review patches after verification" Process Agreement (governs status handling if a code-review round patches this story's files post-verification).

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- 2026-08-08 — **Task 1 (AC #1), CONFIRMED bug present, itemized per button:** User's Simulator check at AX5, checked individually:
  - `HomeView`'s primary action button ("Start Story"/"Resume Story", `.primaryAction`): vertical crowding confirmed (label filled `minHeight` with no breathing room top/bottom); horizontal was not crowded.
  - `HomeView`'s secondary action button ("Start Tutorial", `.secondaryAction`): same result — vertical crowding confirmed, horizontal not crowded.
  - `TutorialView`'s primary action button ("Start Story"/"Resume Story", `.primaryAction`): same result — vertical crowding confirmed, horizontal not crowded.
  - All three buttons received the full `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` pattern per AC #1's literal instruction to apply "the same explicit ... pattern Story 3.5 used" — the horizontal component was not independently confirmed necessary (horizontal was fine pre-fix on all three), but is applied for pattern consistency with `BranchArrivalInterstitialView.swift`'s existing Continue button and does no harm (these buttons already have generous horizontal room via `maxWidth: .infinity`). Only the vertical component is fixing a confirmed bug; the horizontal component is precautionary/pattern-matching, not itself fixing an observed defect.
- 2026-08-08 — **Task 2 (AC #2), CONFIRMED no code change needed:** User's Simulator check in landscape (compact-height) at ordinary Dynamic Type confirmed the interstitial's illustration + caption + Continue button (with Story 3.5's padding) all fit within `illustrationMaxHeightFractionCompact`'s headroom without clipping or the button being pushed off-screen. No adjustment made.
- 2026-08-08 — **Post-fix verification note:** `swiftc -parse` confirmed both edited files are syntactically valid; `swift test` (89 tests, 6 suites) passed with no regressions. Per this story's own Dev Notes, the Task 1 code change should be re-confirmed in Simulator against the actual patched buttons (not just the original crowding finding) before the story advances past `review`.
- 2026-08-08 — **Post-fix Simulator re-verification, CONFIRMED:** user re-checked the patched buttons (HomeView primary/secondary, TutorialView primary) directly in Simulator — all three look good. This satisfies the outstanding re-verification gate; story advances to `done`.
- 2026-08-08 — **Out-of-scope regression reported during manual testing:** user observed that tapping on an ending page no longer navigates to the memory page. `swift test`'s engine-logic suite (including `advancePageFromEndingTransitionsPhaseToMemory`) passed, so this is not an engine-logic regression and is unrelated to this story's files (`HomeView.swift`, `TutorialView.swift`, `BranchArrivalInterstitialView.swift`, `LayoutMetrics.swift` were the only files in scope; none of the ending/memory-transition UI wiring was touched here). Not investigated or fixed as part of Story 3.10 — flagged to the user for separate tracking (new story or `deferred-work.md` entry).

### File List

- `ForkedEchoes/Views/Home/HomeView.swift` — added `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` to both action buttons' labels (Task 1, AX5 crowding confirmed).
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` — added `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` to the action button's label (Task 1, AX5 crowding confirmed).

### Review Findings

- [x] [Review][Decision] Completion Notes don't itemize per-button verification, and don't record whether the horizontal-padding component was independently confirmed necessary — **Resolved 2026-08-08:** user confirmed all three buttons (HomeView primary, HomeView secondary, TutorialView primary) showed vertical crowding at AX5; horizontal was not crowded on any. Completion Notes List rewritten item-by-item to reflect this; horizontal padding is retained per AC #1's literal "apply the same pattern" instruction but is now documented as pattern-consistency, not an independently-confirmed fix.
- [x] [Review][Defer] Padding modifier pair duplicated verbatim across 4 call sites — deferred, pre-existing pattern [ForkedEchoes/Views/DesignSystem/ButtonStyles.swift, ForkedEchoes/Views/Home/HomeView.swift:47-48,56-57, ForkedEchoes/Views/Tutorial/TutorialView.swift:66-67] — `.padding(.horizontal, Spacing.medium).padding(.vertical, Spacing.small)` is now repeated identically at 4 call sites (the pre-existing `BranchArrivalInterstitialView` Continue button plus this story's 3 new ones), unfactored into a shared `ViewModifier` or folded into the `ButtonStyle`s themselves. Low severity and consistent with the codebase's existing (unfactored) precedent at the interstitial button — not blocking, but a reuse opportunity if a 5th call site appears.
