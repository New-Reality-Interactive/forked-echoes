---
baseline_commit: 90f9a09f0a786d8aec83e77e2bf71883aebb46ea
retroactive: true
retroactive_note: "This story file was written after the fact (2026-07-26, during Story 5.2's code review) to backfill tracking for work already completed and merged directly by the UX Designer agent (bmad-ux skill) on 2026-07-26, commit d2b71da ('completed 5.1'), merged via PR #28 (5521eb1) — outside the create-story/dev-story flow. It documents what was actually done, reconstructed from _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/.memlog.md and the commit diff, not planned prospectively."
---

# Story 5.1: Landscape UX Design Pass

Status: done

<!-- Retroactive record — see retroactive_note in frontmatter. Written 2026-07-26 to close the traceability gap flagged during Story 5.2's code review (sprint-status.yaml showed 5-1 as done with no backing story file). -->

## Story

As a UX Designer,
I want a documented landscape layout strategy for every screen type (Home, Tutorial, Story/Choice, Interstitial, Ending, Memory),
so that Epic 5 and all subsequent epics can build landscape-aware screens consistently.

## Acceptance Criteria

1. **Given** DESIGN.md/EXPERIENCE.md's current portrait-only specs, **when** this story is complete, **then** both docs include an explicit landscape section covering: reading-surface reflow (column/margin/max-width behavior), circuit-frame behavior in landscape, gesture-zone geometry (swipe/tap-zone page-turn, hold-to-choose) adapted for landscape's wider/shorter aspect ratio, and Home/Tutorial's title-card layout in landscape. [Source: epics.md#Story 5.1]

