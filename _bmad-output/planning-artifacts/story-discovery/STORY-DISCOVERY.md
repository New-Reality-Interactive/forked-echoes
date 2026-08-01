# Story Discovery — Forked Echoes Narrative Design

Living notes from an ongoing party-mode session (Sophia, Maya, Carson, Victor) designing the actual v1 story content. This is narrative/creative design only — no app code, no architecture decisions. Feeds Epic 4 (Story Content & Illustration Production) when it's ready to be authored into the real Content tree.

Maintained by the orchestrator across the session; updated after each round the room settles something. Not a transcript — a running record of what's decided and what's still open.

## Status

The AI-generated "boat/dock/shoreline" content currently in the app (`StoryTree.swift`) is a **throwaway placeholder** used only to prove out engine mechanics (Stories 2.1–2.5). It is not canon, not a starting point, and not meant to survive into Epic 4's real authoring pass.

## Core Premise (as of this session)

- The player starts the run **already inside a branch reality** — not at home, not mid-transition. Neither the character nor the reader is told this.
- Things are "just a little off" from the first page, but not legible as wrong until at least 2 choices in.
- Character and reader discover the truth **at the same moment** — no dramatic irony where the reader knows before the character does, and no lag where the character figures it out first and narrates it to a reader playing catch-up.

## Decisions Made

- **2026-08-01 — Branch-arrival interstitial timing (resolves Open Question 3):** for the opening branch, the full-bleed interstitial retimes to fire at the *realization* moment (the page after the reveal lands), not at branch entry — Option 2 from the room's three-way framing. Still needs a UX-spine pass (Sally/Winston) to formalize as a variant of `EXPERIENCE.md`'s existing branch-arrival-interstitial behavior, since the spine as written assumes entry-timing only.
- **2026-08-01 — Player-character identity (resolves Open Question 1, elicited via What-If Scenarios):** working identity is a night-shift rideshare driver, ~12 years in one city, who drives nights by choice (ownership, not necessity) and refuses GPS as a point of pride — competence-as-identity. Underlying want/wound: some past experience of being genuinely, frighteningly lost/unmoored; the driving competence is roughly a decade's answer to never feeling that again. This gives the branch reality's "off-ness" personal stakes beyond inconvenience — it threatens the specific thing she's spent 12 years making sure never happens again. Rejected during elicitation: hospice nurse (too close to the user's real spouse's profession — off the table entirely), empty-nest father (didn't land), recently-divorced father (thematically on-the-nose, alignment-score mapping "toward old life vs. new life" felt too literal; also close to Apple TV's *Dark Matter*).
- **2026-08-01 — Wrongness mechanism (partially resolves Open Question 2):** the opening branch's off-ness is geographic/social-micro-detail, not tonal or moody — a landmark one shade off, a regular who half-recognizes her wrong. Chosen specifically because it's legible to *this* character (her competence would normally catch it) but not to a generic tourist-observer, and because it's genuinely undetectable as "wrong" on a single read — it takes accumulating two data points to add up, satisfying the 2-choice discovery delay without narration winking at the reader.

## Open Questions

1. ~~Who is the player-character...~~ — **resolved above.** Still open beneath it: her name, and how much (if any) backstory on "the past unmoored experience" gets stated on-page vs. left implicit.
2. The *specific* wrongness details for the opening branch aren't authored yet — only the *mechanism* (geographic/social micro-detail) is decided. Needs: what the opening fare/destination is, which landmark carries the first unnoticed tell, what the regular-who-half-recognizes-her beat actually says.
3. ~~Branch-arrival interstitial timing~~ — **resolved above**, pending a formal UX-spine variant.
4. How literally does "at least 2 choices" bound the reveal — is choice #2's echo the reveal mechanism itself, or does the reveal land on a reading page between choices? *(Working answer from this session's Exquisite-Corpse-style build: the reveal lands on the page immediately after choice #2, not inside the choice itself — matches the interstitial retiming above. Not yet locked as a formal decision.)*

## Parking Lot (raised, not decided)

- Whether each branch reality gets its *own* flavor of wrongness (compounding variety) vs. one consistent axis of wrongness escalating in degree. (Victor vs. Carson, unresolved as of this entry.)

## World / Home Bible

### Player-character (working sketch — name TBD)

- **Occupation:** night-shift rideshare driver, ~12 years in the same city.
- **Why nights:** a choice, not a necessity — nights are when the city feels like hers: empty streets, no traffic, just her and a decade-plus of memorized turns.
- **Defining trait:** refuses GPS as a point of pride; knows every street cold. Competence is load-bearing — it's not a hobby-level quirk, it's identity.
- **Underlying want/wound:** some past experience of being genuinely, frighteningly lost/unmoored (specifics not yet authored). The driving competence reads as a ~12-year answer to never feeling that again — so a branch reality isn't mere inconvenience for her, it's the specific fear her whole adult life has been organized around avoiding.
- **Open:** name; how explicit the "unmoored" backstory gets on-page; whether she drives alone/with family/other relationships at home worth establishing before the fork.

## Branch Reality Catalog

Budget: ~10-15 distinct illustrated flavors total (art budget constraint from brainstorm intent). None specified yet.

## Session Log

- 2026-08-01: Session opened. Established the placeholder boat content is non-canon. New premise set: run opens inside an unannounced branch reality, off-ness surfaces gradually, character and reader discover together by choice 2. Flagged the branch-arrival-interstitial timing conflict for later resolution.
- 2026-08-01: Locked interstitial timing to Option 2 (retimed to the realization moment). Ran a What-If-Scenarios elicitation to find the player-character; landed on a night-shift rideshare driver with competence-as-identity, after rejecting a hospice-nurse concept (too close to the user's real spouse's profession) and a divorced-father concept (too on-the-nose against the alignment mechanic, echoes *Dark Matter*). Wrongness mechanism decided as geographic/social micro-detail rather than tonal unease.
