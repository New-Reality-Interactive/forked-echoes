---
name: Forked Echoes — Experience Spine
status: final
updated: 2026-08-02
sources:
  - _bmad-output/planning-artifacts/prds/prd-game-2026-07-25/prd.md
  - _bmad-output/brainstorming/brainstorm-ios-app-concept-2026-07-25/brainstorm-intent.md
  - _bmad-output/brainstorming/brainstorm-ios-app-concept-2026-07-25/pitch-one-pager.md
design_ref: ./DESIGN.md
---

# Forked Echoes — Experience Spine

## Foundation

Single-surface native iOS, portrait and landscape on iPhone (see Responsive & Platform — v1 originally shipped portrait-only, reversed via Sprint Change Proposal 2026-07-26). No UI system named — built directly against UIKit/SwiftUI platform conventions (Dynamic Type, VoiceOver, standard gestures); `DESIGN.md` is the visual identity reference, this spine is the experience. Fully on-device: no network states, no offline/sync patterns to design for (FR-11 platform constraint).

No tab bar, no drawer — this is a linear story-runner with one home base, not a multi-section app. A run is a single forward-moving stack (Home → optional Tutorial → Story/Choice pages → Ending → Memory) that always resolves back to Home.

## Information Architecture

| Surface | Reached from | Purpose |
|---|---|---|
| Home | App open (cold or resumed), Ending/Memory "return home" | Title, Start Story, Start Tutorial |
| Tutorial | Home | Explains mechanics; optional, one screen |
| Story / Choice | Home "Start Story", Memory "start a new run" | Paged prose; choice pages gate forward progress (FR-3, FR-4) |
| Branch-arrival interstitial | Triggered mid-story on entering a new branch reality | Full-bleed illustration + flavor caption (FR-12) |
| Ending | Triggered when the story reaches a terminal node | Shared template, 4 outcome variants: home / stay / limbo / hard-fail (FR-8, FR-9) |
| Memory / Recap | Ending (tap anywhere to continue), every run | Choices made, what each caused, alignment score/tier (FR-10) |

Single stack, no branching navigation chrome — the *story* branches, the *app's* IA doesn't. Modal depth is zero: nothing stacks a sheet on a sheet.

A run-options button (subtle ellipsis-circle icon, top-right of the reading card — see `DESIGN.md.components.run-options-button`) persists on every Story/Choice and Tutorial page, opening the platform-native action sheet: **Exit to Home**, **Restart This Run**, **Cancel**. Tap-only, no gesture — this is chrome, not part of the choice-echo interaction language.

→ Composition reference — all 6 IA surfaces now have a visual mockup: `mockups/story-choice-warm-ink-circuit.html` (Story/Choice screen, its echo state, and the Branch-arrival interstitial), `mockups/story-choice-three-way.html` (3-choice decision point — 2 ordinary + 1 hard-fail — at default and accessibility-Dynamic-Type sizes), `mockups/home.html` (fresh-install and run-in-progress/"Resume Story" states), `mockups/tutorial.html` (no circuit frame, run-options icon), `mockups/ending.html` (permanently-active frame; home vs. hard-fail variants side by side), `mockups/memory.html` (score/tier header, choice-and-consequence rows, no frame). Spine wins on conflict.

→ **Landscape composition reference** (see Responsive & Platform): `mockups/home-landscape.html` (fresh-install and run-in-progress states, reflowed), `mockups/tutorial-landscape.html` (no circuit frame; reading column capped/centered), `mockups/story-choice-landscape.html` (2-choice and 3-choice states at default text size; the accessibility-Dynamic-Type 2+1 wrap case is deferred to Story 5.3). Branch-arrival interstitial, Ending, and Memory landscape mockups are deferred to their own future epics.

## Voice and Tone

Microcopy only — brand voice and aesthetic posture live in `DESIGN.md.Brand & Style`. Second person, present tense, wry and observational rather than alarmed — the register is *anticipation*, never horror. Dark-comedy hard-fails are the one place the prose is allowed to turn openly absurd.

| Do | Don't |
|---|---|
| "You did say that. Didn't you?" | "Something is terribly wrong!" |
| "The story remembers." (echo tag) | "Callback unlocked!" / "Achievement: Full Circle" |
| "Somewhere between the third left turn and home, the streetlights changed color." | "WARNING: reality has shifted." |
| Ending/Memory copy states what happened plainly, then lets the score speak | Congratulatory banners, confetti-language, "You win!" |
| Tutorial: short, declarative instructions ("Hold a choice to make it.") | Tooltips-as-hype ("Get ready for an amazing adventure!") |

## Component Patterns

Behavioral. Visual specs live in `DESIGN.md.Components`.

