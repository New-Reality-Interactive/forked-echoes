---
baseline_commit: 4875900
---

# Story 2.12: Run-Options Sheet — Fix Popover Presentation & Missing Cancel

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want the run-options control to present as the native bottom action sheet with a visible Cancel, exactly as designed,
so I always have a clearly-labeled way to back out without accidentally triggering Exit or Restart.

*(Bug surfaced via user-reviewed Simulator screenshot, 2026-08-03 — `Simulator Screenshot - iPhone 17 - 2026-08-03 at 08.14.12.png`, taken on `RunOptionsButton`'s options dialog. UX-DR11 specifies a "platform-native action sheet" with three options — "Exit to Home", "Restart This Run", "Cancel" — and `RunOptionsButton.swift` (Story 2.7) declares an explicit `Button("runOptions.cancel", role: .cancel)` in both its options dialog and its restart-confirmation dialog. The screenshot instead shows a popover anchored to the ellipsis button (callout arrow, not a bottom sheet) with only two rows — "Exit to Home" and "Restart This Run" — no Cancel visible. iOS auto-suppresses an explicit `.cancel`-role button only when a dialog renders in popover style (regular horizontal size class or an anchor-based presentation), since tap-outside-to-dismiss already covers that case there — so the missing Cancel is a symptom of the wrong presentation style, not two independent bugs. `TARGETED_DEVICE_FAMILY` is iPhone-only (1) and no `.popover`/`presentationCompactAdaptation`/size-class override exists anywhere in the codebase, so the root cause is not yet understood and needs investigation, not just a style override.)*

## RESOLVED CONFLICT — 2026-08-04

The first implementation attempt (`.presentationCompactAdaptation(.none)`, targeting a horizontal-size-class hypothesis) was verified **not to work** — user-provided Simulator screenshot (`Simulator Screenshot - iPhone 17 - 2026-08-03 at 21.58.04.png`) showed the identical popover-with-arrow, no-Cancel-row presentation after the fix was applied, in what was not a landscape/regular-size-class scenario.

Follow-up research (WebSearch/WebFetch against Apple WWDC 2025 Session 284, "Build a UIKit app with the new design," and multiple Apple Developer Forums threads) found the real, confirmed cause: **starting in iOS 26, `confirmationDialog`/`actionSheet` presentations triggered from an ordinary button (not a `UIBarButtonItem` in a navigation bar) anchor to that button by default on iPhone** — the same button-anchored popover style iPadOS has always used. This is intentional Apple platform behavior (part of the "Liquid Glass" redesign), not a bug, and this app builds against the iOS 26 SDK (project-context.md).

User decision, 2026-08-04: accept the anchored-popover presentation as the new "platform-native" meaning of UX-DR11 for this control, rather than fighting the platform to force the old bottom-sheet style. UX-DR11 amended in `epics.md` accordingly. AC #1 below is revised to match. The original AC #1/#3 (root-cause and force a bottom sheet) are struck through but left visible for history; AC #2 (visible Cancel row) is unchanged and *is* independently fixable — see below.

## Acceptance Criteria

1. **Given** `RunOptionsButton`'s options `confirmationDialog` or its restart-confirmation `confirmationDialog`
   **When** invoked on an iPhone simulator or device, in portrait or landscape
   **Then** ~~it presents as a bottom-anchored native action sheet (UX-DR11), never as a button-anchored popover~~ **(REVISED 2026-08-04)** it presents as iOS 26's button-anchored popover-style action sheet, which is the accepted "platform-native" presentation for a non-nav-bar-anchored control as of iOS 26 (UX-DR11, amended)

2. **Given** either of `RunOptionsButton`'s two confirmation dialogs
   **When** presented
   **Then** the explicit `runOptions.cancel` row is visible and dismisses the dialog with no side effects, in addition to the existing "Exit to Home"/"Restart This Run" rows

3. ~~**Given** the popover presentation seen in the 2026-08-03 screenshot **When** root-caused **Then** the investigation identifies why this build resolved a regular/anchor-based presentation despite `TARGETED_DEVICE_FAMILY = 1` and no popover-forcing code, and the fix addresses that cause (not just a superficial style override) — findings recorded in the story's Completion Notes List (project-context.md Process Agreement)~~ **(REVISED 2026-08-04)** **Given** the popover presentation seen in the 2026-08-03 screenshots **When** root-caused **Then** the investigation identifies the true cause (iOS 26's new default anchored-popover presentation for confirmationDialog on iPhone, confirmed via WWDC 2025 Session 284) and records it, and the fix separately addresses the one part of the original bug report that remains a genuine defect under the accepted presentation style — the missing Cancel row — findings recorded in the story's Completion Notes List (project-context.md Process Agreement)

