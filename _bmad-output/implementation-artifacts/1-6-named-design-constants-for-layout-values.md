---
baseline_commit: c5618bafad7a350fd4430960c2f90fa1f455711e
---

# Story 1.6: Named Design Constants for Layout Values

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want numeric layout literals (spacing, sizing, opacity) in view code to reference named constants — sourced from a DESIGN.md token where one exists, or a suitably named local constant where one doesn't,
so that values stay traceable to design intent and are never silently duplicated or drifted between call sites.

## Acceptance Criteria

1. **Given** a numeric layout literal in `Views/Home/HomeView.swift` or `Views/Tutorial/TutorialView.swift` that corresponds to a DESIGN.md token (the 8pt spacing scale `{spacing.1}`–`{spacing.8}`, `{components.reading-surface.min-tap-target}` = 44pt, `{components.reading-surface.column-max-width-landscape}` = 680px), **when** it is used, **then** it references a named Swift constant derived from that token, not an inline literal. [Source: epics.md#Story 1.6, lines 317-321]
2. **Given** a numeric layout literal with no corresponding DESIGN.md token (e.g. the action-stack width cap, the subtitle width cap, `SecondaryActionButtonStyle`'s border width, the pressed/disabled opacity values in `ButtonStyles.swift`), **when** it is used, **then** it is defined as a named Swift constant with a descriptive name, not an inline literal. [Source: epics.md#Story 1.6, lines 323-325]
3. **Given** two or more literals across the touched files that share the same value and the same semantic context (e.g. the `320`pt action-stack cap used identically in both `HomeView.swift` and `TutorialView.swift`), **when** they are extracted, **then** they reference one shared constant, not separate per-file definitions. [Source: epics.md#Story 1.6, lines 327-329]
4. **Given** the existing `Views/DesignSystem/` folder (established in Story 1.4) already holds `Typography.swift`/`ButtonStyles.swift` as the project's design-token home, **when** new constants are added, **then** they live in a new file in that same folder, following its existing naming/organization conventions. [Source: epics.md#Story 1.6, lines 331-333]
5. **Given** this is a pure refactor of existing, already-shipped Home/Tutorial/ButtonStyles code, **when** the change is complete, **then** rendered output, layout, and behavior are pixel-for-pixel unchanged — no visual or functional diff. [Source: epics.md#Story 1.6, lines 335-337]

## Tasks / Subtasks

- [x] Task 1: Create `Views/DesignSystem/LayoutMetrics.swift` (AC: #1, #2, #4)
  - [x] Subtask 1.1: Added `Views/DesignSystem/LayoutMetrics.swift` with a header comment describing its purpose, matching `Typography.swift`'s convention.
  - [x] Subtask 1.2: Defined DESIGN.md-sourced constants for every token value actually consumed by `HomeView.swift`/`TutorialView.swift` (only `{spacing.2}`, `{spacing.4}`, `{spacing.6}` — not the full scale): `Spacing.token2` (8pt), `Spacing.token4` (16pt), `Spacing.token6` (24pt), `LayoutMetrics.minTapTarget` (44pt), `LayoutMetrics.readingColumnMaxWidthLandscape` (680pt). Each has a `///` doc comment citing its DESIGN.md token path.
  - [x] Subtask 1.3: Defined no-token constants: `LayoutMetrics.subtitleMaxWidth` (280pt, Home-only), `LayoutMetrics.actionStackMaxWidth` (320pt, shared Home+Tutorial), `ButtonMetrics.borderWidth` (2pt), `ButtonMetrics.pressedOpacity` (0.75, shared), `ButtonMetrics.disabledOpacity` (0.4, shared).
  - [x] Subtask 1.4: Left the bare `1` in the opacity ternaries untouched — not extracted, per its rationale (implicit full-opacity baseline, no traceability purpose).

- [x] Task 2: Replace inline literals in `HomeView.swift` (AC: #1, #2, #3, #5)
  - [x] Subtask 2.1: `VStack(spacing: 24)` → `Spacing.token6`.
  - [x] Subtask 2.2: `VStack(spacing: 8)` → `Spacing.token2`.
  - [x] Subtask 2.3: `.frame(maxWidth: 280)` (subtitle) → `LayoutMetrics.subtitleMaxWidth`. Existing mockup-provenance comment preserved unchanged.
  - [x] Subtask 2.4: `VStack(spacing: 16)` → `Spacing.token4`.
  - [x] Subtask 2.5: Both `minHeight: 44` sites → `LayoutMetrics.minTapTarget`.
  - [x] Subtask 2.6: `.frame(maxWidth: 320)` → `LayoutMetrics.actionStackMaxWidth`. Existing AD-8 comment preserved unchanged.

- [x] Task 3: Replace inline literals in `TutorialView.swift` (AC: #1, #2, #3, #5)
  - [x] Subtask 3.1: `VStack(spacing: 24)` → `Spacing.token6`.
  - [x] Subtask 3.2: `VStack(alignment: .leading, spacing: 16)` → `Spacing.token4` (alignment unchanged).
  - [x] Subtask 3.3: `.frame(maxWidth: 680, alignment: .leading)` → `LayoutMetrics.readingColumnMaxWidthLandscape`. Existing AD-8/landscape rationale comment preserved unchanged.
  - [x] Subtask 3.4: `VStack(spacing: 16)` → `Spacing.token4` (same constant as Subtask 3.2, one definition/two call sites).
  - [x] Subtask 3.5: Both `minHeight: 44` sites → `LayoutMetrics.minTapTarget` (same constant Task 2.5 introduced).
  - [x] Subtask 3.6: `.frame(maxWidth: 320)` → the same `LayoutMetrics.actionStackMaxWidth` Task 2.6 introduced — no second constant defined. Existing AD-8 comment preserved unchanged.

- [x] Task 4: Replace inline literals in `ButtonStyles.swift` (AC: #2, #3, #5)
  - [x] Subtask 4.1: `Rectangle().stroke(Color.inkPrimary, lineWidth: 2)` → `ButtonMetrics.borderWidth`.
  - [x] Subtask 4.2: Both `opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)` sites → `0.75` replaced with `ButtonMetrics.pressedOpacity`, `0.4` with `ButtonMetrics.disabledOpacity` (bare `1` left as-is). Same two constants referenced from both `PrimaryActionButtonStyle` and `SecondaryActionButtonStyle`.

- [x] Task 5: Verify pure-refactor equivalence (AC: #5)
  - [x] Subtask 5.1: Confirmed every constant's assigned value exactly matches the literal it replaced (8, 16, 24, 44, 680, 280, 320, 2, 0.75, 0.4) via side-by-side diff review — no transpositions.
  - [x] Subtask 5.2: Static verification performed (no Xcode/Swift toolchain in this devcontainer): brace/paren balance check passed on all 4 touched/new files (counts match on both sides); `grep -nE "spacing: [0-9]|maxWidth: [0-9]|minHeight: [0-9]"` on `HomeView.swift`/`TutorialView.swift` and `grep -nE "lineWidth: [0-9]|0\.75|0\.4[^0-9]"` on `ButtonStyles.swift` returned zero matches — none of the 10 values remain as bare literals at their original call sites.
  - [x] Subtask 5.3: **User-verified in Simulator (2026-07-27):** build succeeded and Home/Tutorial/button rendering confirmed working as expected — AC #5's pixel-for-pixel parity holds.

## Dev Notes

- **Scope boundary:** Exactly four files: three modified (`HomeView.swift`, `TutorialView.swift`, `ButtonStyles.swift`) and one new (`Views/DesignSystem/LayoutMetrics.swift` or equivalent name). Do not touch `Typography.swift`, `Localizable.xcstrings`, `RootView.swift`, or any engine/content code — none are implicated by this story's ACs. This is a pure refactor: no new UI, no new strings, no behavior change (AC #5).
- **Full literal→constant mapping** (the exhaustive list this story must resolve):

  | Value | Token / Rationale | Files & call sites |
  |---|---|---|
  | 8pt | `{spacing.2}` | `HomeView.swift` title `VStack` |
  | 16pt | `{spacing.4}` | `HomeView.swift` actions `VStack`; `TutorialView.swift` text `VStack` and actions `VStack` |
  | 24pt | `{spacing.6}` | `HomeView.swift` and `TutorialView.swift` outer `VStack`s |
  | 44pt | `{components.reading-surface.min-tap-target}` | 4 action-button `minHeight` sites across both files |
  | 680pt | `{components.reading-surface.column-max-width-landscape}` | `TutorialView.swift` text-column `.frame(maxWidth:)` |
  | 280pt | No token — Home-only subtitle width cap (matches `mockups/home.html`'s `.story-sub { max-width:280px }`) | `HomeView.swift` subtitle only |
  | 320pt | No token — shared action-stack width cap | `HomeView.swift` and `TutorialView.swift` actions `VStack`, identical value/semantics — **one shared constant** |
  | 2pt | No token — `SecondaryActionButtonStyle` border width | `ButtonStyles.swift`, single site |
  | 0.75 | No token — pressed-state opacity | `ButtonStyles.swift`, both button styles — **one shared constant** |
  | 0.4 | No token — disabled-state opacity | `ButtonStyles.swift`, both button styles — **one shared constant** |

- **Why this story exists:** Flagged during Story 1.5's code review — the user noticed several magic numbers across these three files while reviewing and asked for a dedicated cleanup story. `project-context.md`'s "Design tokens" rule (already in force for *new* code since before this story) formalizes the policy this story retroactively applies: DESIGN.md-sourced values get a named constant tied to their token; valueless numbers get a descriptive name; duplicate same-context values collapse to one shared constant.
- **Don't over-scope the spacing scale:** DESIGN.md defines `{spacing.1}` through `{spacing.8}` (4pt–40pt), but only `{spacing.2}`, `{spacing.4}`, `{spacing.6}` are actually used in the two touched view files today. Define only those three — adding the unused five would be speculative, contradicting the project's "no design for hypothetical future requirements" norm. If a later story needs another scale step, it adds that constant then.
- **Two width caps are easy to conflate — don't:** 280pt (subtitle, Home-only) and 320pt (action stack, shared Home+Tutorial) are different values for different elements. AC #3's "one shared constant" rule applies to the 320pt cap (and the two opacity values) because those are *identical value + identical semantic context* across sites — it does not mean collapsing 280 and 320 together.
- **The bare `1` in `ButtonStyles.swift`'s opacity ternary is intentionally left alone** — it's the full-opacity default, not a design-sourced magic number. Extracting it would add a constant with no traceability benefit.
- **Naming and doc-comment convention:** Follow `Typography.swift`'s existing pattern — each design-token-sourced constant gets a `///` doc comment citing the exact DESIGN.md token path it derives from (e.g. `Typography.swift` lines 33, 38, 48 model this for typography roles). No-token constants get a plain descriptive doc comment explaining what they cap/control and which mockup or file they were pulled from (matching `HomeView.swift`'s existing inline comment at lines 22-24 for the 280pt cap, and lines 41-44 for the 320pt cap — those comments should move with the literal to the new constant file, or be referenced from both places, developer's judgment).
- **Preserve existing inline comments in the view files** — several call sites being touched (`HomeView.swift` lines 22-24, 41-44; `TutorialView.swift` lines 26-32, 51-52) have load-bearing rationale comments (mockup provenance, AD-8 landscape reasoning, the Spacer-free-VStack warning from Story 1.4). Replacing the literal must not silently drop this context — either keep the comment in place above the now-named-constant reference, or ensure the constant's own doc comment in the new file captures the same rationale.
- **Testing standard (AD-7):** Swift Testing coverage is scoped to `StoryRunEngine` logic only. This story touches no engine code and introduces no new behavior — no automated test additions expected, consistent with Stories 1.2/1.3/1.4/1.5/5.3's precedent. The only verification is the static equivalence check in Task 5 plus a user Simulator pass to confirm AC #5's pixel-for-pixel claim.

### Previous Story Intelligence

- **From Story 1.5:** `Views/DesignSystem/` currently holds `Typography.swift` (view-modifier-based text styles, each with a `///` doc comment citing its DESIGN.md token) and `ButtonStyles.swift` (the two `ButtonStyle` structs this story edits). Both files are filesystem-synchronized under Xcode's `PBXFileSystemSynchronizedRootGroup` — adding `LayoutMetrics.swift` (or whatever it's named) needs **zero** `project.pbxproj` edits; Xcode auto-discovers it on disk.
- **From Story 1.5:** The `GeometryReader` + `ScrollView` + `minHeight: proxy.size.height` centering pattern and the Spacer-free flat `VStack` structure in both `HomeView.swift` and `TutorialView.swift` are load-bearing for landscape correctness (Story 5.3) — this story only swaps literal values for named constants at existing call sites; it must not restructure the `VStack` nesting, add/remove a `Spacer`, or touch the `GeometryReader`/`ScrollView` wrapping in either file.
- **From Story 1.5's code review:** the reviewer caught a case where a width cap (280pt) was missing entirely and had to be patched in — a reminder that these width-cap values are easy to under-scope. This story's job is the opposite risk: make sure none of the 10 cataloged values above are missed or silently changed in the process of extraction.
- **From Story 1.4:** `ButtonStyles.swift`'s two styles were built specifically to avoid iOS 26's rounded default button chrome (Liquid Glass) per DESIGN.md's sharp-corners rule — this story does not touch that shape/style decision, only the two styles' numeric literals (border width, opacity).

### Project Structure Notes

- One new file: `ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` (name is a developer judgment call within `Views/DesignSystem/`; must follow that folder's existing file-per-concern convention — one file for the new layout/opacity constants, not merged into `Typography.swift` or `ButtonStyles.swift`, per AC #4).
- Three modified files: `ForkedEchoes/Views/Home/HomeView.swift`, `ForkedEchoes/Views/Tutorial/TutorialView.swift`, `ForkedEchoes/Views/DesignSystem/ButtonStyles.swift`.
- `Views/` is a filesystem-synchronized Xcode group; no `project.pbxproj` changes needed for the new file or the edits to existing ones.
- No conflicts detected with the unified project structure.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.6, lines 311-339]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md — frontmatter `spacing` scale (lines 87-95) and `components.reading-surface` block (lines 109-112); Layout & Spacing section (lines 229-239)]
- [Source: _bmad-output/project-context.md — "Design tokens (colors, spacing, sizing)" rule, the section this story formalizes]
- [Source: _bmad-output/implementation-artifacts/1-5-home-story-subtitle.md — Dev Notes, Review Findings (the 280pt subtitle-cap patch), Completion Notes]
- [Source: ForkedEchoes/Views/Home/HomeView.swift, ForkedEchoes/Views/Tutorial/TutorialView.swift, ForkedEchoes/Views/DesignSystem/ButtonStyles.swift, ForkedEchoes/Views/DesignSystem/Typography.swift — current source, read in full]

### Review Findings

- [x] [Review][Patch] `Spacing.small`/`.medium`/`.large` doc comments name specific caller screens ("used for HomeView's title/eyebrow/subtitle grouping", "used for the Home/Tutorial actions groups and Tutorial's text group", "used for HomeView's and TutorialView's outer content stacks") — inconsistent with `Typography.swift`'s precedent (which documents only the DESIGN.md token, never the caller) and will read as stale documentation the moment a third screen or a different grouping adopts these shared constants. **Applied:** doc comments now cite only the DESIGN.md token and point value (e.g. `/// DESIGN.md {spacing.2} = 8pt.`), matching `Typography.swift`'s convention. [ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift]

**Dismissed as noise/false positive/handled elsewhere (11):** a claim that `readingColumnMaxWidthLandscape`'s doc comment misquotes DESIGN.md's unit ("680pt" vs. the doc's literal "680px") — matches pre-existing project precedent, not a new inconsistency: `TutorialView.swift`'s own preserved inline comment already read "680pt" before this story touched the file; a claim that leaving the bare `1` in the opacity ternaries unextracted contradicts the file's stated goal — explicitly directed by the story's Subtask 1.4 with documented rationale (implicit full-opacity baseline, no traceability value), not an oversight; a claim that other reading surfaces (Story/Choice, Ending, Memory) don't yet reference `readingColumnMaxWidthLandscape`/`minTapTarget` — those screens don't exist in the codebase yet (Epics 2/3 are still backlog), confirmed via `grep` that no other file duplicates these literals, so there's nothing to migrate and no risk of a stray duplicate today; a claim of 3 incompatible naming conventions across `Spacing`/`LayoutMetrics`/`ButtonMetrics` and a follow-on claim that t-shirt-size naming doesn't scale to a future 4th spacing value — both already weighed and explicitly decided by the user this session (semantic naming chosen over numeric with the scaling tradeoff disclosed up front); a claim that AD-8 rationale is now duplicated between `LayoutMetrics.swift`'s doc comments and the view files' inline comments — the story's own Dev Notes explicitly permitted this as a judgment call ("either keep the comment in place... or ensure the constant's own doc comment captures the same rationale"); a claim that `ButtonMetrics` overpromises app-wide scope — already sufficiently scoped by its own doc comments ("shared... by both action button styles") and the file only having two `ButtonStyle` consumers today; a claim that "pure refactor, unchanged" is an unverified assertion absent a snapshot test — already self-disclosed in this story's Debug Log/Completion Notes as a devcontainer limitation, not a newly surfaced gap; a claim that filing screen-specific `Spacing` under a "DesignSystem" folder implies false universality — the folder location and single-new-file structure are mandated by AC #4, not an implementation choice; a claim that the enums lack explicit access-control modifiers — confirmed consistent with the file's own consumers (`ButtonStyle` structs are also implicit `internal`), no mismatch; a claim that `Spacing`/`LayoutMetrics` are collision-prone generic top-level names — speculative, no actual collision exists in this codebase or SwiftUI today.



### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/Swift toolchain available in this devcontainer (consistent with every prior story). Verified statically via: brace/paren balance check on all 4 touched/new `.swift` files (all balanced), and targeted `grep` confirming none of the 10 replaced literals (8, 16, 24, 44, 680, 280, 320, 2, 0.75, 0.4) remain as bare values at their original call sites in `HomeView.swift`/`TutorialView.swift`/`ButtonStyles.swift`. Actual Simulator build/run (visual pixel-for-pixel check per AC #5) was not performed here — flagged for the user.
- **User build report:** first Xcode build after the review's patch failed with "Cannot find `ButtonMetrics` in scope" in `ButtonStyles.swift`. Root cause was not a code or project-membership defect — `LayoutMetrics.swift` was verified present in `Views/DesignSystem/` with correct contents, and `project.pbxproj`'s `Views` `PBXFileSystemSynchronizedRootGroup` has zero exceptions and is already listed in the `ForkedEchoes` target's `fileSystemSynchronizedGroups`, so the new file should auto-include with no manual project-file change needed. The failure was Xcode's synchronized-group scan being stale from the file having been created by an external tool while Xcode wasn't watching. User confirmed the file appeared correctly in the Project Navigator, quit and reopened Xcode, and the subsequent build **succeeded**.
- **User Simulator verification (2026-07-27):** ran the app in Simulator — Home, Tutorial, and both button styles all render as expected, confirming AC #5's pixel-for-pixel parity claim. No visual regressions from the literal→constant substitutions.

### Completion Notes List

- Added `ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` with three namespaces: `Spacing` (DESIGN.md 8pt-scale tokens actually in use: `small`={spacing.2}=8pt, `medium`={spacing.4}=16pt, `large`={spacing.6}=24pt), `LayoutMetrics` (`minTapTarget`=44pt and `readingColumnMaxWidthLandscape`=680pt from DESIGN.md's `components.reading-surface`; plus the no-token `subtitleMaxWidth`=280pt and `actionStackMaxWidth`=320pt), and `ButtonMetrics` (no-token `borderWidth`=2pt, `pressedOpacity`=0.75, `disabledOpacity`=0.4). Each constant carries a doc comment citing its DESIGN.md token path or explaining its local-only rationale, mirroring `Typography.swift`'s existing convention. **Naming note:** `Spacing`'s members were initially named after their DESIGN.md scale index (`token2`/`token4`/`token6`); renamed to semantic `small`/`medium`/`large` per user review feedback — traceability is preserved via each member's doc comment citing its exact `{spacing.N}` token, so the semantic name doesn't lose the DESIGN.md link, it just reads better at call sites.
- Replaced all 10 cataloged bare-literal call sites across `HomeView.swift`, `TutorialView.swift`, and `ButtonStyles.swift` with references to the new constants. `actionStackMaxWidth` (320pt) and both opacity constants are shared identically between the two files/two button styles rather than duplicated, per AC #3. `subtitleMaxWidth` (280pt) was kept distinct from `actionStackMaxWidth` (320pt) — different values for different elements, not collapsed together.
- Deliberately did not extract the bare `1` in `ButtonStyles.swift`'s `isEnabled ? (configuration.isPressed ? ... : 1) : ...` ternary — it's the implicit full-opacity/no-op default, not a design-sourced magic number, and naming it would add an unneeded abstraction.
- Deliberately did not pre-define the unused portion of DESIGN.md's `{spacing.1}`–`{spacing.8}` scale (only `{spacing.2}`, `{spacing.4}`, `{spacing.6}` are consumed by the touched files today) — adding the other five would be speculative work with no current call site, contrary to the project's no-premature-abstraction norm. A later story needing another scale step can add it then.
- Every existing load-bearing inline comment at the touched call sites (mockup provenance for the 280pt cap, AD-8 landscape rationale for both 320pt caps and the 680pt column, the 44pt contentShape note) was preserved verbatim — only the literal itself was swapped for the named constant.
- Pure refactor: no new strings, no new UI, no behavior change. No new Swift Testing coverage added — this story touches no `StoryRunEngine`/engine logic, consistent with AD-7's test scope and the precedent set by every prior view-only story (1.2/1.3/1.4/1.5/5.3).
- **Flagging for the user:** AC #5 requires "pixel-for-pixel unchanged" output. Static analysis (diff review, brace balance, grep) confirms every constant's value exactly matches the literal it replaced, but actual rendered-output verification needs a Simulator build/run pass, unavailable in this devcontainer.

### File List

- `ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift` (new — `Spacing`, `LayoutMetrics`, `ButtonMetrics` constant namespaces)
- `ForkedEchoes/Views/Home/HomeView.swift` (modified — replaced 6 bare literals with named constants)
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` (modified — replaced 6 bare literals with named constants, 2 shared with HomeView)
- `ForkedEchoes/Views/DesignSystem/ButtonStyles.swift` (modified — replaced 3 bare literals [x2 sites each for 2 of them] with named constants)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 1-6 status progression: ready-for-dev → in-progress → review)
- `_bmad-output/implementation-artifacts/1-6-named-design-constants-for-layout-values.md` (this story file)

## Change Log

- 2026-07-26: Story created (create-story workflow).
- 2026-07-26: Implemented (dev-story workflow). Added `Views/DesignSystem/LayoutMetrics.swift` with `Spacing`/`LayoutMetrics`/`ButtonMetrics` constant namespaces, and replaced all 10 cataloged bare-literal call sites across `HomeView.swift`, `TutorialView.swift`, and `ButtonStyles.swift`. Verified via diff review, brace-balance check, and grep that every value maps 1:1 to what it replaced. No automated tests added (no new engine logic, per AD-7). Simulator build/run verification could not be performed in this devcontainer (no Xcode toolchain) — flagged for the user. Status moved to review.
- 2026-07-26: Post-implementation, user requested renaming `Spacing`'s members from `token2`/`token4`/`token6` to semantic `small`/`medium`/`large` (too-generic naming feedback) — applied across `LayoutMetrics.swift` and both view files' call sites.
- 2026-07-27: Code review (3-layer adversarial + edge-case + acceptance audit against this story file and DESIGN.md). Edge Case Hunter and Acceptance Auditor both returned clean (zero findings — all 5 ACs satisfied, no value drift, no unhandled edge cases). Applied 1 patch from the adversarial layer: reworded `Spacing.small`/`.medium`/`.large`'s doc comments to cite only their DESIGN.md token (matching `Typography.swift`'s convention) instead of naming specific caller screens, removing a documentation-staleness risk. Dismissed 11 findings as noise, pre-existing precedent, already-decided-by-user, or speculative/out of scope. Status moved to done.
