# Validation Report — Forked Echoes (Landscape Update)

- **DESIGN.md:** `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md`
- **EXPERIENCE.md:** `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md`
- **Run at:** 2026-07-26T00:00:00Z

## Overall verdict

This synthesis covers the landscape-orientation addition (Epic 5, Story 5.1) reviewed after the original portrait-only pass (see `review-rubric.md`/`review-accessibility.md` for that history — its findings remain resolved and are not re-litigated here). The rubric walker found the addition mechanically sound: every new token resolves, the new mockups are properly linked, and folding landscape into a "Responsive & Platform" section as behavioral deltas (rather than a new Key Flow) was the right structural call.

The accessibility lens caught a real, concrete defect: all 3 new landscape reference mockups shrank padding and font-size to fit the shorter landscape frame and dropped below the pre-existing 44pt tap-target floor on real interactive elements — not a theoretical risk, an already-failing measurement in the artifacts as first authored. It also found the Dynamic Type headroom clearance had silently shrunk versus portrait, the "3-card row might be tight" note was framed as a vague assumption rather than a testable rule, and a cross-reference syntax break in the new EXPERIENCE.md section. All findings below have been resolved via direct spec and mockup edits in this same session.

## Category verdicts
- Flow coverage — adequate → resolved (hold-to-choose tap-target compliance now stated explicitly)
- Token completeness — strong
- Component coverage — adequate → resolved (reading-surface Components bullet added, Interstitial deferred-list mismatch aligned)
- State coverage — thin → resolved (rotate-mid-interstitial and rotate-mid-echo-active rules added; hold-path-only clarification added to the rotate-mid-charge assumption)
- Visual reference coverage — adequate → resolved (landscape mockup annotations now match portrait's level of detail)
- Bloat & overspecification — strong
- Inheritance discipline — broken → resolved (EXPERIENCE.md's cross-references now use the established `DESIGN.md.components.X` convention)
- Shape fit — strong

## Findings by severity

### Critical (1) — resolved

**Accessibility** — All 3 new landscape mockups computed real interactive elements below the 44pt tap-target floor at default text size (§ mockups/home-landscape.html, tutorial-landscape.html, story-choice-landscape.html `.btn`/`.choice`)
Padding and font-size were both shrunk to fit the shorter landscape frame, dropping buttons to ~37-42px and short choice cards to ~40px — all below EXPERIENCE.md's own pre-existing, orientation-agnostic 44pt floor.
Fix applied: added `min-height: 44px` to every interactive element in all 3 mockups, and added an explicit `min-tap-target: 44pt` token to `DESIGN.md`'s `choice-card` and `reading-surface` components stating the floor applies regardless of orientation or layout.

### High (3) — resolved

**Accessibility** — Dynamic Type headroom claim didn't visibly survive landscape's shorter frame-well (§ DESIGN.md Layout & Spacing; mockups' frame-well padding)
The landscape mockups reduced frame-well vertical padding versus portrait's proven-safe values, shrinking exactly the clearance the headroom rule depends on, with no landscape equivalent of portrait's `story-choice-three-way.html` accessibility-scale stress test to validate it.
Fix applied: restored frame-well vertical padding to match portrait's (26px/16px) in both `tutorial-landscape.html` and `story-choice-landscape.html`, and added explicit language to `DESIGN.md`/`EXPERIENCE.md` committing to headroom parity between orientations. A full accessibility-scale landscape stress mockup remains deferred to Story 5.3 implementation/testing — noted explicitly rather than falsely claimed as validated.

**Accessibility** — The "3-card row may feel tight" note was a vague assumption, not a testable rule, and its mockup used the wrong device size (§ EXPERIENCE.md Responsive & Platform)
Framed as a cosmetic "may feel tight... flag for validation" note despite gating forward progress in the app's narrowest-vertical-headroom orientation; the mockup depicting it used Pro-class (852×393pt) dimensions, not the SE-class (~667×375pt) size the risk was about.
Fix applied: replaced the assumption with a hard constraint — a 3-card row wraps to 2+1 once any label exceeds 2 lines at the current column width, or at Dynamic Type accessibility sizes and above — stated identically in `DESIGN.md`'s `choice-card.layout-landscape` token and `EXPERIENCE.md`'s Responsive & Platform section. The mockup's caption and frame title were corrected to describe what it actually shows (a default-size 3-choice case that doesn't trigger the wrap) rather than mislabeling it a validated "tight-fit" case.

**Rubric — Inheritance discipline** — EXPERIENCE.md's new Responsive & Platform section broke the file's own cross-reference convention (§ EXPERIENCE.md, Responsive & Platform)
Every other DESIGN.md cross-reference in the file uses the backtick-wrapped `DESIGN.md.components.X` form; the new section used raw `{components.X}` curly-brace syntax instead — the only place in the file that does.
Fix applied: rewrote both references (`reading-surface.column-max-width-landscape`, `choice-card.layout-landscape`) to the established `DESIGN.md.components.X` form.

### Medium (4) — resolved

**Rubric — Component coverage** — `reading-surface` had no narrative bullet in DESIGN.md's `## Components` list, unlike all 12 sibling components (§ DESIGN.md, Components)
Fix applied: added a "Reading surface" bullet.

**Rubric — Component coverage** — DESIGN.md and EXPERIENCE.md's deferred-landscape-mockup lists disagreed on whether the branch-arrival interstitial was included (§ DESIGN.md vs. EXPERIENCE.md landscape-mockup notes)
Fix applied: both now read "Branch-arrival interstitial, Ending, and Memory landscape mockups are deferred."

**Accessibility** — Reference mockups' actual reading-column width didn't match the `column-max-width-landscape` token (680px vs. 520px/480px in the mockups) (§ mockups/tutorial-landscape.html, story-choice-landscape.html)
Fix applied: both mockups' `.reading-column` now use `max-width:680px`, matching the token exactly.

**Accessibility** — VoiceOver traversal order among horizontally-arranged choice cards was never stated as an explicit invariant (§ EXPERIENCE.md Responsive & Platform)
Fix applied: added an explicit sentence — traversal follows narrative/document order regardless of visual arrangement, so accessibility order and visual order never diverge.

### Low (2) — resolved

**Rubric — State coverage** — Rotating during an Echo-active page wasn't addressed (§ EXPERIENCE.md Responsive & Platform)
Fix applied: added a line clarifying the powered-up frame state persists/re-renders on rotation without restarting its transition.

**Accessibility** — The rotate-mid-charge assumption didn't note it only affects the hold path (§ EXPERIENCE.md Responsive & Platform)
Fix applied: the assumption now explicitly states the tap-plus-undo-window path and VoiceOver double-tap are both unaffected by rotation, so no interaction is ever left without a rotation-safe path.

### Mechanical notes (resolved)
- Stale `updated:` frontmatter date (2026-07-25) bumped to 2026-07-26 in both files, matching the Sprint Change Proposal date both files now cite.

## Reviewer files
- `review-rubric-landscape.md`
- `review-accessibility-landscape.md`
- (historical, portrait-only pass: `review-rubric.md`, `review-accessibility.md`)
