# Sprint Change Proposal — Landscape Orientation Support

**Date:** 2026-07-26
**Project:** Forked Echoes (iOS, v1)
**Trigger point:** Surfaced by the user while manually testing Story 1.2 (Home Screen) in the iOS Simulator — rotating the device did nothing.

## 1. Issue Summary

The app is currently architected and built as iPhone-only, portrait-only for v1 — a deliberate, documented decision, not a bug:

- `ARCHITECTURE-SPINE.md` (Structural Seed): *"Device target: iPhone only for v1 — matches the portrait-only, single-column reading surface `EXPERIENCE.md` specifies."*
- `epics.md` (Additional Requirements): *"Device target: iPhone only, portrait only, single Xcode app target, Debug/Release configurations only."*
- `project.pbxproj` (both Debug/Release configs, set in Story 1.1): `INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait`
- Every UX artifact (`DESIGN.md`, `EXPERIENCE.md`, all 7 mockups) is portrait-only single-column; zero landscape design exists anywhere.
- The PRD itself never specifies orientation (confirmed via search — zero mentions of "portrait"/"landscape"/"orientation"). The constraint lived only in Architecture/Epics, not the PRD.

**Category:** New requirement emerging from the user as stakeholder (not a bug, not a misunderstanding — a deliberate scope expansion beyond the original v1 decision).

**Decision:** Do this now, before Epic 2, rather than deferring to post-MVP. Rationale: only 2 of 27 planned stories are built (both simple screens — Home, and the scaffold). Waiting until after Epic 2 builds the reading-surface/pager mechanics (swipe/tap-zone page-turn, hold-to-choose gestures, all currently designed around a single-column portrait surface) would make retrofitting landscape substantially more expensive.

## 2. Impact Analysis

**Epic Impact:**
- Epic 1 (Home & Onboarding) — no change to its own 4 stories; they proceed as planned. Story 1.2 (already done) becomes an early landscape-retrofit target (Epic 5, Story 5.3).
- Epic 2 (Story Reader, Choice Echo & Branch Realities) — highest-complexity impact. Its 8 not-yet-created stories should incorporate landscape from the start once Epic 5's design language exists, avoiding a second retrofit.
- Epic 3 (Alignment Scoring, Ending & Memory Recap) — its closing story (3.5, End-to-end accessibility validation) should validate landscape too; not yet created, no immediate edit needed.
- Epic 4 (Story Content & Illustration Production) — branch-reality illustration aspect ratios and App Store screenshots (Story 4.6) may need landscape variants; not yet created, no immediate edit needed.
- **New Epic 5 (Landscape Support)** added — see Section 4.

**Story Impact:** No existing story files are rolled back or invalidated. Story 1.2 (done) will need a landscape pass once Epic 5's Stories 5.1/5.2 land (tracked as Epic 5 Story 5.3, not a reopen of 1.2).

**Artifact Conflicts (all resolved in this proposal):**
- PRD (`prd.md`) — §4.6 Cross-Cutting NFRs: added explicit Orientation bullet.
- Architecture (`ARCHITECTURE-SPINE.md`) — Structural Seed device-target statement corrected; new "Landscape layout strategy: TBD" note added (the actual strategy is real UX design work, out of scope for this proposal).
- Epics (`epics.md`) — Additional Requirements bullet corrected; new Epic 5 (summary + full 3-story section) added.
- UX (`DESIGN.md`, `EXPERIENCE.md`, mockups) — **not edited by this proposal.** A full landscape design pass is required (Epic 5 Story 5.1) and is genuine design work for the UX Designer agent (`bmad-ux` skill), not something to improvise here.
- `sprint-status.yaml` — new `epic-5` block inserted between `epic-1` and `epic-2` so Epic 5's stories are picked up next by `create-story`, without renumbering Epics 2-4 (which are already cross-referenced by number in Story 1.2's implementation/Dev Notes — renumbering would create unnecessary blast radius for a sequencing decision).

**Technical Impact:** `project.pbxproj`'s `INFOPLIST_KEY_UISupportedInterfaceOrientations` orientation lock is a code-level consequence, to be lifted in Epic 5 Story 5.2 once the design work exists to build against.

## 3. Recommended Approach

**Selected:** Option 1 — Direct Adjustment (add Epic 5 within the existing plan, no rollback, no MVP scope reduction).

