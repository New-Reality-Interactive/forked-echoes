---
name: 'Sprint Change Proposal — Branch-Arrival Interstitial First-Visit Gate'
type: sprint-change-proposal
status: approved
created: '2026-08-02'
triggering_story: '2-6-branch-arrival-interstitial-and-illustrations'
follow_up_story: '2-9-branch-arrival-interstitial-first-visit-only-gate'
---

# Sprint Change Proposal — Branch-Arrival Interstitial First-Visit Gate

## 1. Issue Summary

Story 2.6 (Branch-Arrival Interstitial & Illustrations) shipped and merged (PR #49) with the interstitial designed as a **one-shot, non-persisted gate**: on arriving at a branch-arrival node, a full-bleed illustration + caption renders, blocking swipe/tap-zone navigation until the player taps Continue — at which point the phase permanently reverts to `.reading` and the node's ordinary body prose is shown instead, for the rest of the run.

Per Story 2.6's AC #8, this was flagged as needing user confirmation in Xcode/Simulator, since the devcontainer used for implementation cannot render SwiftUI. That Simulator playtest happened 2026-08-02, followed by a design discussion (with Sally, UX Designer). The playtest surfaced a genuine design gap, not a bug: the current one-shot behavior means the branch-arrival illustration is erased from the story's path after the first visit — backing up to that node later, or arriving again after an app relaunch, shows plain prose with no trace of the arrival moment. That didn't match the intended feel of the illustration being a real, persistent "place" in the story.

**Design decision reached:** the illustration + caption becomes the arrival node's **permanent** page content (no ordinary-prose swap). The forced-Continue gate (blocking swipe/tap-zone) applies **only on the node's true first-ever visit**; every later visit — same session or after a relaunch — renders identically but behaves like an ordinary swipeable page. The trigger mechanism itself (a dedicated Continue button, not tap-anywhere, a timer, or a custom gesture) was reconsidered and reconfirmed as correct — a button is the only option that doesn't conflict with the existing "tap-zones do nothing during the interstitial" rule and needs no extra VoiceOver work.

## 2. Impact Analysis

**Epic Impact:** None at the epic level. Epic 2 remains fully achievable as planned; no epic resequencing, no new epic, no impact on Epic 2's other stories (2.7's run-options-absent rule and 2.5's `visitedNodeIds` mechanism are unaffected — 2.5's existing mechanism is in fact what makes this fix cheap).

**Story Impact:**
- **Story 2.6** — already `done`/merged. Left historically intact (its AC accurately describes what was actually shipped); one pointer note added referencing the amendment.
- **New Story 2.9** — added to `epics.md` (after 2.8, to avoid renumbering the still-backlog 2.7/2.8, which are already referenced by name elsewhere) and to `sprint-status.yaml` as `backlog`. Owns implementing the revised gating behavior.

**Artifact Conflicts:**
- `ARCHITECTURE-SPINE.md` AD-5 — updated. Removed the "relaunch resumes straight into the node's reading content" framing (implied a permanent, always-different ordinary-prose fallback); added the `visitedNodeIds`-keyed first-visit-ever gate description, with a dated amendment note following the same pattern as AD-5's prior (Story 2.2) amendment.
- `EXPERIENCE.md` — two rows updated: the Branch-arrival interstitial IA-table row (removed "not a page" framing) and the "Interstitial active" state-pattern row (added the first-visit-only qualifier).
- PRD — no conflict. FR-12 (bundled illustrations) is untouched; this is an interaction-behavior refinement, not a requirements change.
- No other artifacts (deployment, CI, infra) affected.

**Technical Impact:** Implementation direction (for Story 2.9's dev pass, not decided here): key the first-visit gate off `visitedNodeIds`, which already exists and is already persisted per `RunSnapshot` (AD-4, in use since Story 2.5 for echo reachability) — no new persisted state needed. Story 2.6's Swift Testing coverage needs revision: any test currently asserting a permanent revert to ordinary body prose after dismissal must be updated or removed.

## 3. Recommended Approach

**Selected: Option 1 — Direct Adjustment**, via a new follow-up story (2.9) rather than reopening Story 2.6.

Rationale:
- Effort: **Low**. Risk: **Low**. No new components, no new persisted state, reuses an existing mechanism (`visitedNodeIds`).
- Rollback (Option 2) isn't applicable — nothing is broken, this refines intended behavior.
- MVP scope review (Option 3) isn't applicable — no PRD/FR impact.
- A new story (rather than editing Story 2.6 in place) was chosen deliberately: Story 2.6 is `done` and already merged to `main`. Rewriting its AC would misrepresent what was actually built and shipped under that story number. This project's own precedent (Story 2.2's AD-5 amendment) shows in-place doc amendment happening only while the *triggering* story was still in `review`, pre-merge — that precedent doesn't extend to editing a already-merged story's historical record. A dated, cross-referenced amendment (matching how AD-5 itself already carries a "(Amended ..., Story X)" note) keeps history accurate while making the current rule easy to find.

## 4. Detailed Change Proposals

### Architecture — `ARCHITECTURE-SPINE.md`, AD-5

**OLD:**
> Interstitial is a derived, non-persisted phase, not a distinct RunSnapshot state: if the app terminates while it's showing, relaunch resumes straight into the node's reading content without re-showing the arrival announcement.

**NEW:**
> The branch-arrival illustration+caption is the arrival node's permanent page content — there is no separate "ordinary reading content" to fall back to. Phase derives to `.interstitial` (forced-Continue, no swipe/tap-zone) only on a node's true first-ever visit, keyed off `visitedNodeIds` (already persisted per AD-4/Story 2.5) rather than a session-only flag — so the gate correctly reflects first-visit-ever, not merely first-visit-this-session. Every subsequent visit — backing up to the node, or arriving again after an app relaunch — renders the identical illustration+caption but behaves as an ordinary swipeable page (`advancePage()`/`goBack()` behave normally, no Continue button needed).

Plus a new dated amendment paragraph explaining the change, following the existing Story 2.2 amendment's format. **Status: applied.**

### UX — `EXPERIENCE.md`

IA-table row and "Interstitial active" state-pattern row both updated to remove the "not a page"/always-blocking framing and add the first-visit-only qualifier. **Status: applied.**

### Epics — `epics.md`

- Story 2.6: one-line pointer note added, pointing to Story 2.9. **Status: applied.**
- Story 2.9 added (full text in `epics.md`, after Story 2.8). **Status: applied.**

### Sprint tracking — `sprint-status.yaml`

- `2-9-branch-arrival-interstitial-first-visit-only-gate: backlog` added under `epic-2`. **Status: applied.**

## 5. Implementation Handoff

**Scope classification: Minor.**

- **Route to:** Developer agent (`bmad-dev-story` / `bmad-create-story`), via the normal Story 2.9 cycle whenever the user is ready to schedule it (Epic 2 still has 2.7 and 2.8 ahead of it in the backlog; sequencing is the user's call).
- **Deliverables ready now:** this proposal, the updated architecture/UX docs, and Story 2.9's full AC in `epics.md` — everything a `create-story` pass needs to produce a dev-ready story file.
- **Success criteria:** Story 2.9's three ACs pass Swift Testing coverage and Simulator manual verification (per this project's standing process agreement of user-confirmed Simulator checks for any view-layer change).
