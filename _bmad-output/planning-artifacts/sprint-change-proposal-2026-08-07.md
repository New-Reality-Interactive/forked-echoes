# Sprint Change Proposal — 2026-08-07

**Trigger story:** 3-5-end-to-end-accessibility-validation (in-progress)
**Mode:** Batch
**Decided by:** Brian Mericle (user), during Story 3.5's dev-story session

---

## 1. Issue Summary

Story 3.5 (End-to-End Accessibility Validation) requires a live VoiceOver walkthrough of the full app (AC1) as its central acceptance gate. During implementation it was discovered — and confirmed via Apple's own developer documentation — that **VoiceOver's spoken/interactive behavior does not run in the iOS Simulator at all**; it requires a physical iOS device. The user does not have a workflow for physical-device VoiceOver testing at this stage and has decided, deliberately, **not to officially support or test VoiceOver for v1**.

This is a **product-scope decision, not a workaround**: the user explicitly wants to keep every *other* accessibility feature already built (Dynamic Type, Reduce Motion, WCAG contrast, 44pt tap targets, logical focus/reading order) fully in scope. Only the specific commitment to *officially test and support VoiceOver* is being dropped for v1.

**Clarified during this session:** the "every gesture has a standard tap equivalent, none reachable only via a custom gesture" rule (FR-11, UX-DR3/UX-DR12) stays as a hard requirement even though VoiceOver was its original motivating case — the user confirmed this is good general/motor-accessibility practice independent of VoiceOver, and it's already fully implemented, so nothing changes here.

---

## 2. Impact Analysis

### Epic Impact

