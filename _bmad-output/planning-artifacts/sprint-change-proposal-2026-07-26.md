# Sprint Change Proposal — Alignment Score / Ending Resolution Correction

**Date:** 2026-07-26
**Project:** Many-Worlds CYOA iOS App (v1)
**Trigger point:** Surfaced during `bmad-create-epics-and-stories`, while drafting Epic 3 Story 3.1 (`scoreToEnding`), before it was saved to `epics.md`.

## 1. Issue Summary

The PRD, its addendum, the spec kernel, and the Architecture spine all described ending resolution (home/stay/limbo) as a **computed** outcome: alignment deltas summed per choice into a running score, then checked against numeric bands (Home 1-2, Stay 3-4, Limbo otherwise). This was a misreading of the original design intent, caught when the user reviewed Epic 3's proposed `scoreToEnding` story and stopped to clarify.

**Correct understanding:** Ending kind is a **direct, authored property of each terminal node** in the story tree — fixed at write-time, not computed. The "1-2" and "3-4" figures were always a content-authoring ratio (how many distinct home-ending and stay-ending terminal nodes to write), not score thresholds. Alignment score still exists as a real running tally, but its only role is a reflective display stat on the Memory screen — it has zero influence on which ending a run reaches.

The misreading was consistent enough that a genuine-seeming "boundary bug" (Home 1-2 / Stay 2-4 overlapping at score 2) was caught and fixed by hand during PRD authoring — a bug that only existed because of the wrong mental model in the first place.

**Category:** Misunderstanding of original requirements.

## 2. Impact Analysis

**Epic Impact:**
- Epic 1 (Home & Onboarding) and Epic 2 (Story Reader, Choice Echo & Branch Realities) — **no impact**. Epic 2 Story 2.3's alignment-delta accumulation is still exactly correct; only the *downstream use* of that accumulated value changes.
- Epic 3 (Alignment Scoring, Ending & Memory Recap) — **not yet saved**, so no rollback needed. Story 3.1 requires a full redesign (no threshold function; ending kind read directly off the terminal node). Story 3.3 needs its score/tier framing clarified as cosmetic-only. Will be redrafted when `bmad-create-epics-and-stories` resumes.

**Story Impact:** None of the 12 already-saved stories (Epic 1: 4, Epic 2: 8) require changes. Epic 3's 5 proposed stories (never saved) will be redrafted, and are expected to come out simpler — a threshold function and its boundary-case tests are no longer needed.

**Artifact Conflicts (all resolved in this proposal):**
- PRD (`prd.md`) — FR7, FR8, Glossary
- PRD Addendum (`addendum.md`) — full rewrite of the "Alignment score → ending tier thresholds" section
- Spec kernel (`SPEC.md`, `glossary.md`) — CAP-7, CAP-8, Constraints, glossary
- Architecture (`ARCHITECTURE-SPINE.md`) — AD-1 (clarifying addition), AD-6 (full rewrite), AD-7 (testing surface), Capability→Architecture Map, Structural Seed comment
- Architecture Explainer (`EXPLAINER.md`) — AD-6 rationale section, full rewrite
- Epics document (`epics.md`) — FR7/FR8 in Requirements Inventory, two Additional Requirements bullets, Epic 3's testing note

**Not touched (deliberately):** `DESIGN.md`/`EXPERIENCE.md` (never encoded the threshold mechanic — verified, no conflict), historical review documents (`review-adversarial.md`, `review-rubric-walker.md`, etc. — left as an honest record of a past review, not rewritten).

**Technical Impact:** None — zero code exists yet. This is the cheapest possible point in the project to have caught this.

## 3. Recommended Approach

**Selected: Option 1 — Direct Adjustment.** All affected documents corrected in place; no rollback needed (nothing built yet encoded the wrong mechanic), no MVP/scope reduction needed (vision and goals are untouched — this is a mechanism correction, not a scope change).

Effort: Low-Medium. Risk: Low.

## 4. Detailed Change Proposals

All six proposals below were presented incrementally and approved individually by the user.

### 4.1 PRD (`prd.md`)
- FR7: added explicit statement that the running total has no bearing on ending; added a "no ending influence" testable consequence.
- FR8: rewritten from score/tier resolution to direct per-terminal-node resolution; added content-authoring ratio guidance as a new Note.
- Glossary: "Alignment score" and "Ending taxonomy" entries rewritten to reflect direct node-authored ending kind.

### 4.2 PRD Addendum (`addendum.md`)
- "Alignment score → ending tier thresholds" section replaced with "Ending taxonomy: terminal-node authoring ratio," including a dated correction note explaining what changed and why (the boundary-overlap "fix" is retired along with the misreading it was patching).

### 4.3 Spec Kernel (`SPEC.md`, `glossary.md`)
- CAP-7, CAP-8, and the Constraints section rewritten to mirror the corrected PRD, using SPEC's CAP-numbering.
- `glossary.md` updated to match `prd.md`'s glossary correction.

### 4.4 Architecture (`ARCHITECTURE-SPINE.md`)
- AD-1: added a clarifying sentence decoupling ending kind (per-node, compile-time-guaranteed) from alignment deltas (display-only data).
- AD-6: retitled and fully rewritten from "Ending resolution is one pure function" (`scoreToEnding`) to "Ending kind is a direct property of the terminal node reached."
- AD-7: testing surface reworded — no more "alignment-tier boundary cases"; now verifies terminal-node `EndingKind` coverage and hard-fail reachability.
- Capability→Architecture Map: FR-8 row updated to point at `Content` (per-node `EndingKind`) instead of `Engine` (`scoreToEnding`).
- Structural Seed: removed `scoreToEnding` from the `Engine/` folder comment.

### 4.5 Architecture Explainer (`EXPLAINER.md`)
- AD-6 rationale section retitled and rewritten to narrate the correction transparently — what the mistake was, why the boundary "bug" was itself a symptom of the wrong model, and what changed.

### 4.6 Epics Document (`epics.md`)
- FR7/FR8 in Requirements Inventory updated to match the corrected PRD.
- Two Additional Requirements bullets replaced with corrected versions (direct per-node ending kind; alignment score as display-only data).
- Epic 3's "Testing note" in the Epic List replaced with a revised note reflecting the simpler testing responsibility.

## 5. Implementation Handoff

**Scope classification: Moderate.** Touches upstream PRD/Architecture (beyond pure backlog reorganization) but does not require a fundamental replan — vision, scope, and MVP are fully intact; this is a targeted mechanism correction, already fully drafted and applied in this session.

**Handoff:** Resume `bmad-create-epics-and-stories` at Step 3 (story generation) to redraft Epic 3 against the corrected documents. No PM/Architect escalation needed beyond the corrections already made here — the corrected Architecture is self-consistent and ready to build against.

**Success criteria:** Epic 3's redrafted stories reference `EndingKind` as a direct per-node property (no `scoreToEnding`), and no remaining document in `_bmad-output/` describes ending resolution as score-threshold-driven.