2. **Given** the 7 existing portrait mockups, **when** this story is complete, **then** Home and Tutorial have landscape companion mockups at minimum (Story/Choice, Ending, Memory landscape mockups may follow when their own epics are built, informed by this story's design language). [Source: epics.md#Story 5.1]

*(Owner: UX Designer agent, via the `bmad-ux` skill — not the Developer agent.)*

## Tasks / Subtasks

- [x] Task 1: Author the landscape design language in DESIGN.md (AC: #1)
  - [x] Subtask 1.1: Add `components.reading-surface` to frontmatter (`column-max-width-landscape: 680px`, `min-tap-target: 44pt`) plus a `## Components` narrative bullet.
  - [x] Subtask 1.2: Add `frame` landscape note (corner geometry reflows to wider/shorter aspect ratio; corner mark sizes stay fixed, only position adapts).
  - [x] Subtask 1.3: Add `choice-card.layout-landscape` token (stack→horizontal-row, 2+1 wrap rule, 44pt floor regardless of layout).
  - [x] Subtask 1.4: Add the Layout & Spacing "Landscape" paragraph consolidating the reflow rules (reading column cap, choice-card row, frame/Home-Tutorial/interstitial carrying over conceptually unchanged, 44pt/headroom parity stated once authoritatively).
  - [x] Subtask 1.5: Add 2 new Do/Don't rows (cap the reading column in landscape; arrange choice cards in a row once landscape width allows it).
- [x] Task 2: Author the landscape behavioral spec in EXPERIENCE.md (AC: #1)
  - [x] Subtask 2.1: Update Foundation's device-target line from portrait-only to portrait+landscape.
  - [x] Subtask 2.2: Add the "Responsive & Platform" section: reading-surface reflow, circuit-frame reflow, choice-card stack→row (with VoiceOver traversal-order-follows-narrative-order clarification), Home/Tutorial unchanged-stack-just-centered, branch-arrival interstitial reflow, page-turn tap-zone parity.
  - [x] Subtask 2.3: Document rotation-mid-interaction behavior for all three cases raised in review: branch-arrival interstitial active (Continue-gate/blocking survives rotation, art recomposes without a jarring cut), echo-active page (power-up state persists/re-renders, no restart), and choice-card hold-in-progress ([ASSUMPTION]: rotation cancels the charge, identical to early release — tap-plus-undo-window and VoiceOver double-tap are unaffected).
- [x] Task 3: Produce landscape mockups (AC: #2)
  - [x] Subtask 3.1: `mockups/home-landscape.html` — fresh-install and run-in-progress states, reflowed.
  - [x] Subtask 3.2: `mockups/tutorial-landscape.html` — dormant frame, reading column capped/centered.
  - [x] Subtask 3.3: `mockups/story-choice-landscape.html` — 2-choice and 3-choice states at default text size (user opted to mock this now rather than defer to Epic 2, since the choice-card row is the biggest visual change); the 3-choice state doubles as a visual check on the "tight fit" assumption. Interstitial/Ending/Memory landscape mockups intentionally deferred to their own future epics.
- [x] Task 4: Reviewer Gate and editorial passes (all ACs)
  - [x] Subtask 4.1: Run rubric review (`review-rubric-landscape.md`) — 7 findings (2 high: interstitial-rotation gap, EXPERIENCE.md cross-reference syntax break using raw `{...}` tokens instead of the `DESIGN.md.X` convention; 4 medium: reading-surface missing a Components bullet, deferred-mockup list mismatch between the two docs, hold-to-choose landscape tap-target confirmation, thin mockup annotations; 1 low: echo-active rotation unaddressed). All resolved via direct spec edits — verified in the current DESIGN.md/EXPERIENCE.md text (e.g. EXPERIENCE.md's landscape citations now correctly use the `` `DESIGN.md.components.X` `` prefix, the interstitial-rotation and echo-rotation bullets exist, `reading-surface` has its Components bullet, both docs list identical deferred-mockup sets, all three landscape mockups have parenthetical state descriptions).
  - [x] Subtask 4.2: Run accessibility review (`review-accessibility-landscape.md`) — findings on the *spec text* (2+1 wrap-to-hard-constraint wording, VoiceOver choice-card traversal order) were resolved via direct spec edits, verified present in current EXPERIENCE.md/DESIGN.md text. Findings on the *reference mockups themselves* (a critical 44pt tap-target violation in all 3 new mockups' CSS at default text size, a medium mismatch between the mockups' reading-column max-width — 520px/480px — and the `680px` token, and a high finding that no accessibility-Dynamic-Type landscape mockup exists to validate the headroom/tight-fit risk) were **not** fixed in the mockup files — the review's own "Fix" language explicitly routes these forward as acceptance criteria for Story 5.3, which is where they remain tracked (see Story 5.2's Dev Notes, which carries this forward).
  - [x] Subtask 4.3: Structural editorial pass — consolidated the 44pt-tap-target/headroom-parity rule (previously restated three times) into one authoritative Layout & Spacing statement; grouped the three rotation-mid-interaction bullets under one lead-in instead of three flat bullets.
  - [x] Subtask 4.4: Prose editorial pass — fixed a double-negative in the Dynamic Type headroom sentence, clarified the reading-surface tap-target sentence, standardized the 3-card-to-2+1-wrap rule's wording identically across both docs.
  - [x] Subtask 4.5: Finalize — both DESIGN.md and EXPERIENCE.md set to `status: final`, `updated: 2026-07-26`.

## Dev Notes

- **This is a retroactive record, not a prospective plan.** All tasks above are reconstructed from `.memlog.md`'s update-session entries and the `d2b71da` commit diff, then marked complete because the work is already merged (PR #28, `5521eb1`). Nothing in this file should be treated as outstanding.
- **Known deferred defects, carried forward into Story 5.2/5.3 — not re-opened here:** the accessibility review's mockup-level findings (44pt violations in `home-landscape.html`/`tutorial-landscape.html`/`story-choice-landscape.html`'s actual CSS, the `column-max-width-landscape` token/mockup mismatch, and the missing SE-size accessibility-scale landscape stress test) remain unresolved in the mockup files themselves. Story 5.2's Dev Notes already documents this explicitly and instructs against re-fixing it there; it is Story 5.3's job. [Source: ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md]
- **Why this story bypassed `create-story`/`dev-story`:** the UX Designer work was executed directly via the `bmad-ux` skill (an "Update," not a fresh "Create," per `.memlog.md`'s first new entry) in the same working session the Sprint Change Proposal was authored in, rather than being queued through sprint tracking first. `sprint-status.yaml`'s `epic-5`/`5-1` entries were consequently left at `backlog` until corrected during Story 5.2's own kickoff (2026-07-26) and code review (2026-07-26), once this gap was noticed.
- **Scope actually stayed disciplined despite the process bypass:** no `Views/`/`Engine/`/`Content/` Swift files were touched — this was pure planning-artifact work (`DESIGN.md`, `EXPERIENCE.md`, `.memlog.md`, 3 new mockup HTML files, plus the two new review docs), consistent with the story's UX-Designer-only ownership.

### Project Structure Notes

- Files touched (from `d2b71da`, scoped to this story's actual UX-design work — excludes the sprint-change-proposal-level edits to `prd.md`/`epics.md`/`ARCHITECTURE-SPINE.md` bundled into the same commit, which belong to the Sprint Change Proposal itself, not this story):
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md` (edit)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md` (edit)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/.memlog.md` (edit)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/home-landscape.html` (new)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/tutorial-landscape.html` (new)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/story-choice-landscape.html` (new)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/review-rubric-landscape.md` (new)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/review-accessibility-landscape.md` (new)
  - `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/validation-report.md` / `validation-report.html` (regenerated)
- No conflicts with the unified project structure — this story never touches the app's Swift source tree.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.1] — acceptance criteria, owner
- [Source: _bmad-output/planning-artifacts/sprint-change-proposal-2026-07-26-landscape-support.md] — the trigger for this story; explicitly scopes the landscape design pass out of the SCP itself and into this story
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/.memlog.md] — session-by-session record this story file was reconstructed from
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/review-rubric-landscape.md, review-accessibility-landscape.md] — Reviewer Gate findings referenced in Task 4
- [Source: git commit d2b71da "completed 5.1", merged via PR #28 / 5521eb1] — the actual change this story documents

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5) — retroactive documentation only; the original work was performed by the UX Designer agent (`bmad-ux` skill) in a prior session, not this one.

### Debug Log References

- Reconstructed task/subtask breakdown by reading `.memlog.md`'s five landscape-related entries and cross-checking each claimed fix against the current text of `DESIGN.md`/`EXPERIENCE.md` (not just trusting the memlog's "all resolved" framing) — confirmed all 7 `review-rubric-landscape.md` findings and the spec-text-level `review-accessibility-landscape.md` findings are actually reflected in the current docs; confirmed the mockup-level accessibility findings are genuinely still open and correctly routed to Story 5.3.

### Completion Notes List

- No functional gaps found between what `.memlog.md` claims and what the current `DESIGN.md`/`EXPERIENCE.md` text contains — the "all resolved" framing in the memlog holds up under direct verification for every rubric finding and the spec-text portion of the accessibility findings.
- This file's purpose is traceability, not re-review — it does not re-litigate or re-score Story 5.1's work, only records what happened.

### File List

- `_bmad-output/implementation-artifacts/5-1-landscape-ux-design-pass.md` (this story file — new)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (no change made by this file's creation — status was already corrected to `done` during Story 5.2's kickoff)
