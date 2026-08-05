# Sprint Change Proposal — Epic 3 Pre-Implementation Review

**Date:** 2026-08-05
**Author:** Brian Mericle (via Claude Code / bmad-correct-course)
**Trigger type:** Misunderstanding/staleness of original requirements (planning-artifact drift), plus minor spec-completeness gaps

---

## 1. Issue Summary

Before starting any Epic 3 ("Alignment Scoring, Ending & Memory Recap") story work, a pre-implementation edge-case review was run against `epics.md`'s Epic 3 section, cross-referenced with `ARCHITECTURE-SPINE.md`, `addendum.md`, `DESIGN.md`, and the PRD. This was requested specifically to avoid repeating Epic 2's pattern, where three unplanned bug-fix stories (2.12, 2.13, 2.14) had to be added mid-epic to close gaps not caught during planning (see `epic-2-retro-2026-08-05.md`).

The review found two categories of issue:

1. **Stale cross-references** — two prior corrections (AD-7's 2026-07-26 rework dropping score-threshold ending resolution; `addendum.md`'s same-day correction clarifying the "1-2 home / 3-4 stay" numbers were never score bands) each fixed one document but left sibling documents pointing at the pre-correction design.
2. **Spec-completeness gaps** — behaviors implied by existing rules (negative alignment scores per FR-7, relaunch during a completed-run screen per AD-4) that no AC anywhere actually specifies.

No Epic 3 code or story files exist yet, so all fixes are edits to planning documents only.

---

## 2. Impact Analysis

### Epic Impact
- **Epic 3:** Can proceed as originally structured — no story additions, removals, or resequencing. All fixes are in-place text edits to the shared NFR list and to Stories 3.1 and 3.2's acceptance criteria, plus one new architecture decision record.
- **Epic 4** ("Story Content & Illustration Production"): Downstream-affected only in that it inherits an explicit "finalize with real numbers" obligation (ending-node ratio + score→tier boundaries) once the real v1 tree is authored. No new Epic 4 story required — the obligation is anchored in AD-9 and Story 3.1's AC.
- **Epic 5:** No impact.

### Artifact Conflicts
- **PRD:** None. FR-7 and FR-8 already correctly describe alignment score as having no bearing on ending resolution. FR-10 already commits to a "score/tier" display — the tier-band fix here fulfills an already-promised requirement rather than expanding scope.
- **Architecture (`ARCHITECTURE-SPINE.md`):** AD-7 itself is already correct; one new AD-9 is added to give the score→tier mapping the same single-source-of-truth treatment AD-6 gives ending resolution.
- **UX (`DESIGN.md`):** No changes needed — `memory-score` component styling is already correct; only the *content source* for the tier label was missing, which AD-9 now supplies a contract for.
- **Other artifacts:** No deployment/IaC/CI impact. `sprint-status.yaml` requires no story-count changes (see Section 6.4 below).

### Technical Impact
None — no code exists for Epic 3 yet. Zero implementation risk from these changes; this is the lowest-cost point in the process to make them.

---

## 3. Recommended Approach

**Selected: Option 1 — Direct Adjustment.**

All five original findings resolve to documentation-level edits within the current epic/story structure. No rollback is applicable (nothing implemented yet to roll back) and no PRD/MVP scope review is needed (PRD already correctly scopes this; see 3.1 above).

**Effort:** Low (five text edits across two files). **Risk:** Low (no code touched, no dependencies broken).

---

## 4. Detailed Change Proposals

### 4.1 — NFR3 reword (`epics.md:53`)

**OLD:**
> NFR3: Automated test coverage — Engine logic (`StoryRunEngine`) must be covered by Swift Testing: alignment-tier resolution (including boundary cases), echo-callback reachability as authored in the tree, hard-fail bypass, pager-gating (forward blocked on unresolved choice; locked display on revisit), and `RunSnapshot` encode/decode round-trip.

**NEW:**
> NFR3: Automated test coverage — Engine logic (`StoryRunEngine`) must be covered by Swift Testing: every terminal node resolves to exactly one `EndingKind` with no ambiguity, echo-callback reachability as authored in the tree, hard-fail terminal nodes reachable only via their designated gotcha choice, pager-gating (forward blocked on unresolved choice; locked display on revisit), and `RunSnapshot` encode/decode round-trip (including the alignment-score field, verified only for correct accumulation/persistence, not for any ending-resolution role).

**Justification:** Brings NFR3 into agreement with AD-7 (`ARCHITECTURE-SPINE.md:88`), corrected 2026-07-26 to drop tier-threshold ending resolution. Story 3.1's AC (`epics.md:771`) cites NFR3 directly and inherits the fix automatically — no separate edit needed there.

---