- **Epic 3** (in-progress): Story 3.5 is directly affected — its central AC (AC1, live VoiceOver walkthrough) is no longer required. Three of its ten ACs (AC1, AC6, AC8) reference VoiceOver; the other seven (AC2-5, AC7, AC9, AC10) are unaffected (Dynamic Type, Reduce Motion, contrast, gesture-equivalence, and gesture-reachability-at-AX5 checks never actually depended on VoiceOver itself). **Net effect: Story 3.5 becomes substantially easier to close** — its remaining Simulator-only blockers (Dynamic Type AX5, Reduce Motion, button clearance, EndingView swipe reachability) are all testable without VoiceOver or a physical device.
- **Epic 4** (backlog, not started): Story 4.2 (Full Prose Authoring) has one AC authoring VoiceOver-specific illustration descriptions and one AC authoring VoiceOver-specific Tutorial copy; Story 4.4 (Illustration Production) has one AC wiring those descriptions as `accessibilityLabel`. None of this work has started, so these are clean edits, not rework.
- **Epics 1, 2, 5** (done): Several already-shipped stories' ACs reference VoiceOver as part of their (already-satisfied, already-verified) acceptance criteria (Story 1.4, 2.2, 2.7, 2.8, 2.13). Per this project's own established convention (project-context.md's "Resolving doc conflicts" section — "the most recent explicit team/user decision wins and gets recorded directly in the story file... don't re-litigate a resolved conflict"), **these historical story files are left untouched**. The code they describe (accessibility labels, hints, rotor actions, focus order) is not being ripped out — it remains in the app as best-effort scaffolding. Only the forward-looking canonical docs (PRD, epics.md's requirements inventory, EXPERIENCE.md, project-context.md) get a recorded decision.
- No epic needs to be added, removed, resequenced, or reprioritized. No new epic is needed either — this is a scope narrowing within existing epics, not new work.

### Artifact Conflicts

| Artifact | Conflict | Action |
|---|---|---|
| PRD (`prd.md`) | FR-11 names "VoiceOver-compatible" as the defining test for the tap-alternative requirement, and "VoiceOver labeling"/"VoiceOver navigation" as hard-tested consequences | Reword FR-11 to drop VoiceOver as the officially-tested criterion while keeping the tap-alternative/Dynamic-Type/contrast requirements; add a scope-decision note |
| `epics.md` | FR11 (Requirements Inventory), UX-DR12, Story 3.5's ACs, Story 4.2's two ACs, Story 4.4's one AC all reference VoiceOver as a testable requirement | Reword FR11/UX-DR12 with the same scope-decision note; rewrite Story 3.5's ACs/Tasks concretely (in-progress); reword Story 4.2/4.4's ACs (not started, no rework cost) |
| `EXPERIENCE.md` | Accessibility Floor's VoiceOver bullet is framed as a required, tested behavioral spec | Reframe as "implemented, best-effort scaffolding — not an officially tested v1 requirement," keep the technical detail intact for a possible future VoiceOver push |
| `project-context.md` | No existing entry documents this decision | Add a new Process Agreements entry recording the decision, its rationale, and its scope (what stays vs. what's dropped) |
| Architecture (`ARCHITECTURE-SPINE.md`) | Two references to VoiceOver are descriptive (one intent-method-per-user-action rule, one traceability table row), not testable requirements — no behavioral claim to walk back | No change needed |
| `deferred-work.md` | The AC8 (rotor no-op) entry closed this session frames the finding as a VoiceOver-specific judgment call | Append a note: now moot/non-blocking given VoiceOver isn't officially tested, but the underlying code-level finding (true no-op, harmless) still stands |
| Story 3.5 file (`3-5-end-to-end-accessibility-validation.md`) | AC1 (live VoiceOver walkthrough) is no longer required; AC6/AC8 no longer need live VoiceOver confirmation (already satisfied via code audit); Task 1 needs restructuring | Rewrite ACs, Tasks, and Completion Notes; this substantially de-blocks the story |
| Test/CI artifacts | None — AD-7's Swift Testing scope was never VoiceOver-dependent (engine logic only) | N/A |

### Technical Impact

None. No `.swift` code needs to change — accessibility labels, hints, rotor actions (`.accessibilityAction`), and focus-order modifiers (`.accessibilitySortPriority`) already implemented across Epics 1-3 are **not being removed**. They remain in the codebase as-is; they're just no longer a gate for calling v1 "done." This is a pure documentation/scope change.

---

## 3. Recommended Approach

**Direct Adjustment (Option 1).** This is a scope-narrowing decision within already-planned epics — no rollback, no MVP reduction beyond the one explicit carve-out (official VoiceOver support/testing), no new epic needed.

- **Effort:** Low — documentation-only edits across 5 files (PRD, epics.md, EXPERIENCE.md, project-context.md, Story 3.5), plus one deferred-work.md annotation.
- **Risk:** Low — no code changes, no regression surface. The only risk is documentation drift if a future story re-adds a VoiceOver-testing AC without checking this decision first; mitigated by recording the decision in project-context.md (loaded as a persistent fact by both `create-story` and `dev-story`).
- **MVP impact:** Narrows FR-11's officially-tested surface (drops VoiceOver from the tested/gated portion) but does not reduce any other MVP commitment. Every other accessibility NFR (NFR5-8) and FR-11's gesture-equivalence clause are unaffected.

---

## 4. Detailed Change Proposals

### 4.1 PRD — `prds/prd-game-2026-07-25/prd.md`

**Section 4.6, FR-11:**

OLD:
> Every gesture-based interaction (navigation and choice selection alike) has a standard, VoiceOver-compatible tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, VoiceOver labeling, sufficient contrast).
>
> **Consequences (testable):**
> - No interaction in the app is reachable *only* via a custom gesture.
> - Story text area passes VoiceOver navigation and responds to Dynamic Type sizing.

NEW:
> Every gesture-based interaction (navigation and choice selection alike) has a standard tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, sufficient contrast). **Scope decision, 2026-08-07:** VoiceOver is not officially tested or supported for v1 — see project-context.md's Process Agreements for full rationale. Accessibility labels, hints, and VoiceOver-specific affordances (rotor custom actions, focus order) already implemented remain in the app as best-effort scaffolding but are not an officially tested v1 requirement.
>
> **Consequences (testable):**
> - No interaction in the app is reachable *only* via a custom gesture.
> - Story text area responds to Dynamic Type sizing.

**Rationale:** Keeps the tap-alternative requirement (per the user's explicit decision to retain it) and Dynamic Type/contrast, drops VoiceOver as the officially tested criterion, records the decision inline where a future reader would look first.

---

### 4.2 `epics.md`

**Requirements Inventory, FR11 (line 43):**

OLD:
> FR11: Accessible interaction parity — Every gesture-based interaction (navigation and choice selection alike) has a standard, VoiceOver-compatible tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, VoiceOver labeling, sufficient contrast). No interaction in the app is reachable only via a custom gesture; the story text area passes VoiceOver navigation and responds to Dynamic Type sizing.

NEW:
> FR11: Accessible interaction parity — Every gesture-based interaction (navigation and choice selection alike) has a standard tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, sufficient contrast). No interaction in the app is reachable only via a custom gesture; the story text area responds to Dynamic Type sizing. **Scope decision, 2026-08-07 (see project-context.md Process Agreements):** VoiceOver is not officially tested/supported for v1 — labels/hints/rotor actions/focus order already implemented across Epics 1-3 remain as best-effort scaffolding, not a v1 acceptance gate. Historical story ACs (Epics 1, 2, 5) referencing VoiceOver as a tested requirement are left as-shipped, per this doc's existing "don't re-litigate a resolved conflict" convention.

