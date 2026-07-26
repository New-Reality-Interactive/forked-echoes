---
title: Adversarial Review — Many-Worlds CYOA iOS App v1 Architecture Spine
type: review
review-kind: adversarial
target: architecture-game-2026-07-25/ARCHITECTURE-SPINE.md
created: 2026-07-25
---

# Adversarial Review: ARCHITECTURE-SPINE.md

## Verdict

The spine is well-formed as a *layering* contract (Content → Engine → Presentation is airtight, and AD-1/AD-2/AD-6 are genuinely load-bearing) but it is **not yet sufficient as a build substrate** for independent contributors: the intent surface (AD-3), the persistence trigger (AD-4), and the phase-transition machine (AD-5 + the state diagram) each leave at least one decision point where two implementations can each satisfy the written rule to the letter while producing materially different, non-interoperable behavior — differences that would surface as bugs only when two pieces of work (or two points in time on a solo timeline) meet. Eight concrete divergent pairs are documented below, three of them severe enough (data-loss / resume-correctness / silent echo-frequency drift) to fix before any Engine code is written. None require re-architecting; each is closable with one or two added sentences to an existing AD or one new AD.

---

## Finding 1 — [Critical] Choice-commit timing vs. the undo window is unresolved, and it is a data-integrity hole

**Spine text:** AD-3: "Views hold only local, transient, non-persisted UI state (e.g. choice-card charge/undo-window animation progress) via plain `@State`." AD-4: engine "writes [RunSnapshot] on state mutation." EXPERIENCE.md: a quick tap commits *instantly* then holds a 1.5s undo window before finalizing; paging forward also finalizes early.

**Pair A — engine commits eagerly:** The View calls `engine.selectChoice(_:)` the instant the tap/hold completes. The choice is immediately in `choiceHistory`, forward nav unblocks, and per AD-4 a RunSnapshot write fires right then — during the still-open 1.5s undo window. There is no intent method in AD-3's enumerated five (`selectChoice`, `advancePage`, `goBack`, `exitToHome`, `restartRun`) for "undo the just-made choice," so this builder either adds an unlisted sixth intent or overloads `goBack()` to also mean "un-commit a pending selection" — a second, silent meaning for a method FR-5 defines as "navigate to view an already-locked choice."

**Pair B — engine commits only at finalization:** The View keeps the pending choice id + a `Task`/timer entirely in local `@State` (matches AD-3's explicit example of permitted transient state) and calls `engine.selectChoice(_:)` only when the undo window elapses or `advancePage()` is invoked early. The engine never observes a "pending" choice at all; state only ever mutates once, atomically finalized.

**Divergence:** Both readings are licensed by AD-3's literal text. They produce opposite real behavior at the exact moment a player backgrounds/kills the app inside the 1.5s undo window:
- Pair A: the tentative choice is already persisted. A force-quit during the undo window **permanently locks in a choice the player was still free to cancel** — the undo window becomes cosmetic once the OS reclaims the app.
- Pair B: the tentative choice lives only in un-persisted `@State`. A force-quit during the same window **loses the selection entirely** — on resume the player is dropped back on an *unanswered* choice page, silently contradicting FR-5's "once made, locked" guarantee (it was never "made" from the engine's point of view).

Neither is obviously wrong per the spine as written; they are simply incompatible engine-mutation semantics that a second contributor (or the same contributor eight weeks later) could pick independently.

**Fix:** Add one clause to AD-3: *"`selectChoice(_:)` is the sole state-mutating call for a choice; it fires exactly once, at the moment the choice is irrevocably finalized (charge-complete, undo-window-elapsed, or early page-advance) — never at gesture-start or tap-down. The undo window itself has no corresponding engine call; it is resolved entirely in View-local `@State` before `selectChoice(_:)` is ever invoked."* This pins Pair B as canonical and closes the "sixth intent" temptation.

---

## Finding 2 — [Critical] `ChoiceRecord`'s internal shape is named but never defined

**Spine text:** Consistency Conventions: "`RunSnapshot` is the only persisted data shape: `currentNodeId`, `choiceHistory: [ChoiceRecord]`, `alignmentScore: Int`, `tutorialSeen: Bool`." Nothing else in the document says what fields `ChoiceRecord` has.

