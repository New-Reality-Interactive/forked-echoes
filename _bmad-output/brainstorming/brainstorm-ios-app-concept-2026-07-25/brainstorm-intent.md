# Brainstorm Intent: iOS CYOA App

## Concept
An on-device iOS choose-your-own-adventure game where the player is stranded in a branching alternate reality and must find their way home, with choices that visibly echo later in the story.

## Core Premise / Hook
A many-worlds branching narrative: the player's choices fork them into alternate "branch realities." An earlier choice's consequence resurfaces 2-3 times later in the story (choice echo), and an end-of-run "memory" screen lists the choices made, what they actually caused, and a score/tier reflecting how closely the player stayed on the "ideal" (home-bound) path. Design principle: there should always be an ideal path through the story, even if it isn't obvious to the player.

## Platform & Constraints
- Platform: iOS (native)
- Fully on-device: no network calls, no external integrations, no backend
- Developer context: first-time iOS developer; goal is to learn to build and ship an iOS app through the full App Store submission process — not revenue-motivated
- No Apple Developer Program license yet (needed before submission)
- Planned price: $0.99, if the concept proves worthy

## v1 (Must-Have) Scope
- Branching CYOA narrative — lean, more linear structure (not the full procedural remix engine)
- Choice echo: an earlier choice's consequence resurfaces 2-3 times across later scenes
- Alignment scoring: each choice tagged with a small +/- alignment value at write-time, summed silently during play, surfaced only at the end
- End-of-run "memory" screen: lists choices made, what they caused, and the alignment score/tier
- Ending taxonomy wired off alignment score/tier: home endings (1-2), stay endings (2-4, player deliberately remains in the branch), limbo endings (everything else)
- Comedic hard-fail choices scattered through the tree: obviously-bad choices end the run immediately; tone is absurd/dark-comedy gotcha, not fair-and-telegraphed
- "Safe choice unreliable" pushback, token version: safe-looking choices don't always guarantee the safe outcome; no spendable resource system in v1
- Custom art: one unique illustration per distinct branch-reality flavor (~10-15 total), produced with generative AI image tools at dev-time, pre-generated and bundled in the app (not fetched at runtime)

## Deferred to v1.1+ (Won't-This-Time)
- Deviation meter (0-100, flavor-text feedback) and content-pool remix engine (mundane vs. surreal scene/choice variants) — bigger implementation risk; lean MVP ships to submission faster
- Anchor Points system (explicit home-reality details preserved/corrupted by choices) — tied to the deferred deviation meter/remix engine
- Certainty resource (earned, spendable to force a safe outcome) — same reason
- Deviation-driven visual theming (accent color/theme shift from calm to saturated/glitchy) — depends on the deferred deviation meter
- Undo/rewind credit (earned via alignment points; rewind to the last choice, one use per branch reality) — explicit v1 Won't-this-time; polish, not core
- IAP addon to purchase rewind credits — explicit v1 Won't-this-time; project is not revenue-motivated
- Anonymized play-metadata telemetry to a self-maintained endpoint — deliberately breaks the on-device-only constraint; planned as a second, later revisit of that constraint, paired with learning networking/backend/App Store privacy-disclosure skills

## Open Questions / Risks for PRD Stage
- Core risk (user's stated main concern): whether the story is compelling enough to keep players engaged — this is the central design risk the v1 Must-have set (choice echo, alignment score, ending taxonomy) is meant to address
- Story compellingness is only planned to be validated informally (self + friends playtesting) before any v1.1 telemetry is added — no formal validation method defined yet
