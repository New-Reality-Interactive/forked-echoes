---
title: Architecture Spine Review — Rubric Walk
target: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md
reviewer-method: 7-point good-spine checklist
created: 2026-07-25
---

# Review: ARCHITECTURE-SPINE.md (Many-Worlds CYOA iOS App v1)

## Overall Verdict

**Conditional pass.** The spine is well-formed as build substrate: terse, every AD ties to a concrete "Prevents" claim traceable to a real PRD/addendum divergence risk, and the Deferred section correctly routes non-architectural decisions elsewhere instead of inventing answers. It should not, however, be treated as final without addressing two real gaps: (a) the engine's intent-method surface (AD-3) does not account for the tap-then-undo-window commit mechanic the UX spec (`EXPERIENCE.md`) actually specifies, which is exactly the kind of thing that causes two independently-built units to diverge; and (b) device family / target platform scope (iPhone-only vs. Universal/iPad) is decided nowhere — not in Decided, not in Deferred, not in Open Questions — despite being a real operational/structural dimension. Several other findings are lower-severity polish items.

---

## Checklist Item 1 — Does it fix the real divergence points, missing none?

Mostly yes. AD-1 through AD-7 each target a genuine, concrete divergence risk (dead-end branches, string/asset typos, fragmented per-screen state, over-engineered persistence, forcing a tree into `NavigationStack`, duplicated ending-tier logic, unverified engine logic). These are not filler ADs — each has a specific, checkable "Prevents" clause.

Two real divergence points are **not** fixed, however:

