# Validation Report — Many-Worlds CYOA

- **DESIGN.md:** `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md`
- **EXPERIENCE.md:** `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md`
- **Run at:** 2026-07-25T00:00:00Z

## Overall verdict

The spine pair is close to source-extractable: token definitions are complete and resolve cleanly, section order matches the canonical shape, and both Key Flows mirror the PRD's UJ-1/UJ-2 verbatim with named protagonist, numbered steps, and a clear climax. One critical defect breaks the "source-extract cleanly" bar outright — EXPERIENCE.md's Information Architecture section falsely claims four of the five IA surfaces have no visual mockup when all five exist and DESIGN.md already links them — plus two high-severity gaps (no stated contrast targets despite a hard FR-11 requirement, and no DESIGN.md spec at all for the Memory screen's score/tier display).

The accessibility lens raises the stakes further: page-turn navigation is documented as swipe-only with no tap/VoiceOver equivalent anywhere — a direct contradiction of FR-11's hard "no gesture-only interaction" constraint, and a real iOS mechanics problem since VoiceOver consumes one-finger swipes for its own navigation. The echo-callback tag — the label for the app's signature "story remembers" moment, firing 2-3 times every run — also fails WCAG AA contrast in both light and dark themes. Combined, this is one more targeted edit pass, not a redesign, before the pair is safe to build from.

## Category verdicts
- Flow coverage — strong
- Token completeness — adequate
- Component coverage — adequate
- State coverage — adequate
- Visual reference coverage — broken
- Bloat & overspecification — strong
- Inheritance discipline — adequate
- Shape fit — adequate

## Findings by severity

### Critical (2)

**Visual reference coverage** — EXPERIENCE.md's IA section falsely claims 4 of 5 mockups don't exist yet (§ EXPERIENCE.md, Information Architecture)
DESIGN.md's own "Reference mockups" line already links all five files (`home.html`, `tutorial.html`, `ending.html`, `memory.html`, `story-choice-warm-ink-circuit.html`); `.memlog.md` confirms all four were mocked in a later session, but EXPERIENCE.md's IA section was never updated. A consumer trusting EXPERIENCE.md alone would wrongly skip four existing mockups.
Fix: update EXPERIENCE.md's composition-reference line to list and briefly describe all 5 mockups, matching DESIGN.md.

**Accessibility** — Swipe-driven page turn has no documented tap/VoiceOver equivalent (§ EXPERIENCE.md, Interaction Primitives + Component Patterns "Story page")
FR-11 is explicit: "No interaction in the app is reachable *only* via a custom gesture." Page-turning is the most frequent interaction in the app and is swipe-only as written. This is also a real iOS mechanics problem: when VoiceOver is on, a one-finger swipe is consumed by VoiceOver itself for accessibility-focus navigation and never reaches the app as a page-turn unless an alternate path is built. Every other gesture in the system got an explicit tap/VoiceOver equivalent; page turn did not.
Fix: add a tap-accessible page-turn affordance (edge tap zones, or a VoiceOver custom rotor action "Next/Previous page") and document it in both Component Patterns and Accessibility Floor.

### High (4)

**Token completeness** — No contrast ratio or WCAG target stated anywhere in DESIGN.md (§ DESIGN.md, Colors; EXPERIENCE.md Accessibility Floor explicitly delegates contrast to DESIGN.md)
FR-11 makes "sufficient contrast" a hard, testable requirement. Highest-risk pairs: `ink-secondary` on `surface-raised`/`surface-base` (memory-row consequence text, captions), light and dark.
Fix: add explicit verified ratios (e.g. "ink-secondary on surface-raised: ≥4.5:1, verified") for each load-bearing pair, both themes.

**Component coverage** — Memory/Recap score/tier display has no DESIGN.md spec at all (§ DESIGN.md Components → memory-row; `mockups/memory.html`)
A load-bearing FR-7/FR-10 element, rendered in the ember accent per the mockup, is only discoverable by reverse-engineering the HTML — inverting "spines win on conflict."
Fix: add a `score` sub-spec (to `memory-row` or its own component) naming the ember color and typography role used for the number and tier label.

**Accessibility** — The tap-to-commit path (the spec's own "standard accessible tap equivalent") is instant and irrevocable, while the primary hold gesture allows cancel-by-release (§ EXPERIENCE.md, Component Patterns "Choice card"; State Patterns)
A user relying on tap — tremor, limited dexterity, or a VoiceOver double-tap used to explore rather than commit — gets zero opportunity to reconsider before a choice locks permanently (FR-5), while the "primary" hold gesture has a built-in grace period. The path meant to be *more* accessible is *less* forgiving than the gestural one.
Fix: add a brief confirm/undo step after a quick tap, or explicitly document why instant-lock-on-tap is intentional and reconsider how VoiceOver's double-tap should route.

**Accessibility** — `echo-callback` tag color fails WCAG AA contrast in both color schemes (§ DESIGN.md components.echo-callback; confirmed against mockup CSS)
Computed: light mode `#C2540F` on `#241C14` ≈ 3.65:1; dark mode `#E0763A` on `#F3ECDD` ≈ 2.62:1 — both below the 4.5:1 required for small bold/uppercase text. This is the label for the app's signature callback moment, appearing 2-3 times every run, and it fails AA in both themes.
Fix: introduce a separate text-safe ember token for this role, or move the tag text to `ink-on-inverse` and reserve ember for a small icon/underline accent instead of the text run itself.

### Medium (10)

**Flow coverage** — FR-7's "invisible during play" half of alignment scoring has no corresponding behavioral rule in EXPERIENCE.md (§ EXPERIENCE.md, whole doc — absence)
Fix: add a State Patterns line, e.g. "Alignment running total: never rendered or exposed during a run (FR-7); first surfaces on Memory."

**Component coverage** — Eyebrow tag has a DESIGN.md visual row but no EXPERIENCE.md behavioral row (§ EXPERIENCE.md, Component Patterns — absence)
Fix: add an Eyebrow tag row stating its (minimal) behavioral rule.

**State coverage** — Ending → Memory transition mechanism is unspecified and the artifacts disagree by omission (§ EXPERIENCE.md Key Flow UJ-1 step 7 vs. `mockups/ending.html` "Tap to see your run →")
Fix: add an explicit interaction rule to the Ending row in Component Patterns (auto-advance vs. tap-to-continue).

**Visual reference coverage** — DESIGN.md's "Reference mockups" line under-describes 4 of 5 files (§ DESIGN.md, Components — mockup list)
Fix: add short parentheticals for `home.html`, `tutorial.html`, `ending.html`, `memory.html` matching the detail already given the first entry.

**Inheritance discipline** — "Choice button" (DESIGN.md) vs. "Choice card" (EXPERIENCE.md) is a real naming drift, not cosmetic (§ DESIGN.md components.choice-button; EXPERIENCE.md Component Patterns/Foundation/State Patterns/Accessibility Floor)
Fix: pick one name and apply it in both files.

**Shape fit** — Inspiration & Anti-patterns omitted from DESIGN.md, only partly defensible (§ DESIGN.md — absent section; `.memlog.md` records an explicit rejected plain-bracket alternative)
The direction is explicitly built on editorial/magazine typography and PCB/circuit-trace geometry, and a rejected alternative (plain bracket/hairline) is on record in the memlog but never landed in the shipped spine.
Fix: add a short Inspiration & Anti-patterns section, or fold a condensed lifted-from/rejected note into Brand & Style.

**Accessibility** — Trace-brass and ember are near-identical in luminance, making the frame's "powered up" state a pure hue shift (§ DESIGN.md colors.trace-brass / colors.accent-ember)
Computed relative luminance: `#8B6F47` ≈ 0.173 vs. `#C2540F` ≈ 0.178 — indistinguishable by lightness alone; orange/brown is a classic CVD confusion pair. Functional meaning isn't lost (text co-fires), but the app's own stated signature device is silently non-functional as a standalone signal for colorblind users.
Fix: state this explicitly as an accepted, redundantly-backed limitation, or add a non-hue cue (dash pattern, filled-vs-hollow via, larger brightness jump).

**Accessibility** — Fixed-pixel circuit-corner geometry and interstitial art risk collisions at accessibility Dynamic Type sizes (§ mockup CSS; DESIGN.md Shapes/Components)
Fixed 30×30px corner assemblies and fixed frame-well padding don't scale with enlarged text; the interstitial's unclamped headline is layered over position-fixed decorative art with no reflow relationship.
Fix: specify that frame-well padding/corner clearance scale with the largest supported Dynamic Type category, and state how the interstitial's art responds when its headline wraps.

**Accessibility** — No mapping from design typography roles to iOS Dynamic Type text styles (§ DESIGN.md, Typography)
Literal pixel values are given per role with "must scale" instructions, but no `UIFontTextStyle` binding — two implementations could scale roles at inconsistent relative rates, breaking the weight/scale hierarchy the Brand & Style section calls load-bearing.
Fix: add an explicit token-to-text-style mapping table.

**Accessibility** — Reduce Motion guidance covers only 2 of the plausible animated moments (§ EXPERIENCE.md, Accessibility Floor)
Page-turn transition and the interstitial's entrance/exit are unaddressed, in tension with DESIGN.md's blanket claim that the echo glow is "the only thing in this system allowed to animate."
Fix: state explicitly whether page turns and the interstitial transition animate under normal conditions, and what they collapse to under Reduce Motion.

### Low (6)

**Component coverage** — "choice-button"/"Choice card" naming drift flagged again as a cross-reference to the Inheritance discipline finding (§ DESIGN.md line ~90; EXPERIENCE.md throughout).

**State coverage** — Branch-arrival interstitial has a Component Patterns row but no symmetric State Patterns row, unlike the structurally similar "Echo active" beat (§ EXPERIENCE.md State Patterns — absence).

**Inheritance discipline** — `run-options-button` (DESIGN.md) vs. "Run options button" (EXPERIENCE.md) — trivial formatting difference only, not a real naming problem.

**Accessibility** — Run-options button (`ellipsis.circle`) has no specified `accessibilityLabel` (§ EXPERIENCE.md, Accessibility Floor — absence). Fix: add "Run options" as the explicit label.

**Accessibility** — `ink-secondary` on `surface-base` passes AA only marginally (~4.85:1) for small wayfinding text (§ DESIGN.md colors). Fix: darken slightly for margin, or confirm it's only used at caption-level (17px), not the smaller meta/pager role.

**Accessibility** — No stated position on iOS "Bold Text"/"Increase Contrast" interacting with the weight-driven type hierarchy (§ DESIGN.md, Typography — absence). Fix: note whether the system is expected to remain legible under Bold Text, or accept as unhandled.

## Reviewer files
- `review-rubric.md`
- `review-accessibility.md`
