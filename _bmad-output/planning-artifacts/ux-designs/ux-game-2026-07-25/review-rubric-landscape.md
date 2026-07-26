# Spine Pair Review — Landscape Update (Forked Echoes)

## Overall verdict
The landscape addition is mechanically sound and mostly resolves cleanly: every new token (`{components.reading-surface.column-max-width-landscape}`, `{components.choice-card.layout-landscape}`) is defined in DESIGN.md's frontmatter, both new mockup groups are referenced from both spine files, and the "Responsive & Platform" section is correctly placed and correctly scoped as behavioral deltas rather than a new flow. It is not, however, airtight: `reading-surface` is missing its narrative entry in DESIGN.md's `## Components` list (every sibling component has one), the two spine files disagree on whether the branch-arrival interstitial's landscape mockup is "deferred," the new EXPERIENCE.md section breaks the file's own cross-reference convention by using raw `{...}` tokens instead of the established `DESIGN.md.components.X` citation style, and there's a real state-coverage gap around rotating mid-interstitial that the doc's own language (calling Interstitial-active "symmetric to Echo active") makes hard to justify leaving unaddressed. None of these block implementation, but the inheritance-syntax break and the interstitial-rotation gap are worth fixing before Stories 5.2/5.3 lock in against this spine.

## 1. Flow coverage — adequate
Checked: whether landscape affects UJ-1/UJ-2, whether it warranted its own Key Flow, and whether Epic 5's Stories 5.1–5.3 acceptance criteria are traceable into the spine text.

Folding landscape into "Responsive & Platform" as behavioral deltas (rather than a new Key Flow) is the right call — UJ-1/UJ-2 describe a sequence of beats, not a layout, and nothing about the sequence changes in landscape. Story 5.1's AC items are traceable: reading-surface reflow ✓ (EXPERIENCE.md line 109), circuit-frame behavior ✓ (line 110), Home/Tutorial layout ✓ (line 112), swipe/tap-zone page-turn geometry ✓ (line 114). Story 5.3's "Home/Tutorial reflow correctly, FR11 parity holds" is covered by the same section plus the two new mockups.

### Findings
- **medium** Story 5.1's AC explicitly asks for "gesture-zone geometry (swipe/tap-zone page-turn, **hold-to-choose**) adapted for landscape's wider/shorter aspect ratio." Page-turn zones get an explicit geometry statement ("same proportional left/right-third split"), but the hold-to-choose gesture only gets "same hold/tap-commit interaction" — no confirmation that a horizontal-row choice card, now narrower and vertically constrained by landscape's ~393pt screen height, still clears the 44pt tap-target floor from the Accessibility Floor. (`EXPERIENCE.md` Responsive & Platform, line 111; `EXPERIENCE.md` Accessibility Floor, line 100). *Fix:* add one line either confirming landscape choice-card tap-target compliance or tagging it as an [ASSUMPTION] the way the 3-card-tight-fit case already is.

## 2. Token completeness — strong
Extracted every token referenced in the new landscape content: `{components.reading-surface}`, `{components.reading-surface.column-max-width-landscape}`, `{components.choice-card.layout-landscape}`, plus the pre-existing `{typography.body}` reused inside the reading-surface note. All resolve against DESIGN.md's frontmatter (`components.reading-surface.column-max-width-landscape: 680px`, `components.choice-card.layout-landscape: '...'`). No orphan or undefined tokens found.

### Findings
None — every landscape token cited in either file is defined in DESIGN.md's frontmatter.

## 3. Component coverage — adequate
Checked frame, choice-card, reading-surface, and Home/Tutorial chrome for a DESIGN.md visual spec paired with an EXPERIENCE.md behavioral delta.

- Frame: DESIGN.md frontmatter note (line 108) + EXPERIENCE.md bullet (line 110) — concrete, matching ("corner mark sizes stay fixed, only position adapts" in both places).
- Choice-card: DESIGN.md `layout-landscape` token (line 123) + EXPERIENCE.md bullet (line 111) — concrete, matching.
- Reading-surface: DESIGN.md frontmatter entry (lines 109–111) + EXPERIENCE.md bullet (line 109) — concrete, matching, but see finding below.
- Home/Tutorial chrome: covered once, clearly, in DESIGN.md's Layout & Spacing paragraph (line 233) and EXPERIENCE.md bullet (line 112) — real rule ("no side-by-side rearrangement"), not hand-waving.

