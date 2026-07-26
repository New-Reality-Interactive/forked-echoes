---
name: Forked Echoes — Warm Ink, Circuit Frame
description: Native iOS CYOA reader. Warm ink on paper, oversized editorial-sans confidence, and a brass circuit-trace frame that powers up when the story echoes a past choice.
status: final
updated: 2026-07-25
sources:
  - _bmad-output/planning-artifacts/prds/prd-game-2026-07-25/prd.md
  - _bmad-output/brainstorming/brainstorm-ios-app-concept-2026-07-25/brainstorm-intent.md
  - _bmad-output/brainstorming/brainstorm-ios-app-concept-2026-07-25/pitch-one-pager.md
colors:
  surface-base: '#FAF6EE'
  surface-raised: '#FFFFFF'
  surface-inverse: '#241C14'
  ink-primary: '#241C14'
  ink-secondary: '#6A5A45'
  ink-on-inverse: '#FFFFFF'
  accent-ember: '#C2540F'
  accent-ember-text: '#E37A2E'
  trace-brass: '#8B6F47'
  selected-fill: '#F0DDAF'
  surface-base-dark: '#1C1712'
  surface-raised-dark: '#262019'
  surface-inverse-dark: '#F3ECDD'
  ink-primary-dark: '#F3ECDD'
  ink-secondary-dark: '#B7A78D'
  ink-on-inverse-dark: '#1C1712'
  accent-ember-dark: '#E0763A'
  accent-ember-text-dark: '#9A3D12'
  trace-brass-dark: '#C9A876'
  selected-fill-dark: '#3A2E1E'
typography:
  headline:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 34px
    fontWeight: '900'
    lineHeight: '1.0'
    letterSpacing: -0.02em
    iosTextStyle: 'largeTitle, scaled — custom weight/tracking override on top of the system style'
    note: 'Uppercase. Base size at default Dynamic Type category — scales with system setting (FR-11).'
  body:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 20px
    fontWeight: '500'
    lineHeight: '1.5'
    iosTextStyle: 'body, scaled'
    note: 'Story/scene prose. Base size at default Dynamic Type category — must scale with system setting up through accessibility sizes (FR-11); never clamp.'
  choice-label:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 17px
    fontWeight: '800'
    iosTextStyle: 'headline, scaled'
  echo-callback:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 20px
    fontWeight: '600'
    iosTextStyle: 'body, scaled'
    note: 'Same base size and text style as body — the echo must read as part of the story, not a smaller footnote.'
  eyebrow:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 12px
    fontWeight: '800'
    letterSpacing: 0.1em
    iosTextStyle: 'caption2, scaled'
    note: 'Uppercase.'
  caption:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 17px
    fontWeight: '600'
    iosTextStyle: 'callout, scaled'
  meta:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 12px
    fontWeight: '700'
    letterSpacing: 0.08em
    iosTextStyle: 'caption2, scaled'
    note: 'Uppercase. Pager, swipe hint.'
  stat:
    fontFamily: 'SF Pro (system sans)'
    fontSize: 34px
    fontWeight: '900'
    lineHeight: '1.0'
    iosTextStyle: 'largeTitle, scaled'
    note: 'Memory screen alignment-score number. Same scale as headline — the score is a headline moment, not a caption.'
rounded:
  DEFAULT: '0px'
  full: '9999px'
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '7': 32px
  '8': 40px
