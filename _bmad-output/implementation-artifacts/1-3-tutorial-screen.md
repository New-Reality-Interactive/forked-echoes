---
baseline_commit: 36ec320845c3ed69e07aadbb2ef4021fd02d5caa
---

# Story 1.3: Tutorial Screen

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a first-time player,
I want to view a tutorial that explains the game's mechanics in words,
so that I understand how to read and choose before I reach a real decision.

## Acceptance Criteria

1. **Given** the player navigates to Tutorial from Home, **when** it renders, **then** it explains page-turning (swipe or tap-zone) and choice-making (hold or tap) mechanics in words, per EXPERIENCE.md Voice and Tone. [Source: epics.md#Story 1.3, lines 249-251]
2. **Given** Tutorial is shown, **when** inspected, **then** it offers "Back Home" and "Start Story" actions, tap only. [Source: epics.md#Story 1.3, lines 253-255]
3. **Given** any other screen in the app, **when** checked for a path to Tutorial, **then** Tutorial is reachable only from Home (FR2). [Source: epics.md#Story 1.3, lines 257-259]
4. **Given** all Tutorial screen text (mechanic explanations, action labels), **when** rendered, **then** every string is sourced from `Localizable.xcstrings`, never hardcoded (AD-2). [Source: epics.md#Story 1.3, lines 261-263]

## Tasks / Subtasks

- [x] Task 1: Replace `TutorialPlaceholderView` with the real `TutorialView` (AC: #1, #4)
  - [x] Subtask 1.1: Create `ForkedEchoes/Views/Tutorial/TutorialView.swift`; delete `TutorialPlaceholderView.swift`. `Views/` is a filesystem-synchronized Xcode group ([Source: ForkedEchoes.xcodeproj/project.pbxproj#PBXFileSystemSynchronizedRootGroup]) — no project.pbxproj edits needed for the add/rename/delete.
  - [x] Subtask 1.2: Preserve the existing centering/scroll pattern from the placeholder: `GeometryReader { proxy in ScrollView { ... .frame(maxWidth: .infinity, minHeight: proxy.size.height) } }` — this is a post-review fix from Story 5.3, required so content centers when it fits but scrolls instead of clipping at large Dynamic Type sizes in landscape. [Source: 5-3-home-and-tutorial-landscape-retrofit.md; current `TutorialPlaceholderView.swift`]
  - [x] Subtask 1.3: Author the three mechanic-explanation paragraphs plus an eyebrow heading, matching the drafted copy in `mockups/tutorial.html` lines 83-86 (short, declarative — per Voice and Tone):
    - Eyebrow: "How To Play"
    - Page-turning: "Swipe left to keep reading, or tap the right edge. Swipe right to look back, or tap the left edge."
    - Choice-making: "When a choice comes up, hold it. It takes a moment to commit — you can let go and change your mind before it locks in. A quick tap decides right away — tap it again in the second or two after if you change your mind."
    - Echo framing: "Once you've chosen, it's part of your story. **The story remembers** what you pick — it'll come back to it later." (bold via Markdown-capable `LocalizedStringKey`/`AttributedString` string-catalog value, matching the mockup's inline emphasis)
    [Source: ux-designs/ux-game-2026-07-25/mockups/tutorial.html lines 83-86; EXPERIENCE.md Voice and Tone table, "Tutorial: short, declarative instructions"]
  - [x] Subtask 1.4: Add new entries to `Resources/Localizable.xcstrings` for every new string, following the exact JSON shape and namespacing precedent already in the file (`tutorial.eyebrow`, `tutorial.mechanic.pageTurn`, `tutorial.mechanic.choice`, `tutorial.mechanic.echo`, `tutorial.action.backHome`, `tutorial.action.startStory`), each with a `comment` describing where it appears — mirror `home.appTitle` etc. [Source: `Resources/Localizable.xcstrings` lines 1-66]

- [x] Task 2: Add "Back Home" and "Start Story" actions, tap only (AC: #2)
  - [x] Subtask 2.1: "Back home" — use `@Environment(\.dismiss) private var dismiss` and pop the pushed Tutorial view (`dismiss()` on tap). Do not introduce a bound `NavigationPath` for this alone; that refactor is bigger scope than this story needs and can wait until a story needs pop-to-root from arbitrary depth (likely Story 2.7's `exitToHome()`).
  - [x] Subtask 2.2: "Start Story" — reuse the existing `HomeDestination` enum and its `navigationDestination(for:)` resolver already registered on the stack in `RootView.swift`; push `HomeDestination.storyChoice` the same way `HomeView` does (`NavigationLink(value: HomeDestination.storyChoice)`). No new destination type needed.
  - [x] Subtask 2.3: Both actions are plain tap buttons, vertically stacked (not gesture-driven), each `.frame(maxWidth: .infinity, minHeight: 44)` to meet the 44pt minimum tap target — mirror `HomeView`'s existing button sizing. [Source: `ForkedEchoes/Views/Home/HomeView.swift` lines 21-30]

- [x] Task 3: Wire the real Tutorial view into navigation (AC: #3)
  - [x] Subtask 3.1: Update `ForkedEchoes/Views/RootView.swift` — change `case .tutorial: TutorialPlaceholderView()` to `case .tutorial: TutorialView()`.
  - [x] Subtask 3.2: Update the duplicate `navigationDestination` switch inside `HomeView.swift`'s `#Preview` block the same way (it currently also references `TutorialPlaceholderView()`).
  - [x] Subtask 3.3: Confirm no other call site references `TutorialPlaceholderView` (`grep -rn "TutorialPlaceholderView"`) so Tutorial remains reachable only via Home's "Start Tutorial" link, per FR2.

- [ ] Task 4: Manual verification (AC: #1-#4)
  - [ ] Subtask 4.1: **NOT VERIFIED BY DEV AGENT — but user-tested, and one landscape defect found and fixed.** This dev environment has no Xcode/Swift toolchain (Linux devcontainer, `xcodebuild`/`swiftc` unavailable), so the dev agent could not build/run the app itself. The user built and ran it in Simulator and found: in landscape, the "Start Story" button was not visible/tappable. Root cause: the initial layout used a `Spacer(minLength: 24)` between the mechanics text and the action buttons, inside the `ScrollView`+`GeometryReader` combo — a `Spacer` measured under this pattern's layout pass collapses toward zero/minLength rather than reliably expanding, and it also doubled up with the outer `VStack`'s own `spacing: 24`, inflating the minimum content height right when landscape has the least height to spare. Fixed by removing the `Spacer` entirely and returning to a flat `VStack` (text block, then action block, single `spacing: 24`) — the same Spacer-free structure `HomeView` already uses and that Story 5.3 verified reflows correctly in landscape. **Still needs a re-test by the user in Simulator to confirm the fix resolves the reported issue** (dev agent cannot verify this itself).
  - [x] Subtask 4.2: Confirm every visible string traces to a `Localizable.xcstrings` key (no `Text(verbatim:)`/string literals left over from the placeholder). Verified by inspection — all six new keys added and referenced.
  - [x] Subtask 4.3: No automated UI test is required — per AD-7, Swift Testing coverage is scoped to `StoryRunEngine`/engine-logic only; Tutorial is a plain SwiftUI view with no new engine logic. [Source: ARCHITECTURE-SPINE.md AD-7; `ForkedEchoesTests/` contains only `RunSnapshotPresenceTests.swift` and the default test target file]

## Dev Notes

- **File/naming convention:** Views live at `Views/<ScreenName>/<ScreenName>View.swift` with a matching `struct <ScreenName>View: View` and a `#Preview` — no ViewModel layer per screen (AD-3: single shared engine, not per-screen ViewModels). Follow `HomeView.swift`'s shape exactly; drop the "Placeholder" naming entirely rather than keeping it alongside the real view. [Source: ARCHITECTURE-SPINE.md AD-3, lines 46-55; Capability Map line 165 — "FR-2 Tutorial → `Views/Tutorial`"]
- **Localization convention (actual precedent, not the AD-2 aspiration):** Home's real code uses plain string-literal catalog keys via `Text("home.action.startStory")` / a `LocalizedStringKey`-typed constant — not codegen'd type-safe symbols (no codegen setting exists in the Xcode project despite AD-2's stated intent). Match this actual precedent: `tutorial.*` keys as plain literals. If a label's text is chosen with a ternary, give the constant an explicit `LocalizedStringKey` type annotation (this was a real fix needed in Story 1.2 to avoid `Text` resolving the wrong overload). [Source: `ForkedEchoes/Views/Home/HomeView.swift` lines 5-6; 1-2-home-screen-start-resume-story-and-start-tutorial.md Dev Notes]
- **Navigation:** `NavigationStack` + `Hashable` enum route (`HomeDestination`) is reserved for this coarse top-level flow only (AD-5) — never used for individual story pages. The `navigationDestination(for: HomeDestination.self)` resolver is registered once in `RootView.swift` and works for pushes from any descendant in the stack, so Tutorial can push `.storyChoice` the same way Home does; no new enum case or resolver needed. [Source: `ForkedEchoes/Views/RootView.swift` lines 1-24]
- **Circuit frame — flag, do not resolve in this story:** Docs conflict on whether Tutorial's real screen carries the circuit frame chrome. `DESIGN.md` (lines 263, 289) and Story 1.2's own Dev Notes both say Tutorial *does* get the dormant-brass frame (Home is the only screen that never gets it) — confirmed by `mockups/tutorial.html` line 70 ("reuses the reading frame... since it's still a reading surface"). But epics.md's Story 1.4 AC (line 275) says "no circuit frame on either screen" for Home **and** Tutorial. Given Epic 1's story split — 1.2/1.3 build functional screens, 1.4 applies the DESIGN.md visual-identity pass to both — treat the frame as **out of scope for this story either way**: ship Tutorial's functional layout (no frame decoration), and raise the DESIGN.md-vs-epics.md conflict to the team before Story 1.4 starts so the frame question is resolved once, not per-story. Do not guess at the frame's visual implementation here.
- **Run-options icon — explicitly out of scope:** The mockup shows a run-options ellipsis icon on Tutorial, but Story 2.7 ("Run Options Action Sheet") explicitly owns adding it ("this retrofits Tutorial (Story 1.3) with the control it was missing" — i.e., 2.7 retrofits it *after* 1.3 ships without it). Do not add it now. [Source: epics.md#Story 2.7, lines 471-473]
- **Testing standard:** Per AD-7, Swift Testing only covers `StoryRunEngine` logic (ending resolution, echo reachability, snapshot round-trip, etc.) — there is no automated-UI-test requirement for views. Manual build/run + VoiceOver/Dynamic Type check is the established norm (matches Story 1.2's approach). Full VoiceOver-label and Dynamic-Type-at-accessibility-sizes validation is Story 1.4's job, not this one.
- **Accessibility floor that still applies now (not deferred):** 44pt minimum tap target on both actions; no gesture-only interaction (FR11) — the mechanics are *described* in words here, not required to be demonstrated live.

### Review Findings

- [x] [Review][Decision] Should "Start Story" on Tutorial relabel to "Resume Story" when a run is already in progress, mirroring `HomeView`'s `hasInProgressRun`/`primaryActionLabel` logic? — **Resolved: yes, mirror Home.** Applied: `TutorialView` now computes `hasInProgressRun`/`primaryActionLabel` the same way `HomeView` does. [TutorialView.swift:7-8, 48]
- [x] [Review][Decision] `tutorial.action.backHome` is sentence case ("Back home") while every other action label in the catalog is Title Case — copied verbatim from the approved mockup. **Resolved: fix to Title Case.** Applied: catalog value changed to "Back Home". [Localizable.xcstrings]

- [x] [Review][Patch] Mechanics text block has no landscape width cap, unlike the action buttons — DESIGN.md/EXPERIENCE.md classify Tutorial as a "reading surface" requiring the `column-max-width-landscape` (680px per ARCHITECTURE-SPINE.md) cap in landscape. **Applied:** added `.frame(maxWidth: 680, alignment: .leading)` (inner) + `.frame(maxWidth: .infinity)` (outer, default-centered) so the text column caps at 680pt and centers with side margins in wide landscape, matching DESIGN.md's "extra width becomes side margin." [TutorialView.swift:13-36]
- [x] [Review][Patch] Trim the `.frame(minHeight:)` comment to state the current invariant, not narrate the discarded `Spacer` attempt. **Applied.** [TutorialView.swift:58-64]

- [x] [Review][Defer] No VoiceOver-specific alternative wording for the gesture-only page-turn mechanic — deferred, pre-existing: full VoiceOver/Dynamic-Type-at-accessibility-sizes validation is explicitly Story 1.4's scope per this story's own Dev Notes. [TutorialView.swift; tutorial.mechanic.pageTurn]
- [x] [Review][Defer] No `tutorialSeen` persistence flag written on Tutorial dismissal/completion — deferred, pre-existing: `tutorialSeen` would live on the real `RunSnapshot` (AD-4), which isn't built yet — only a presence-check stub (`RunSnapshotPresence`) exists; the Codable `RunSnapshot` model is Story 2.4's job. Cannot be correctly implemented before that lands.
- [x] [Review][Defer] Rapid double-tap on the "Start Story" `NavigationLink` before the push transition completes could in theory push a duplicate destination — deferred, pre-existing: identical risk already exists in `HomeView`'s already-shipped, already-reviewed `NavigationLink(value: HomeDestination.storyChoice)` (Story 1.2); not introduced by this diff.

### Project Structure Notes

- New/changed files: `ForkedEchoes/Views/Tutorial/TutorialView.swift` (replaces `TutorialPlaceholderView.swift`), `ForkedEchoes/Views/RootView.swift` (one-line reference update), `ForkedEchoes/Views/Home/HomeView.swift` (its `#Preview` block's duplicate reference), `ForkedEchoes/Resources/Localizable.xcstrings` (new `tutorial.*` entries).
- `Views/` is a filesystem-synchronized Xcode group (`PBXFileSystemSynchronizedRootGroup`) — adding/removing/renaming files under it requires no `project.pbxproj` changes.
- No conflicts detected with the unified project structure; this story stays entirely within the pattern Story 1.2 already established.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3, lines 241-263]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4, lines 265-283]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.7, lines 463-493]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR9/UX-DR10, lines 103-105]
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md — AD-2, AD-3, AD-5, AD-7, AD-8; Capability Map line 165]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md — Voice and Tone (lines 39-49), Tutorial actions (line 64), Accessibility Floor (lines 93-103)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md — lines 233-235 (landscape), 263 (Home/Tutorial chrome), 289 (Do/Don't table)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/tutorial.html and tutorial-landscape.html]
- [Source: _bmad-output/implementation-artifacts/1-2-home-screen-start-resume-story-and-start-tutorial.md — Dev Notes, Completion Notes]
- [Source: _bmad-output/implementation-artifacts/5-3-home-and-tutorial-landscape-retrofit.md — Dev Notes]
- [Source: _bmad-output/implementation-artifacts/deferred-work.md — "Story 1.3's concern when it adds the first 'Back home' button"]
- [Source: ForkedEchoes/Views/RootView.swift, ForkedEchoes/Views/Home/HomeView.swift, ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift, ForkedEchoes/Engine/RunSnapshotPresence.swift, ForkedEchoes/Resources/Localizable.xcstrings — current source, read in full]

## Previous Story Intelligence

- **From Story 1.2:** `HomeDestination` enum + stack-level `navigationDestination(for:)` was deliberately chosen over per-link `NavigationLink(destination:)` specifically so Story 1.3 only needs to swap the view returned for `.tutorial`, not touch nav plumbing — confirmed true, Task 3 above is exactly that swap. Ternary-driven `LocalizedStringKey` needs explicit typing to avoid `Text` overload bugs. Auto-extracted placeholder strings can leave stray empty `Localizable.xcstrings` entries — only add real, intentional keys.
- **From Story 5.3:** The `GeometryReader`+`ScrollView`+`minHeight: proxy.size.height` centering pattern in `TutorialPlaceholderView.swift` was a post-review fix, not incidental — it must carry over into the real `TutorialView`. The placeholder has less available height than Home due to the NavigationStack back bar; keep that in mind when the real content (3 paragraphs + 2 buttons) is longer than the placeholder's single line. Sibling scope can silently diverge (`StoryChoicePlaceholderView` was left un-retrofitted for landscape) — not this story's problem, but a reminder to actually finish what's in scope rather than leaving a partial job.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/Swift toolchain available in this devcontainer (`xcodebuild`, `swiftc` both absent — consistent with Stories 1.1/1.2/5.2/5.3's prior finding). Verified via `python3 -m json.tool`-equivalent JSON parse of the edited `Localizable.xcstrings` (valid), a full read-through of all four touched Swift/RootView/HomeView files, and `grep -rn "TutorialPlaceholderView"` returning zero matches project-wide. Actual Simulator build/run (rotation, Dynamic Type, VoiceOver smoke test) is flagged for the user — see Subtask 4.1.

### Completion Notes List

- Replaced `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` with `ForkedEchoes/Views/Tutorial/TutorialView.swift`: eyebrow + three mechanic-explanation paragraphs (page-turn, choice-hold/tap, echo callback), all sourced from new `tutorial.*` `Localizable.xcstrings` keys. Preserved the `GeometryReader` + `ScrollView` + `minHeight: proxy.size.height` centering/scroll pattern from the placeholder (Story 5.3's post-review fix).
- **Post-implementation fix (user-reported):** the user tested in Simulator and found "Start Story" unreachable in landscape. Root cause was a `Spacer(minLength: 24)` used to pin actions to the bottom — unreliable inside this `ScrollView`/`GeometryReader` combo and it inflated the minimum content height (stacked with the outer `VStack`'s own `spacing: 24`) right when landscape has the least height available. Fix: removed the `Spacer`, reverted to a flat, single-`VStack` structure identical to `HomeView`'s (the one pattern already confirmed to reflow correctly in landscape by Story 5.3). Not yet re-verified in Simulator by the user.
- Added "Back home" (`@Environment(\.dismiss)`) and "Start Story" (`NavigationLink(value: HomeDestination.storyChoice)`) actions — both plain tap buttons, `.frame(maxWidth: .infinity, minHeight: 44)`, action stack capped at `maxWidth: 320` matching `HomeView`'s landscape convention. No new `NavigationPath` binding introduced; reused the existing stack-level `navigationDestination(for: HomeDestination.self)` resolver already registered in `RootView.swift`.
- Updated `RootView.swift` and `HomeView.swift`'s `#Preview` to reference `TutorialView()` instead of `TutorialPlaceholderView()`. Confirmed zero remaining references to the old placeholder anywhere in the project.
- Deliberately did **not** add the circuit frame (docs conflict between DESIGN.md and epics.md Story 1.4's AC — flagged in Dev Notes for resolution before Story 1.4) or the run-options icon (explicitly Story 2.7's scope).
- No new Swift Testing coverage added — this story introduces no new `StoryRunEngine`/engine logic, only a SwiftUI view, consistent with AD-7's test scope and Stories 1.2/5.3's precedent.
- **Code review (bmad-code-review, 2026-07-26):** 3-layer adversarial review (Blind Hunter, Edge Case Hunter, Acceptance Auditor) ran against the diff plus this story file. 2 decision-needed, 2 patch, 3 defer, 8 dismissed as noise/handled-elsewhere. User resolved both decisions (mirror Home's resume relabel: yes; fix "Back Home" casing: yes) and asked to apply all 4 resulting patches:
  - `TutorialView` now computes `hasInProgressRun`/`primaryActionLabel` exactly like `HomeView`, so "Start Story" relabels to "Resume Story" when a run is already in progress.
  - `tutorial.action.backHome` catalog value corrected from "Back home" to "Back Home" for Title Case consistency with every other action label.
  - Added a 680pt landscape width cap (`ARCHITECTURE-SPINE.md`'s reading-surface `column-max-width-landscape` value) to the mechanics text block, centered via an outer `.frame(maxWidth: .infinity)` — closes a second landscape-stretch gap the reviewers found independently of the user's reported bug.
  - Trimmed the `.frame(minHeight:)` comment to state the current invariant instead of narrating the discarded `Spacer` attempt.
  - 3 findings deferred to `deferred-work.md` (VoiceOver alt-text for gesture mechanics — Story 1.4; `tutorialSeen` persistence — blocked on Story 2.4's `RunSnapshot`; double-tap re-entrancy on `NavigationLink` — pre-existing, matches Home).
- **Outstanding:** Subtask 4.1 (Simulator build/run in both orientations, including the landscape fix and the new width cap) could not be performed — no macOS/Xcode available in this environment. Please build and run in Xcode before merging.

### File List

- `ForkedEchoes/Views/Tutorial/TutorialView.swift` (added — replaces `TutorialPlaceholderView.swift`)
- `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` (deleted)
- `ForkedEchoes/Views/RootView.swift` (modified — `.tutorial` case now returns `TutorialView()`)
- `ForkedEchoes/Views/Home/HomeView.swift` (modified — `#Preview`'s `.tutorial` case now returns `TutorialView()`)
- `ForkedEchoes/Resources/Localizable.xcstrings` (modified — added `tutorial.eyebrow`, `tutorial.mechanic.pageTurn`, `tutorial.mechanic.choice`, `tutorial.mechanic.echo`, `tutorial.action.backHome`, `tutorial.action.startStory`)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 1-3 status progression: backlog → ready-for-dev → in-progress → review)
- `_bmad-output/implementation-artifacts/1-3-tutorial-screen.md` (this story file)
- `_bmad-output/implementation-artifacts/deferred-work.md` (modified — appended 3 findings deferred from this story's code review)

## Change Log

- 2026-07-26: Story created (create-story workflow) and implemented (dev-story workflow) in the same session. Real `TutorialView` built to replace the placeholder: mechanics copy, localized strings, and Back Home/Start Story navigation, following Home/5.3's established landscape-safe layout pattern. Circuit-frame chrome and the run-options icon were intentionally left out of scope (flagged for 1.4 and already owned by 2.7, respectively). No automated tests added (no new logic, per AD-7). Simulator build/run verification could not be performed in this devcontainer (no Xcode toolchain) — flagged for the user. Status moved to review.
- 2026-07-26: User-reported bug fix — "Start Story" button unreachable in landscape. Removed the `Spacer(minLength: 24)` between text and actions (unreliable inside the `ScrollView`/`GeometryReader` pattern and doubled up with the outer `VStack`'s spacing); reverted to `HomeView`'s flat, Spacer-free structure.
- 2026-07-26: Code review (3-layer adversarial + acceptance audit against this story file). Applied 4 patches: resume-state relabel on "Start Story", "Back Home" casing fix, 680pt landscape width cap on the mechanics text (closing a second stretch gap independently found by reviewers), and a comment cleanup. Deferred 3 findings (VoiceOver alt-text, `tutorialSeen` persistence, double-tap re-entrancy) — see `deferred-work.md`. Still needs Simulator re-verification by the user.
- 2026-08-02: UX design pass (Sally) amended UX-DR10 in response to user feedback: this story's "Back Home" button (redundant with the `NavigationStack` back chevron already present) is being removed, and "Start Story"/"Resume Story" is being made a fixed, always-visible action instead of scrolling with the mechanics copy. This story's own AC/implementation are left historically intact (matches what actually shipped and was reviewed above); the change is scoped to new Story 2.11. See `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md`.