### Findings
- **medium** `reading-surface` is defined in DESIGN.md's frontmatter and used throughout the landscape prose, but unlike every other frontmatter component (frame, choice-card, eyebrow-tag, page-tap-zones, echo-callback, interstitial, continue-button, run-options-button, ending-frame, memory-row, memory-score — all 12 of them), it has no corresponding bullet in the `## Components` narrative list (`DESIGN.md` lines 247–261). A consumer reading the Components section top-to-bottom for a component inventory would miss it entirely. *Fix:* add a "Reading surface" bullet alongside the others, even if brief.
- **medium** DESIGN.md's landscape-mockup note says only "Ending and Memory landscape mockups are intentionally deferred to their own future epics" (`DESIGN.md` line 265), omitting the branch-arrival interstitial. EXPERIENCE.md's equivalent line says "Interstitial, Ending, and Memory landscape mockups are deferred to their own future epics" (`EXPERIENCE.md` line 37). A consumer reading DESIGN.md alone would not know interstitial-landscape mockup coverage is intentionally out of scope rather than an oversight. *Fix:* align the two lists — add "Interstitial" to DESIGN.md's deferred note.

## 4. State coverage — thin
Checked the two existing [ASSUMPTION] tags (rotate-mid-charge, 3-card tight-fit) against the two scenarios flagged for review: rotating during the branch-arrival interstitial's blocking state, and rotating during an echo-active page.

### Findings
- **high** No note addresses rotating the device while the branch-arrival interstitial is active. This is a real gap, not a nitpick: the State Patterns table explicitly describes "Interstitial active" as "symmetric to Echo active as a distinct, transient, blocking beat" (`EXPERIENCE.md` line 81), and the doc did think to add an [ASSUMPTION] for the other blocking/in-progress state (rotate-mid-charge, line 115). The interstitial is also CSS-composed full-bleed art keyed to a specific aspect ratio — plausibly more disruptive to rotate through than a choice-card charge fill, since the reflow could visibly recompose the artwork mid-view rather than just cancel a timer. (`EXPERIENCE.md` Responsive & Platform, lines 113, 115–116). *Fix:* add a matching [ASSUMPTION] or explicit rule — e.g., does the Continue-gate and blocking behavior survive rotation untouched, does the art recompose without a jarring cut.
- **low** Rotating during an Echo-active page (frame powered up + echo callback block) also isn't addressed — does the reflow interrupt or replay the power-up glow/shape-cue? Lower risk than the interstitial case since Echo-active isn't an in-progress gesture, just a static per-page visual state, but it's the second half of the same question the task explicitly raised and the doc is silent on both. (`EXPERIENCE.md` State Patterns line 80; Responsive & Platform lines 105–116). *Fix:* one line clarifying the power-up state simply persists/re-renders on rotation without restarting its transition.

## 5. Visual reference coverage — adequate
Checked whether the 3 new landscape mockups are linked at the relevant sections (not just listed at the bottom), whether they name what they illustrate, and whether any are orphaned or vaguely described.

Placement matches the existing convention: both files already collect all mockup references into one block at the end of the relevant section (Components in DESIGN.md, Information Architecture in EXPERIENCE.md) rather than inline-per-component — the landscape references follow that same pattern, so this isn't a new deviation. No orphaned mockups: all three files (`home-landscape.html`, `tutorial-landscape.html`, `story-choice-landscape.html`) are referenced from both spine docs and exist on disk with content matching their descriptions.

### Findings
- **medium** The new landscape mockup references are annotated less thoroughly than their portrait counterparts. Portrait references name their states explicitly — `mockups/home.html` ("fresh-install and run-in-progress/'Resume Story' states"), `mockups/tutorial.html` ("dormant frame, run-options icon introduced"). Of the three landscape mockups, only `story-choice-landscape.html` gets a parenthetical ("2-choice and 3-choice/tight-fit states"); `home-landscape.html` and `tutorial-landscape.html` get none in either file, even though (per the actual mockup files) home-landscape shows the same two states (fresh install / run-in-progress) as its portrait counterpart. (`DESIGN.md` line 265; `EXPERIENCE.md` line 37). *Fix:* add matching parentheticals, e.g. "(fresh-install and run-in-progress states, reflowed)" for consistency and so a consumer doesn't have to open the file to know what it covers.