**UX-DR12 (line 109):**

OLD:
> UX-DR12: VoiceOver support — every choice card exposes role/label/state (including the 1.5s undo-window announcement); Story page exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible, since swipe is otherwise consumed by VoiceOver navigation); run-options button carries an explicit `accessibilityLabel` of "Run options"; focus traversal follows reading order (eyebrow → prose → choices → pager, run-options last).

NEW:
> UX-DR12: VoiceOver support (implemented, best-effort — not an officially tested v1 requirement, see FR11's 2026-08-07 scope decision) — every choice card exposes role/label/state (including the 1.5s undo-window announcement); Story page exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible, since swipe is otherwise consumed by VoiceOver navigation); run-options button carries an explicit `accessibilityLabel` of "Run options"; focus traversal follows reading order (eyebrow → prose → choices → pager, run-options last). Focus order and accessibility labels remain in scope generally (project-context.md); only live VoiceOver testing is out of scope for v1.

**Story 3.5 (lines 903-949) — full rewrite**, replacing the current AC block. See §4.5 (Story file) below for the paired story-file edit; the epics.md version is kept in sync (same content, epics.md is the canonical source per this project's story-generation flow).

OLD (AC1):
> **Given** the full app (Epics 1-3) is complete
> **When** walked end-to-end using VoiceOver only, no sighted/gesture interaction
> **Then** every screen and action is reachable, correctly labeled, and announces state changes (choice selected, undo window, echo firing, ending reached) (FR11)

NEW (AC1 — replaces the live-walkthrough requirement with a structural, code/Inspector-level audit):
> **Given** the full app (Epics 1-3) is complete
> **When** every screen is audited via code inspection and Xcode's Accessibility Inspector (Audit tool) — **not** live VoiceOver, per the 2026-08-07 scope decision that VoiceOver is not officially tested for v1
> **Then** every interactive element has a structurally correct accessibility label/trait/state, with no Accessibility Inspector audit warnings (missing description, ambiguous trait) on any screen

OLD (AC6):
> **Given** every illustration in the app
> **When** audited with VoiceOver
> **Then** each announces its authored descriptive label — none is silent (hidden) and none announces a meaningless default label

NEW (AC6):
> **Given** every illustration in the app
> **When** audited via code inspection (grep for `Image(` call sites and their accessibility modifiers)
> **Then** each has a real, descriptive `accessibilityLabel` or is deliberately `.accessibilityHidden(true)` as pure decoration — none silent-by-omission, none a meaningless default label

OLD (AC8):
> **Given** VoiceOver's "Next Page"/"Previous Page" custom rotor actions (`StoryChoiceView.swift`)
> **When** exercised while forward navigation is blocked by an unresolved choice
> **Then** the audit records whether silent no-op (no audio/haptic feedback) is acceptable as shipped or needs a follow-up fix — a judgment call, not an automatic AC failure (closes the Story 2.2 deferred-work.md item)

NEW (AC8):
> **Given** the rotor action closures in `StoryChoiceView.swift` call the same `advancePage()`/`goBack()` intents used elsewhere
> **When** traced via code inspection (not live VoiceOver, per the 2026-08-07 scope decision)
> **Then** the audit confirms the blocked-navigation behavior is a true no-op with no unintended side effects — closes the Story 2.2 deferred-work.md item; no further live confirmation needed since VoiceOver isn't an officially tested v1 path

AC2, AC3, AC4, AC5, AC7, AC9, AC10 are **unchanged** — none of them actually depend on VoiceOver (Dynamic Type, Reduce Motion, contrast, gesture-equivalence-in-code, and gesture-reachability-at-AX5 are all independently testable in Simulator).

**Rationale:** This is the single biggest practical win from the decision — Story 3.5's real remaining Simulator work (Dynamic Type AX5, Reduce Motion, button clearance, EndingView swipe-back) was never actually VoiceOver-dependent. Only AC1 truly required it, and AC6/AC8 are now satisfiable purely by the code audit already completed this session.

**Story 4.2 (lines 1055-1061):**

OLD:
> **Given** each of the ~10-15 branch-reality illustrations
> **When** authored
> **Then** a distinct, descriptive VoiceOver description of what the illustration depicts is written and added to `Localizable.xcstrings` alongside the caption — not restating the caption, but conveying the illustration's specific visual content so VoiceOver users get equivalent access to the branch reality's atmosphere
>
> **Given** Tutorial's `tutorial.mechanic.pageTurn` copy, which currently describes only the swipe/tap-edge page-turn mechanic
> **When** its final prose is authored
> **Then** it also mentions the VoiceOver-specific alternative (the "Next Page"/"Previous Page" rotor custom actions, Story 2.2/UX-DR12) — a VoiceOver user reading Tutorial's own explanation shouldn't be left to discover that alternative by accident (closes the Story 1.3 deferred-work.md item)

NEW:
> **Given** each of the ~10-15 branch-reality illustrations
> **When** authored
> **Then** a distinct, descriptive accessibility-label string is written and added to `Localizable.xcstrings` alongside the caption — not restating the caption, but conveying the illustration's specific visual content. Kept as best-effort scaffolding (2026-08-07 scope decision: VoiceOver isn't officially tested for v1, but authoring this costs nothing extra during prose-writing and keeps the door open for a future VoiceOver push)
>
> ~~**Given** Tutorial's `tutorial.mechanic.pageTurn` copy... mentions the VoiceOver-specific alternative...~~ **[DROPPED, 2026-08-07 scope decision]** — Tutorial copy explaining a VoiceOver-specific rotor action would be confusing/irrelevant given VoiceOver isn't officially promoted for v1. The Story 1.3 deferred-work.md item this closed should be re-flagged as **[ACCEPTED — no action, VoiceOver out of v1 scope]** instead.

**Story 4.4 (lines 1127-1129):**

OLD:
> **Given** each illustration's authored VoiceOver description (Story 4.2)
> **When** the interstitial renders
> **Then** the illustration exposes that description as its `accessibilityLabel` — VoiceOver users hear a real description of the branch reality's visual flavor, not a meaningless default label and not silence

NEW:
> **Given** each illustration's authored accessibility-label description (Story 4.2)
> **When** the interstitial renders
> **Then** the illustration exposes that description as its `accessibilityLabel` — implemented as best-effort accessibility scaffolding (2026-08-07 scope decision), not gated on live VoiceOver testing for v1

---

### 4.3 `EXPERIENCE.md`

**Accessibility Floor section, VoiceOver bullet:**

OLD:
> - VoiceOver: every choice card exposes role + label + state ("Choice, Ask Sam about the boat, not yet selected" / "...selected, double-tap again within 1.5 seconds to undo"). Double-tap activates immediately — VoiceOver users are never asked to sustain a 3-second hold; the instant-commit-plus-undo-window path (identical to a quick tap) is the VoiceOver-compatible equivalent required by FR-11. The Story page additionally exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible), since a one-finger swipe is otherwise consumed by VoiceOver's own navigation and never reaches the app. The run-options button carries an explicit `accessibilityLabel` of "Run options" (not left to the SF Symbol's default name).