| Component | Use | Behavioral rules |
|---|---|---|
| Choice card | Story/Choice page | Press-and-hold ~3s commits (FR-4); releasing before completion cancels back to idle at any point. A quick tap (or VoiceOver double-tap) also commits — instantly, then holds in a ~1.5s undo window (tap again to cancel) before finalizing, so the tap path is never *less* forgiving than holding. The tap path *is* the standard accessible equivalent, not a hidden fallback. Holding a second card while one is charging cancels the first (only one active charge at a time). Once finalized (charge completes, or the undo window elapses / the player pages forward), locks per FR-5 — revisiting shows the made choice, no re-selection control. |
| Story page | Story/Choice | Swipe left advances, swipe right returns (FR-3); a tap on the right/left third of the reading card (`DESIGN.md.components.page-tap-zones`) does the same, and VoiceOver exposes explicit "Next Page"/"Previous Page" custom actions — page-turning is never reachable only by swipe (FR-11). Forward navigation blocked while an unresolved choice is on-page. Backward always available once ≥1 page read. When prose + choices exceed the visible card height (long scenes, 3-choice decision points, or accessibility Dynamic Type sizes), the content scrolls inside the frame — the frame itself (rule + corners) never scrolls or resizes. |
| Echo callback block | Story page (state variant) | Appears inline within normal page flow, 2-3 times per run per choice per FR-6. Frame powers up (brass → ember, plus the via-grow/pad-fill shape cue, per `DESIGN.md.components.frame`) for the duration this block is on-screen; returns to dormant on the next page turn. |
| Branch-arrival interstitial | Mid-story, on entering a new branch reality | Full-bleed illustration + caption — the arrival node's permanent content (no separate ordinary-prose reveal). On first arrival only, blocks page-turn gestures (swipe and tap-zone alike) until dismissed via its own Continue affordance (tap). On any later visit to the same node, it behaves like an ordinary page — swipe/tap work normally, no gate. |
| Ending screen | Run terminus | One shared template (FR-9); only copy/illustration differ across home/stay/limbo/hard-fail. Hard-fail reaches this screen directly from a gotcha choice, bypassing normal page-turn flow — same destination, different route in. Tap anywhere to advance to Memory — no auto-advance, matching the "Tap to see your run →" affordance shown on-screen. |
| Memory / Recap list | Immediately follows Ending (via tap), every run | Read-only list: choice → what it caused, ending with alignment score/tier. No editing, no re-litigating choices. Always two exits: Return Home, Start New Run. |
| Home actions | Home | "Start Story" / "Start Tutorial" (relabels to "Resume Story" when a run is in progress), each independently tappable — home screen has no gesture-only affordances (FR-1). |
| Tutorial actions | Tutorial | "Start Story" (relabels to "Resume Story" when a run is in progress) is a fixed, always-visible primary action — pinned outside the scrolling content area in both portrait and landscape, so it never requires scrolling to reach. Leaving Tutorial uses the screen's standard iOS navigation-bar back button/edge-swipe — no separate in-content "Back Home" button. *(Amended 2026-08-02 per `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md`; Tutorial's "non-gestural" intent remains scoped to the mechanics it teaches — page-turn tap zones and choice-card tap/hold, both still described in words before the player reaches a real choice — not to leaving the screen itself.)* |
| Eyebrow tag | Every reading screen (Story/Choice, Tutorial, Ending) | Always present, static, non-interactive — never itself a control, never absent on a reading screen. |
| Run options button | Story/Choice, Tutorial | Opens native action sheet: "Exit to Home" (non-destructive — preserves the in-progress run, same as backgrounding), "Restart This Run" (destructive-styled, requires a second confirmation — clears progress and alignment score), "Cancel". Absent from the branch-arrival interstitial and Home. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| Cold / resumed open | Home | [ASSUMPTION] An in-progress run auto-resumes to its last page on next launch rather than forcing restart — no explicit save-slot UI; this is standard iOS state restoration, not a modeled feature. Home's primary action relabels "Start Story" → "Resume Story" whenever a run is in progress. |
| Run in progress, options opened | Story/Choice, Tutorial | Action sheet presented; "Restart This Run" requires an explicit second confirmation step before it clears anything — never a single tap to destroy progress. |
| Choice idle | Choice page | Card shows text + arrow, `DESIGN.md` idle styling, no fill. |
| Choice charging | Choice page | Fill advances over 3s from press start. Releasing early cancels — resets to idle, no partial memory. |
| Choice tap-committed (undo window) | Choice page | Selected styling applies immediately; ~1.5s undo window open (tap again to revert). VoiceOver announces it (see Accessibility Floor). |
| Choice committed (finalized) | Choice page | Selected styling (FR-5 consequence), undo window elapsed or hold charge completed or player paged forward; forward nav unblocks immediately on either commit path, independent of the undo window. |
| Choice page revisited (decided) | Choice page, via back-nav | Shows the made choice in its committed styling; no alternate-choice control rendered at all (not just disabled). |
| Alignment running total | Never surfaced during a run | FR-7: the alignment score is summed silently and is never rendered, announced, or otherwise exposed while a run is in progress — it first appears on Memory. |
| Echo active | Story page | Echo callback block + powered-up frame, exactly for that page's duration. |
| Interstitial active | Branch-arrival interstitial | Full-bleed art + caption, blocking page-turn (swipe and tap-zone alike) until the Continue affordance is tapped — symmetric to Echo active as a distinct, transient, blocking beat (first visit to this node only — later visits render the same content without gating). |
| Ending — home / stay / limbo | Ending | Shared template; tone shifts by copy only (see Voice and Tone). |
| Ending — hard-fail | Ending | Same shared template, reached abruptly; recap still follows in full (FR-10 — no exception for hard-fail). |
| Tutorial skipped | Home → Story | Tutorial is optional and only reachable from Home (FR-2) — skipping it has no different in-story state; the story doesn't know whether the tutorial was seen. |

