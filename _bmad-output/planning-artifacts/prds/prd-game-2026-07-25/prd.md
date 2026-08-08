---
title: Forked Echoes
created: 2026-07-25
updated: 2026-07-25
status: final
---

# PRD: Forked Echoes

## 0. Document Purpose

This PRD scopes v1 of a native iOS Choose-Your-Own-Adventure app, for a solo developer building it as a first learn-to-ship project. It builds on the existing brainstorm output (`brainstorm-intent.md`, `pitch-one-pager.md`) and a walked-through user session captured during this PRD's discovery; those sources are not duplicated here. Mechanism-level detail (scoring thresholds, gesture-mapping options, art pipeline) that doesn't belong in the narrative lives in `addendum.md`.

## 1. Vision

You make one choice too many, and suddenly you're not home anymore — you're in a branch reality that's almost right, except your dog's a cat, your job doesn't exist, and everyone insists you've always lived here. This is a CYOA game about finding your way back, one decision at a time, where reality gets stranger the further you stray.

The one mechanic the whole game is built around: choices echo. Pick something early, and the story explicitly calls back to it 2-3 times later — proof the choice *mattered*, not just that it branched. Every run ends in one of four ways (home, stay, limbo, or an abrupt comedic hard-fail), and a closing memory screen replays what you chose and what it caused, turning the run into a story about *you*.

This is a first iOS app, full stop — not a business. The goal is to walk the entire path from idea to a real App Store submission, on-device only, no backend, no network calls.

## 2. Target User

### 2.1 Jobs To Be Done
- As the builder: learn the full iOS development and App Store submission pipeline hands-on, by shipping something real.
- As a player (self + friends): feel the payoff of an early choice resurfacing later — proof it mattered.
- As a player: discover which of the four endings (home / stay / limbo / hard-fail) a given run lands on, and want to run it again to see another.

### 2.2 Key User Journeys

- **UJ-1. Mary's first full playthrough.**
  - **Persona + context:** Mary, a first-time player, opens the app cold.
  - **Entry state:** Fresh install, home screen.
  - **Path:**
  1. Home screen: app title, story title, two gesture-selectable entries ("Start Story" / "Start Tutorial").
  2. She opens the tutorial (explains mechanics; options to go back home or start the story), then starts the story.
  3. Story screen: large, HIG-accessible text area. Swipe left advances a page, right returns to the previous one.
  4. On a choice page, forward navigation is blocked until she picks — each choice bound to its own distinct touch gesture (with a standard accessible tap equivalent). Once made, the choice is locked; she can page back to look at it but can't change it.
  5. Partway through, the story text explicitly calls back to an earlier choice ("You remember when you...") — she recognizes the echo directly in the prose, 2-3 times across the run.
  - **Climax:** She reaches the end of her branch — an ending screen (home/stay/limbo) matching her path — followed by a separate memory screen listing her choices, what each caused, and her alignment score/tier.
  - **Resolution:** From the memory screen, she can return home or start a new run.

- **UJ-2. Hard-fail run.**
  - **Persona + context:** Same player, later run, same interaction model as UJ-1.
  - **Path:** At a choice point, she picks an obviously-bad, dark-comedy gotcha option.
  - **Climax:** The story jumps immediately to the ending screen — the same shared template as home/stay/limbo, just different text/tone — followed by the same memory screen (choices, causes, score/tier) as any other run. The recap is shown even though the run ended abruptly; it's part of the comedic payoff, not just a completion reward.
  - **Resolution:** Return home or start a new run.

## 3. Glossary

- **Branch reality** — An alternate version of the player's home reality the player is stranded in after a choice; has its own distinct illustration.
- **Choice echo** — The mechanic where an earlier choice's consequence is explicitly referenced in the story text 2-3 times later in the same run.
- **Alignment score** — A running numeric tally, invisible during play, built from a small +/- value tagged to each choice at write-time. Shown only on the Memory screen as a reflective stat — it does not determine the run's ending.
- **Ending taxonomy** — The four possible run outcomes: **home** (returned to the original reality), **stay** (deliberately remained in a branch), **limbo** (adrift, belonging nowhere), and **hard-fail** (run ended abruptly by a comedic gotcha choice). Which outcome a run reaches is determined directly by the specific terminal node the player's path lands on — each terminal node is authored with its ending kind fixed at write-time, not computed from alignment score.
- **Memory screen** — The screen shown after the ending screen, listing the choices made in the run, what each one caused, and the alignment score/tier.
- **Gesture** — A distinct touch input (not a generic tap) bound to a specific choice or navigation action; every gesture has a standard, accessible tap/VoiceOver-compatible equivalent (see FR-11).

