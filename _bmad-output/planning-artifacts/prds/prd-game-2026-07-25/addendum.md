# Addendum: Forked Echoes

Mechanism-level and technical-how detail that supports the PRD but doesn't belong in its narrative. For downstream UX spec / architecture / content-writing use.

## Core narrative design principle
There should always be an ideal path through the story that leads home — even if it isn't obvious to the player while they're making choices. This is the authoring north star for the story-tree writer, not a testable system behavior.

## Ending taxonomy: terminal-node authoring ratio (from original brainstorm)
- Home endings: author 1-2 distinct terminal nodes/paths as home endings
- Stay endings: author 3-4 distinct terminal nodes/paths as stay endings
- Limbo endings: all other non-hard-fail terminal nodes/paths
- Hard-fail: not part of this ratio — reached only via a designated gotcha choice's own terminal node, bypassing the taxonomy above entirely

Each terminal node in the story tree is authored with its ending kind fixed directly at write-time (home/stay/limbo/hard-fail) — FR-8 resolves a run to whichever terminal node the player's path lands on, not by computing a score against a threshold. The player's accumulated alignment score (FR-7) has no bearing on which terminal node a path reaches; it is purely a Memory-screen display stat.

**Correction (2026-07-26):** this section previously described these figures as alignment-score *thresholds* (e.g. "Home = a summed score of 1-2"), including a boundary-overlap fix at score 2. That was a misreading of the original brainstorm intent — the "1-2" and "3-4" always meant a *count of distinct terminal nodes* to author for each ending type, not score ranges. There is no threshold, so there is no overlap to check; this correction removes both the misreading and the fix that was papering over it. Revisit this ratio once the v1 story tree is actually written — it's a rough balance guideline, not a hard constraint.

## "Safe choice unreliable" mechanic (token v1 version)
Safe-looking choices don't always guarantee the safe outcome — a small, non-mechanical narrative pushback so the game doesn't train players to blindly pick the option that reads as safest. No spendable resource system backs this in v1 (that's the deferred "certainty" resource, v1.1+). This is a writing-level design note for whoever authors the story tree, not a distinct FR.

## Generative AI art pipeline (dev-time, not runtime)
- ~10-15 illustrations total, one per distinct branch-reality flavor.
- Produced with generative AI image tools at development time.
- Pre-generated and bundled into the app binary — no runtime generation or network fetch (see FR-12, and the on-device-only platform constraint).

## Gesture vocabulary options (for UX spec, Open Question 2)
Not decided in the PRD. Candidate directions to evaluate at UX-spec stage:
- Small fixed set (e.g., tap-left-half / tap-right-half / long-press) reused consistently across all choice pages.
- Directional swipes beyond left/right (up/down) reserved for choices, since left/right are already claimed by page navigation.
Whatever is chosen must satisfy FR-11 (every gesture has a standard accessible tap/VoiceOver equivalent) — this constrains the vocabulary to gestures that map cleanly to an accessible alternative.
