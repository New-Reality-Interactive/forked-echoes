---
baseline_commit: a393363a316d9e9ae675d1b646d7bb084f57e547
---

# Story 1.5: Home Story Subtitle

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want a short one-line description of the story beneath its title on Home,
so that I know what I'm about to start before committing to it.

## Acceptance Criteria

1. **Given** Home renders, fresh install or run-in-progress, **when** displayed, **then** a subtitle line appears directly below the story title (`home.storyTitle`) and above the action buttons, matching `mockups/home.html`/`mockups/home-landscape.html`'s `.story-sub` placement — present in both Home states shown in those mockups. [Source: epics.md#Story 1.5, lines 293-295]
2. **Given** all Home screen text (AD-2), **when** the subtitle renders, **then** its copy is sourced from `Localizable.xcstrings` via a stable key (`home.storySubtitle`), never hardcoded — placeholder English copy is acceptable for now, same pattern `home.storyTitle` already uses ("Untitled Story") pending Epic 4's full prose authoring. [Source: epics.md#Story 1.5, lines 297-299]
3. **Given** the accessibility bar Story 1.4 already established for Home (VoiceOver labels, Dynamic Type scaling without truncation, 44pt tap targets on actions), **when** the subtitle is added, **then** it meets the same bar — included in VoiceOver reading order between story title and actions, scales with Dynamic Type without clipping — no new exceptions introduced. [Source: epics.md#Story 1.5, lines 301-303]
4. **Given** Story 5.3's landscape retrofit of Home (capped/centered content, `GeometryReader` + `ScrollView`), **when** the subtitle is added, **then** it participates in that existing layout without requiring new landscape-specific handling. [Source: epics.md#Story 1.5, lines 305-307]

## Tasks / Subtasks

- [x] Task 1: Add the `home.storySubtitle` localization key (AC: #2)
  - [x] Subtask 1.1: In `ForkedEchoes/Resources/Localizable.xcstrings`, add a new top-level key `home.storySubtitle` immediately after `home.storyTitle`, following that entry's exact JSON shape: `comment` describing it as "Home screen: short one-line subtitle beneath the story title, describes the story (placeholder until Epic 4 authors the real copy)", `extractionState: "manual"`, one `en` localization with `state: "translated"`. [Source: ForkedEchoes/Resources/Localizable.xcstrings, `home.storyTitle` entry]
  - [x] Subtask 1.2: Placeholder copy is a judgment call — either a generic stand-in matching `home.storyTitle`'s "Untitled Story" pattern (e.g. "A short story description.") or the mockup's illustrative sentence ("A choose-your-own-adventure about finding your way back, one decision at a time.") are both acceptable; AC #2 only requires it be non-hardcoded and String-Catalog-sourced. Either choice is replaced wholesale by Epic 4.

- [x] Task 2: Add a subtitle text style (AC: #1, #3)
  - [x] Subtask 2.1: DESIGN.md's named `typography` roles (`headline` 34px, `body` 20px, `choice-label` 17px, `eyebrow` 12px, `caption` 17px, `meta` 12px, `stat` 34px) do not include one matching `.story-sub`'s CSS (`font-size:15px` portrait / `13px` landscape, `color:var(--ink-soft)`, regular line-height, no letter-spacing) — this is a gap in DESIGN.md's token set, not something to leave unresolved. Bind to the `.subheadline` iOS text style (closest match to 15pt at the default Dynamic Type category, and — like every other role here — a *named* text style so Dynamic Type keeps scaling it automatically, per DESIGN.md's Typography section rule: "Each role binds to a named iOS text style... not a raw point size"). Color: `Color.inkSecondary` (already exists from Story 1.4, matches `.story-sub`'s `var(--ink-soft)` / `ink-secondary` token — no new Color Set needed).
  - [x] Subtask 2.2: Add to `ForkedEchoes/Views/DesignSystem/Typography.swift` as a new `View` extension method `.subtitleStyle()`. Unlike `.eyebrowStyle()`/`.headlineStyle()`, the mockup's `.story-sub` CSS specifies no `letter-spacing`, so no `@ScaledMetric`-driven `tracking()` is needed — model it after `.bodyStyle()`'s simpler shape (plain `View` extension, no `ViewModifier` struct required): `.font(.subheadline)` + `.foregroundStyle(Color.inkSecondary)`.
  - [x] Subtask 2.3: Do not invent a new DESIGN.md-scoped weight token — `.subheadline`'s default system weight (regular) is a reasonable match for `.story-sub`'s unstated (i.e. CSS-default/normal) `font-weight`; DESIGN.md's other roles all state their weight explicitly, this one's absence in the mockup CSS is itself the signal that no override is needed.
  - [x] Subtask 2.4: Flag this token gap in Completion Notes (mirrors how Story 1.4 flagged its headline-uppercase override) so DESIGN.md's `typography` block can be reconciled with a named `subtitle` role later — that doc update is not this story's job.

- [x] Task 3: Render the subtitle in `HomeView.swift` (AC: #1, #3, #4)
  - [x] Subtask 3.1: Add `Text("home.storySubtitle").subtitleStyle().multilineTextAlignment(.center)` as a third child inside the existing `VStack(spacing: 8) { Text("home.appTitle")...; Text("home.storyTitle")... }` block, immediately after the story title — this reuses the already-established 8pt-scale grouping (UX-DR2) rather than introducing new spacing values, and naturally places it below the title / above the actions `VStack` per AC #1. Do not restructure the outer `VStack(spacing: 24)` or introduce a `Spacer` — Story 1.4's Dev Notes flagged the Spacer-free `VStack` nesting as load-bearing for landscape correctness (Story 5.3).
  - [x] Subtask 3.2: No `verticalSizeClass` branch, no orientation-conditional font size, and no changes to the `GeometryReader`/`ScrollView`/`minHeight: proxy.size.height` centering pattern — the subtitle is just a third item in an already-reflowing, already-centered stack (AD-8, AC #4). Note: `home-landscape.html`'s `.story-sub` CSS shows a smaller `13px` vs. portrait's `15px`, but `.headlineStyle()` (the story title, right above it) already renders at one fixed size in both orientations with no precedent for orientation-conditional type scale anywhere in this codebase — follow that precedent and use one size in both orientations; do not add a landscape-specific font-size branch for this story.
  - [x] Subtask 3.3: No explicit accessibility modifiers needed — `HomeView` currently has no `.accessibilityElement(children: .combine)` or similar grouping, so each `Text` already gets its own accessibility element in natural (top-to-bottom) VoiceOver reading order; placing the subtitle between the title and the actions `VStack` (Subtask 3.1) satisfies AC #3's reading-order requirement with no extra code.
  - [x] Subtask 3.4: No `.lineLimit()` or `.fixedSize()` — consistent with AC #3's Dynamic Type / no-truncation requirement and the precedent set by every other Home/Tutorial text element.

- [x] Task 4: Manual verification (AC: #1, #3, #4)
  - [x] Subtask 4.1: **User-verified in Simulator (2026-07-26):** subtitle placement (below title, above actions, both Home states), VoiceOver reading order, Dynamic Type at an accessibility size, and both orientations all confirmed working correctly.
  - [x] Subtask 4.2: No automated UI test required per AD-7 — this story introduces no new engine logic, only a new localized string and view styling, consistent with Stories 1.2/1.3/1.4/5.3's precedent.

## Dev Notes

- **Scope boundary:** This story only touches three things: one new `Localizable.xcstrings` key (`home.storySubtitle`), one new typography helper in `Views/DesignSystem/Typography.swift` (`.subtitleStyle()`), and one new `Text` line in `HomeView.swift`. Do not touch `RootView.swift`, `RunSnapshotPresence`, `TutorialView.swift`, existing `Localizable.xcstrings` values, or the existing button styles — none of them are implicated by this story's ACs.
- **Typography token gap:** DESIGN.md's `typography` block has no role matching `.story-sub`'s CSS (15px/13px, `ink-soft`, no explicit weight). Task 2 resolves this by binding to the closest named iOS text style (`.subheadline`) rather than a fixed point size, consistent with every other role in DESIGN.md. This is a genuine spec gap, not an oversight to silently paper over — flag it in Completion Notes.
- **No orientation-conditional type size:** `home-landscape.html`'s `.story-sub` is smaller (13px) than `home.html`'s (15px), same as the story title (28px vs. 38px) — but `.headlineStyle()` already renders the title at one fixed size regardless of orientation, with no precedent anywhere in this codebase for `verticalSizeClass`-branched font sizes. Follow that existing precedent for the subtitle too; don't introduce the first one here.
- **Landscape/AD-8:** The subtitle is a third child in the already-reflowing, already-centered `VStack` (Story 5.3's `GeometryReader`+`ScrollView`+`minHeight: proxy.size.height` pattern) — it participates for free. No new landscape-specific code path, per AD-8's "no orientation-specific view types" rule.
- **Reuse `Color.inkSecondary`:** already added in Story 1.4 (`#6A5A45` / dark `#B7A78D`) and matches `.story-sub`'s `var(--ink-soft)`. No new Color Set needed.
- **Testing standard:** Per AD-7, Swift Testing covers `StoryRunEngine` logic only. This story has no new engine logic — no automated test additions expected, consistent with Stories 1.2/1.3/1.4/5.3.

### Previous Story Intelligence

- **From Story 1.4:** `Views/DesignSystem/Typography.swift` already exists with `.eyebrowStyle()`/`.headlineStyle()` (both `ViewModifier` structs using `@ScaledMetric(relativeTo:)` for tracking, added during 1.4's code review to keep letter-spacing proportional at accessibility sizes) and `.bodyStyle()` (a plain `View` extension, no tracking). Since `.story-sub` has no letter-spacing in its CSS, model `.subtitleStyle()` on `.bodyStyle()`'s simpler shape — a `@ScaledMetric` wrapper would be unnecessary complexity here.
- **From Story 1.4:** The `GeometryReader`+`ScrollView`+`minHeight: proxy.size.height` centering pattern and the Spacer-free flat `VStack` structure in `HomeView.swift` are load-bearing for landscape correctness (Story 5.3) — do not restructure them, only add the new `Text` line inside the existing title `VStack`.
- **From Story 1.4:** `HomeView.swift`'s title block is `VStack(spacing: 8) { Text("home.appTitle").eyebrowStyle(); Text("home.storyTitle").headlineStyle().multilineTextAlignment(.center) }`, inside an outer `VStack(spacing: 24)` whose next child is the actions `VStack(spacing: 16)`. Both spacing values are already on DESIGN.md's 8pt scale (UX-DR2) — don't introduce new spacing constants for the subtitle.
- **Cross-cutting, not this story's concern:** `deferred-work.md` documents a cold-launch orientation mismatch (tracked as Story 5.4, currently backlog) — unrelated to this story, don't attempt to fix if observed during manual verification.

### Project Structure Notes

- No new files. Modified files only: `ForkedEchoes/Resources/Localizable.xcstrings`, `ForkedEchoes/Views/DesignSystem/Typography.swift`, `ForkedEchoes/Views/Home/HomeView.swift`.
- `Views/` is a filesystem-synchronized Xcode group; no `project.pbxproj` changes needed for edits to existing files.
- No conflicts detected with the unified project structure.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5, lines 285-309]
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md — AD-2, AD-7, AD-8]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md — frontmatter `typography`/`colors` blocks; Typography section (lines 217-227); Layout & Spacing (229-239)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/home.html — `.story-sub` CSS (line 44) and markup (lines 69, 88)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/home-landscape.html — `.story-sub` CSS (line 45) and markup (lines 71, 90)]
- [Source: _bmad-output/implementation-artifacts/1-4-home-and-tutorial-visual-identity-and-accessibility-pass.md — Dev Notes, Review Findings, Completion Notes]
- [Source: ForkedEchoes/Views/Home/HomeView.swift, ForkedEchoes/Views/DesignSystem/Typography.swift, ForkedEchoes/Resources/Localizable.xcstrings — current source, read in full]

### Review Findings

- [x] [Review][Patch] Subtitle has no width cap matching `mockups/home.html`'s `.story-sub` (`max-width:280px`) — unlike the actions `VStack` (`.frame(maxWidth: 320)`), neither the subtitle `Text` nor its containing title `VStack` constrains width, so on wide layouts (landscape, larger phones) the one-line blurb can stretch far wider than the mockup's compact "jacket copy" intent. **Applied:** added `.frame(maxWidth: 280)` to the subtitle `Text`. [ForkedEchoes/Views/Home/HomeView.swift]
- [x] [Review][Patch] Verification status is contradictory across three places after the user's Simulator pass was recorded: Subtask 4.1 and Completion Notes say verified/confirmed working, but the Change Log entry still says verification "could not be performed... flagged for the user," Debug Log References still says it "is flagged for the user," and `sprint-status.yaml`'s `last_updated` still says "still outstanding." **Applied:** reconciled all three to reflect the user's confirmed Simulator verification. [1-5-home-story-subtitle.md Change Log / Dev Agent Record → Debug Log References; _bmad-output/implementation-artifacts/sprint-status.yaml]
- [x] [Review][Patch] `.subtitleStyle()`'s doc comment cites only the portrait 15pt CSS value and omits that `home-landscape.html` specifies a different 13px value for the same element (a deliberate no-orientation-branch decision recorded in the story's Dev Notes, but absent from the code comment a future maintainer is most likely to read). **Applied:** expanded the doc comment to note the deliberate same-size-in-both-orientations decision. [ForkedEchoes/Views/DesignSystem/Typography.swift]
- [x] [Review][Defer] No automated existence/regression test for the new subtitle string/view [ForkedEchoes/Views/Home/HomeView.swift] — deferred, pre-existing: no UI existence/snapshot testing pattern exists anywhere in this codebase (1.2/1.3/1.4/5.3 precedent), and AD-7 scopes automated coverage to `StoryRunEngine` logic only.

**Dismissed as noise/false positive/handled elsewhere (6):** a claim that the DESIGN.md typography-token gap should be written into `DESIGN.md`/`deferred-work.md` — the story's own Dev Notes explicitly scope that doc reconciliation out of this story ("that doc update is not this story's job"); a claim that `subtitleStyle()` is an "overly generic" name for a Home-specific value in a shared file — consistent with the existing `eyebrowStyle()`/`headlineStyle()`/`bodyStyle()` precedent in the same file, all of which are similarly Home/Tutorial-specific; a claim that the subtitle should be VoiceOver-grouped with the title (`.accessibilityElement(children: .combine)`) — AC #3 requires the subtitle be its own reading-order stop between title and actions, so combining would be an unrequested design change, not a fix; a note that the placeholder subtitle's evocative copy reads oddly next to `home.storyTitle`'s generic "Untitled Story" — both are independently-approved placeholders under AC #2, replaced wholesale by Epic 4, not a defect in this story's scope; a note that the new placeholder is a full sentence vs. other short Home labels, an unflagged "localization workload asymmetry" — informational only, violates no AC or constraint; a claim that the localization key's placement (before `home.storyTitle` rather than the story's literal "immediately after" wording) is a spec deviation — self-disclosed in Completion Notes with sound rationale (preserves the file's existing alphabetical convention), not an actual defect.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/Swift toolchain available in this devcontainer (consistent with every prior story). Verified statically via: `python3 -m json.tool` on `Localizable.xcstrings` (valid JSON); brace-balance check on `Typography.swift` and `HomeView.swift`; `grep` confirming no `.lineLimit()`/`.fixedSize()`/`Font.system(size:)` was introduced (AC #3 truncation-risk check). Actual Simulator build/run (visual placement check, VoiceOver reading order, Dynamic Type at an accessibility size, both orientations) was performed by the user directly — see Subtask 4.1.

### Completion Notes List

- Added `home.storySubtitle` to `Localizable.xcstrings`, following `home.storyTitle`'s exact JSON shape (comment, `extractionState: "manual"`, one `en` `stringUnit`). Placed it immediately *before* `home.storyTitle` rather than "immediately after" as the story's Subtask 1.1 literally said — the file's existing keys are in alphabetical order (`home.action.*` → `home.appTitle` → `home.storyTitle`), and `storySubtitle` sorts before `storyTitle`; keeping that established convention took priority over the story's literal placement wording, which was really about locality, not sort order. Used the mockup's illustrative sentence ("A choose-your-own-adventure about finding your way back, one decision at a time.") as placeholder copy per Subtask 1.2's judgment call — Epic 4 replaces it wholesale regardless of which placeholder option was picked.
- Added `.subtitleStyle()` to `Views/DesignSystem/Typography.swift` as a plain `View` extension (no `ViewModifier`/`@ScaledMetric`, matching `.bodyStyle()`'s shape since `.story-sub` has no letter-spacing to scale) binding to the named `.subheadline` text style with `Color.inkSecondary`. **Flagging the token gap this resolves:** DESIGN.md's `typography` block has no role matching `.story-sub`'s CSS (15px/13px, `ink-soft`, unstated/regular weight) — `.subheadline` is the closest named iOS text style to 15pt at the default Dynamic Type category. This should be reconciled into DESIGN.md as a named `subtitle` role in a future doc pass; out of scope for this story.
- Rendered the subtitle in `HomeView.swift` as a third child of the existing `VStack(spacing: 8)` title block, right after `home.storyTitle`, with `.multilineTextAlignment(.center)` matching the title. No `verticalSizeClass` branch, no orientation-conditional font size, no changes to the `GeometryReader`/`ScrollView`/`minHeight: proxy.size.height` centering pattern or the Spacer-free `VStack` nesting — the subtitle participates in the existing landscape reflow (AD-8) and 8pt spacing scale (UX-DR2) for free.
- Did **not** touch: `RootView.swift`, `RunSnapshotPresence`, `TutorialView.swift`, existing `Localizable.xcstrings` values, or the button styles — all out of scope per Dev Notes, none needed changes for this story's ACs.
- No new Swift Testing coverage added — this story introduces no new `StoryRunEngine`/engine logic, only a localized string and view styling, consistent with AD-7's test scope and Stories 1.2/1.3/1.4/5.3's precedent.
- Subtask 4.1's Simulator verification (subtitle placement, VoiceOver reading order, Dynamic Type at an accessibility size, both orientations) was performed by the user directly and confirmed working correctly (2026-07-26).

### File List

- `ForkedEchoes/Resources/Localizable.xcstrings` (modified — added `home.storySubtitle` key)
- `ForkedEchoes/Views/DesignSystem/Typography.swift` (modified — added `.subtitleStyle()`)
- `ForkedEchoes/Views/Home/HomeView.swift` (modified — renders the subtitle)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 1-5 status progression: ready-for-dev → in-progress → review)
- `_bmad-output/implementation-artifacts/1-5-home-story-subtitle.md` (this story file)

## Change Log

- 2026-07-26: Story created (create-story workflow).
- 2026-07-26: Implemented (dev-story workflow). Added `home.storySubtitle` to `Localizable.xcstrings`, `.subtitleStyle()` to `Views/DesignSystem/Typography.swift` (binds to `.subheadline` — no DESIGN.md token matches `.story-sub`'s CSS, flagged as a doc gap), and rendered it in `HomeView.swift` as a third child of the title `VStack`. No automated tests added (no new engine logic, per AD-7). Simulator build/run/VoiceOver/Dynamic Type verification could not be performed in this devcontainer (no Xcode toolchain) — flagged for the user. Status moved to review.
- 2026-07-26: User performed Simulator verification directly — subtitle placement (both Home states), VoiceOver reading order, Dynamic Type at an accessibility size, and both orientations all confirmed working correctly.
- 2026-07-26: Code review (3-layer adversarial + edge-case + acceptance audit against this story file). Applied 3 patches: added `.frame(maxWidth: 280)` to the subtitle `Text` to match `mockups/home.html`'s `.story-sub` width cap (previously unbounded, could stretch too wide on landscape/large phones), reconciled the Change Log/Debug Log entries with the user's confirmed Simulator verification (they still read as outstanding after the fact), and expanded `.subtitleStyle()`'s doc comment to note the deliberate same-size-in-both-orientations decision (landscape's mockup specifies a different 13px value). Deferred 1 finding (no automated existence/regression test for the new string/view — pre-existing project-wide gap, out of AD-7's scope). Dismissed 6, including a self-disclosed, soundly-reasoned localization-key placement deviation and several informational/by-design observations that didn't violate any AC.