## 4. Features

### 4.1 Home & Onboarding
**Description:** Entry surface and optional tutorial. Realizes UJ-1.

#### FR-1: Home screen entry
Player can choose "Start Story" or "Start Tutorial" from the home screen, each bound to a distinct gesture with an accessible tap equivalent.

**Consequences (testable):**
- Home screen displays app title and story title.
- Both entry actions are reachable via VoiceOver/standard tap, not gesture-only.

#### FR-2: Tutorial screen
Player can view a tutorial screen explaining the game's mechanics, then return home or start the story.

**Consequences (testable):**
- Tutorial is optional and reachable only from the home screen.
- Both exit actions (back home, start story) are gesture-selectable with accessible tap equivalents.

### 4.2 Story Reader & Choice Navigation
**Description:** Core reading and decision interaction. Realizes UJ-1, UJ-2.

#### FR-3: Page navigation
Player can advance a page (swipe left) or return to the previous page (swipe right) within a story branch, with an accessible non-gesture equivalent.

**Consequences (testable):**
- Forward navigation is blocked on a page containing an unresolved choice (see FR-4).
- Backward navigation is always available once at least one page has been read.

#### FR-4: Choice presentation and selection
Player can select one of the presented choices on a choice page, each bound to a distinct gesture with a standard accessible tap/VoiceOver equivalent. [ASSUMPTION: choices per decision point stay within a small fixed vocabulary of gestures — exact mapping is a UX-spec decision, see Open Question 2.]

**Consequences (testable):**
- A choice page presents at least two choices, each independently selectable.
- Making a choice unblocks forward navigation past that page.

#### FR-5: Choice permanence
Once a choice is made, the player cannot change it by re-navigating to that page.

**Consequences (testable):**
- Revisiting an already-decided choice page (via back-navigation) displays the choice already made and offers no alternate-choice control.

### 4.3 Choice Echo
**Description:** The game's core differentiator. Realizes UJ-1.

#### FR-6: Narrative callback
The story text explicitly references an earlier choice's consequence 2-3 times later in the same run.

**Consequences (testable):**
- Each echoed choice's callback text is distinguishable in-prose as a reference to the earlier decision (not merely implied by branching).

### 4.4 Alignment Scoring & Ending Taxonomy
**Description:** Determines and presents run outcome. Realizes UJ-1, UJ-2.

#### FR-7: Silent alignment scoring
Each choice carries a small +/- alignment value (author-assigned at write-time); the system sums this silently during play without surfacing it. This running total is a reflective statistic only — it has no bearing on which ending the run reaches (see FR-8).

**Consequences (testable):**
- No alignment value or running total is visible to the player during a run.
- The accumulated total influences no navigation, resolution, or ending outcome — only the Memory screen's display (FR-10).

#### FR-8: Ending resolution
At the end of a branch, the run resolves to whichever ending kind (home, stay, limbo, or hard-fail) is authored directly on the terminal node the player's path reaches. Hard-fail terminal nodes are reached only via a designated gotcha choice.

**Consequences (testable):**
- Every possible branch terminates in exactly one of the four ending types, fixed by which terminal node is authored there — not computed from alignment score.
- Hard-fail endings are reachable only via a designated gotcha choice's terminal node, never any other path.

**Notes:**
- Hard-fail choices must read as obviously bad, absurd dark-comedy gotchas — not a fair, telegraphed warning the player could reasonably see coming. This is authoring guidance for the story-tree writer, not a testable system behavior.
- Content-authoring guidance: across the v1 story tree, author roughly 1-2 distinct terminal nodes/paths as **home** endings and 3-4 as **stay** endings, with the remaining non-hard-fail terminals as **limbo** — a balance ratio for the tree, not a runtime calculation (see `addendum.md`).

#### FR-9: Ending screen
The system displays an ending screen using a single shared template across all four ending types, with outcome-specific text.

