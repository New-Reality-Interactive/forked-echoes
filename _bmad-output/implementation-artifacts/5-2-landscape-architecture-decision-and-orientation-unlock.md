---
baseline_commit: 5521eb1a0eec012862a80ef769306cefd12455f1
---

# Story 5.2: Landscape Architecture Decision & Orientation Unlock

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want the orientation lock lifted and the architecture doc updated with the landscape layout strategy,
so that landscape becomes a first-class, documented constraint for all future stories.

## Acceptance Criteria

1. **Given** Story 5.1's landscape design language (DESIGN.md/EXPERIENCE.md's "Responsive & Platform" content), **when** this story is complete, **then** `ARCHITECTURE-SPINE.md`'s Structural Seed documents the landscape layout strategy in full (replacing the "TBD" note added by the 2026-07-26 Sprint Change Proposal), including any new Architecture Decision needed (e.g. a landscape reflow AD). [Source: epics.md#Story 5.2]

2. **Given** the current orientation lock (`INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait`), **when** this story is complete, **then** both Debug and Release configurations support the orientations Story 5.1 designed for (portrait + landscape). [Source: epics.md#Story 5.2]

## Tasks / Subtasks

- [x] Task 1: Add the landscape Architecture Decision (AC: #1)
  - [x] Subtask 1.1: Add a new `AD-8` entry to `ARCHITECTURE-SPINE.md`'s "Invariants & Rules" section, in the same `Binds`/`Prevents`/`Rule` format as AD-1 through AD-7. Content should establish: landscape is a continuous reflow of one view hierarchy per screen (Home, Tutorial, Story/Choice, Ending, Memory) — never a separate orientation-specific view type — and orientation is detected via `@Environment(\.verticalSizeClass)` (`.compact` = landscape, `.regular` = portrait), **not** `UIDevice.orientation`/`UIDeviceOrientationDidChangeNotification` (fragile, requires manual lifecycle management) and **not** `horizontalSizeClass` (reports `.compact` in *both* orientations on standard iPhones — cannot distinguish portrait from landscape). This is a Presentation-layer-only rule; `StoryRunEngine`'s phase model (AD-5) is orientation-agnostic and untouched.
  - [x] Subtask 1.2: Replace the Structural Seed's `**Landscape layout strategy:** TBD — pending the UX Designer's landscape design pass...` line with the real strategy, referencing AD-8 and summarizing Story 5.1's concrete deliverables: reading-surface column capped at `680px`/`column-max-width-landscape` and centered (side margin absorbs extra width); choice cards switch stack→horizontal-row, wrapping to 2+1 once a label would exceed 2 lines or at accessibility Dynamic Type sizes (hard constraint, not a judgment call); circuit frame, Home/Tutorial's centered stack, and the branch-arrival interstitial all reflow existing geometry to the new aspect ratio (no new component types); 44pt tap targets and Dynamic Type headroom clearance hold identically in both orientations. Cite `EXPERIENCE.md#Responsive and Platform` and `DESIGN.md#Layout & Spacing` / `DESIGN.md#Components` (`reading-surface`, `choice-card.layout-landscape`) rather than restating their full text.
  - [x] Subtask 1.3: Add `AD-8` to the "Governed by" cell of the `FR-11 Accessible interaction parity` row in the Capability → Architecture Map table (currently `AD-2, AD-3`) — this is the row landscape most directly extends. Do not add AD-8 to every screen's FR row; that would over-scope a table meant to name the *primary* governing decisions per capability.
  - [x] Subtask 1.4 (nice-to-have, not AC-gating): Add a short section to `EXPLAINER.md` explaining the *why* behind AD-8 (verticalSizeClass over UIDevice.orientation/horizontalSizeClass). Note (corrected during code review, 2026-07-26): `EXPLAINER.md` does not actually have one subsection per AD for every AD — AD-7 (Testing surface) has none — so AD-8's new subsection was added directly after AD-6's, not as a continuation of a fully unbroken pattern. Skip if time-constrained — `ARCHITECTURE-SPINE.md` is the binding contract; `EXPLAINER.md` is commentary.
- [x] Task 2: Lift the orientation lock (AC: #2)
  - [x] Subtask 2.1: In `ForkedEchoes.xcodeproj/project.pbxproj`, change `INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;` (Debug config, currently line 376) to an array supporting Portrait + both Landscapes. Use Xcode's standard array-valued build-setting syntax:
    ```
    INFOPLIST_KEY_UISupportedInterfaceOrientations = (
        UIInterfaceOrientationPortrait,
        UIInterfaceOrientationLandscapeLeft,
        UIInterfaceOrientationLandscapeRight,
    );
    ```
    Deliberately **exclude** `UIInterfaceOrientationPortraitUpsideDown` — neither DESIGN.md/EXPERIENCE.md's "Responsive & Platform" content nor the PRD's Orientation NFR (`prd.md` §4.6: "Supports both portrait and landscape") mention upside-down, and excluding it matches Apple's own default for iPhone-only targets (Xcode's project-settings orientation checkboxes leave "Upside Down" unchecked by default for iPhone, unlike iPad).
  - [x] Subtask 2.2: Apply the identical change to the Release config (currently line 401). Both configs currently have byte-identical `INFOPLIST_KEY_UISupportedInterfaceOrientations` lines — keep them in sync.
  - [x] Subtask 2.3: Do not touch `TARGETED_DEVICE_FAMILY` (stays `1`, iPhone-only per ARCHITECTURE-SPINE.md's Structural Seed) or add an `~ipad`-suffixed orientation key — out of scope, no iPad support planned.
- [x] Task 3: Verify (all ACs)
  - [x] Subtask 3.1: This devcontainer has no Xcode/macOS toolchain (confirmed in Stories 1.1/1.2 — same caveat applies here). At minimum, visually diff `project.pbxproj` to confirm valid, well-formed syntax (matching brace/paren nesting, trailing semicolons) since there's no local `xcodebuild`/`plutil` to validate it.
  - [x] Subtask 3.2: Flag for the user to verify on macOS/Xcode: open the project, confirm Signing & Capabilities → General shows Portrait + both Landscapes checked (Upside Down unchecked) for both Debug and Release, then run on Simulator and rotate the device — Home (the only real screen built so far) should now rotate instead of staying locked portrait. (Home isn't retrofitted for landscape *layout* yet — that's Story 5.3 — this story only confirms rotation is no longer blocked at the OS level.)

### Review Findings

- [x] [Review][Patch] `sprint-status.yaml`'s `last_updated` annotation text says "5-2 marked ready-for-dev" but the status value it describes is actually `review` — stale comment left over from an earlier edit pass. [_bmad-output/implementation-artifacts/sprint-status.yaml:44]
- [x] [Review][Patch] `sprint-status.yaml` was modified (epic-5/5-1/5-2 status, last_updated) but is missing from this story's own File List, which enumerates only `ARCHITECTURE-SPINE.md`, `EXPLAINER.md`, `project.pbxproj`, and the story file itself. [_bmad-output/implementation-artifacts/5-2-landscape-architecture-decision-and-orientation-unlock.md#File List]
- [x] [Review][Patch] AD-8's "Binds" line claims "all screens," matching AD-3's identical scope claim — but the Capability → Architecture Map only appends AD-8 to FR-11's row, unlike AD-3 which appears across FR-1, FR-2, FR-9, FR-10 (every screen-related row). Inconsistent with the doc's own established convention for "all screens" ADs. [_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#Capability → Architecture Map]
- [x] [Review][Patch] This story's own Subtask 1.4 and Completion Notes assert EXPLAINER.md has "AD-1 through AD-7 each ... a subsection" / "the existing one-section-per-AD pattern" — false: AD-7 (Testing surface) has no EXPLAINER.md subsection, so the new AD-8 section now sits directly after AD-6 with no AD-7 in between. [_bmad-output/implementation-artifacts/5-2-landscape-architecture-decision-and-orientation-unlock.md#Tasks/Subtasks, #Completion Notes List]
- [x] [Review][Patch] AD-8's Rule specifies `.compact` = landscape / `.regular` = portrait but doesn't state a fallback for `verticalSizeClass == nil` (it's an `Optional` in SwiftUI, e.g. some preview/host contexts without an explicit size-class override) — leaves that edge case unspecified for Story 5.3+ implementers. [_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-8]
- [x] [Review][Patch] The removed Structural Seed "TBD" note's blanket prohibition ("no new story may hard-code portrait-only layout assumptions") wasn't replaced with an equally general clause — the new paragraph only concretely covers `reading-surface`/`choice-card`, leaving not-yet-designed components (e.g. future Epic 2/3 screens) without an explicit general guardrail. [_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#Structural Seed]
- [x] [Review][Patch] EXPLAINER.md's new AD-8 rationale states "a face-up/face-down device reports `.unknown`, not a rotation" — factually imprecise; `UIDeviceOrientation` has dedicated `.faceUp`/`.faceDown` cases, neither of which is `.unknown`. [_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/EXPLAINER.md#Landscape reflows the same views]
- [x] [Review][Defer] `sprint-status.yaml` flips `5-1-landscape-ux-design-pass` to `done` and `epic-5` to `in-progress` with no corresponding `5-1-*.md` story file, breaking the tracker's usual file-per-status-change convention — deferred, pre-existing: Story 5.1's design work (DESIGN.md/EXPERIENCE.md landscape sections, mockups) was completed and merged directly, outside the `create-story`/`dev-story` flow, before this session began Story 5.2. The status correction itself reflects the user's own confirmation that 5.1 is "done and merged," not new work this story performed; fixing the missing artifact (a retroactive 5.1 story file) is out of this story's scope. [_bmad-output/implementation-artifacts/sprint-status.yaml]
- [x] [Review][Defer] Lifting the OS-level orientation lock ships ahead of the Home/Tutorial landscape layout retrofit (Story 5.3), creating a window where a build could show stretched/un-retrofitted landscape UI — deferred, pre-existing: this is the deliberate two-story split `epics.md` itself specifies (5.2 unlock, then 5.3 retrofit, back-to-back next in the sprint), and there is no active TestFlight/App Store distribution channel yet (Apple Developer Program enrollment remains an open blocking dependency per `ARCHITECTURE-SPINE.md`'s Deployment section) for this window to actually reach anyone. [ForkedEchoes.xcodeproj/project.pbxproj]

## Dev Notes

- **Scope discipline — this story is docs + one build setting, not a UI retrofit.** Story 5.3 ("Home & Tutorial Landscape Retrofit") is what actually changes `HomeView.swift`/`TutorialPlaceholderView.swift` layout to reflow per Story 5.1's mockups. This story (5.2) only: (a) writes down the architecture decision that makes that retrofit well-defined, and (b) removes the OS-level orientation lock so landscape can physically occur. Resist the urge to touch `HomeView.swift` here even though it would render "wrong" (stretched, uncapped) in landscape once the lock lifts — that's expected and explicitly deferred to 5.3 per `epics.md`'s own Story 5.3 scope. [Source: epics.md#Story 5.3]
- **Known open landscape-design issues, not this story's job to fix:** `review-accessibility-landscape.md` (Story 5.1's own review pass) flagged that the *reference mockups* (`home-landscape.html`, `tutorial-landscape.html`, `story-choice-landscape.html`) have concrete 44pt tap-target violations and a `column-max-width-landscape` mismatch (mockups use 520px/480px vs. the token's 680px) — but the review's own fix routes these to Story 5.3 ("treat it as an acceptance criterion for Story 5.3"), not here. The DESIGN.md/EXPERIENCE.md *spec text* itself (as opposed to the mockups) already reads as internally consistent and already incorporates two of that review's fixes (the 2+1 wrap hard-constraint wording, and the VoiceOver traversal-order sentence) — confirmed by direct reading of the current `EXPERIENCE.md`/`DESIGN.md`, not assumed. Don't re-open or re-fix the mockups in this story. [Source: ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md]
- **Why `verticalSizeClass`, not `horizontalSizeClass` or `UIDevice.orientation`:** standard, non-Plus/Max iPhones report `horizontalSizeClass == .compact` in *both* portrait and landscape — it cannot distinguish the two. `verticalSizeClass` is `.regular` in portrait and `.compact` in landscape across all iPhone sizes, which is the reliable, Apple-documented signal for this. `UIDevice.orientation` (or its notification) is a lower-level UIKit API that requires manual observation/lifecycle handling and doesn't map cleanly onto SwiftUI's declarative environment model — avoid it. This reasoning is what AD-8 needs to capture so Story 5.3 (and every screen-building story from Epic 2 onward, per `epics.md`'s "Downstream note") doesn't reinvent or diverge on orientation detection per screen.
- **No FR renumbering:** the PRD's Orientation requirement (`prd.md` §4.6) is a bullet under the existing Cross-Cutting NFRs section, not a new numbered FR — don't invent an "FR-13" when citing it. Cite it as `PRD §4.6 Orientation NFR`.
- **`project.pbxproj` structure reminder (from Story 1.1):** `Views/` is a `PBXFileSystemSynchronizedRootGroup` (no manual group editing needed for Swift files), but that's irrelevant here — this story's only `project.pbxproj` edit is the two `INFOPLIST_KEY_UISupportedInterfaceOrientations` build-setting values, which are plain key/value(-array) edits within the existing `XCBuildConfiguration` blocks, not group/membership structure. Don't touch anything else in the file.
- **No test coverage applies:** this story is a documentation update plus a static Info.plist build setting — there is no runtime Swift logic to cover with Swift Testing. Don't add a test file for this story.

### Project Structure Notes

- Files touched: `_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md` (edit), optionally `EXPLAINER.md` (edit, nice-to-have), `ForkedEchoes.xcodeproj/project.pbxproj` (edit, 2 build settings). No new files, no `Views/`/`Engine/`/`Content/` source changes.
- No conflicts with the unified project structure — this story doesn't touch the app's Swift source tree at all beyond the Info.plist-generating build setting.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.2] — acceptance criteria, owner (Architect + Developer)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#Structural Seed] — current "TBD" placeholder to replace; AD-1–AD-7 format to match for AD-8
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md#Responsive and Platform] — the landscape behavior spec to translate into architecture language
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md#Layout & Spacing, #Components] — `column-max-width-landscape`, `choice-card.layout-landscape` token values
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md] — known mockup issues explicitly deferred to Story 5.3
- [Source: ForkedEchoes.xcodeproj/project.pbxproj:376,401] — current orientation-lock build settings (Debug/Release)
- [Source: _bmad-output/planning-artifacts/prds/prd-game-2026-07-25/prd.md#4.6 Cross-Cutting NFRs] — Orientation NFR bullet

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/macOS toolchain available in this devcontainer (consistent with Stories 1.1/1.2's prior finding). `project.pbxproj` validity was checked via brace/paren balance (`{`/`}`: 52/52, `(`/`)`: 45/45 post-edit) and a clean, minimal `git diff` review rather than `xcodebuild`/`plutil` (neither present on this Linux devcontainer). Actual Xcode-side verification (Signing & Capabilities checkboxes, Simulator rotation) is flagged for the user per Subtask 3.2.

### Completion Notes List

- Added `AD-8` to `ARCHITECTURE-SPINE.md`'s Invariants & Rules (after AD-7, preserving existing AD ordering), replaced the Structural Seed's landscape "TBD" placeholder with the real strategy, and added AD-8 to FR-11's "Governed by" cell in the Capability → Architecture Map.
- Added a companion rationale section to `EXPLAINER.md` (why `verticalSizeClass` over `horizontalSizeClass`/`UIDevice.orientation`, and why one reflowing view instead of per-orientation view types) — optional per Subtask 1.4, included since it was low-cost. Note: this doesn't complete a fully unbroken one-section-per-AD pattern — AD-7 has no `EXPLAINER.md` subsection, a pre-existing gap this story didn't introduce and isn't in scope to fix.
- Lifted `INFOPLIST_KEY_UISupportedInterfaceOrientations` in both Debug and Release build configs from a portrait-only scalar to an array of `UIInterfaceOrientationPortrait`, `UIInterfaceOrientationLandscapeLeft`, `UIInterfaceOrientationLandscapeRight` (upside-down deliberately excluded, matching Apple's iPhone default and the design docs' scope).
- No Swift source, tests, or `TARGETED_DEVICE_FAMILY` touched — this story is scoped to architecture documentation plus one build setting, per its own Dev Notes' scope-discipline note. Home/Tutorial's landscape *layout* retrofit remains Story 5.3's job.

### File List

- `_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md` (modified — added AD-8, replaced landscape TBD note, updated Capability Map)
- `_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/EXPLAINER.md` (modified — added AD-8 rationale section)
- `ForkedEchoes.xcodeproj/project.pbxproj` (modified — orientation lock lifted for Debug and Release configs)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — epic-5/5-1/5-2 status corrections, tracked separately from this story's own implementation)
- `_bmad-output/implementation-artifacts/5-2-landscape-architecture-decision-and-orientation-unlock.md` (this story file)
