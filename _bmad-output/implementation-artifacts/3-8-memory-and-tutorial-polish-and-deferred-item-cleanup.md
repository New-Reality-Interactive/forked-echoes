---
baseline_commit: 15285be43bdc59ffa25335a5578a0392f9a5b60c
---

# Story 3.8: Memory & Tutorial Polish and Deferred-Item Cleanup

Status: done

## Story

As a developer,
I want to close out the remaining small correctness and dead-code items logged in `deferred-work.md`,
so that nothing lingers there as an open loop once Epic 3 wraps.

## Acceptance Criteria

1. **Given** `MemoryView.swift`'s `.formatted(.number.sign(strategy: .always()))` alignment-score display, **when** a run's accumulated `alignmentScore` is exactly `0`, **then** it renders as `"0"`, not `"+0"` — a genuinely neutral run no longer reads as positive; positive and negative scores continue to show their sign. [Source: epics.md#Story-3.8, AC1 — closes the Story 3.4 deferred-work.md item]
2. **Given** `StoryChoiceView.swift`'s echo-callback tag `Text` ("The story remembers"), currently styled with ad-hoc `.fontWeight(.bold)` and no named DESIGN.md typography role, **when** this story lands, **then** either a new named typography role is added to DESIGN.md/`Typography.swift` and applied here, or DESIGN.md explicitly documents that this element is intentionally ad-hoc — not left as an undocumented gap. [Source: epics.md#Story-3.8, AC2 — closes the Story 2.8 deferred-work.md item]
3. **Given** `RunSnapshot.tutorialSeen` (AD-4), currently always encoded as `false` with no producer that ever sets it `true` and no consumer that reads it anywhere in the codebase since Story 2.4, **when** this story lands, **then** a decision is made and implemented: either Tutorial writes `true` on dismissal and at least one real consumer uses it meaningfully, or the field is removed entirely as dead scope — not left as silent, permanently-`false` weight in every `RunSnapshot`. [Source: epics.md#Story-3.8, AC3 — closes the Story 1.3 deferred-work.md item]
4. **Given** `RunSnapshot`'s decode-compatibility precedent (AD-4, mirrored by `visitedArrivalNodeIds`/`visitedNodeIds`), **when** `tutorialSeen` is removed (if that's the decision reached above), **then** an on-disk snapshot written by an older build that still contains the `tutorialSeen` key decodes successfully (the extra key is ignored, not a decode failure) — no NFR4 regression. [Source: epics.md#Story-3.8, AC4]
5. **And** a manual-verification AC: in Xcode/Simulator, confirm (1) a genuinely neutral-score run displays "0" (not "+0") on Memory, and (2) whichever `tutorialSeen` decision was implemented behaves as decided. Result + date recorded in the story's Completion Notes List. [Source: epics.md#Story-3.8, AC5 — project-context.md Process Agreement]

## Background: Why This Story Exists

Added via deferred-work review, 2026-08-06 (epics.md's Story 3.8 header note) — bundles three small, otherwise-unrelated items that don't individually justify their own story: `deferred-work.md`'s "code review of 3-4-ending-and-memory-visual-identity" entry (the `"+0"` item, line 10), `deferred-work.md`'s "code review of 2-8-reading-surface-visual-identity-dynamic-type-and-reduce-motion" entry (the echo-tag typography item, line 146), and `deferred-work.md`'s "code review of 1-3-tutorial-screen" entry (the `tutorialSeen` item, line 98) plus `RunSnapshot.swift`'s own doc comment on the field. All three are independently small, verified-still-open (re-confirmed by direct code read below), and unrelated to each other beyond "loose ends before Epic 3 closes" — implement them as three separate, independently-completable tasks rather than looking for a unifying theme that doesn't exist.

This is Epic 3's last story: `epic-3-retrospective` is `optional` in `sprint-status.yaml` and every other Epic 3 story (3.1-3.7) is `done`. No downstream story in this epic depends on this one.

## Tasks / Subtasks

- [x] Task 1: Fix Memory's zero-score sign display (AC: #1)
  - [x] In `ForkedEchoes/Views/Memory/MemoryView.swift`, `header`'s score `Text` (line 52) currently reads `Text(engine.alignmentScore.formatted(.number.sign(strategy: .always())))`. `NumberFormatStyleConfiguration.SignDisplayStrategy` has no built-in "always except zero" case — the fix is a small conditional: when `engine.alignmentScore == 0`, format without a sign (plain `.formatted()` or `.number`); otherwise keep `.sign(strategy: .always())`. Keep this inline in `header` (one call site, no new helper needed — matches this file's existing style of small inline conditionals, e.g. `chosenOption(for:)`).
  - [x] Do not touch `Tier.scoreToTier(score:)` or the tier label next to the score — AC #1 is about the number's sign glyph only, the tier logic (Story 3.1, AD-9) is unrelated and must keep resolving a neutral score to whichever tier band already covers zero.
  - [x] Preview provider check: `MemoryView.swift`'s two `#Preview`s (`.boat` choice, `.gotcha` choice) don't currently exercise a zero-score run — you don't need to add a third preview, but if you want a fast visual sanity check while iterating, a zero-`alignmentScore` run is reachable by starting a run and reaching an ending whose `choiceHistory` nets to 0 (check `StoryTree`/`Content` for a zero-net path, or simplest: temporarily hardcode `alignmentScore: 0` in a scratch preview and delete it before finishing — don't leave a throwaway preview in the file).

- [x] Task 2: Give the echo-callback tag a documented typography treatment (AC: #2)
  - [x] Read `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` lines 264-281 in full — the `if let echoBodyKey` block. The tag `Text(LocalizedStringKey("storyChoice.echo.tag"))` (line 269) has `.fontWeight(.bold)` and `.foregroundStyle(Color.accentEmberText)` but no `.font()` call, so it inherits SwiftUI's default `Text` font (`.body`, unweighted) with `.bold` layered on top — a 700-ish weight that doesn't correspond to any of this project's named weight tokens (900/800/700(new)/600/500 — see `Typography.swift`'s doc comments citing DESIGN.md's "weight contrast 900/800/600/500" hierarchy, which currently has no 700 entry).
  - [x] Read DESIGN.md's `components.echo-callback` entry (`_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md` line 265) and its Colors section entry for `accent-ember-text` (line 199) — both describe the tag by color only ("tagged 'The story remembers' in `{colors.accent-ember-text}`"), neither names a `typography.*` role for it. This means DESIGN.md itself never specified a token for the tag's weight — the `.fontWeight(.bold)` was an implementation-time ad-hoc choice (Story 2.5), not a dropped spec.
  - [x] Make and implement one of these two decisions (do not do both):
    - **Option A — add a named role.** Add a new `typography.echo-tag` (or similarly-named) entry to DESIGN.md's Typography section (mirroring the existing role table's shape — text style, weight, tracking/case if any) and a corresponding modifier in `Typography.swift` (e.g. `echoTagStyle()`, following `metaStyle()`/`captionStyle()`'s precedent: modifier struct + `View` extension, doc comment citing the new DESIGN.md token). Apply it at `StoryChoiceView.swift:269` in place of the bare `.fontWeight(.bold)`.
    - **Option B — document as intentional. (CHOSEN)** Add a short note to DESIGN.md's `components.echo-callback` entry (or the Typography section's prose) stating explicitly that the tag's bold weight is a deliberate one-off emphasis, not a named typography role, and why (e.g., it's a single, non-reused UI label distinct from the reusable `typography.*` roles). Leave the `.fontWeight(.bold)` call as-is in code, but it must no longer be a silent gap — the doc note is the deliverable.
  - [x] Either way, this is a one-call-site change — don't go looking for a second place to apply a new role if you choose Option A; `grep -rn "storyChoice.echo.tag"` confirms it's used exactly once.