4. **And** a manual-verification AC: in Xcode/Simulator, on an iPhone target, invoke both dialogs and confirm all three rows are visible and functional ("Exit to Home"/"Restart This Run", "Cancel") in the anchored-popover presentation, in both portrait and landscape — tapping "Cancel" or tapping outside the popover both dismiss with no side effects. Result + date recorded in the story's Completion Notes List

## Tasks / Subtasks

- [x] Task 1: Root-cause the popover presentation (AC #3)
  - [x] Read `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` and `RootView.swift` in full — no intermediate container or size-class override anywhere in the app's own view tree
  - [x] **First hypothesis (horizontal size class / landscape) — tried, verified wrong.** Applied `.presentationCompactAdaptation(.none)` on both dialogs; user-provided post-fix Simulator screenshot showed the identical popover-with-arrow, no-Cancel presentation, disproving the hypothesis (see RESOLVED CONFLICT banner above)
  - [x] **Second investigation, via WebSearch/WebFetch against Apple's own documentation and developer forums:** confirmed root cause is iOS 26's platform-level change to `confirmationDialog`/`actionSheet` presentation on iPhone — it now anchors to its triggering button by default (matching iPadOS's long-standing popover behavior), per WWDC 2025 Session 284 ("Build a UIKit app with the new design"). This app builds against the iOS 26 SDK. Not a bug in this codebase; an intentional Apple platform/design change with no publicly documented way to force the old bottom-sheet style for a non-nav-bar-anchored button.
  - [x] Separately confirmed (long-documented `UIAlertController` behavior since iOS 8): a popover-style action sheet always auto-suppresses actions with `role: .cancel` specifically, since tap-outside-to-dismiss already covers that case — this is *why* the Cancel row was missing, and it's independently fixable without touching presentation style
  - [x] Recorded in Dev Agent Record → Completion Notes per AC #3

- [x] Task 2: Fix the missing Cancel row within the accepted anchored-popover presentation (AC #2)
  - [x] Reverted the ineffective `.presentationCompactAdaptation(.none)` modifier from both `confirmationDialog` calls in `RunOptionsButton.swift`
  - [x] Changed both `Button("runOptions.cancel", role: .cancel) {}` declarations to `Button("runOptions.cancel") {}` (dropped the `.cancel` role) — a plain button is not subject to popover-style auto-suppression, so it now stays visible as a normal row in both dialogs
  - [x] Updated `RunOptionsButton.swift`'s header comment to document the iOS 26 finding and the actual fix, replacing the now-inaccurate "confirmationDialog... still renders as a native action sheet on iPhone" claim
  - [x] Fix scoped entirely to `RunOptionsButton.swift` — no changes to `StoryChoiceView.swift`/`RootView.swift`
  - [x] Amended `epics.md`'s UX-DR11 entry with a 2026-08-04 addendum recording this decision (accepted platform behavior + Cancel-role fix), per project-context.md's "Resolving doc conflicts" convention

- [x] Task 3: Manual verification (AC #4)
  - [x] Request from user per project-context.md's Process Agreement (this devcontainer has no Xcode/Simulator) — invoke both dialogs and confirm: presentation is the anchored popover (now accepted as correct), all three rows are visible including a functional plain "Cancel" row, and both tapping Cancel and tapping outside the popover dismiss with no side effects, in portrait and landscape
  - [x] Record result + date in Completion Notes List once reported back

## Dev Notes

### What already exists — do not re-create any of this

This is a narrowly-scoped bug fix, not a redesign. `RunOptionsButton.swift`'s structure, labels, and localization keys are all correct as shipped by Story 2.7 — only the presentation *style* is wrong. No new UI, no new options, no new localization keys.

`ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` (57 lines, read in full before editing):
- Lines 20-56: `body` — a `Button` (ellipsis icon) with two `.confirmationDialog` modifiers chained after it: the options dialog (lines 37-45, `isPresented: $isPresentingOptions`) and the restart-confirmation dialog (lines 46-55, `isPresented: $isPresentingRestartConfirmation`)
- Line 44 / Line 54 (pre-fix): `Button("runOptions.cancel", role: .cancel) {}` — was already present in both dialogs; the fix (Task 2) drops the `.cancel` role, since that role specifically is what popover-style presentations auto-suppress
- Lines 62-67: `RunOptionsButtonStyle` — custom `ButtonStyle`, unrelated to this bug, do not touch
- Comment block (lines 9-12, pre-fix) claimed "`.confirmationDialog`... still renders as a native action sheet on iPhone" — this premise is exactly what this story's screenshot disproved on iOS 26; Task 2 replaces this comment with the accurate iOS 26 finding (anchored-popover is now the default, confirmed via WWDC 2025 Session 284) and the actual fix rationale

`ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` line 153-163: the one production call site, `.overlay(alignment: .topTrailing) { RunOptionsButton(onExitToHome:, onRestartRun:) }`, inside `readingComposition` — itself reached only when `engine.phase != .interstitial` (i.e., the ordinary reading/choice composition, not the branch-arrival interstitial, which explicitly excludes this control per Story 2.6/2.9). This view is presented via `RootView.swift`'s `.fullScreenCover`, not a `NavigationStack` push (AD-5) — the most likely structural factor behind the popover misroute per Task 1's investigation lead.

**Note:** `TutorialView.swift` no longer has a `RunOptionsButton` call site as of Story 2.11 (removed entirely, not just changed) — `StoryChoiceView.swift` is the only production usage today. `RunOptionsButton.swift`'s own `#Preview` (lines 69-71) is a second, non-production call site with no `.fullScreenCover` wrapper — useful as a quick sanity check but not authoritative for reproducing the bug, since the bug is specifically tied to the real `.fullScreenCover` presentation context.

### Investigation-first approach (AC #3)

This story's epic entry is explicit that the fix must address a *root cause*, not apply a superficial style override without understanding why. Practical investigation approach for this devcontainer (no Xcode/Simulator here — see Environment section below):
1. Read `RootView.swift` in full to understand the exact presentation hierarchy `RunOptionsButton` lives inside (`.fullScreenCover` nesting, any `.environment()` applications, any container views between the cover's root and `StoryChoiceView`).
2. Compare against Apple's known SwiftUI behavior: `confirmationDialog`/`actionSheet` on iPhone should always be sheet-style; popover-style is a `UIUserInterfaceIdiom.pad` or Mac Catalyst behavior, or can be forced by `.presentationCompactAdaptation(.popover)`. Since neither applies here, the popover routing is either (a) an iOS SDK-version-specific bug specifically involving `.fullScreenCover`-nested presentation contexts, or (b) some other environment/trait leak in the view hierarchy.
3. Since this devcontainer cannot build/run the app, the investigation is necessarily code-review-based (reading the presentation hierarchy, checking Apple release notes / known issues if research tools are available) plus the fallback described in Task 1 if a definitive cause can't be nailed down without live Simulator experimentation. Be explicit in Completion Notes about which of these paths was taken.
4. If web research tools are available, check for known Apple Feedback/StackOverflow reports of `confirmationDialog` in `.fullScreenCover` rendering as popover on iPhone in iOS 26 — this is a plausible, previously-reported class of SwiftUI bug and would directly corroborate the investigation lead above.

### Architecture compliance (AD-5)

- **AD-5**: the Story session is presented via `.fullScreenCover` (owned by `RootView`) — this story does not change that presentation mechanism, it fixes a secondary dialog's presentation *within* that context. Do not convert the Story session itself to a `NavigationStack` push as a side effect of chasing this bug; that would reintroduce the swipe-gesture conflict AD-5 was written to avoid (see project-context.md's Navigation section).
- No engine-logic changes (`StoryRunEngine`, `RunSnapshot`, `Engine/`) — this is a View-layer presentation bug only.

### Testing standards summary

- No engine-logic code is touched (AD-7 scope is `StoryRunEngine`/`RunSnapshot` and similar `Engine/` types) — this story adds **zero** Swift Testing cases. Run `swift test` anyway to confirm nothing broke (60/60 as of Story 2.11).
- No UI test target exists in this project (project-context.md's Testing section) — SwiftUI dialog presentation style is verified manually in Simulator only (AC #4). Don't add a UI test as a side effect of this story.
- `swiftc -parse` on the edited `RunOptionsButton.swift` (and any other file touched per Task 2) for genuine syntax verification — this devcontainer has no Xcode/SwiftUI module resolution.

### Project Structure Notes

- Expected modified: `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift`. Possibly also `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` or `ForkedEchoes/Views/RootView.swift` **only if** Task 1's investigation proves the true cause lives there rather than in `RunOptionsButton.swift` itself — document why if so.
- Explicitly **not** modified: any `Engine/` file, `Resources/Localizable.xcstrings` (no new/changed/removed keys — `runOptions.cancel` and friends already exist correctly), `ForkedEchoesTests/` (no new tests expected — see Testing standards above).
- No new files anticipated.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.12: Run-Options Sheet — Fix Popover Presentation & Missing Cancel]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR11] (original "platform-native action sheet" spec this story restores compliance with)
- [Source: _bmad-output/project-context.md#Navigation] (`.fullScreenCover` for the Story session, AD-5, and why — the structural fact most likely implicated in this bug)
- [Source: _bmad-output/project-context.md#Environment] (this devcontainer's Xcode/Simulator limitations — investigation here is code-review-based, not empirical)
- [Source: _bmad-output/project-context.md#Process Agreements] (actively request user's Xcode/Simulator verification at session end)
- [Source: ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift] (the file with the bug — both `confirmationDialog` modifiers)
- [Source: ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift] (the one production call site, line 153, inside `.fullScreenCover`-presented content)
- [Source: ForkedEchoes/Views/RootView.swift] (owns the `.fullScreenCover` presentation — read in full during Task 1's investigation)
- [Source: _bmad-output/implementation-artifacts/2-11-tutorial-navigation-and-fixed-actions-layout.md] (previous story in Epic 2 — confirms `RunOptionsButton.swift` is unchanged since Story 2.7 and `TutorialView.swift` no longer has a call site)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-5]
- [Source: WWDC 2025 Session 284, "Build a UIKit app with the new design" — https://developer.apple.com/videos/play/wwdc2025/284/] (confirms iOS 26's action-sheet-anchors-to-source-view-on-iPhone platform change)
- [Source: Apple Developer Forums thread 803824, "How to get an anchored action sheet without the popover..." — https://developer.apple.com/forums/thread/803824] (confirms no supported way to force the pre-iOS-26 bottom-sheet style for a non-nav-bar-anchored button)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swiftc -parse ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift` — clean, no syntax errors (checked after both the initial and corrected fix).
- `swift test` from repo root — 60/60 passing, no regressions, after both fix attempts (unchanged from Story 2.11's baseline; this story touches no `Engine`/`Content` code).
- WebSearch/WebFetch against Apple WWDC 2025 Session 284 and multiple Apple Developer Forums threads — confirmed the real root cause (see Completion Notes).
- Repo-wide `grep -rn "presentationCompactAdaptation\|confirmationDialog"` across `ForkedEchoes/` — confirmed both `confirmationDialog` call sites are in `RunOptionsButton.swift` only.

### Completion Notes List

- Task 1 (AC #3 root cause) — **first attempt, disproven:** hypothesized the popover was caused by `confirmationDialog` resolving to `.regular` horizontal size class on Plus/Pro-Max-class iPhones in landscape (project-context.md documents this same size-class quirk in a different context). Applied `.presentationCompactAdaptation(.none)` as the fix. User reported no change and provided a post-fix Simulator screenshot (`Simulator Screenshot - iPhone 17 - 2026-08-03 at 21.58.04.png`) confirming the identical popover-with-arrow, no-Cancel presentation persisted — disproving the hypothesis.
- Task 1 (AC #3 root cause) — **second attempt, confirmed via research:** used WebSearch/WebFetch to research the actual cause against Apple's own documentation rather than guessing further. Found: starting in iOS 26, `confirmationDialog`/`actionSheet` presentations triggered from an ordinary button (not a `UIBarButtonItem` in a navigation bar) anchor to that button by default on iPhone, matching iPadOS's long-standing popover behavior — confirmed via WWDC 2025 Session 284 ("Build a UIKit app with the new design": "Starting in iOS 26, [action sheets] behave the same on iPhone [as iPad], appearing directly over the originating view"). This app builds against the iOS 26 SDK (project-context.md), so it's squarely affected. Multiple Apple Developer Forums threads (e.g. `developer.apple.com/forums/thread/803824`) confirm developers have found no supported way to force the old bottom-sheet style for a non-nav-bar-anchored control on iOS 26 — the anchored-without-arrow treatment is limited to `UIBarButtonItem`s in a navigation bar. Given this, and per the user's 2026-08-04 decision (see RESOLVED CONFLICT banner), the anchored-popover presentation is accepted as the new "platform-native" meaning of UX-DR11 for this control, rather than continuing to fight the platform.
- Task 1 (AC #3 root cause) — **the missing Cancel row, separately diagnosed:** this is long-documented `UIAlertController` behavior, unchanged since iOS 8 — a popover-style action sheet always auto-suppresses any action with `role: .cancel`, since tap-outside-to-dismiss already covers that case in a popover. This part of the original bug report remains a genuine, independently-fixable defect even after accepting the anchored-popover presentation style.
- Task 2 (AC #2 fix): reverted the disproven `.presentationCompactAdaptation(.none)` modifier. Changed both `Button("runOptions.cancel", role: .cancel) {}` declarations in `RunOptionsButton.swift` to `Button("runOptions.cancel") {}` — dropping the `.cancel` role means the row is no longer subject to popover-style auto-suppression, since that suppression targets the `.cancel` role specifically, not buttons generically. This is a one-line, low-risk, easily-verifiable change consistent with 17 years of documented `UIAlertController` popover behavior. Updated the file's header comment to document the iOS 26 finding and remove the now-inaccurate claim that `confirmationDialog` "still renders as a native action sheet on iPhone." No changes to `StoryChoiceView.swift`/`RootView.swift`. Amended `epics.md`'s UX-DR11 entry with a 2026-08-04 addendum recording the accepted-platform-behavior decision, per project-context.md's "Resolving doc conflicts" convention.
- Task 3: manual verification requested from user (second round) — this devcontainer has no Xcode/Simulator, so AC #4's revised checklist (confirm the anchored popover now shows all three rows including a functional plain "Cancel," and both Cancel-tap and tap-outside dismiss cleanly, in portrait and landscape) was handed off. **Result, 2026-08-04: confirmed by user** — both dialogs show all three rows including a visible, functional "Cancel"; tapping Cancel dismisses cleanly with no side effects; verified in both portrait and landscape.
- Pre-Completion Self-Check run against project-context.md's list: no `tracking()`, no transparent-background button touched, no custom `ButtonStyle` modified, no ternary-selected `LocalizedStringKey` introduced, `Font.system(size:)`/`.lineLimit()`/`.fixedSize()` grep across the edited file returns nothing new. No symbols deleted/renamed this session, so no repo-wide grep-for-old-name check applies.
- **Process note for future stories:** this story is a concrete example of why AC #3's "investigation-first, don't just override style superficially" instinct was right, but also why an unverified guess (Task 1's first attempt) shouldn't be treated as done without user confirmation — the fix was reported as applied and awaiting verification, the user's re-test caught it immediately, and a second, evidence-based investigation (this time using real external research rather than code-review-only reasoning) found the true, confirmed cause on the second pass.

### File List

- Modified: `ForkedEchoes/Views/DesignSystem/RunOptionsButton.swift`
- Modified: `_bmad-output/planning-artifacts/epics.md` (UX-DR11 addendum)

## Change Log

- 2026-08-04: Story 2.12 created via create-story workflow. Scoped to `RunOptionsButton.swift`'s two `confirmationDialog` modifiers: investigate and fix the root cause of a popover-style presentation (button-anchored callout, missing visible Cancel row) instead of the spec'd bottom-anchored native action sheet (UX-DR11), surfaced via a 2026-08-03 Simulator screenshot. No engine-logic changes; investigation-first requirement (AC #3) means the fix must address the underlying cause, not just override presentation style superficially.
- 2026-08-04: First implementation attempt via dev-story. Hypothesized root cause: `confirmationDialog`'s popover-vs-sheet resolution keyed on horizontal size class, regular on Plus/Pro-Max-class iPhones in landscape. Fix: `.presentationCompactAdaptation(.none)` added to both dialogs. `swift test` 60/60 passing. Manual Simulator verification requested from user; status set to review pending that result.
- 2026-08-04: User-reported the fix had no effect, with a post-fix Simulator screenshot as evidence. Re-investigated using WebSearch/WebFetch against Apple's own WWDC 2025 Session 284 and developer forums — found the real cause: iOS 26 intentionally changed `confirmationDialog`/`actionSheet` to anchor to its triggering button on iPhone (matching iPadOS), with no supported way to force the old bottom-sheet style for a non-nav-bar-anchored control. Presented the user a choice between continuing to fight the platform or accepting the new behavior and narrowing scope to the genuinely-fixable part (the missing Cancel row); user chose to accept the platform behavior. Reverted the disproven fix, changed both `Button("runOptions.cancel", role: .cancel)` declarations to plain (non-cancel-role) buttons — popover-style action sheets have always auto-suppressed `.cancel`-role actions specifically (documented since iOS 8), so a plain button stays visible. Amended `epics.md`'s UX-DR11 and this story's ACs with a RESOLVED CONFLICT banner recording the decision. `swiftc -parse` clean, `swift test` 60/60 passing, no regressions. Second round of manual Simulator verification requested from user; status remains review pending that result.
- 2026-08-04: Task 3 complete — user confirmed both dialogs show all three rows (including a visible, functional "Cancel"), Cancel dismisses cleanly with no side effects, and both dialogs verified correct in portrait and landscape. All tasks now complete.
