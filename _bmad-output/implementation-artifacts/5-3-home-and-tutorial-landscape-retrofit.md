---
baseline_commit: 8e0d5148234a6b1f3f01a5d006e6a040cc6a4060
---

# Story 5.3: Home & Tutorial Landscape Retrofit

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want Home and Tutorial to work correctly in landscape,
so that rotating my device doesn't break the two screens that already exist.

## Acceptance Criteria

1. **Given** Story 5.1's landscape design and Story 5.2's unlocked orientation, **when** Home/Tutorial render in landscape, **then** they reflow per the documented design, not a stretched/clipped portrait layout. [Source: epics.md#Story 5.3]
2. **Given** FR11 accessibility parity, **when** in landscape, **then** Dynamic Type/VoiceOver/tap-target requirements still hold (same bar Story 1.4 already establishes for portrait, extended to the landscape variant). [Source: epics.md#Story 5.3]

## Tasks / Subtasks

- [x] Task 1: Retrofit `HomeView.swift` for landscape (AC: #1, #2)
  - [x] Subtask 1.1: Add an unconditional `.frame(maxWidth: .infinity, maxHeight: .infinity)` after the existing `.padding()` on the outer `VStack` so the title/subtitle/actions stack is explicitly centered within the full available frame in both orientations, rather than relying on undocumented default NavigationStack-content centering behavior. This matches `mockups/home-landscape.html`'s `.content{... display:flex; align-items:center; justify-content:center;}` treatment and AD-8's "plain `.frame(maxWidth:)`-style constraint, simply a no-op in portrait" pattern — no `verticalSizeClass` branch needed since Home never changes structure (stack→row is reserved for `choice-card`, not Home/Tutorial).
  - [x] Subtask 1.2: Cap the actions `VStack` (the two `NavigationLink` buttons) to `.frame(maxWidth: 320)` so the buttons stop stretching to the full landscape width. `320` is taken directly from `mockups/home-landscape.html`'s `.actions{max-width:320px}` — there is no equivalent named token in `DESIGN.md` yet (portrait's `mockups/home.html` `.actions` has no cap at all, since portrait's own content width is already narrow). Applying `320` unconditionally is a small change in portrait on most devices (current `.padding()` leaves ~360pt of content width) but visibly narrows the buttons (by roughly 20%) on the largest phones (e.g. iPhone Pro Max, ~398pt content width) — an accepted trade-off, not a true no-op — while being the actual meaningful cap in landscape (which would otherwise offer 700pt+). Do not add a `verticalSizeClass` check for this — it's exactly the "geometry-only, no branch" case AD-8 calls out.
  - [x] Subtask 1.3: Do not touch button `minHeight: 44` (already present on both `NavigationLink` labels) — that's the existing 44pt tap-target floor and must hold unchanged in both orientations per AC #2 and `DESIGN.md components.reading-surface.min-tap-target` / `components.choice-card.min-tap-target` (Home's buttons are covered by the same floor per `EXPERIENCE.md`'s "Home/Tutorial action buttons" note under `reading-surface`).
  - [x] Subtask 1.4: Do not add a `story-sub` subtitle line, design-token colors/typography, or any other visual-identity change — `HomeView.swift` today has only `home.appTitle` + `home.storyTitle` + the two actions (no subtitle exists in code, unlike the mockups). Applying DESIGN.md's full visual identity to Home/Tutorial is Story 1.4's job, not this story's. Stay scoped to the two landscape-specific geometry constraints above.
- [x] Task 2: Retrofit `TutorialPlaceholderView.swift` for landscape (AC: #1)
  - [x] Subtask 2.1: Add `.frame(maxWidth: .infinity, maxHeight: .infinity)` to the placeholder `Text` so it explicitly centers within the full available frame in both orientations, matching the same "every screen reflows, nothing stretches/clips" invariant AC #1 requires — even though this view is a one-line placeholder with no real layout to break.
  - [x] Subtask 2.2: Do not build any part of the real Tutorial screen here (no circuit frame, no reading column, no "Back Home"/"Start Story" actions, no mechanic-explanation text) — `mockups/tutorial-landscape.html` depicts the *real* Tutorial screen's landscape treatment, which is Story 1.3's (build the real screen) and Story 1.4's (visual identity/accessibility) job once they leave backlog. This task only ensures the placeholder itself doesn't rely on implicit/undocumented centering behavior while it's still standing in for the real screen.
- [x] Task 3: Verify (AC: #1, #2)
  - [x] Subtask 3.1: No Xcode/macOS toolchain is available in this devcontainer (consistent with Stories 1.1/1.2/5.2's prior finding). Validate the two edited files by direct source review only: confirm the added `.frame` modifiers are syntactically well-formed Swift (balanced parens/braces) and don't alter any other existing modifier chain order in ways that would change portrait rendering.
  - [x] Subtask 3.2: Flag for the user to verify on macOS/Xcode Simulator: rotate to landscape on Home (both fresh-install and run-in-progress states — `RunSnapshotPresence.hasInProgressRun()` drives the label swap, unaffected by this story) and on the Tutorial placeholder; confirm the title/subtitle/actions stay centered and the action buttons cap at ~320pt instead of stretching edge-to-edge. Also verify at an accessibility Dynamic Type size (e.g. AX5) in landscape that neither screen clips or truncates text, and that VoiceOver can still reach and activate both Home actions with the 44pt tap-target floor intact.
  - [x] Subtask 3.3: No new automated Swift Testing coverage is needed. AD-7 scopes automated test coverage to `StoryRunEngine` logic (ending resolution, echo reachability, pager-gating, `RunSnapshot` round-trip) plus "no automated UI-test requirement beyond the manual/VoiceOver playtesting FR-11 already calls for" — this story is pure SwiftUI layout with two `.frame` modifier additions and no new branching logic, consistent with Story 5.2's identical "no test coverage applies" conclusion for its own doc/build-setting-only scope.

## Dev Notes

- **Why no `verticalSizeClass` branch anywhere in this story:** AD-8 draws a hard line between two cases — a *structural* layout branch (e.g. `choice-card` stack→row, which reads `@Environment(\.verticalSizeClass)`) versus a *geometry-only* change (e.g. a max-width cap), which should be "a plain `.frame(maxWidth:)`-style constraint that is simply a no-op in portrait, not a size-class branch at all." Home/Tutorial fall entirely in the second bucket per `EXPERIENCE.md`'s "Home/Tutorial: same vertical stack ... in both orientations, simply centered within the wider landscape frame — no side-by-side rearrangement." Don't introduce `verticalSizeClass` reads in either file — there is nothing structural to branch on. [Source: ARCHITECTURE-SPINE.md#AD-8]
- **The actual landscape bug this story fixes:** Story 5.2 lifted the OS-level orientation lock but explicitly deferred the layout retrofit, leaving a known, documented gap — `HomeView.swift`'s action buttons use `.frame(maxWidth: .infinity, minHeight: 44)` with no outer width cap, so in a landscape frame (up to ~800pt wide on larger iPhones) they would stretch far beyond the ~320pt the design intends. This is the concrete "stretched/clipped portrait layout" AC #1 is written to catch. [Source: 5-2-landscape-architecture-decision-and-orientation-unlock.md#Dev Agent Record, deferred review item]
- **44pt tap-target floor is already satisfied, don't touch it:** `review-accessibility-landscape.md` (Story 5.1's own review) found the *CSS reference mockups'* buttons/choice-cards fall below 44pt in landscape at default text size — but that's a mockup-authoring defect (shrunk padding/font-size), not a defect in this app's Swift code. `HomeView.swift`'s buttons already hard-code `minHeight: 44` (a real SwiftUI constraint, not CSS-derived), which is orientation-agnostic by construction and already clears the floor in both orientations. Nothing needs to change here for AC #2's tap-target clause — just don't accidentally remove or shrink `minHeight: 44` while adding the width cap. [Source: ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md]
- **Tutorial is still a placeholder — don't over-build it:** `TutorialPlaceholderView.swift` is literally `Text(verbatim: "Tutorial (placeholder)")`, a stand-in until Story 1.3 (still `backlog` in sprint-status.yaml) builds the real screen. The rich `mockups/tutorial-landscape.html` (circuit frame, reading column capped at 680px, "Back Home"/"Start Story" actions) describes what Story 1.3/1.4 will eventually build for landscape too — it is not a spec for this story's placeholder. This story's Tutorial task is intentionally tiny: make the placeholder's own centering explicit, nothing more. (Confirmed with the user during story creation: both Home and the Tutorial placeholder get the retrofit now, rather than deferring Tutorial's task entirely to Story 1.3/1.4.)
- **No design-token Swift layer exists yet:** there is no `DesignTokens.swift`/constants file in this codebase — existing views (`HomeView.swift`, `RootView.swift`) use raw SwiftUI modifiers and numeric literals directly (e.g. `spacing: 24`, `minHeight: 44`). Follow the same convention: use the raw `320` literal for the actions cap, don't invent a token abstraction as part of this story.
- **No test coverage needed:** per AD-7, automated Swift Testing coverage is scoped to `StoryRunEngine`; there's no UI-test target in this project (confirmed: only `ForkedEchoesTests/` exists, covering `RunSnapshotPresence` — no `ForkedEchoesUITests` target). This story adds no new logic to unit test.
- **No Xcode/macOS toolchain in this devcontainer** (same caveat as Stories 1.1, 1.2, 5.2) — validation here is source-review-only; Simulator/device rotation verification is flagged for the user per Subtask 3.2.

### Review Findings

- [x] [Review][Patch] No `ScrollView` fallback for Dynamic Type + landscape — fixed by wrapping both views' content in `ScrollView` + `GeometryReader`, using `.frame(minHeight: proxy.size.height)` so content still centers when it fits but scrolls instead of clipping when Dynamic Type + reduced landscape height push it past the available frame (AC #2). [HomeView.swift, TutorialPlaceholderView.swift] — resolved: user chose to patch now (2026-07-26)
- [x] [Review][Patch] Portrait "near no-op" claim is overstated — fixed by correcting the code comment ([HomeView.swift:33-36]) and Dev Notes/Dev Agent Record wording to describe the ~20% portrait narrowing on the largest phones as an accepted trade-off rather than a no-op.
- [x] [Review][Defer] `StoryChoicePlaceholderView.swift` not retrofitted [StoryChoicePlaceholderView.swift:7] — deferred, pre-existing

### Project Structure Notes

- Files touched: `ForkedEchoes/Views/Home/HomeView.swift` (edit), `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` (edit). No new files, no `Engine/`/`Content/` changes — this story is Presentation-layer-only per AD-8.
- Both files were last touched in Story 1.2 (`22312ef`) and untouched by Stories 5.1/5.2 (which were scoped to docs/design and the build-setting/orientation-lock respectively) — confirmed via `git log`.
- No conflicts with the unified project structure — `Views/` remains a synchronized file-system group (Story 1.1); no membership/group edits needed for a body-only change.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.3] — acceptance criteria, owner (Developer), downstream note about Epic 2+ building landscape-aware from the start
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-8] — landscape-is-a-reflow rule; structural-branch-vs-geometry-only-constraint distinction; `verticalSizeClass` guidance
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#Structural Seed] — landscape layout strategy summary, Capability → Architecture Map (FR-1 Home, FR-2 Tutorial rows: `AD-3, AD-4/AD-8`)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md#Responsive and Platform] — "Home/Tutorial: same vertical stack ... simply centered ... no side-by-side rearrangement" behavioral spec
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/home-landscape.html] — `.content` centering treatment, `.actions{max-width:320px}` cap, `.btn{min-height:44px}`
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/tutorial-landscape.html] — real Tutorial screen's landscape treatment (reference for future Story 1.3/1.4, not this story's placeholder)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md] — 44pt tap-target finding against the CSS mockups (not applicable to this app's Swift code, which already hard-codes `minHeight: 44`)
- [Source: _bmad-output/implementation-artifacts/5-2-landscape-architecture-decision-and-orientation-unlock.md] — deferred "stretched/un-retrofitted landscape UI" review item this story resolves; scope-discipline precedent
- [Source: ForkedEchoes/Views/Home/HomeView.swift] — current implementation to edit
- [Source: ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift] — current implementation to edit
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml] — confirms `1-3-tutorial-screen` and `1-4-home-and-tutorial-visual-identity-and-accessibility-pass` are still `backlog`

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/macOS toolchain available in this devcontainer (consistent with Stories 1.1/1.2/5.2's prior finding). Both edited files were validated via brace/paren balance (`HomeView.swift`: `{`/`}` 11/11, `(`/`)` 27/27; `TutorialPlaceholderView.swift`: `{`/`}` 3/3, `(`/`)` 5/5) and a clean, minimal diff review rather than `xcodebuild`. Actual Simulator-side verification (rotation, Dynamic Type accessibility sizes, VoiceOver) is flagged for the user per Subtask 3.2.

### Completion Notes List

- `HomeView.swift`: added `.frame(maxWidth: 320)` to the actions `VStack` (caps button width in landscape; narrows buttons somewhat in portrait on the largest phones too, an accepted trade-off) and wrapped the outer content in `ScrollView` + `GeometryReader`, with `.frame(maxWidth: .infinity, minHeight: proxy.size.height)` after the outer `.padding()` (explicit centering in both orientations that scrolls instead of clipping when content exceeds the available frame). No `verticalSizeClass` branch added — both changes are geometry-only per AD-8. Existing `minHeight: 44` tap-target floor on both buttons left untouched.
- Post-review patch: added `ScrollView` + `GeometryReader` to both `HomeView.swift` and `TutorialPlaceholderView.swift` to guard against Dynamic Type + landscape overflow (Review Finding, resolved 2026-07-26).
- `TutorialPlaceholderView.swift`: added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to the placeholder `Text` for the same explicit-centering invariant. No part of the real Tutorial screen (circuit frame, reading column, actions) was built — that remains Story 1.3/1.4's scope once they leave backlog.
- No new Swift Testing coverage added — this story introduces no new logic, only SwiftUI layout modifiers, consistent with AD-7's test-scope and Story 5.2's identical precedent.
- No design tokens, colors, typography, or subtitle content were added to either file — those remain Story 1.4's (Home & Tutorial Visual Identity + Accessibility Pass) scope.

### File List

- `ForkedEchoes/Views/Home/HomeView.swift` (modified — landscape action-button width cap + explicit centering)
- `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` (modified — explicit centering)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 5-3 status progression: backlog → ready-for-dev → in-progress → review)
- `_bmad-output/implementation-artifacts/5-3-home-and-tutorial-landscape-retrofit.md` (this story file)

## Change Log

- 2026-07-26: Story created (create-story workflow) and implemented (dev-story workflow) in the same session. Home's action buttons capped to 320pt max-width and both Home/Tutorial-placeholder root views given explicit `.frame(maxWidth: .infinity, maxHeight: .infinity)` centering, resolving the "stretched/un-retrofitted landscape UI" gap Story 5.2 deliberately deferred. No automated tests added (no new logic, per AD-7). Status moved to review.
