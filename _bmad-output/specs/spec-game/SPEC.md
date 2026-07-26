---
id: SPEC-game
companions:
  - glossary.md
  - ../../planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md
  - ../../planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md
  - ../../planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md
sources:
  - ../../planning-artifacts/prds/prd-game-2026-07-25/prd.md
  - ../../planning-artifacts/prds/prd-game-2026-07-25/addendum.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability only — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Forked Echoes — v1

## Why

A vision to realize, doubling as a mandate the builder set for themself: ship a solo-built, native iOS Choose-Your-Own-Adventure game — about a player stranded in branch realities one choice too many from home — as a first real, end-to-end learn-to-ship project, walking the entire path from idea to actual App Store submission. The game's one load-bearing mechanic is that choices echo: an early pick is explicitly called back 2-3 times later, so a run reads as proof a choice *mattered*, not just that it branched, and every run closes with a memory screen that turns it into a story about the player. On-device only, no backend — the constraint is as much part of the "learn to ship a real thing, small and complete" goal as any feature.

## Capabilities

- **CAP-1**
  - **intent:** Player chooses "Start Story" or "Start Tutorial" from the home screen, each via a distinct gesture with an accessible tap equivalent.
  - **success:** Home screen shows app title and story title; both entries are reachable via VoiceOver/standard tap, not gesture-only.
- **CAP-2**
  - **intent:** Player views a tutorial explaining the game's mechanics, then returns home or starts the story.
  - **success:** Tutorial is reachable only from the home screen; both exits are gesture-selectable with accessible tap equivalents.
- **CAP-3**
  - **intent:** Player advances a page (swipe left) or returns to the previous page (swipe right) within a story branch, with an accessible non-gesture equivalent.
  - **success:** Forward navigation is blocked on a page containing an unresolved choice; backward navigation is always available once at least one page has been read.
- **CAP-4**
  - **intent:** Player selects one of the presented choices on a choice page, each bound to a distinct gesture with a standard accessible tap/VoiceOver equivalent.
  - **success:** A choice page presents at least two independently selectable choices; making a choice unblocks forward navigation past that page.
- **CAP-5**
  - **intent:** Once a choice is made, the player cannot change it by re-navigating to that page.
  - **success:** Revisiting an already-decided choice page shows the choice already made and offers no alternate-choice control.
- **CAP-6**
  - **intent:** The story text explicitly references an earlier choice's consequence 2-3 times later in the same run.
  - **success:** Each echoed choice's callback text is distinguishable in-prose as a reference to the earlier decision, not merely implied by branching.
- **CAP-7**
  - **intent:** Each choice carries a small author-assigned +/- alignment value, summed silently during play as a reflective stat with no bearing on the run's ending.
  - **success:** No alignment value or running total is ever visible to the player during a run; the total influences no navigation or ending outcome — only the Memory screen's display (CAP-10).
- **CAP-8**
  - **intent:** At the end of a branch, the run resolves to whichever ending kind (home, stay, limbo, or hard-fail) is authored directly on the terminal node the player's path reaches; hard-fail terminal nodes are reached only via a designated gotcha choice.
  - **success:** Every possible branch terminates in exactly one of the four ending types, fixed by the authored terminal node — not computed from alignment score; hard-fail endings are reachable only via a designated gotcha choice's terminal node.
- **CAP-9**
  - **intent:** The system displays an ending screen using a single shared template across all four ending types, with outcome-specific text.
  - **success:** Home/stay/limbo/hard-fail endings render through the same screen component, differing only in text content.
- **CAP-10**
  - **intent:** After the ending screen, the system shows a memory screen listing the choices made during the run, what each one caused, and the alignment score/tier — for every ending type, including hard-fail.
  - **success:** Memory screen is shown for 100% of completed runs with no ending-type exception; from it, the player can return home or start a new run.
- **CAP-11**
  - **intent:** Every gesture-based interaction has a standard, VoiceOver-compatible tap alternative, and the story text area follows Apple HIG accessibility guidance.
  - **success:** No interaction in the app is reachable only via a custom gesture; the story text area passes VoiceOver navigation and responds to Dynamic Type sizing.
- **CAP-12**
  - **intent:** The app ships with one pre-generated illustration per distinct branch-reality flavor (~10-15 total), bundled in the app binary.
  - **success:** No illustration is fetched over the network at runtime.

## Constraints

- On-device only: no network calls, backend, or external integrations — a product-level scope/privacy constraint, not just an implementation choice. Support current major iOS release and the previous one (N-1).
- Ending kind (home/stay/limbo/hard-fail) is authored directly on each terminal node, not computed from alignment score. Content-authoring ratio: roughly 1-2 home-ending terminal nodes, 3-4 stay-ending terminal nodes, remaining non-hard-fail terminals as limbo; hard-fail terminals reached only via a designated gotcha choice.
- The story tree must always contain an ideal path leading home, even if it isn't obvious to the player while making choices.
- Safe-looking choices must not always guarantee the safe outcome (narrative pushback so players aren't trained to blindly pick "safest"); no spendable resource backs this in v1.

## Non-goals

- Not a business: no revenue goal. A possible $0.99 App Store price, if the app feels like a finished, real thing, is a marker, not a monetization strategy — pricing is conditional, not committed.
- Deferred to v1.1+: deviation meter and content-pool remix engine (v1's story tree stays authored and lean, not dynamically generated), Anchor Points system, Certainty resource, deviation-driven visual theming, undo/rewind credit and any IAP for it, and anonymized play-metadata telemetry (breaks the on-device-only constraint).
- Second-language translation is not a v1 commitment. iPad/Universal support is not designed for in v1 (iPhone-only, portrait, single-column reading surface).

## Success signal

App is submitted to and accepted on the App Store with the full CAP-1–CAP-12 set intact — that acceptance is the definition of "shipped." A submission that drops choice echo (CAP-6), alignment scoring (CAP-7), or the four-way ending taxonomy (CAP-8) does not count as success regardless of acceptance status.

## Assumptions

- Choices per decision point stay within a small, fixed gesture vocabulary rather than unlimited custom gestures — since resolved concretely: press-and-hold (~3s, cancellable) or quick-tap-then-1.5s-undo-window commits a choice, swipe or tap-zone turns a page, all with VoiceOver equivalents (`EXPERIENCE.md`/`DESIGN.md`).

## Open Questions

- Story scale (target branch count, choice-point count, total v1 playtime) is undetermined — a content-planning decision, not a spec-kernel one.
- App Store content rating / age disclosure for the dark-comedy hard-fail content is unresolved — needs settling before submission.
- Story compellingness (is it engaging enough) is only planned to be validated informally via self + friends playtesting — no formal validation method defined.
- Apple Developer Program enrollment, a blocking prerequisite for any TestFlight/App Store distribution, is not yet in place.