## Interaction Primitives

- Swipe left / right, **or** a tap on the right/left third of the reading card (`DESIGN.md.components.page-tap-zones`): page turn (Story/Choice surface). VoiceOver additionally exposes "Next Page"/"Previous Page" as custom actions, independent of both. No path here is gesture-only (FR-11).
- Press-and-hold (~3s) on a choice card: primary "commit" gesture, cancellable by releasing at any point. Quick tap on the same card: identical commit, instantly, followed by a ~1.5s undo window — always available, not contingent on detecting assistive technology, and never less forgiving than the hold path.
- Tap: all non-story-page navigation (Home, Tutorial, interstitial Continue, Ending, Memory).
- **Banned:** any interaction reachable only via a custom gesture (FR-11, hard constraint); streak counters, badge counts, or re-engagement nudges (fits the non-gamified posture — no backend to drive them anyway); carousels; hero animations on cold open.

## Accessibility Floor

Behavioral. Visual contrast and Dynamic Type values live in `DESIGN.md`.

- VoiceOver: every choice card exposes role + label + state ("Choice, Ask Sam about the boat, not yet selected" / "...selected, double-tap again within 1.5 seconds to undo"). Double-tap activates immediately — VoiceOver users are never asked to sustain a 3-second hold; the instant-commit-plus-undo-window path (identical to a quick tap) is the VoiceOver-compatible equivalent required by FR-11. The Story page additionally exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible), since a one-finger swipe is otherwise consumed by VoiceOver's own navigation and never reaches the app. The run-options button carries an explicit `accessibilityLabel` of "Run options" (not left to the SF Symbol's default name).
- Dynamic Type: honored through `DESIGN.md` typography tokens at every role, each bound to a named iOS text style (see `DESIGN.md.Typography`) rather than a manual scale multiplier; body/echo text must grow through accessibility sizes without truncation — layout absorbs the growth (with headroom sized for the largest accessibility category, see `DESIGN.md.Layout & Spacing`), type never clamps.
- Reduce Motion: skip the choice-card charge-fill animation (commit is instant instead, no 3s wait) and skip the frame's echo power-up glow/transition (ember state + shape cue apply immediately, no transition). Page-turn and the branch-arrival interstitial's entrance/exit — both plain wayfinding motion under normal conditions — collapse to an instant cut; nothing in the system produces continuous or looping motion under Reduce Motion.
- Tap targets ≥ 44pt on every interactive element, including choice cards, page tap zones, the run-options button, and the Home/Tutorial/Ending/Memory actions.
- Focus traversal follows reading order — eyebrow tag → prose → choices → pager — on every Story/Choice page; the run-options button sits last in traversal order so it never interrupts reading flow.
- The Restart confirmation uses the platform's native destructive-action pattern (system alert/action sheet) — inherits VoiceOver announcement and Dynamic Type behavior for free; no custom-built confirmation dialog.
- Branch-reality illustrations: every illustration exposes a distinct, descriptive `accessibilityLabel` — not restating the interstitial's caption, but conveying the illustration's specific visual content, so VoiceOver users get equivalent access to the branch reality's atmosphere. No illustration relies on a meaningless default label, and none is silently hidden from the accessibility tree — the visual detail is part of the experience, not decoration.

## Responsive & Platform

Both portrait and landscape are first-class on iPhone (v1 originally shipped portrait-only; reversed via Sprint Change Proposal, 2026-07-26 — Epic 5). No iPad/Universal support (unchanged from Foundation).