components:
  frame:
    inset-rule-width: 1px
    inset-rule-color: '{colors.trace-brass}'
    inset-rule-color-active: '{colors.accent-ember}'
    corner-trace-color: '{colors.trace-brass}'
    corner-trace-color-active: '{colors.accent-ember}'
    corner-via-diameter: 7px
    corner-via-diameter-active: 9px
    corner-pad-diameter: 5px
    corner-pad-fill-active: '{colors.accent-ember}'
    background: '{colors.surface-raised}'
    note: 'Active state is never color-alone: the via grows 7px → 9px and the hollow pads fill solid, so the powered-up state reads by shape/size as well as hue (CVD-safe redundancy — brass/ember are luminance-close and would otherwise be a pure hue shift).'
  choice-card:
    background: '{colors.surface-raised}'
    border-width: 3px
    border-color: '{colors.ink-primary}'
    text: '{typography.choice-label}'
    radius: '{rounded.DEFAULT}'
    charge-fill-color: '{colors.trace-brass}'
    charge-duration: 3000ms
    tap-undo-window: 1500ms
    selected-background: '{colors.selected-fill}'
    selected-border-color: '{colors.ink-primary}'
    note: 'A quick tap (or VoiceOver double-tap) commits instantly but enters the same tap-undo-window before finalizing, so the tap path is never less forgiving than the hold path (which allows cancel-by-release throughout its full charge-duration).'
  page-tap-zones:
    left-zone-width: 33%
    right-zone-width: 33%
    visual: 'invisible — no persistent chrome, consistent with the flat reading surface; this is a tap-equivalent for the swipe page-turn gesture, not a new visible control'
    tap-target: 'each zone spans the full card height, comfortably exceeding the 44pt minimum'
  eyebrow-tag:
    background: '{colors.surface-inverse}'
    text-color: '{colors.ink-on-inverse}'
    text: '{typography.eyebrow}'
    padding: '4px {spacing.2}'
  echo-callback:
    background: '{colors.surface-inverse}'
    tag-color: '{colors.accent-ember-text}'
    tag-color-dark: '{colors.accent-ember-text-dark}'
    text-color: '{colors.ink-on-inverse}'
    text: '{typography.echo-callback}'
    note: 'tag-color uses the text-safe ember variant, not the decorative {colors.accent-ember} used on the frame — accent-ember fails AA at this text size/weight on surface-inverse in both themes; accent-ember-text/-dark are tuned to clear 4.5:1.'
  interstitial:
    background: '{colors.surface-inverse}'
    headline-color: '{colors.selected-fill}'
    caption-color: '{colors.ink-on-inverse}'
    caption-bar-accent: '{colors.accent-ember}'
  continue-button:
    background: '{colors.selected-fill}'
    text-color: '{colors.surface-inverse}'
    radius: '{rounded.DEFAULT}'
  run-options-button:
    icon: 'ellipsis.circle (SF Symbol)'
    color-idle: '{colors.trace-brass}'
    color-pressed: '{colors.ink-primary}'
    position: 'top-right of the reading card content area, inset so it never overlaps the circuit corner geometry'
    tap-target: 44pt minimum (glyph itself smaller, hit area padded)
  ending-frame:
    inherits: '{components.frame}'
    rule-color: '{colors.accent-ember}'
    corner-color: '{colors.accent-ember}'
    note: 'Frame rests permanently in its powered-up ember state (including the grown-via/filled-pad shape cue) on the Ending screen — the one place the active state is static rather than transient, signaling the run is fully resolved.'
  memory-row:
    background: '{colors.surface-raised}'
    divider-color: '{colors.trace-brass}'
    text-choice: '{typography.choice-label}'
    text-consequence: '{typography.body}'
    text-color-consequence: '{colors.ink-secondary}'
  memory-score:
    number-color: '{colors.accent-ember}'
    number-color-dark: '{colors.accent-ember-dark}'
    number-typography: '{typography.stat}'
    tier-color: '{colors.ink-secondary}'
    tier-typography: '{typography.meta}'
    note: 'Decorative {colors.accent-ember}/{colors.accent-ember-dark} are safe here because the number is always set in {typography.stat} (34px/900) — large-text AA only needs 3:1, and both colors clear it against surface-base/surface-raised with margin. Never reuse accent-ember at body/caption size — use accent-ember-text/-dark instead (see echo-callback).'
  app-icon:
    background: '{colors.surface-inverse}'
    motif-color: '{colors.trace-brass}'
    accent-color: '{colors.accent-ember}'
    note: 'The frame''s corner geometry (trace line, via, pad) scaled up to fill the full icon square — brass motif on the inverse (dark-in-light-mode) surface, with a single ember-lit via as the one chromatic accent. No text, no in-app UI chrome (no choice cards, no prose) — must read as a mark at 60x60pt down to the App Store''s largest presentation size.'
---

## Brand & Style

This is a story you're holding, not an app you're operating. The premise — one choice too many, and suddenly the dog's a cat and everyone insists you've always lived here — should feel like *anticipation*: a pull toward the next page, not dread. Warm ink on paper carries that: a reading surface with the confidence of a magazine masthead (oversized bold sans, high-contrast choice cards) rather than the softness of a diary app.