- **Effort:** High — a full landscape UX design pass across 6 screen types, an architecture decision, and orientation unlock.
- **Risk:** Medium — well-scoped (new epic, no renumbering), but genuinely substantial design work with no existing precedent to build from.
- **Rejected alternatives:**
  - *Rollback:* not applicable — nothing built conflicts badly enough to need reverting.
  - *MVP scope reduction:* the user explicitly chose expansion over deferral, so this doesn't apply; deferring to post-MVP was considered and declined in favor of doing it now while cheap.
  - *Renumbering Epics 2-4 to insert landscape as "Epic 2":* rejected due to existing by-number cross-references in Story 1.2.

## 4. Detailed Change Proposals

### PRD (`prds/prd-game-2026-07-25/prd.md`, §4.6)

```diff
 - **Platform:** Native iOS, on-device only — no network calls, no backend, no external integrations.
 - **Compatibility:** Support current major iOS release and the previous one (N-1).
+- **Orientation:** Supports both portrait and landscape on iPhone (see Epic 5: Landscape Support).
```

### Architecture (`ARCHITECTURE-SPINE.md`, Structural Seed)

```diff
-**Device target:** iPhone only for v1 — matches the portrait-only, single-column reading surface `EXPERIENCE.md` specifies. iPad/Universal is not excluded by anything architectural, just not designed for; see Deferred.
+**Device target:** iPhone only for v1, supporting both portrait and landscape orientation — the single-column reading surface `EXPERIENCE.md` specifies reflows for landscape rather than assuming portrait-only. iPad/Universal is not excluded by anything architectural, just not designed for; see Deferred.
+
+**Landscape layout strategy:** TBD — pending the UX Designer's landscape design pass (Epic 5, Story 5.1). Until that lands, no new story may hard-code portrait-only layout assumptions (fixed aspect-ratio frames, orientation-locked navigation chrome, etc.).
```

### Epics (`epics.md`)

```diff
-- Device target: iPhone only, portrait only, single Xcode app target, Debug/Release configurations only.
+- Device target: iPhone only, supporting both portrait and landscape orientation (see Epic 5: Landscape Support), single Xcode app target, Debug/Release configurations only.
```

New Epic 5 summary added to `## Epic List`, and a full `## Epic 5: Landscape Support` section added at the end of the document, with three stories:

- **Story 5.1: Landscape UX Design Pass** — owner: UX Designer agent (`bmad-ux`). Produces landscape sections in DESIGN.md/EXPERIENCE.md plus Home/Tutorial landscape mockups.
- **Story 5.2: Landscape Architecture Decision & Orientation Unlock** — owner: Architect + Developer. Replaces the "TBD" note with a real documented strategy; lifts the `Info.plist` orientation lock.
- **Story 5.3: Home & Tutorial Landscape Retrofit** — owner: Developer. Applies Stories 5.1/5.2 to the two screens that already exist.

Full text of all edits is already applied to the source files as of this proposal (see Section 6).

### sprint-status.yaml

New `epic-5` block (3 stories, all `backlog`) inserted between `epic-1` and `epic-2` blocks, so it's the next epic picked up by `create-story` regardless of its number.

## 5. Implementation Handoff

**Scope classification: Major.**

This requires real UX design work with no existing precedent (zero landscape mockups/specs exist), plus an architecture decision — not something the Developer agent can implement directly from what exists today.

| Story | Owner | Depends on |
|---|---|---|
| 5.1 Landscape UX Design Pass | UX Designer agent (`bmad-ux`) | — |
| 5.2 Architecture Decision & Orientation Unlock | Architect + Developer | 5.1 |
| 5.3 Home & Tutorial Landscape Retrofit | Developer (`bmad-dev-story`) | 5.1, 5.2 |

**Success criteria:** Epic 5 is complete when Home and Tutorial correctly reflow in both orientations, the architecture's "TBD" landscape note is replaced with a real documented strategy, and Epic 2's future stories can be created directly against that strategy without needing their own separate landscape-retrofit pass.

## 6. Artifacts Modified

- `_bmad-output/planning-artifacts/prds/prd-game-2026-07-25/prd.md` — added Orientation NFR bullet
- `_bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md` — corrected device-target statement, added Landscape layout strategy (TBD) note
- `_bmad-output/planning-artifacts/epics.md` — corrected Additional Requirements bullet, added Epic 5 summary + full section
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — added `epic-5` block (3 stories, backlog), positioned before `epic-2`