NEW:
> - VoiceOver (implemented, best-effort — not an officially tested/supported v1 requirement, per the 2026-08-07 scope decision recorded in project-context.md): every choice card exposes role + label + state ("Choice, Ask Sam about the boat, not yet selected" / "...selected, double-tap again within 1.5 seconds to undo"). Double-tap activates immediately — the instant-commit-plus-undo-window path (identical to a quick tap) doubles as the standard-tap equivalent FR-11 requires regardless of VoiceOver. The Story page additionally exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible). The run-options button carries an explicit `accessibilityLabel` of "Run options" (not left to the SF Symbol's default name). None of this is being removed — it's kept as-is, just no longer an officially tested v1 gate.

**Rationale:** Preserves the technical documentation (useful if VoiceOver support is picked up post-v1) while correcting what it claims about testing/support status.

---

### 4.4 `project-context.md`

**New entry under Process Agreements:**

> - **VoiceOver is not officially tested or supported for v1 — a deliberate scope decision, not a workaround.** (2026-08-07, during Story 3.5's dev-story session.) Discovered mid-story that VoiceOver's spoken/interactive behavior does not run in the iOS Simulator at all (confirmed via Apple's own developer forums) — only a physical device can exercise it, and the user does not have a physical-device VoiceOver testing workflow set up at this stage. Rather than block Story 3.5 (or every future story) on unavailable infrastructure, the user decided to drop *official testing/support* of VoiceOver for v1 while explicitly keeping every other accessibility feature in scope: Dynamic Type (NFR8), Reduce Motion (NFR5), WCAG AA/1.4.11 contrast (NFR7), 44pt minimum tap targets (NFR6), and the "every gesture has a standard tap equivalent" rule (FR-11) — the last one confirmed to stay even though VoiceOver was its original motivating case, since it's good general/motor-accessibility practice on its own and already fully implemented. **What this means for future stories:** accessibility labels, hints, rotor actions (`.accessibilityAction`), and focus-order modifiers (`.accessibilitySortPriority`) already built across Epics 1-3 are not being removed — keep writing them as best-effort scaffolding when it's cheap to do so (e.g. authoring an illustration's descriptive label alongside its caption), but do **not** add new ACs that require live VoiceOver testing, and do not block a story on VoiceOver verification. Xcode's **Accessibility Inspector** (Audit tool, targets the Simulator) remains available for a structural check (missing labels/traits) without needing actual VoiceOver speech — use that instead when an accessibility-label sanity check is warranted. Full Sprint Change Proposal: `sprint-change-proposal-2026-08-07.md`.

**Rationale:** This is the authoritative, persistent-fact-loaded record (both `create-story` and `dev-story` load `project-context.md` automatically) that prevents a future story from re-adding a VoiceOver-testing AC without knowing this decision exists.

---

### 4.5 Story file — `3-5-end-to-end-accessibility-validation.md`

- Rewrite AC1, AC6, AC8 to match the epics.md text in §4.2 above.
- Restructure Tasks:
  - **Task 1** renamed "Accessibility structural audit — labels, traits, rotor no-op (AC: #6, #8)" — both subtasks already complete via this session's code audit; mark `[x]`.
  - **Task 2** unchanged title, but AC9 (EndingView swipe-back at AX5) folds in alongside AC7 since both are AX5-Simulator-only checks with no VoiceOver dependency: "Task 2: Dynamic Type, button clearance & gesture reachability at AX5 (AC: #2, #7, #9)."
  - Tasks 3-6 unchanged.
- Update Completion Notes: record the scope decision, note AC1's live-walkthrough requirement is superseded, and that AC6/AC8 are now fully satisfied (already true from this session's code audit — no further action). Update the Simulator checklist handed to the user: **drop item 1 (VoiceOver walkthrough) entirely**; items 2 (Dynamic Type), 3 (button clearance), 4 (EndingView swipe, now understood as gesture-only not VoiceOver), 5 (Reduce Motion) all remain and are now the *complete* remaining checklist — none require VoiceOver or a physical device.
- Given AC1/AC6/AC8 close out this session (no further Simulator work needed for them), and Task 4/5/6 were already complete last session, the story's *only* remaining open work is the AX5/Reduce-Motion Simulator pass (now VoiceOver-free) — status stays `in-progress` until that comes back, but the remaining ask of the user is now meaningfully smaller.

---

### 4.6 `deferred-work.md`

**Append to the AC8 entry (2-2-page-navigation's rotor no-op item) closed this session:**

> **Update, 2026-08-07 (Sprint Change Proposal):** VoiceOver is no longer officially tested/supported for v1 (see project-context.md Process Agreements) — this finding is now lower-stakes than originally scoped (a no-op in an unofficially-tested interaction path), but the underlying code-level finding stands unchanged: `advancePage()`'s blocked-choice case is a true, harmless no-op. No further action needed.

**Append to the AC9 entry (3-4's `backSwipeGesture` item):**

> **Note, 2026-08-07:** this item is unaffected by the VoiceOver scope decision — the swipe-back reachability question is about touch/gesture arbitration (`ScrollView` vs. sibling `.gesture()`), not VoiceOver, and remains a real open Simulator checkpoint for Story 3.5.

---

## 5. Implementation Handoff

**Scope classification: Minor.** Documentation-only changes across 6 files, no code changes, no new stories/epics, no sprint-status.yaml restructuring (no story/epic added, removed, or renumbered — checklist item 6.4 is N/A). Directly implementable by the Developer agent (this session) once approved.

**Success criteria:**
- PRD, epics.md, EXPERIENCE.md, project-context.md, deferred-work.md, and the Story 3.5 file all consistently reflect: VoiceOver implemented-but-not-officially-tested for v1; all other accessibility features (Dynamic Type, Reduce Motion, contrast, tap targets, focus order, gesture-equivalence) remain fully in scope and unaffected.
- Story 3.5's remaining open work is reduced to the VoiceOver-free Simulator checklist (Dynamic Type AX5, button clearance, EndingView swipe reachability, Reduce Motion).
- No `.swift` files touched.