**Consequences (testable):**
- Home/stay/limbo/hard-fail endings render through the same screen component, differing only in text content.

### 4.5 Memory / Recap Screen
**Description:** Closing recap for every run, regardless of ending type. Realizes UJ-1, UJ-2.

#### FR-10: End-of-run recap
After the ending screen, the system shows a memory screen listing the choices made during the run, what each one caused, and the alignment score/tier — for every ending type, including hard-fail.

**Consequences (testable):**
- Memory screen is shown for 100% of completed runs, with no ending-type exception.
- From the memory screen, player can return home or start a new run (each gesture-selectable with accessible tap equivalent).

### 4.6 Cross-Cutting NFRs

#### FR-11: Accessible interaction parity
Every gesture-based interaction (navigation and choice selection alike) has a standard tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, sufficient contrast). **Scope decision, 2026-08-07:** VoiceOver is not officially tested or supported for v1 — see project-context.md's Process Agreements for full rationale. Accessibility labels, hints, and VoiceOver-specific affordances (rotor custom actions, focus order) already implemented remain in the app as best-effort scaffolding but are not an officially tested v1 requirement.

**Consequences (testable):**
- No interaction in the app is reachable *only* via a custom gesture.
- Story text area responds to Dynamic Type sizing.

- **Platform:** Native iOS, on-device only — no network calls, no backend, no external integrations.
- **Compatibility:** Support current major iOS release and the previous one (N-1).
- **Orientation:** Supports both portrait and landscape on iPhone (see Epic 5: Landscape Support).

### 4.7 Content & Art
**Description:** Visual assets bundled at build time. Realizes UJ-1.

#### FR-12: Bundled branch-reality illustrations
The app ships with one pre-generated illustration per distinct branch-reality flavor (~10-15 total), bundled in the app binary.

**Consequences (testable):**
- No illustration is fetched over the network at runtime.

## 5. Non-Goals (Explicit)

- Not a business — no revenue goal; *if* it seems worth putting in front of strangers, a $0.99 App Store price is a "this is a finished, real thing" marker, not a monetization strategy. Pricing is conditional on that judgment call, not committed.

## 6. MVP Scope

### 6.1 In Scope
All FRs in §4 (FR-1–FR-12) are in scope for v1 — no partial carve-outs.

### 6.2 Out of Scope for MVP
Deferred to a v1.1+ update:
- Deviation meter (0-100) and content-pool remix engine (mundane vs. surreal variants) — the story tree stays authored and lean in v1, not dynamically generated
- Anchor Points system (home-reality details preserved/corrupted by choices)
- Certainty resource (earned, spendable to force a safe outcome)
- Deviation-driven visual theming
- Undo/rewind credit, and any IAP to purchase it
- Anonymized play-metadata telemetry — explicitly deferred because it breaks the on-device-only constraint; paired with a later, deliberate revisit once networking/backend/privacy-disclosure skills are in scope

## 7. Success Metrics

**Primary**
- **SM-1**: App successfully submitted to and accepted on the App Store. Validates the full FR set — this is the definition of "shipped."

**Counter-metrics (do not optimize)**
- **SM-C1**: Shipping speed should not come at the cost of cutting the core differentiator — a submitted app missing choice echo (FR-6), alignment scoring (FR-7), or the four-way ending taxonomy (FR-8) does not count as success, regardless of submission status.

## 8. Open Questions

1. **Story scale** — target branch count, choice-point count, and total playtime for v1 are undetermined; to be settled during content planning/writing, not locked here.
2. **Gesture vocabulary** — the exact set of distinct touch gestures mapped to choices (especially when a choice page has more than two options) is deferred to UX spec.
3. **App Store content rating** — the dark-comedy hard-fail content needs an appropriate age rating / content disclosure; to be resolved before submission.
4. **Story compellingness validation** — the central design risk (is the story engaging enough) is only planned to be validated informally via self + friends playtesting; no formal method defined yet.
5. **Apple Developer Program enrollment** — required before App Store submission; not yet in place.

## 9. Assumptions Index

- From §4.2 FR-4 — assumed choices per decision point stay within a small, fixed gesture vocabulary rather than unlimited custom gestures; exact mapping deferred to Open Question 2.