## 6. Bloat & overspecification — strong
The landscape-specific additions are lean: they reuse existing tokens (`{spacing.3}`, `{typography.body}`) rather than inventing parallel ones, state "unchanged from portrait" plainly wherever true (frame concept, interstitial composition, page-turn zones, Home/Tutorial actions) instead of re-describing settled behavior, and the two [ASSUMPTION] tags are appropriately scoped rather than resolved prematurely without a device to test against.

### Findings
None.

## 7. Inheritance discipline — broken
Checked whether the new landscape tokens/sections cross-reference by name consistent with the rest of each file's existing convention.

DESIGN.md's own landscape token usage is internally consistent (self-references like `{colors.trace-brass}` and the new `{components.reading-surface.column-max-width-landscape}` both use the file's standard curly-brace self-reference syntax). The break is on the EXPERIENCE.md side.

### Findings
- **high** Everywhere else in EXPERIENCE.md, a cross-reference into DESIGN.md is written as a backtick-wrapped dotted path prefixed with `DESIGN.md.` — e.g. `` `DESIGN.md.components.frame` `` (line 59), `` `DESIGN.md.components.page-tap-zones` `` (lines 33, 58, 88), `` `DESIGN.md.Typography` `` (line 98). The new Responsive & Platform section instead uses DESIGN.md's own internal curly-brace token syntax directly — `` `{components.reading-surface.column-max-width-landscape}` `` and `` `{components.choice-card.layout-landscape}` `` (`EXPERIENCE.md` lines 109, 111) — with no `DESIGN.md.` prefix anywhere in the section. This is the only place in the entire file that does this; it's a real inconsistency, not a style nit, because a downstream consumer (or tool) that pattern-matches on the established `DESIGN.md.X` convention to resolve cross-file references would silently miss these two. *Fix:* rewrite as `` `DESIGN.md.components.reading-surface.column-max-width-landscape` `` / `` `DESIGN.md.components.choice-card.layout-landscape` `` to match the rest of the file.

## 8. Shape fit — strong
EXPERIENCE.md's own spec calls "Responsive & Platform" a "when triggered" section positioned alongside "Inspiration & Anti-patterns." It's placed at lines 105–116, immediately before "Inspiration & Anti-patterns" (line 118) and after Foundation/IA/Component Patterns/State Patterns/Interaction Primitives/Accessibility Floor — i.e., after every section it depends on (it cites the frame, choice-card, and tap-zone components already defined earlier) and before Key Flows. Placement and dependency order are both correct.

### Findings
None.

## Mechanical notes

- **Stale `updated:` frontmatter date.** Both `DESIGN.md` (line 5) and `EXPERIENCE.md` (line 4) still carry `updated: 2026-07-25`, one day before the `2026-07-26` Sprint Change Proposal date both files cite inline as the source of the very landscape changes being reviewed. Should be bumped to `2026-07-26` in both files for consistency with the epics.md citation ("Added via Sprint Change Proposal (2026-07-26)", `epics.md` line 833) and the current date.
- **Deferred-mockup list mismatch** between DESIGN.md (line 265, omits Interstitial) and EXPERIENCE.md (line 37, includes Interstitial) — see Component coverage finding above.
- **Cross-reference syntax break** in EXPERIENCE.md's new Responsive & Platform section — see Inheritance discipline finding above.
- All three new mockup files (`mockups/home-landscape.html`, `mockups/tutorial-landscape.html`, `mockups/story-choice-landscape.html`) exist on disk, are named/linked correctly in both spine docs, and their content matches what the docs claim (verified by reading each file).
- No naming drift found between DESIGN.md token names and EXPERIENCE.md's citations of them (`column-max-width-landscape`, `layout-landscape` are spelled identically everywhere they appear).
- Sprint Change Proposal date (`2026-07-26`) is otherwise consistent across DESIGN.md, EXPERIENCE.md, and epics.md.