### Finding A (Medium-High) — The tap+undo-window choice-commit mechanic has no home in the engine's intent surface
- **Where:** AD-3's rule (`ARCHITECTURE-SPINE.md` lines 46-51) enumerates the full intent surface as `selectChoice(_:)`, `advancePage()`, `goBack()`, `exitToHome()`, `restartRun()`, and states views hold only "local, transient, non-persisted UI state (e.g. choice-card charge/undo-window animation progress)."
- **Conflict:** `EXPERIENCE.md` (Component Patterns, Choice card row; State Patterns, "Choice tap-committed (undo window)" row) specifies that a quick tap commits **instantly** but then sits in a ~1.5s **revocable** undo window (tap again to cancel) before finalizing — and that FR-5 "locked" permanence only applies once the window elapses or the player pages forward.
- **Why this is a real divergence risk:** whether the "committed but revocable" choice is business state (something the engine already knows about and can undo) or purely a view-local rendering illusion (the view defers calling `selectChoice` until the window elapses, holding the *pending choice itself* — not just animation progress — in local `@State`) is left open. Two engineers would plausibly build this two different ways:
  1. Call `selectChoice()` immediately at tap, requiring an `undoChoice()`/`revertChoice()` engine method that doesn't exist in AD-3's list, and raising the question of whether "locked choice history" (AD-3's own phrase) briefly contains a choice that gets un-locked.
  2. Buffer the pending choice in view-local state and only call `selectChoice()` once the undo window elapses — which contradicts AD-3's own characterization of view-local state as "transient... animation progress," since a pending-but-not-yet-committed *choice* is exactly the kind of state AD-3 says never lives outside the engine.
- **Recommendation:** Add either a sixth intent method (e.g. `selectChoice(_:provisional:)` / `confirmChoice()` / `cancelProvisionalChoice()`) or an explicit statement that the undo window is engine-owned state (a `provisionalChoice` slot alongside `locked choice history`), so both implementers converge on the same design.

### Finding B (Low) — The interstitial's "Continue" affordance isn't mapped onto a named intent method
- **Where:** AD-5's phase enum includes an `Interstitial` phase, and the state diagram shows `Interstitial --> Reading: Continue tapped`, but AD-3's intent list doesn't mention how "Continue" is invoked (is it `advancePage()` reused, or a distinct method?).
- **Impact:** Likely resolves fine by reusing `advancePage()`, but it isn't stated, so it's left to inference rather than being fixed by the spine.

---

## Checklist Item 2 — Is every AD's Rule enforceable and does it actually prevent its stated divergence?

Walked AD-1 through AD-7 individually:

- **AD-1** — Enforceable. Because content node/choice IDs are constrained to be Swift enum cases (per the Naming row in Consistency Conventions) rather than free-form strings, "dangling reference" is genuinely compiler-impossible: any value of the ID type necessarily corresponds to an existing case. Combined with non-optional "next node" / terminal-ending-only leaves, the "no dead end" claim holds. Good design — but note this enforceability argument only fully closes once you combine the AD-1 rule with the separate Naming-conventions row; AD-1 alone doesn't state that IDs are enum cases. Minor self-containedness nit, not a functional gap.
- **AD-2** — Enforceable at the level of "typo'd key fails to compile" once generated symbols are enabled; reasonable.
- **AD-3** — Enforceable for the "single mutator" claim (SwiftUI/@Observable/@Environment access patterns make direct state mutation from views structurally awkward to smuggle in, and code review can catch it). See Finding A above for where its stated intent surface is incomplete relative to the UX spec it's supposed to be consistent with.
- **AD-4** — Enforceable and appropriately scoped (UserDefaults + Codable is proportionate to a single small blob). See Finding C below for an unaddressed failure mode.
- **AD-5** — Enforceable; correctly identifies why `NavigationStack`/`TabView(.page)` are the wrong tool (both assume a fixed, known page list) and replaces it with an engine-owned phase enum. Solid.
- **AD-6** — Enforceable; naming one function (`scoreToEnding`) as the single source of tier truth is a clean, checkable rule, and directly fixes the exact bug (`addendum.md`'s Home/Stay boundary overlap) that motivated it.
- **AD-7** — Enforceable as a testing mandate, but its coverage list has a gap — see Finding D below.

### Finding C (Medium) — AD-4 doesn't specify RunSnapshot decode-failure/schema-mismatch behavior
- **Where:** AD-4's rule states the engine "decodes it on cold launch to restore an in-progress run" but says nothing about what happens if decode fails (corrupt data, or a schema change between app versions/content-tree edits leaving a `currentNodeId` that no longer resolves).
- **Why it matters:** This is exactly a case where two implementations could diverge silently — one might crash, one might silently drop to a fresh Home state, one might attempt partial recovery. Given the spine's own "Consistency Conventions" table commits to "impossible engine states... prevented by the type system and engine guard logic, not caught and recovered from at runtime" — the decode-failure path is the one place recovery *is* needed (you cannot type-system your way out of a corrupted UserDefaults blob), and the spine is silent on it.
- **Recommendation:** One sentence — e.g. "Decode failure of any kind (missing key, malformed JSON, unrecognized node id) is treated identically to no saved run: engine starts fresh at Home, key is not retried." — would close this.

### Finding D (Low) — AD-7's test-coverage list omits pager-gating logic
- **Where:** AD-7 lists coverage for "alignment-tier resolution..., echo-callback reachability..., hard-fail bypass, and RunSnapshot encode/decode round-trip." It does not list the forward-navigation gate (`advancePage()` blocking on an unresolved choice; locked-choice display on revisit) that AD-5 assigns to engine guard logic.
- **Why it matters:** The Consistency Conventions table explicitly frames "impossible engine states (e.g. advancing past an unresolved choice)" as prevented by "guard logic, not caught and recovered from at runtime" — i.e., this is runtime logic, not a compile-time guarantee, and is precisely the kind of thing AD-7 exists to pin down with tests. It's a conspicuous omission from an otherwise well-targeted list.

---

## Checklist Item 3 — Could anything under "Deferred" let two independently-built units diverge in a way that matters?

No new issues beyond what's flagged elsewhere. Walked each Deferred bullet:
- Story scale, App Store content rating, second-language translation, v1.1+ scope: correctly non-architectural or correctly out of v1 scope; none affect code-level consistency between independently-built units.
- Gesture vocabulary: correctly deferred — verified it actually *is* resolved in `EXPERIENCE.md`/`DESIGN.md` (press-and-hold ~3s / tap-third-zones / VoiceOver custom actions are fully specified there), so this isn't a gap dressed up as a deferral.
- Apple Developer Program enrollment: correctly tracked as an external blocking dependency, not something architecture can resolve; consistent with also being called out in the Structural Seed's deployment paragraph.

The one omission that *would* matter (device family/target scope) isn't even in the Deferred list — it's silent, which is worse than deferred. See Finding E under Item 6.

---

## Checklist Item 4 — Does named tech read as verified-current, or asserted from stale training data?

Flag for human verification before locking. As of this review, the following cannot be confirmed against an authoritative source and should be checked against current Apple documentation before being treated as fixed:

### Finding F (Low-Medium) — Swift 6.3 / Xcode 26.6 are asserted without citation
- The Stack table states Swift 6.3, iOS 26 SDK / iOS 18 min deployment, and Xcode 26.6 as fact, with no source link and no "as of" caveat.
- The iOS 18 → iOS 26 jump itself is consistent with Apple's actual 2025 platform-version renaming (aligning OS version numbers to release year), so "iOS 26 SDK, iOS 18 min (N-1)" is plausible and internally consistent with the PRD's N-1 compatibility requirement — that part checks out logically even without a live citation.
- What's *not* independently verifiable here: the specific point releases "Swift 6.3" and "Xcode 26.6." Xcode's dot-release cadence historically reaches .3–.4 within the first year of a major version, not .6 — reaching 26.6 by the document's own dated "today" (2026-07-25, ~10 months after a presumed Sept 2025 Xcode 26 launch) is on the high end of plausibility and reads more like an extrapolated/placeholder value than a checked one.
- **Recommendation:** Before this spine is used as a build gate, verify the exact Swift/Xcode versions against Apple's current release notes (or the actual Xcode installed on the dev machine) and either cite the source or soften to "latest available at implementation time."
- Same caveat applies more mildly to the claim that String Catalogs support "type-safe generated symbols enabled" as a checkbox feature tied to a specific Xcode version — real feature, but the exact version gating isn't cited.

Not flagged (verifiable / stable facts, safe to trust): Swift Testing bundled with Xcode 16+/Swift 6+, `@Observable` (Observation framework, iOS 17+), `ImageResource`/asset-catalog generated symbols, `LocalizedStringResource` — all predate the version-currency risk window and are consistent with established API history.

---

## Checklist Item 5 — Does it cover FR-1 through FR-12 correctly and completely?

All 12 FRs appear in the Capability → Architecture Map. Spot-checked each row; two are governed slightly loosely:

### Finding G (Low) — FR-6's "Governed by" column points to testing (AD-7), not structure
- FR-6 (Narrative callback/echo) is mapped to `AD-1, AD-7`. AD-7 is the *testing* AD ("echo-callback reachability... as authored in the tree, is tested"), not the AD that architecturally guarantees the echo mechanism exists and renders correctly. There's no AD that explicitly commits to *how* an echo page signals its "echo-ness" to the view layer (see Finding H).

### Finding H (Low-Medium) — AD-3's rendering projection doesn't include an echo/node-kind signal
- AD-3 states the engine exposes "current content to views as a rendering projection (resolved node: prose keys, choice list, illustration reference)" — three fields, exhaustively listed (not "e.g.").
- But the UX spec's signature interaction — the circuit frame powering from brass to ember "for the duration this [echo] block is on-screen" (`EXPERIENCE.md`, Component Patterns) — requires the view to know "is this page an echo callback" (and, similarly, the Ending screen needs an ending-kind signal, which the tree's `EndingKind` case does provide implicitly).
- The three-field projection as literally stated has no slot for this. It's likely intended to be inferred (view branches on which resolved-node case it receives), but since AD-3 explicitly forbids views from importing/traversing `Content` directly, the projection type itself needs to carry this signal, and the spine doesn't say so.
- **Recommendation:** Either mark the projection list as non-exhaustive ("e.g.") or add the echo/kind signal explicitly, since it's the one thing the visual design most depends on.

### Finding I (Low) — FR-1/FR-2's "Governed by AD-3" undersells AD-4's role
- Home's primary listed job includes resuming an in-progress run (`EXPERIENCE.md` State Patterns: "Start Story" relabels to "Resume Story"), which is fundamentally an AD-4 (RunSnapshot presence) concern, not an AD-3 (intent-method surface) concern. Minor mapping-precision nit; doesn't cause a real build divergence since AD-4 is at least mentioned elsewhere for Home.

No FR is entirely uncovered; no FR is mapped to a nonexistent or contradictory AD. This item passes with only precision nits.

---

## Checklist Item 6 — Is every structural dimension the feature altitude should own decided, deferred, or an open question?

Most dimensions are covered: content modeling, state ownership, persistence, navigation, ending-resolution logic, testing strategy, and the operational/deployment envelope (single Xcode target, Debug/Release only, App Store Connect + TestFlight distribution, Apple Developer Program flagged as an unresolved blocking dependency) are all explicitly addressed in the Structural Seed's "Deployment & environments" paragraph. This is good — the spine did not skip the operational envelope wholesale, which is the most common failure mode for this kind of document.

One dimension, however, is genuinely silent — not decided, not deferred, not an open question:

### Finding E (Medium) — Device family / target platform scope is undecided and unmentioned
- Neither the PRD, the addendum, nor the spine states whether this is an iPhone-only app or a Universal (iPhone + iPad) app. `EXPERIENCE.md` says "Single-surface native iOS, portrait only," which implies an iPhone-shaped mental model but doesn't foreclose Xcode's default Universal target family, iPad multitasking (Split View/Slide Over), or iPad's different aspect ratios/orientations.
- This is exactly the kind of operational/environmental dimension the checklist calls out: it affects the Xcode project's `TARGETED_DEVICE_FAMILY` setting, whether orientation lock needs to be enforced per-device-idiom, and whether the DESIGN.md layout assumptions (single-column, full-bleed reading card) hold on an iPad-sized canvas. Two builders (or the same solo developer at two different times) could easily diverge — one leaves the Xcode template default (Universal), one restricts to iPhone — with no spine language to catch it either way.
- **Recommendation:** One line either in the Stack table or Structural Seed — "iPhone only; iPad/Mac Catalyst out of scope for v1" (or the inverse, if Universal is actually intended) — would close this cleanly.

No other structural dimension was found silent; CI/build-automation and third-party dependency policy are arguably also unaddressed but are lower-stakes for a solo-developer, zero-dependency project and are reasonably left implicit (no SPM packages are named or implied anywhere, and none are needed given the fully on-device, Apple-framework-only design).

---

## Checklist Item 7 — Is the spine appropriately terse, and does it avoid inventing decisions to fill gaps?

Passes. The document is dense and free of narrative padding; every AD is structured identically (Binds/Prevents/Rule) and reads as substrate rather than prose. The Deferred section actively resists the temptation to invent answers — it correctly punts story scale, content rating, and translation scope to the right altitude rather than making something up, and it explicitly calls out the one place a deferred item (telemetry) would require reopening an existing AD if ever pulled into scope, which is a good practice worth noting as a positive, not a finding.

One very minor naming-precision nit:

### Finding J (Low, cosmetic) — "Single-Engine MVVM" doesn't quite match what's described
- The paradigm name promises MVVM, but the design described has no per-screen ViewModel layer at all — it's a single shared `@Observable` store (`StoryRunEngine`) directly bound to every view via `@Environment`, which reads closer to a unidirectional-data-flow / single-store pattern than classic MVVM (where each screen typically owns its own ViewModel mediating access to a model). Not a functional problem — the actual rule (AD-3) is clear and self-consistent — but the label may mislead a reader expecting per-screen ViewModels to exist somewhere.

---

## Summary Table

| # | Finding | Severity | Checklist item |
|---|---|---|---|
| A | Tap+undo-window choice commit has no home in AD-3's intent surface | Medium-High | 1, 2 |
| E | Device family/target platform scope (iPhone vs Universal/iPad) undecided and unmentioned anywhere | Medium | 6 |
| C | AD-4 doesn't specify RunSnapshot decode-failure/schema-mismatch behavior | Medium | 2, 6 |
| H | AD-3's rendering projection has no echo/node-kind signal the UX's signature interaction depends on | Low-Medium | 2, 5 |
| F | Swift 6.3 / Xcode 26.6 asserted without citation; plausible but unverifiable | Low-Medium | 4 |
| D | AD-7 test-coverage list omits pager forward-navigation-gating logic | Low | 2 |
| B | Interstitial "Continue" not mapped to a named intent method | Low | 1 |
| G | FR-6 mapped to a testing AD (AD-7) rather than a structural one | Low | 5 |
| I | FR-1/FR-2 mapping undersells AD-4's role in "Resume Story" | Low | 5 |
| J | "Single-Engine MVVM" label doesn't match the no-per-screen-ViewModel design described | Low, cosmetic | 7 |

**Recommendation:** Fix Finding A and Finding E before treating this spine as build-ready — both are genuine fork points for a solo developer building over multiple sessions (the exact failure mode a spine exists to prevent). Findings C and H are worth a one-line fix each while the document is open. The rest can be tracked but don't block starting implementation.