### 4.2 — New AD-9 (`ARCHITECTURE-SPINE.md`, appended after AD-8)

**NEW:**
> ### AD-9 — Alignment score maps to a display-only tier via one pure function
>
> - **Binds:** Memory screen, `StoryRunEngine`'s alignment-score field (AD-4)
> - **Prevents:** tier-label logic being duplicated or invented ad hoc at the View layer; tier boundaries drifting between what's documented and what's implemented.
> - **Rule:** A single pure function, `scoreToTier(score: Int) -> Tier`, is the one place score→tier-label boundaries live (mirrors AD-6's `EndingKind` pattern). The lowest tier's range is open-ended toward negative infinity (never a fixed floor like "0"), so no possible score — including negative — falls through unmapped. `Tier`'s label text is sourced from `Localizable.xcstrings` per AD-2, never hardcoded. Concrete boundary values and tier count are placeholder until Epic 4 authors the real v1 story tree and its actual score distribution is known — same open item as Story 3.1's ending-node-ratio guidance (`addendum.md`); both should be finalized together once real content exists, not guessed now.

**Justification:** Story 3.3 (`epics.md:827-829`) introduces a "descriptive tier label ... derived from the score" with no defined mapping anywhere — not in Epic 3, `addendum.md` (whose correction explicitly removed the only score-threshold numbers that ever existed), `DESIGN.md`, or UX-DR8. Rather than inventing numbers now (repeating the exact mistake the 2026-07-26 correction already fixed once), AD-9 establishes the contract — pure function, single source of truth, open-ended bottom band — and defers concrete numbers to Epic 4 when real score-distribution data exists.

---

### 4.3 — Story 3.3 new AC (`epics.md`, appended after line 841)

**NEW:**
> **Given** `scoreToTier(score:)` (AD-9)
> **When** the accumulated alignment score is negative, zero, or any value outside a placeholder band's current bounds
> **Then** it still resolves to exactly one tier — no unmapped/crash state — because the lowest band is open-ended

**Justification:** Closes the negative/zero-score edge case (FR-7 explicitly allows +/- values) by requiring the open-ended-bottom-band contract from AD-9 to actually be tested, without needing concrete numbers to exist yet.

---

### 4.4 — Story 3.1 AC edit (`epics.md:773`)

**OLD:**
> **And** content-authoring guidance is documented for later story-tree writing: roughly 1-2 terminal nodes as home endings and 3-4 as stay endings across the full v1 tree (addendum.md); this story's placeholder tree only needs enough terminal nodes to exercise all four `EndingKind` cases at least once each

**NEW:**
> **And** content-authoring guidance is documented for later story-tree writing: roughly 1-2 terminal nodes as home endings and 3-4 as stay endings across the full v1 tree (addendum.md) — both this ratio and AD-9's score→tier boundaries are placeholder until Epic 4 authors the real v1 tree and finalizes them together against actual score distribution; this story's placeholder tree only needs enough terminal nodes to exercise all four `EndingKind` cases at least once each

**Justification:** Anchors the "finalize once real content exists" obligation in the story itself, not just in AD-9's note — `addendum.md`'s own correction already flagged the ratio as provisional and unrevisited; this closes the ownership gap so it doesn't silently harden into Epic 4's default.

---

### 4.5 — Story 3.2 new AC (`epics.md`, appended after line 805)

**NEW:**
> **Given** the app is backgrounded or terminated while on the Ending or Memory screen
> **When** it relaunches
> **Then** Home renders in its fresh-install "Start Story" state — `RunSnapshot` was already cleared on entering Ending (Story 3.1, AD-4), so there is no in-progress run to resume and no persisted recap to restore; this is expected, not a bug

**Justification:** AD-4 already dictates this behavior by construction (no engine change needed) — this states it as a deliberate, documented decision rather than an implicit consequence nobody wrote down, closing the same class of "quietly true but never stated" gap that produced Epic 2's unplanned stories.

---

## 5. Implementation Handoff

**Scope classification: Minor.** All five changes are direct text edits to existing planning documents (`epics.md`, `ARCHITECTURE-SPINE.md`) — no code, no backlog reorganization, no new stories, no PRD change.

**Route to:** Direct implementation (no Developer-agent story cycle needed — these are planning-artifact edits, not code). Brian Mericle applies/approves the edits directly in this session.

**Success criteria:**
- `epics.md` NFR3 and Story 3.1/3.2/3.3 ACs updated as specified above
- `ARCHITECTURE-SPINE.md` gains AD-9
- `sprint-status.yaml` unchanged (no story count/ID changes — confirmed in Section 6 below)
- Epic 3 story creation (`bmad-create-story`) can proceed with Story 3.1 next, using the corrected documents