- [x] Task 3: Decide and implement `tutorialSeen`'s fate (AC: #3, #4)
  - [x] Read `ForkedEchoes/Engine/RunSnapshot.swift`'s full doc comment (lines 1-11) and the field itself (line 16) — it already states plainly: "has no producer anywhere in the codebase yet... always written/read as `false` until a future story wires a real signal into the engine." This story is that future story — make the actual call, don't defer again.
  - [x] `grep -rn "tutorialSeen"` across the repo first (already done during story creation — 27 hits, all either the field/doc comment itself, `StoryRunEngine.swift:346`'s single production writer (`tutorialSeen: false`, hardcoded), or test fixtures constructing `RunSnapshot` literals). There is genuinely no reader anywhere — confirmed, not just claimed by the doc comment.
  - [x] Check whether any planning artifact (PRD, epics.md, DESIGN.md, EXPERIENCE.md) describes a feature that would consume a "has the player seen the tutorial" signal (e.g., relabeling "Start Tutorial" once seen, skipping tutorial content, a design gate). A search of `epics.md`/`prd.md` during story creation found **no such feature described anywhere** — `UX-DR9`/Story 1.2's "Start Story"/"Start Tutorial" relabeling is driven entirely by `hasInProgressRun` (run-snapshot presence), never by tutorial-seen state. This is a strong (not conclusive — re-verify yourself) signal toward removal being the correct call, but the decision is yours to make and justify in Dev Notes, not to inherit from this note.
  - [x] **DECISION: removed.** Deleted the `tutorialSeen` property, its `CodingKeys` case, its `encode(to:)` line, and its `container.decode(Bool.self, forKey: .tutorialSeen)` line from `RunSnapshot.swift`; removed the `tutorialSeen:` parameter from the memberwise `init`; removed the `tutorialSeen: false` argument from `StoryRunEngine.swift:346`'s `RunSnapshot(...)` call; removed every `tutorialSeen: false` argument from `RunSnapshot(...)` call sites in `ForkedEchoesTests/RunSnapshotTests.swift`, `RunSnapshotPresenceTests.swift`, and `StoryRunEngineTests.swift` (the JSON-literal `"tutorialSeen": false` keys inside `RunSnapshotTests.swift`'s raw-JSON decode fixtures were kept, per AC #4). AC #4's decode-compatibility requirement is satisfied by simply no longer naming `tutorialSeen` in `CodingKeys`/`init(from:)`/`encode(to:)` — `Codable`'s keyed-container decode silently ignores an unknown JSON key by default, no `decodeIfPresent` shim needed. Verified: `RunSnapshotTests.swift`'s two pre-existing decode-compatibility fixtures (`decodingASnapshotWithoutTheVisitedArrivalNodeIdsKeyDefaultsToEmpty`, `decodingASnapshotWithoutTheVisitedNodeIdsKeyDefaultsToEmpty`), both of which embed `"tutorialSeen": false` in their raw JSON, still pass unchanged — this *is* AC #4's regression proof.
  - [x] Whichever path: run `swift test` and confirm the full suite passes with zero `tutorialSeen`-shaped compile errors across all three test files.

- [x] Task 4: Manual Xcode/Simulator verification (AC: #5) — record results in Completion Notes (project-context.md Process Agreement: actively request this, report inline when it happens)
  - [x] Reach a genuinely zero-net-alignment ending (or temporarily force `alignmentScore` to 0 for the check, then revert) and confirm Memory's score renders `"0"`, not `"+0"`.
  - [x] Reach a positive-score ending and a negative-score ending and confirm both still show their sign (`"+N"` / `"-N"`) — this guards against an overcorrection that strips the sign unconditionally.
  - [x] Confirm whichever `tutorialSeen` decision was implemented behaves as decided: if removed, confirm nothing regressed (Home/Tutorial/Memory flows all behave identically to before); if kept, confirm the new producer/consumer behavior works as designed.
  - [x] Record the date and a one-line result for each check in Completion Notes.

## Dev Notes

### This is a cleanup story, not a feature story — scope discipline matters

Three independent, small fixes. Do not let Task 3's `tutorialSeen` decision balloon into new engine/UI work beyond what AC #3 actually requires (a decision + its minimal implementation). If you land on "keep and wire a consumer," the consumer's design is genuinely undecided by any planning artifact — implement the smallest sensible one and say so plainly in Completion Notes rather than inventing product scope silently.

### AC #1 — the exact fix shape

`MemoryView.swift:52`:
```swift
Text(engine.alignmentScore.formatted(.number.sign(strategy: .always())))
```
`Foundation`'s `IntegerFormatStyle.sign(strategy:)` strategies (`.always()`, `.never`, `.automatic`, `.exceptZero`) — **`.always(includingZero: false)` is the built-in answer**: `FormatStyleConfiguration.SignDisplayStrategy.always(includingZero:)` takes a `Bool` parameter (default `true`) specifically for this case. Prefer `.number.sign(strategy: .always(includingZero: false))` over a manual `if score == 0` branch if that overload is available in this project's Swift/SDK version (Swift 6.3 per project-context.md) — check `Foundation`'s actual API surface first (this devcontainer's Linux toolchain has `Foundation` and can typecheck a `.formatted()` call via `swiftc -parse`, though full `NumberFormatStyleConfiguration` resolution may still need the real SDK to confirm the parameter exists at this Swift version — fall back to the manual conditional described in Task 1 if `includingZero:` isn't available).

### AC #2 — precedent for adding a new typography role, if Option A is chosen

`Typography.swift`'s existing roles (`eyebrowStyle()`, `metaStyle()`, `captionStyle()`, `echoCallbackStyle()`, `headlineStyle()`, `statStyle()`, `bodyStyle()`, `subtitleStyle()`) all follow the same shape: a private `ViewModifier` struct (only when `@ScaledMetric` tracking is needed) or an inline `self.font(...)` chain, exposed via a `View` extension method with a doc comment citing the DESIGN.md token path (`typography.<role>` or a named component note when no `typography.*` entry exists, e.g. `subtitleStyle()`'s doc comment). Match this exactly if you add a role — don't introduce a different pattern (e.g., a global enum of fonts) for one new entry.

### AC #3/#4 — `RunSnapshot`'s decode-compatibility mechanism, if removing

The precedent this AC points to (`visitedArrivalNodeIds`/`visitedNodeIds`, `RunSnapshot.swift` lines 60-68) is for the *opposite* direction — a field that's new-and-optional-on-decode because *old* snapshots lack it. Removing `tutorialSeen` is the reverse case: old snapshots *have* the key, new code must not choke on it. `Codable`'s default keyed-decoding behavior already handles this correctly — decoding via a `CodingKeys` enum that simply omits `tutorialSeen` means the decoder never looks for that key and silently ignores its presence in the underlying JSON. You do not need a `decodeIfPresent` shim for a field you're deleting; you need to *not reference it at all* in the new `CodingKeys`/`init(from:)`/`encode(to:)`. Confirm this empirically: `RunSnapshotTests.swift` already has JSON-literal fixtures with `"tutorialSeen": false` embedded (lines 34, 52) — after removing the Swift property, these fixtures' decode assertions must still pass unchanged (the extra JSON key is simply ignored), which is the concrete proof AC #4 asks for. Do not delete these two JSON-literal fixtures' `"tutorialSeen": false` lines — their presence *is* the regression test.

### Architecture citations

- **AD-4** (RunSnapshot's persisted shape, decode-compatibility contract for old-build snapshots): directly governs Task 3 — both the removal path (AC #4's decode-must-still-succeed requirement) and, if chosen instead, the keep-and-wire path (a new producer must still write synchronously via the existing `persistOrClearSnapshot()` intent pattern).
- **AD-3** (StoryRunEngine is the sole mutator of run state; every mutating intent ends in `persistOrClearSnapshot()`): governs the "keep" path if chosen — a new `markTutorialSeen()`-style intent must follow this exact shape, not write to `UserDefaults`/mutate state from the View layer directly.
- **NFR4** (no crash, fresh-Home fallback on any malformed/incompatible snapshot): the reason AC #4 exists at all — a naive field removal that made the decoder strict about `tutorialSeen`'s presence would regress this.

### Project Structure Notes

Files expected to change:
- `ForkedEchoes/Views/Memory/MemoryView.swift` — Task 1, `header`'s score `Text` (line 52 area) only.
- `ForkedEchoes/Views/DesignSystem/Typography.swift` — Task 2, only if Option A (new role) is chosen.
- `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md` — Task 2, either option (new token entry for Option A, or an intentional-ad-hoc note for Option B).
- `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` — Task 2, line 269's tag `Text` modifier only.
- `ForkedEchoes/Engine/RunSnapshot.swift` — Task 3, if removing: property/`CodingKeys`/`init(from:)`/`encode(to:)`. If keeping: no change needed here beyond what a new producer requires.
- `ForkedEchoes/Engine/StoryRunEngine.swift` — Task 3, line 346's `RunSnapshot(...)` construction (remove the argument if removing the field; add a new intent method if keeping/wiring).
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` — Task 3, only if keeping/wiring (would need a dismissal call site into the engine that doesn't exist today).
- `ForkedEchoesTests/RunSnapshotTests.swift`, `RunSnapshotPresenceTests.swift`, `StoryRunEngineTests.swift` — Task 3, remove `tutorialSeen:` constructor arguments if removing (keep the two JSON-literal fixture keys per the AC #4 note above); add coverage for a new producer/consumer if keeping.

No other files should need changes — this is a small, surgical story across the three tasks above.

### Testing Standards Summary (AD-7)

- `swift test` from the repo root — this devcontainer's Linux Swift toolchain genuinely runs the engine-logic suite (see project-context.md Environment section). Confirm the full suite passes after Task 3's `RunSnapshot` signature change ripples through the test files (compile errors here are expected mid-edit, not a sign of a wrong approach — fix every call site).
- `swiftc -parse` on any `.swift` file touched, for syntax verification (no Xcode/UIKit in this devcontainer).
- No new Swift Testing case is required by any AC here unless Task 3's "keep and wire" path is chosen and needs its own coverage for the new producer/consumer — if you remove `tutorialSeen` instead, the *existing* `RunSnapshotTests.swift` decode-compatibility fixtures (with their JSON-literal `"tutorialSeen": false` keys preserved) already serve as AC #4's regression test; do not feel obligated to add a new test on top of them.
- Task 4's manual Xcode/Simulator pass is required, not optional (project-context.md Process Agreement) — actively request it from the user rather than noting it as unverified.
- Per project-context.md's process rule (added after Story 3.4's code review): if any code review after Task 4's verification patches `.swift` code, do not advance status to `done` on the strength of the pre-patch verification — leave at `review` and re-request Task 4's specific checks.

## Previous Story Intelligence (Story 3.7)

Story 3.7 was an audit-and-test story with **zero application-code changes** (its two audited mechanisms turned out already correct; its one required test already existed). That story's pattern doesn't directly transfer here since 3.8 does require real code changes, but one thing carries over: its Completion Notes format (dated, itemized, one line per task/AC, explicit "no files changed" statement) is the bar to match — Story 3.8's Completion Notes should be similarly itemized per task (1/2/3/4), not one paragraph.

Two process rules 3.7 exercised, both still binding here:
- **Manual verification is this story's primary correctness gate for the view-layer changes** (Tasks 1/4) — `swift test` verifies Task 3's engine-layer change compiles/passes, but Memory's actual on-screen sign rendering can only be confirmed by the user in Simulator.
- **If a code review patches `.swift` after Task 4's verification already happened, status stays at `review`, not `done`, until Task 4's specific checks are re-confirmed** (project-context.md Process Agreements, added during Story 3.4's code review, most recently exercised in this exact form by Story 3.7 itself).

## Git Intelligence Summary

Last 5 commits are all Story 3.5/3.7 wrap-up (merge commits, doc updates, status flips) — no new library dependencies, no `Package.swift` changes, no architectural shifts to account for. Story 3.7 touched zero `.swift` files (audit-only), so there's no fresh code pattern from it to carry forward beyond the process rules above; the most recent actual `.swift`-touching precedent remains Story 3.5/3.4/3.6's accessibility/visual-identity work, none of which is directly relevant to this story's three narrow fixes.

## Project Context Reference

Full rules loaded from `_bmad-output/project-context.md` (55 rules, last updated 2026-08-07) as a persistent fact for this workflow run — see especially: Localization (dot-path keys, `LocalizedStringKey` ternary typing — not triggered by this story's changes, but relevant if Task 2/3 touch any `Text(...)`), Design tokens (numeric literals must trace to a DESIGN.md token or a named constant — relevant to Task 2's typography decision), the VoiceOver-not-officially-tested-for-v1 Process Agreement (not directly triggered here, but relevant background if Task 3's `tutorialSeen` removal touches any accessibility-adjacent Tutorial code), and the devcontainer-vs-real-device verification gap (Task 4 must be a real Simulator check, not assumed from `swift test` passing).

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- **Task 1 (2026-08-08):** `MemoryView.swift:52`'s score `Text` now uses `.formatted(.number.sign(strategy: .always(includingZero: false)))`. Confirmed empirically (typecheck + run via `swiftc` on this devcontainer's Linux Foundation) that `SignDisplayStrategy.always(includingZero:)` exists and resolves at Swift 6.3 — `.formatted()` on `0`/`7`/`-3` produced `"0"`/`"+7"`/`"-3"` exactly as required, so the built-in overload from Dev Notes was used rather than a manual `if score == 0` branch. `Tier.scoreToTier(score:)` untouched.
- **Task 2 (2026-08-08):** Chose **Option B** (document as intentional) — a single, non-reused UI label didn't justify a new reusable `typography.*` role. Added a `tag-weight` field and an extended `note` to DESIGN.md's `components.echo-callback` entry stating the bold weight is a deliberate one-off emphasis, not a dropped token. `StoryChoiceView.swift:269`'s `.fontWeight(.bold)` left unchanged in code, with a comment pointing at the new DESIGN.md note so it's no longer a silent gap.
- **Task 3 (2026-08-08):** Decision: **removed** `tutorialSeen` as dead scope. Re-confirmed via `grep -rn "tutorialSeen"` that no reader exists anywhere in the codebase and no planning artifact describes a consuming feature. Removed the field/`CodingKeys` case/`encode`/`decode` lines from `RunSnapshot.swift`, its constructor parameter, the `StoryRunEngine.swift:346` writer argument, and every `tutorialSeen: false` constructor argument across the three test files — kept the two `"tutorialSeen": false` JSON-literal fixtures in `RunSnapshotTests.swift` untouched (AC #4's regression test). `swift test`: **89/89 tests pass**, zero `tutorialSeen`-shaped compile errors. The two pre-existing decode-compatibility fixtures embedding `"tutorialSeen": false` in raw JSON both still pass, confirming an old on-disk snapshot with the now-unknown key decodes cleanly (AC #4).
- **Task 4 (2026-08-08):** During manual-verification setup, discovered the placeholder `StoryTree`'s single choice node had no combination of its 4 options (`+1`/`-1`/`-3`/`+2`) that nets to a genuine `0` — AC #1's "0" vs "+0" fix had no real-gameplay path to verify. At the user's explicit direction, changed `.shore`'s `alignmentDelta` from `-1` to `0` in `StoryTree.swift` (keeping `.boat`/`.driftLimbo` positive and `.gotcha` negative, so all three sign cases stay reachable by normal play). `swift test`: 89/89 still pass (no test asserted a specific score off `.shore`'s prior `-1` delta).
  - User confirmed in Xcode/Simulator (2026-08-08): "All checks pass" — (1) `.shore` (0 delta) renders Memory's score as `"0"`, not `"+0"`; (2) `.boat`/`.driftLimbo` (positive) and `.gotcha` (negative) still render `"+N"`/`"-N"`; (3) `tutorialSeen`'s removal caused no regression — Home/Tutorial/Memory flows behave identically to before.

### File List

- `ForkedEchoes/Views/Memory/MemoryView.swift` — Task 1
- `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` — Task 2
- `_bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md` — Task 2
- `ForkedEchoes/Engine/RunSnapshot.swift` — Task 3
- `ForkedEchoes/Engine/StoryRunEngine.swift` — Task 3
- `ForkedEchoesTests/RunSnapshotTests.swift` — Task 3
- `ForkedEchoesTests/RunSnapshotPresenceTests.swift` — Task 3
- `ForkedEchoesTests/StoryRunEngineTests.swift` — Task 3
- `ForkedEchoes/Content/StoryTree.swift` — Task 4, `.shore`'s `alignmentDelta` changed from `-1` to `0` so AC #1's zero-score case is reachable by normal play (user-directed)