**Pair A:** `ChoiceRecord` stores a stable `choiceId` (Swift enum case identity, per the Naming convention) plus the alignment delta applied, and the Memory screen (FR-10, "what each [choice] caused") resolves the display text *live* at render time by walking the Content tree + String Catalog for that id.

**Pair B:** `ChoiceRecord` stores the *resolved* prose — the already-localized "what this caused" string, frozen at the moment the choice was made — directly in the JSON blob, so Memory just displays stored strings with no Content-tree lookup at all.

**Divergence:** Both satisfy AD-4's literal wording ("`choiceHistory: [ChoiceRecord]`" — shape unconstrained). They diverge concretely the moment a run spans an app update (a run is backgrounded, an App Store update ships with revised prose or a String Catalog key edit, the player resumes days later and reaches Memory): Pair A's recap now shows *updated* text for choices made under the old copy (a live join against possibly-changed content); Pair B's recap shows exactly what was authored at play-time, frozen forever, even if that key is later renamed or edited. These are not cosmetic — one is "recap reflects current build," the other is "recap is an immutable receipt" — and a Memory-screen implementation built against one assumption will render garbage (or crash on a since-removed key, under Pair A with a renamed/removed String Catalog entry) if the persisted blob was actually written under the other.

There is a second, independent axis of the same gap: does `currentNodeId` (also unspecified) encode as the Content enum case's raw String name, or as a flattened integer index into node-visitation order? Same incompatibility risk if the Content tree is ever reordered/refactored between two points where a snapshot is written vs. read.

**Fix:** Add a new AD (or extend AD-4) that pins `ChoiceRecord`'s fields explicitly, e.g.: *"`ChoiceRecord` = `{ choiceId: String (stable enum-case rawValue), consequenceKey: String (String Catalog key, resolved live at Memory render time, never frozen text) }`. `currentNodeId` is likewise the node case's stable `rawValue`, never a positional index."* Whichever direction is chosen, the point is that the spine must choose — right now it doesn't.

---

## Finding 3 — [High] "Writes on state mutation" doesn't say synchronous-immediate vs. debounced/coalesced

**Spine text:** AD-4: "Engine writes it on state mutation and on scene-phase transition to background/inactive."

**Pair A:** Every intent-method call ends with a synchronous, immediate `UserDefaults.set` — one write per `selectChoice`/`advancePage`/`goBack` call, always fully current.

**Pair B:** To avoid thrashing `UserDefaults` on rapid swiping, mutations are coalesced/debounced (e.g., a 300ms trailing-edge write), with the scene-phase-transition write remaining unconditional/immediate (that half of AD-4 is unambiguous). This is still literally "writes it on state mutation" — just not synchronously.

**Divergence:** iOS can terminate a backgrounded/suspended app without ever delivering a further scene-phase callback (memory pressure jetsam, or a debug/force-quit that races the debounce timer). Under Pair B, several pages of forward progress can be lost on relaunch even though the app "had time" to persist them under normal conditions — the exact "Resume Story" correctness EXPERIENCE.md's `[ASSUMPTION]` ("auto-resumes to its last page on next launch") depends on. Under Pair A this can't happen. Both builders can point at the same AD-4 sentence as justification.

**Fix:** Tighten AD-4's rule to: *"...writes it synchronously on every intent-method return (no batching, debouncing, or async dispatch) and additionally on scene-phase transition to background/inactive (belt-and-suspenders, not the primary trigger)."*

---

## Finding 4 — [High] Echo firing: structurally guaranteed vs. runtime history-check — not pinned, and the Capability Map hints two different ownership models

**Spine text:** AD-1: "echo wiring" is part of the compiled Content tree. AD-7 tests "echo-callback reachability as authored in the tree." Capability Map: `FR-6 | Content (echo wiring) | AD-1, AD-7` — **no Engine cell at all.**

**Pair A (purely structural):** Each branch that follows an earlier choice is its own subtree; 2-3 nodes down that specific subtree simply have echo prose hardcoded (a node-level `isEcho: Bool` flag or a distinguishing case), because the *only* way to reach that node is to have made that choice. Reachability is guaranteed by tree shape; nothing at runtime ever consults `choiceHistory` to decide whether to show an echo. The frame powers up whenever the current node is flagged, full stop.