- **Reading surfaces** (Story/Choice, Tutorial, Ending, Memory): the reading column grows wider with the screen in landscape, capped at `DESIGN.md.components.reading-surface.column-max-width-landscape` for readability — extra width becomes side margin, not longer lines. Portrait is unaffected. The Dynamic Type headroom rule (`DESIGN.md.Layout & Spacing`) applies identically in both orientations — landscape's shorter frame requires the same clearance as portrait.
- **Circuit frame:** unchanged in concept and behavior (dormant brass / ember echo, shape-cue redundancy) — only its corner geometry reflows to the new aspect ratio. Corner mark sizes don't change, only their position along the frame edges.
- **Choice cards:** stack vertically in portrait; arrange in a horizontal row in landscape (2, occasionally 3 cards) — same gap token, same hold/tap-commit interaction, same equal ordinary/hard-fail styling, same 44pt tap-target floor regardless of orientation (`DESIGN.md.components.choice-card.layout-landscape`). VoiceOver traversal order among choice cards follows their narrative/document order regardless of visual arrangement (vertical stack or horizontal row), so accessibility order and visual order never diverge. A 3-card row wraps to a 2+1 layout (not a vertical stack) once any label would exceed 2 lines at the current column width, or at Dynamic Type accessibility sizes and above — a hard constraint, not a deferred judgment call.
- **Home / Tutorial:** same vertical stack (title, subtitle, actions) in both orientations, simply centered within the wider landscape frame — no side-by-side rearrangement. Action buttons carry the same 44pt tap-target floor in both orientations.
- **Branch-arrival interstitial:** same full-bleed composition (art, headline, caption bar), reflows to fill the landscape frame — no new layout, no frame (unchanged from portrait).
- **Page-turn tap zones / swipe:** same proportional left/right-third split in both orientations — no new gesture design.
- **Rotation mid-interaction** (device rotated while something is already in progress):
  - Branch-arrival interstitial active: the Continue-gate and blocking behavior survive rotation untouched; the art recomposes to the new aspect ratio without a jarring cut (a plain reflow, not a transition to replay).
  - Echo-active page: the powered-up frame state and echo callback block simply persist/re-render — the power-up shape/color cue does not restart or replay its transition.
  - [ASSUMPTION] Choice-card hold in progress: rotation cancels the charge, identical to releasing early. This affects only the hold path — the tap-plus-undo-window path (the documented VoiceOver-compatible equivalent, always available) and VoiceOver double-tap are both instant and unaffected by rotation, so no interaction is ever left without a rotation-safe path. Revisit if this reads as jarring during implementation/playtesting.

## Inspiration & Anti-patterns

- **Lifted from editorial/magazine design:** the confidence of oversized bold sans type and high-contrast cards on the choice/story reading surface — see `DESIGN.md.Brand & Style`.
- **Lifted from PCB/circuit-board design:** the frame's corner geometry (trace lines, a via node, open pads) — chosen specifically to carry a "time-machine console" reading and to give the echo/resolved states a shape-based signal alongside color.
- **Rejected — plain hairline bracket/crop-mark frame:** earlier exploration rounds tried a thin hairline-and-corner-tick frame (refined but generic) and a thick black crop-mark bracket (confident but heavy-handed); both were set aside in favor of the circuit-trace treatment specifically for its narrative tie to the "console reading the story back to you" premise.
- **Rejected — deviation-driven visual theming, streak counters, gamification chrome:** explicitly out of scope per the PRD (deferred to v1.1+ or excluded outright as a non-goal) — this experience spine doesn't design for them.

## Key Flows

### UJ-1 — Mary's first full playthrough

1. Mary opens the app cold — Home screen, app title, story title, "Start Story" / "Start Tutorial".
2. She opens the tutorial (learns: swipe to turn pages, hold a choice to make it), then starts the story.
3. Story screen: large HIG-accessible text, swipe left to advance, swipe right to go back.
4. She reaches a choice page — forward is blocked. She holds "Ask Sam about the boat." for the ~3s charge; the card locks in. Forward navigation unblocks.
5. Partway through, the frame powers up from brass to ember and an echo callback appears — "You remember steering the boat..." — she recognizes her earlier choice resurfacing, 2-3 times across the run.
6. Along the way, arriving in a new branch reality triggers the full-bleed interstitial; she taps Continue to resume reading.
7. **Climax:** her branch resolves to an Ending screen (home/stay/limbo, matching her path); she taps anywhere to continue to the Memory screen — every choice she made, what it caused, and her alignment score/tier.
8. **Resolution:** from Memory, she taps Return Home or Start New Run.

### UJ-2 — Hard-fail run

1. Same interaction model as UJ-1, later run.
2. At a choice point, she holds an obviously-bad, dark-comedy gotcha option.
3. **Climax:** the story jumps directly to the Ending screen — same shared template as UJ-1, just hard-fail copy/illustration; tapping through leads to the same full Memory recap as any other run. The recap appearing even after an abrupt ending is itself part of the comedic payoff, not a completion reward withheld and then given.
4. **Resolution:** Return Home or Start New Run, identical to UJ-1.