The signature device is the frame: every reading screen is bordered in brass circuit-trace corners — a trace line, a via node, an open component pad — quietly suggesting a time-machine console reading the story back to you. It stays dormant (brass) through ordinary pages. The moment the prose echoes a choice you made earlier, the whole frame powers up to ember and glows, exactly once per echo — the console registering that the past just reached into the present. The power-up is never color alone: the via grows and the pads fill solid, so it reads by shape as well as hue. The echo glow is the only thing in this system allowed to *pulse as a signal*; ordinary wayfinding motion (a page turning, the interstitial fading in) still happens, but it's plain navigation, not a signal, and it collapses to an instant cut under Reduce Motion (see `EXPERIENCE.md.Accessibility Floor`).

## Colors

Two roles carry almost everything: a warm neutral pair (paper and ink) and one hot accent (ember) reserved entirely for "this choice mattered."

- **Surface Base (`{colors.surface-base}` / `{colors.surface-base-dark}`)** — the page itself. Warm paper-cream in light mode, a warm near-black (not pure black — keeps the brand's warmth) in dark mode. Never pure white or pure black; both would read as generic app chrome instead of a warm object.
- **Surface Raised (`{colors.surface-raised}` / `{colors.surface-raised-dark}`)** — the reading card that sits inside the circuit frame. Distinguished from base by tone only, no shadow.
- **Surface Inverse (`{colors.surface-inverse}` / `{colors.surface-inverse-dark}`)** — the "console is speaking" surface: eyebrow chapter tags, the echo-callback block, and the full-bleed branch-arrival interstitial all use this. It's `ink-primary`'s value in light mode; in dark mode it flips to the light warm cream, so the inverse relationship always holds regardless of system appearance.
- **Ink Primary / Secondary** — body text and its muted counterpart (pager, meta labels, captions-in-passing). Both carry the same warm brown hue family at different weights — never a cool or neutral grey, which would break the "paper" read. `ink-secondary` is deliberately darker than the mockups' first pass (`#6A5A45`, not `#7A6A55`) to clear AA with real margin at the small sizes it's used at.
- **Accent Ember (`{colors.accent-ember}` / dark: `{colors.accent-ember-dark}`)** — the *only* chromatic accent, and it means exactly one thing: a choice echo just fired. Used on the frame, the interstitial's caption-bar accent (arrival is itself a kind of echo — the world announcing it changed), and the Memory score number (always at `{typography.stat}` size). Never used for ordinary emphasis, links, or decoration. **Decorative/large-text use only** — these two values are tuned for the frame's line-work and for text at 24px+/bold, where WCAG's large-text 3:1 threshold applies. They are not AA-safe at body/caption sizes; see Accent Ember Text below.
- **Accent Ember Text (`{colors.accent-ember-text}` / dark: `{colors.accent-ember-text-dark}`)** — the text-safe sibling of Accent Ember, for any small/bold ember-colored text run (currently: the echo-callback's "The story remembers" tag). Verified ≥4.5:1 against `surface-inverse`/`surface-inverse-dark` respectively — brighter/more saturated in light mode, darker/more saturated in dark mode, since the inverse surface flips from dark to light between themes.
- **Trace Brass (`{colors.trace-brass}` / dark: `{colors.trace-brass-dark}`)** — the frame's resting state. A muted aged-copper, deliberately quieter than ember so the powered-up moment reads as a real state change, not a palette variant. Brass and ember sit at nearly identical luminance (a deliberate warm-family choice), so the powered-up state is never signaled by color alone — see the Frame component's shape cue.
- **Selected Fill (`{colors.selected-fill}` / dark: `{colors.selected-fill-dark}`)** — warm cream used for a locked-in choice card and the Continue affordance. Warm, not chromatic — it marks "settled," where ember marks "this mattered."

**Verified contrast (WCAG relative-luminance method), load-bearing pairs:**

| Pair | Light | Dark |
|---|---|---|
| `ink-primary` on `surface-base`/`surface-raised` | ~15.6–16.8:1 | ~15.1:1 |
| `ink-secondary` on `surface-base`/`surface-raised` | ~6.2:1 | ~7.6:1 |
| `ink-on-inverse` on `surface-inverse` | ~16.8:1 | ~15.1:1 |
| `accent-ember-text` (tag, small bold) on `surface-inverse` | ~5.7:1 | ~5.9:1 |
| `accent-ember` / `selected-fill` cross-pair (large text only, e.g. interstitial headline, Memory score) | ~4.6–12.5:1 | ~5.8–12.5:1 |

All exceed the 4.5:1 (normal text) or 3:1 (large text, ≥24px/bold) AA thresholds they're used at. `accent-ember`/`accent-ember-dark` are the one pair restricted to large-text contexts only — see the note above.

Avoid: cool greys (breaks the paper metaphor), a second chromatic accent (ember must stay singular), pure black/white surfaces (too clinical for a warm-ink object), gradients outside the branch-arrival interstitial (the reading surface itself is flat and confident, not atmospheric), `accent-ember`/`accent-ember-dark` on any text under 24px (use `accent-ember-text`/`-dark` instead).

## Typography

One family, SF Pro (system sans — Dynamic Type is non-negotiable per FR-11), carrying every role through weight and size rather than a second typeface. That restraint is deliberate: the confidence comes from scale and weight contrast (`{typography.headline}` at 900 vs. `{typography.body}` at 500), not from mixing display and body faces.

`{typography.body}` and `{typography.echo-callback}` share the same base size on purpose — an echo is not a footnote, it's the story remembering out loud, and it must read with the same weight as everything around it (distinguished by its inverse-surface treatment, not by shrinking). `{typography.eyebrow}` and `{typography.meta}` are the only uppercase, tracked-out roles, reserved for wayfinding chrome (chapter tag, pager) that should recede behind the prose.

Every size in this token set is the *default* Dynamic Type category. None of them are permitted to clamp — FR-11 requires the story text area to scale up through accessibility sizes without truncation; layout (not type) absorbs that growth.

Each role binds to a named iOS text style (`iosTextStyle` field, e.g. `{typography.body}` → `body`), not a raw point size scaled by a manual multiplier — this is what makes "must scale with system setting" implementable and testable rather than directional. Two roles sharing a text style (`headline` and `stat` both bind to `largeTitle`) are expected to scale in lockstep; that's intentional, not drift.

This system's hierarchy comes from weight contrast (900/800/600/500), not size or color, so it's worth naming the edge case: under iOS's **Bold Text** accessibility setting, the system pushes already-heavy weights further, which can compress how distinctly `{typography.body}` (500) reads against `{typography.headline}`/`{typography.choice-label}` (900/800). This is accepted as-is for v1 — the weight relationship may flatten slightly under Bold Text, but nothing becomes illegible or loses its role. Not a blocking constraint; revisit only if user feedback says otherwise.

## Layout & Spacing

An 8pt-based scale (`{spacing.2}` through `{spacing.7}`), standard for iOS. The reading card's internal padding sits at `{spacing.6}`/`{spacing.4}` (generous — this is a book, not a form); gaps between stacked choice cards use `{spacing.3}`; the frame's inset rule sits `{spacing.2}` + 1px in from the card edge, leaving room for the corner trace geometry without crowding the text.

Single column, full-bleed reading card per screen — no split views, no multi-pane. The branch-arrival interstitial is the one full-bleed exception (art fills the frame entirely; the circuit frame does not appear on that screen, reserved for reading/choice screens only).

**Dynamic Type headroom.** The frame-well's padding and the circuit corner assembly's clearance are specified with generous fixed headroom (not scaled 1:1 with type), sized to the *largest* accessibility Dynamic Type category, not the default — the corner geometry itself doesn't grow, only the text inside the well does, so headroom must already assume maximum text size rather than being retrofitted later. On the branch-arrival interstitial, the headline is permitted to wrap to 2 lines at accessibility sizes; the CSS-composed art beneath it is treated as background, not layout — it never claims space the wrapped headline needs, and any overlap is resolved in the headline's favor (art crops/dims under it rather than the reverse).

Structurally, the frame (rule + corner geometry) and the reading content are two independent layers: the frame is pinned to the card's edges and never scrolls; the prose/choices layer scrolls *inside* it whenever content exceeds the visible height — at 3 choice cards, at accessibility text sizes, or both at once. This is what makes the headroom rule verifiable rather than aspirational: content growth is absorbed by scrolling under a fixed frame, never by the frame growing, shrinking, or being crowded. Validated at 3 choices (2 ordinary + 1 hard-fail) against an accessibility-scale text stress-test in `mockups/story-choice-three-way.html`.

## Elevation & Depth

No shadows on the reading surface — `{colors.surface-raised}` sits on `{colors.surface-base}` by tone alone, matching the "flat, confident page" brand posture. The one glow permitted in the whole system is the echo-powered-up frame (`box-shadow` glow on the trace/via/pad in `{colors.accent-ember}`) — because that glow *is* the signal, not decoration. No other element may borrow it.

## Shapes

Sharp everywhere. `{rounded.DEFAULT}` (0px) applies to the reading card, choice buttons, the eyebrow tag, and the Continue button — no rounded corners, no pill shapes anywhere in the reading UI. The one deliberate exception is the circuit motif's own geometry: the via nodes are full circles and the pads are small squares with a hollow center — components, not corners, so `{rounded.full}` applies only there, never to a container.

## Components

- **Frame** (`{components.frame}`) — wraps every story/choice reading screen. A 1px inset rule in `{colors.trace-brass}`, plus four corner assemblies: a horizontal trace stub, a vertical trace stub, a filled via circle at the bend, and two hollow square pads at the stub ends. Active state (see Brand & Style): rule and corners switch to `{colors.accent-ember}` with a soft glow, via grows `{components.frame.corner-via-diameter}` → `{components.frame.corner-via-diameter-active}`, pads fill solid.
- **Eyebrow tag** (`{components.eyebrow-tag}`) — small inverse-surface chip carrying the chapter/location label. Always present at the top of a reading screen; never used for anything other than wayfinding. Static, non-interactive — never itself a control.
- **Page tap zones** (`{components.page-tap-zones}`) — invisible left/right-third tap regions over the reading card, equivalent to swipe-left/right (FR-11: no gesture-only interaction). No visual chrome of their own; the reading surface stays clean, and the Tutorial screen is where the affordance is taught in words rather than shown as a persistent icon.
- **Choice card** (`{components.choice-card}`) — full-width card, `{colors.surface-raised}` background, 3px `{colors.ink-primary}` border, `{typography.choice-label}`, an arrow glyph trailing. On press-and-hold, a `{components.choice-card.charge-fill-color}` fill advances across the card over `{components.choice-card.charge-duration}` (brass, matching the frame's dormant trace color — the card itself is charging like a circuit). A quick tap (or VoiceOver double-tap) commits instantly but enters the same `{components.choice-card.tap-undo-window}` grace period before finalizing — the tap path is never less forgiving than holding, which can be cancelled by releasing at any point during its charge. On completion, it switches to `{components.choice-card.selected-background}` fill with a checkmark — permanent for that page (FR-5); no other affordance appears once selected.
- **Echo callback** (`{components.echo-callback}`) — an inverse-surface block inset within the prose flow, tagged "The story remembers" in `{colors.accent-ember-text}` (the text-safe ember variant — see Colors), body text in `{colors.ink-on-inverse}` at full body weight. Always paired with the frame's powered-up state — the two fire together, never independently.
- **Branch-arrival interstitial** (`{components.interstitial}`) — full-bleed `{colors.surface-inverse}` background, CSS-composed art (no literal image assets), oversized headline in `{colors.selected-fill}`, caption bar with a `{colors.accent-ember}` top accent. No circuit frame here — this screen is the one moment the reading frame steps aside for pure art. At accessibility Dynamic Type sizes the headline may wrap to 2 lines; the art never contests that space (see Layout & Spacing).
- **Continue button** (`{components.continue-button}`) — solid `{colors.selected-fill}` fill, `{colors.surface-inverse}` text, sharp corners, uppercase label. The only filled (non-outline) button in the system besides the selected choice state.

- **Run options button** (`{components.run-options-button}`) — a small ellipsis-circle glyph in `{colors.trace-brass}`, reading as a quiet console control rather than a system chrome element. Present on every Story/Choice and Tutorial page; deliberately absent from the branch-arrival interstitial (that screen stays a pure art moment) and from Home (nothing to exit from there). VoiceOver label specified in `EXPERIENCE.md.Accessibility Floor`.
- **Ending frame** (`{components.ending-frame}`) — the only screen where the circuit frame's powered-up ember state is a resting condition, not a transition. Signals "this run is fully resolved" — the console stayed lit because the story finished, not because an echo just fired. Carries the same grown-via/filled-pad shape cue as the transient echo state, permanently.
- **Memory row** (`{components.memory-row}`) — a read-only choice-and-consequence row, visually related to the choice-card (same label typography) but flat, undecorated, no border or press state — this screen looks back, it doesn't ask for input.
- **Memory score** (`{components.memory-score}`) — the alignment-score number and tier label at the top of Memory, in `{typography.stat}` and `{colors.accent-ember}` (safe at this size — see Colors) with the tier label in `{typography.meta}`/`{colors.ink-secondary}`.
- **Home / Tutorial chrome** — Home and Tutorial are title-card and instructional surfaces, not reading pages. Home does **not** carry the circuit frame — the frame is reserved for reading surfaces (Story/Choice, Tutorial, Ending); Home is the one screen allowed a simpler, more spacious layout so the frame's appearance always means "you're inside the story."

Reference mockups: [`mockups/story-choice-warm-ink-circuit.html`](./mockups/story-choice-warm-ink-circuit.html) (story/choice screen, echo state, branch-arrival interstitial), [`mockups/story-choice-three-way.html`](./mockups/story-choice-three-way.html) (3-choice decision point — 2 ordinary + 1 hard-fail — at default and accessibility-Dynamic-Type sizes), [`mockups/home.html`](./mockups/home.html) (fresh-install and run-in-progress/"Resume Story" states), [`mockups/tutorial.html`](./mockups/tutorial.html) (dormant frame, run-options icon), [`mockups/ending.html`](./mockups/ending.html) (permanently-active frame; home vs. hard-fail variants side by side), [`mockups/memory.html`](./mockups/memory.html) (score/tier header, choice-and-consequence rows, no frame).

## App Icon

The one visual signature a player recognizes before ever opening the app — translates the reading surface's circuit-frame motif (`{components.frame}`) into a single, self-contained icon square rather than borrowing any in-app screen content.

- **Composition:** the frame's corner geometry (trace line, via node, hollow pad) scaled up to fill the icon, on `{colors.app-icon.background}` (`{colors.surface-inverse}` — the "console is speaking" surface, appropriate for the mark that represents the whole app). Brass (`{colors.app-icon.motif-color}`) carries the linework; a single via glows ember (`{colors.app-icon.accent-color}`) as the one chromatic accent — the same "dormant brass, one point of ember" language used throughout the reading surfaces, distilled to its simplest form.
- **No text, no UI chrome:** no app name lettering, no choice-card shapes, no prose — the icon is a mark, not a screenshot.
- **Legibility floor:** must read clearly as a distinct shape at 60x60pt (Home Screen small size) up through the App Store's largest listing presentation — test at the smallest size first, not last.
- **Rationale:** consistent with the rest of this system's restraint (one family, one accent, no decoration for decoration's sake) — the icon shouldn't introduce a visual idea the rest of the app doesn't already have.

## Do's and Don'ts

| Do | Don't |
|---|---|
| Reserve ember for echo/arrival moments only | Use ember for ordinary links, emphasis, or errors |
| Keep the frame brass and dormant on every non-echo page (Ending excepted — see below) | Leave the frame powered-up/glowing as a resting state anywhere but Ending |
| Size everything from the default Dynamic Type category and let it grow | Clamp or fix text size against FR-11's Dynamic Type requirement |
| Keep corners sharp (`{rounded.DEFAULT}`) everywhere but the circuit's own via/pad marks | Round choice cards, buttons, or the reading card |
| Let the echo callback read at full body weight, distinguished by surface | Shrink or de-emphasize echo text as a "footnote" |
| Use warm-hued neutrals throughout (paper, ink, brass) | Introduce cool greys or a second chromatic accent |
| Reserve the circuit frame for reading surfaces (Story/Choice, Tutorial, Ending) | Put the frame on Home — it should always mean "you're inside the story" |
| Let Ending rest in the ember-active frame state permanently | Animate/pulse the Ending frame — it's resolved, not reacting |
| Pair every ember state-change with a shape/size cue (via diameter, pad fill) | Signal "active/echoed" with color alone — brass/ember are luminance-close |
| Use `accent-ember`/`-dark` only at 24px+/bold (frame, headline, Memory score) | Use `accent-ember`/`-dark` on small or caption-weight text — use the `-text` variant |