**Pair B (runtime-conditional):** To allow the tree to reconverge (two different early branches funnel into a shared later node — legitimate content-authoring compression, and nothing in AD-1 forbids Swift enum cases sharing a child value), the shared node carries multiple possible echo variants keyed by which earlier choice was made, and the *engine* checks `choiceHistory` at render time to pick the matching variant (or show no echo if no match).

**Divergence:** Both compile under AD-1 ("no dangling echo/choice reference" is satisfied either way — Pair B's variants are all authored, none dangling). Both can nominally pass an AD-7 "reachability" test (Pair A trivially; Pair B by proving at least one path reaches it). But they produce different real behavior: under Pair A an echo *always* fires exactly when its node is hit (matching FR-6's "2-3 times… explicitly references"); under Pair B, whether the *same* content node echoes at all is conditional on which path you arrived by — meaning two runs that visit the identical node can render with or without the echo block and the associated ember-glow-exactly-once-per-echo rule from DESIGN.md, purely as a function of an unrelated earlier choice. This is a genuine "how often does the mechanic that the whole game is built around actually fire" divergence — SM-C1 in the PRD names FR-6 as the one thing that must never be silently cut or weakened.

**Fix:** Either (a) forbid tree reconvergence explicitly in AD-1 — *"Content is a tree, not a DAG: no two choice paths may resolve to a shared node value; this makes echo firing 100% structural and removes any need for engine-side history checks"* — or (b) if reconvergence is wanted for authoring economy, add an explicit AD-n stating the engine-side echo-resolution algorithm (what happens on no-match, whether a variant can be "consumed" so a re-visited node doesn't re-fire, etc.). Right now the Capability Map's Content-only cell quietly implies (a) without saying so, which is exactly the kind of implicit signal a second contributor would miss.

---

## Finding 5 — [High] The five enumerated intents don't cover every phase transition in the state diagram — builders will invent different sixth-and-seventh methods

**Spine text:** AD-3 enumerates exactly `selectChoice(_:)`, `advancePage()`, `goBack()`, `exitToHome()`, `restartRun()`. The state diagram has transitions with no obvious owner among these five: `Interstitial --> Reading: Continue tapped`, `Ending --> Memory: tap anywhere`, `Memory --> Home: Return Home`, `Memory --> Reading: Start New Run`.

**Pair A:** Reuses existing intents wherever plausible — Interstitial's Continue and Ending's tap-anywhere both call `advancePage()` (treated as the generic "move the phase machine forward" verb); Memory's "Start New Run" calls `restartRun()` (clean fit); Memory's "Return Home" calls `exitToHome()` (reusing the run-options-sheet intent).

**Pair B:** Treats these as semantically distinct from mid-story paging and adds new intents not in AD-3's list — e.g. `continueFromInterstitial()`, `acknowledgeEnding()` — reasoning that overloading `advancePage()` to also dismiss a full-bleed interstitial or leave a terminal Ending screen conflates "turn a story page" with "leave a phase entirely," which AD-5 itself treats as a distinct concept (the phase enum).

**Divergence:** This isn't cosmetic. Under Pair A, `advancePage()`'s guard logic (AD-5: "blocks forward on an unresolved choice") now has to special-case three unrelated phases inside one method, and any RunSnapshot-write hook wired specifically to the five named intents (per Finding 3's fix) automatically covers Interstitial/Ending transitions for free. Under Pair B, a snapshot-write hook wired to "the five AD-3 intents" **silently excludes** the new methods unless a contributor remembers to wire them too — an easy miss precisely because the new methods aren't in the spine's canonical list.

There is a second, sharper problem hiding in Pair A specifically: Memory's "Return Home" reusing `exitToHome()` inherits that method's documented semantics from the run-options sheet — *"non-destructive — preserves the in-progress run, same as backgrounding"* (EXPERIENCE.md). But by the time the player is on Memory, the run is **already over** (terminal node reached). "Preserves the in-progress run" now persists a *finished* run's snapshot indefinitely, so Home's "Resume Story" relabel (which fires "whenever a run is in progress" per EXPERIENCE.md's state table) would keep showing "Resume Story" for a run that has already ended — pointing back at a terminal Ending node forever. Nothing in AD-4 says a completed run's snapshot is ever cleared; the *only* documented clearing trigger is `restartRun()`.

**Fix:** Extend AD-3 (or add AD-8) with two things: (1) an explicit statement of whether the intent list is closed or open, and if open, the naming/wiring convention new intents must follow so persistence and phase-guard logic aren't silently missed; and (2) a lifecycle rule for RunSnapshot on run completion, e.g.: *"Reaching Ending phase is itself a terminal state mutation; RunSnapshot is cleared (same as `restartRun()`) the moment phase transitions to `.ending`, not deferred to whatever the player does on Memory. Memory's 'Return Home' and Home's post-Memory state therefore never need to distinguish a finished run from a fresh install."*

---

## Finding 6 — [Medium] AD-5 only states the choice-block guard; the interstitial's bidirectional block lives only in EXPERIENCE.md

**Spine text:** AD-5's rule: "the engine decides whether the transition is allowed (blocks forward on an unresolved choice; shows a revisited choice locked, per FR-5)." EXPERIENCE.md (not the spine): "blocking page-turn (swipe and tap-zone alike) until the Continue affordance is tapped — symmetric to Echo active as a distinct, transient, blocking beat" for the interstitial.

**Pair A:** Implements the interstitial phase to block *both* `advancePage()` and `goBack()` (matching EXPERIENCE.md, which a diligent builder cross-references).

**Pair B:** Implements strictly from AD-5's own text, which only names one blocking condition ("blocks forward on an unresolved choice"). Since the interstitial isn't a choice page, this builder sees no stated reason to block `goBack()` during it, and allows the swipe-right/tap-left-zone to dismiss the interstitial backward into the previous Reading page — never fully hiding it, just letting the player "back out of" the arrival beat before tapping Continue.

**Divergence:** The spine is meant to be the self-sufficient build substrate (its own framing: "purpose: build-substrate"); a builder who works only from it — which is the entire point of having a spine — has no textual basis to rule out Pair B, even though it contradicts the UX spec's explicit "symmetric... blocking beat" language. This is exactly the kind of cross-document drift a spine exists to prevent.

**Fix:** Fold the UX behavior into AD-5 directly: *"...the engine decides whether the transition is allowed: blocks forward on an unresolved choice page; blocks both forward and back unconditionally while phase == .interstitial or .ending, releasing only via their own dismiss affordance; shows a revisited choice locked, per FR-5."*

---

## Finding 7 — [Medium] RunSnapshot has no `phase` field — resume behavior mid-interstitial (or mid-undo-window) is undefined

**Spine text:** Consistency Conventions lists exactly four RunSnapshot fields — `currentNodeId`, `choiceHistory`, `alignmentScore`, `tutorialSeen` — with no phase. AD-5 makes phase an engine-owned enum (reading / interstitial / ending / memory) but never says whether it's part of the persisted snapshot.

**Pair A:** On decode, the engine always resumes into `.reading` at `currentNodeId`, regardless of what phase the app was actually in when it last wrote the snapshot. If the app was showing the interstitial (or, per Finding 6, mid-undo-window) at background time, the interstitial reveal is silently skipped on relaunch — the player lands straight on the new branch's first page having never seen the full-bleed arrival illustration.

**Pair B:** On decode, the engine re-derives whether an interstitial should be shown by replaying `choiceHistory` against the Content tree to detect "does `currentNodeId` represent a fresh branch-reality entry relative to the prior node on this path" — and re-shows the interstitial on resume if so.

**Divergence:** Identical RunSnapshot bytes on disk produce different resumed experiences depending on which of these two (unstated) recovery strategies was built — and this is squarely the kind of cross-unit incompatibility the review was asked to hunt: nothing in AD-4 or AD-5 tells a second contributor which one is correct, and the four-field snapshot shape (per Finding 2's silence) doesn't even record enough to make Pair B's replay-based recovery reliable without also pinning down how "fresh branch entry" is computed from `currentNodeId` alone.

**Fix:** Either add `phase: RunPhase` as a fifth Codable field to RunSnapshot (simplest, and consistent with AD-4's "state mutation" trigger since phase changes are themselves state) — or explicitly document the replay algorithm if the four-field shape is to remain fixed. Silence should not be the answer either way.

---

## Finding 8 — [Medium] Hard-fail transition timing: inside `selectChoice(_:)` vs. discovered on the next `advancePage()`

**Spine text:** AD-6: "Hard-fail bypasses this function [`scoreToEnding`] entirely via a direct engine transition triggered by a designated gotcha choice — never score-driven." UJ-2 in the PRD: "the story jumps immediately to the ending screen." EXPERIENCE.md: "Hard-fail reaches this screen directly from a gotcha choice, bypassing normal page-turn flow."

**Pair A:** `selectChoice(_:)`, upon detecting the choice is the designated gotcha case, sets `phase = .ending` itself, as a side effect of the same call that records the choice — no forward swipe/tap needed at all; the ending screen appears the instant the hold-charge/tap-commit finalizes.

**Pair B:** Reads AD-6's "bypass" as scoped only to skipping `scoreToEnding`'s score-based resolution, not to skipping the normal page-turn flow. `selectChoice(_:)` records the gotcha choice exactly like any other choice (unblocking forward nav as usual); the hard-fail terminus is simply authored as a regular terminal node in the Content tree, and `phase = .ending` is only set when the player subsequently calls `advancePage()` and lands on it — identical mechanism to every other ending, just reached via a one-choice-long branch.

**Divergence:** Both are consistent with AD-6's literal text (which never mentions *when*, only that the score function is bypassed). They are not consistent with each other: Pair A requires zero additional player action after picking the gotcha option; Pair B requires one more forward gesture. This is a directly player-visible interaction difference (and the PRD's "jumps immediately" language leans Pair A, but that phrasing lives in the PRD, not the spine a builder is meant to implement from).

**Fix:** Extend AD-6: *"The gotcha choice's bypass transition fires synchronously inside `selectChoice(_:)` — phase moves to `.ending` in the same call that records the choice, with no intervening `advancePage()` required — mirroring UJ-2's 'jumps immediately.' This is the one case where `selectChoice(_:)` also performs a phase transition that AD-5 would otherwise gate behind `advancePage()`."*

---

## Discarded (implementation detail, no cross-unit consequence)

- Whether the rendering projection is one enum-with-associated-values or four separate computed properties on the engine — an internal engine API shape with no persisted or cross-contributor-visible consequence, *provided* it never embeds a `Content`-typed value by reference (which would be a real AD-3 violation, not just a style choice — worth a one-line lint/review note but not a spine-level finding).
- Exact gesture vocabulary beyond swipe/hold — explicitly and adequately deferred to DESIGN.md/EXPERIENCE.md already; no architecture-level ambiguity remains.
- App Store content rating, Apple Developer enrollment, story scale — correctly deferred as non-architectural; no two builders would diverge on these at the code level.

---

## Summary Table

| # | Severity | Locus | One-line divergence |
|---|---|---|---|
| 1 | Critical | AD-3 | `selectChoice` commit timing vs. undo window — eager-commit builder locks in un-confirmed choices on force-quit; late-commit builder silently drops them |
| 2 | Critical | AD-4 / Consistency Conventions | `ChoiceRecord`'s fields are never defined — ID-vs-frozen-text and index-vs-stable-key are both open, each incompatible with the other |
| 3 | High | AD-4 | "writes on state mutation" doesn't pin synchronous-vs-debounced; debounced builder can lose pages on abrupt termination |
| 4 | High | AD-1 / Capability Map | Echo firing structural-and-guaranteed vs. runtime-history-conditional — changes how often the game's core mechanic actually fires |
| 5 | High | AD-3 / state diagram | Interstitial-Continue / Ending-tap / Memory-Return-Home have no canonical intent mapping; reusing `exitToHome()` for a finished run leaves a stale "Resume Story" pointing at a terminal node forever |
| 6 | Medium | AD-5 | Interstitial's bidirectional page-turn block is stated only in EXPERIENCE.md, not AD-5 itself — a spine-only build can allow `goBack()` mid-interstitial |
| 7 | Medium | AD-4 / RunSnapshot shape | No persisted `phase` field — resume behavior after backgrounding mid-interstitial (or mid-undo-window) is unconstrained |
| 8 | Medium | AD-6 | Hard-fail phase transition inside `selectChoice(_:)` vs. discovered on next `advancePage()` — one requires an extra forward gesture, the other doesn't |
