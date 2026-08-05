---
baseline_commit: 8da93b0e442afd8844b624a830f26de05ea9e8a0
---

# Story 3.1: Ending Kind Resolution

Status: done

## Story

As a developer,
I want each terminal node in the content tree to carry its `EndingKind` directly, and the engine to resolve a run's ending from whichever terminal node is reached,
so that ending resolution requires no runtime computation.

## Acceptance Criteria

1. **Given** Content/'s minimal tree (from Epic 2, Story 2.1) extended with terminal nodes, **when** each terminal node is authored, **then** it carries an `EndingKind` case (home/stay/limbo/hardFail) fixed at write-time (AD-1, AD-6). [Source: epics.md#Story-3.1, AC1]
2. **Given** the engine's current node is a terminal node, **when** the phase derives to `.ending` (per AD-5), **then** the run's ending is read directly as that node's `EndingKind` — no computation, no score check. [Source: epics.md#Story-3.1, AC2]
3. **Given** a designated gotcha (hard-fail) choice is selected, **when** `selectChoice(_:)` targets a hard-fail terminal node, **then** the engine transitions to Ending the instant the choice fires (AD-5), not on a later `advancePage()` discovery. [Source: epics.md#Story-3.1, AC3]
4. **Given** the content tree, **when** traced across all branches, **then** every branch terminates in exactly one of the four ending types (FR8), enforced by AD-1's tree shape. [Source: epics.md#Story-3.1, AC4]
5. **Given** AD-7/NFR3's testing scope, **when** the suite runs, **then** a Swift Testing case verifies hard-fail nodes are reachable only via their designated gotcha choice, and that the Ending transition fires immediately at `selectChoice(_:)` time rather than being deferred to a subsequent `advancePage()` — `EndingKind` coverage itself is already guaranteed by the compiler (AD-1, every `EndingPayload` requires a non-optional `kind`), not something a test needs to re-verify. [Source: epics.md#Story-3.1, AC5]
6. **Given** this story's placeholder tree, **when** authored, **then** content-authoring guidance is documented for later story-tree writing: roughly 1-2 terminal nodes as home endings and 3-4 as stay endings across the full v1 tree (addendum.md) — both this ratio and AD-9's score→tier boundaries are placeholder until Epic 4 authors the real v1 tree and finalizes them together against actual score distribution; this story's own placeholder tree only needs enough terminal nodes to exercise all four `EndingKind` cases at least once each, it does not need to honor the ratio itself. [Source: epics.md#Story-3.1, AC6]
7. **Given** the engine's phase derives to `.ending`, **when** the transition completes, **then** `RunSnapshot` is cleared from `UserDefaults` as part of that same transition (AD-4) — Memory (Story 3.3) can rely on this having already happened by the time it reads snapshot state. [Source: epics.md#Story-3.1, AC7]

## Tasks / Subtasks

- [x] Task 1: Add `EndingKind` and wire it onto `EndingPayload` (AC: #1, #2, #4)
  - [x] In `ForkedEchoes/Content/StoryNode.swift`, add `enum EndingKind: Sendable { case home, stay, limbo, hardFail }` next to `EndingPayload`.
  - [x] Add a non-optional `let kind: EndingKind` field to `EndingPayload`. Because it's non-optional, every terminal node's construction site becomes a compile error until it supplies a kind — this is what makes AC #1/#4 (every terminal node has exactly one `EndingKind`) a compiler guarantee, not a runtime check, matching AD-1's whole design intent. Do **not** default this field the way `echoBodyKey`/`arrival` on `.reading` were defaulted (see the comment above `EndingPayload` in that file) — those were additive extensions to existing call sites; `kind` is not, every existing `EndingPayload(nodeId:)` call site is expected to break and must be fixed, not silently patched around.
- [x] Task 2: Extend `NodeID` and `ChoiceOptionID` for the two new terminal nodes and the gotcha choice (AC: #1, #3, #6)
  - [x] In `ForkedEchoes/Content/NodeID.swift`, add two new cases: `endingLimbo`, `endingHardFail` (keep the existing `endingHomeward`, `endingElsewhere` — they become the `.home` and `.stay` exemplars).
  - [x] In `ForkedEchoes/Content/StoryNode.swift`, add two new `ChoiceOptionID` cases: one for the designated gotcha choice (e.g. `gotcha`) and one for the new limbo-reaching option (e.g. `driftLimbo`, or similarly descriptive — bikeshedding the exact name is fine, it's placeholder content).
- [x] Task 3: Wire the new terminal nodes and gotcha choice into `StoryTree.swift` (AC: #1, #3, #4, #6)
  - [x] Assign `EndingKind` to the two pre-existing terminal nodes: `.endingHomeward` → `.home`, `.endingElsewhere` → `.stay` (these already sit at the end of the `.boat`/`.shore` paths respectively — do not move them or change what reaches them, only add the `kind:` argument).
  - [x] Add `.endingLimbo` (`kind: .limbo`) and `.endingHardFail` (`kind: .hardFail`) as two new resolved-node cases in `StoryTree.resolvedNode(for:)`.
  - [x] Add the two new options to `firstChoice`'s `options` array (alongside the existing `.boat`/`.shore`): the gotcha option targets `.endingHardFail` directly, the new option targets `.endingLimbo` directly. This keeps the hard-fail path reachable in exactly one hop from a choice node — satisfying AC #3's "instant transition, no intervening `advancePage()`" requirement — and keeps `.boat`/`.shore`'s existing paths (and every test that depends on them, see Dev Notes below) completely untouched.
  - [x] Give both new options non-zero placeholder `alignmentDelta` values (matching the existing `.boat: 1`/`.shore: -1` placeholder-values comment already in this file) and new `labelKey`s following the `story.firstChoice.choice.<n>` convention (they'll be `.choice.3`/`.choice.4`).
  - [x] Update this file's header comment (the block explaining the tree's shape) to describe the now-4-terminal-node, 4-option-`firstChoice` shape — don't leave it describing the old 2-option version.
- [x] Task 4: Add localization entries for the two new choice labels (AC: #1 — content must actually build/run, not just compile)
  - [x] Add `story.firstChoice.choice.3` and `story.firstChoice.choice.4` to `ForkedEchoes/Resources/Localizable.xcstrings`, alphabetically ordered among the existing keys (project-context.md Localization section), each with `comment`, `extractionState: "manual"`, one `en` `stringUnit` with `state: "translated"`. Placeholder copy is fine (e.g. hinting at the gotcha/limbo nature) since Epic 4 authors real prose later.
- [x] Task 5: Swift Testing coverage (AC: #5) — add to `ForkedEchoesTests/StoryRunEngineTests.swift`, following this file's existing `freshDefaults()`/`defer { removePersistentDomain }` pattern used by every test in the suite
  - [x] A test proving `selectChoice(gotcha)` from `.firstChoice` lands the engine on `.endingHardFail` with `phase == .ending` **immediately** — no `advancePage()` call in between. This is the direct regression test for AC #3.
  - [x] A test proving the hard-fail node is reached only via its designated option: selecting any other `.firstChoice` option (`.boat`, `.shore`, or the new limbo option) never results in `currentNodeId == .endingHardFail`. (`EndingKind` presence itself needs no test — Task 1's non-optional field makes it a compile error to omit, per AC #5's own note.)
  - [x] A test proving `.endingLimbo` and `.endingHardFail` both clear the persisted `RunSnapshot` on arrival, exactly like the existing `reachingAnEndingNodeClearsTheStoredSnapshot` test does for `.endingHomeward` — this is AC #7's traceability, though note in Dev Notes below that the clearing behavior itself is **already implemented and generic** (see `persistOrClearSnapshot()`'s `case .ending` branch), so this task only needs a new test case, not an engine code change.
- [x] Task 6: Manual verification (`swift test`, not Xcode/Simulator — this story has no UI) — run `swift test` from the repo root and confirm the full suite passes with the new tests included; record the pass count in Completion Notes (project-context.md Process Agreement).

### Review Findings

- [x] [Review][Patch] No test asserts a terminal node's `EndingPayload.kind` is the *correct* value — only `NodeID` reachability/phase is tested, so a swapped/wrong `EndingKind` (e.g. `.endingHardFail` assigned `.home`) would compile cleanly and the full 69-test suite would still pass, silently defeating AC #1/#2/#5's actual purpose. [ForkedEchoes/Content/StoryTree.swift:103-115]
- [x] [Review][Patch] `.driftLimbo`'s `alignmentDelta` is `0`, contradicting Task 3's explicit "give both new options non-zero placeholder alignmentDelta values" requirement and the pre-existing comment above the options array ("Non-zero placeholder deltas to exercise alignmentScore accumulation in tests") — doesn't affect ending-resolution correctness (AD-6) but is a clear content-authoring inconsistency this story's own task called for. [ForkedEchoes/Content/StoryTree.swift:78-83]
- [x] [Review][Patch] `onlyTheGotchaChoiceReachesTheHardFailEnding` bundles three independent scenarios (`.boat`, `.shore`, `.driftLimbo`) into one `@Test` with copy-pasted `freshDefaults()`/`defer` boilerplate per scenario — a failure on the first assertion masks whether the other two would also fail, and the test report won't distinguish which sub-case broke. [ForkedEchoesTests/StoryRunEngineTests.swift]
- [x] [Review][Patch] Dev Notes/Task 6 frame this story as having "no new View code"/no UI impact, but `firstChoice`'s rendered choice-card count grew from 2 to 4 via the existing `StoryChoiceView`/`ChoiceCardView` — a real, currently-shipping screen whose content just changed. No manual Simulator verification was requested, contrary to project-context.md's Process Agreement to explicitly ask for an Xcode/Simulator check whenever a change touches app-rendered content. Nothing in `ChoiceCardView`/`StoryChoiceView` hardcodes an option count (`ForEach` is generic), so this isn't a proven bug — but per project convention it needs an explicit verification ask, not a "no UI impact" framing. [_bmad-output/implementation-artifacts/3-1-ending-kind-resolution.md Dev Notes]
- [x] [Review][Defer] `sprint-status.yaml`'s `last_updated` field keeps growing unboundedly — this diff's own status-update entry appends yet another multi-thousand-character narrative onto a field a prior retrospective already flagged as a known, deferred, pre-existing problem. Not caused by this diff, just continued. [_bmad-output/implementation-artifacts/sprint-status.yaml] — deferred, pre-existing

## Dev Notes

### This story adds no new View code, but it does change what an existing screen renders

Per the implementation-readiness report and the epic intro, Story 3.1's whole job is making `AD-5`'s phase-derivation reach `.ending` meaningfully — no `EndingView` exists yet (that's Story 3.2). Do not create any `Views/Ending/` files in this story; a `.gitkeep` there or a stub view is explicitly out of scope. `EndingPayload` does **not** need a `bodyKey` — that's Story 3.2's job, when it renders outcome-specific text keyed off `EndingKind`.

**Correction (code review, 2026-08-05):** "no UI impact" was an overstatement. `firstChoice`'s `options` array grew from 2 to 4 (Task 3), and it renders through the existing, currently-shipping `StoryChoiceView`/`ChoiceCardView` (`.choice` case, `ForEach(options, id: \.id)` inside a `VStack`) — a real screen's rendered content changed, even though no View file was touched. `ForEach`/the surrounding `VStack` are generic (no hardcoded option count), so there's no specific reason to expect breakage, but per project-context.md's Process Agreement ("actively request the user's Xcode/Simulator check... at the end of every session that touches app code — don't just passively note it's unverified"), this needed an explicit ask rather than a "no UI impact" framing. **Please check in Xcode/Simulator:** open the choice page at `.firstChoice` (4 cards now, including longer placeholder copy) at at least one accessibility Dynamic Type size, and confirm all four cards render, are tappable, and don't clip/overflow.

### The Ending-clears-snapshot behavior (AC #7) is already implemented — don't reimplement it

`StoryRunEngine.persistOrClearSnapshot()` (Engine/StoryRunEngine.swift) already has a generic `if case .ending = StoryTree.node(for: currentNodeId)` branch that clears the snapshot, written back in Story 2.4/2.9 for the two placeholder endings that already exist (see `reachingAnEndingNodeClearsTheStoredSnapshot` test). Because this branch matches on `.ending` generically (not per-specific-node), it already covers the two *new* terminal nodes this story adds with zero code change. Task 5's third test exists to give the new nodes their own explicit traceability per NFR3/AD-7's citation in AC #7 — not because the behavior is missing. Do not add a second/duplicate clearing code path "to be safe."

### AC #3's immediate-transition behavior is also already implemented — same caution applies

`StoryRunEngine.phase` derives purely from `StoryTree.node(for: currentNodeId)` (Engine/StoryRunEngine.swift, the `phase` computed property), and `selectChoice(_:)` sets `currentNodeId = option.target` synchronously before returning. This means selecting an option whose `target` is an `.ending` node already produces `phase == .ending` the instant `selectChoice(_:)` returns, generically, for any target — no per-ending-kind special-casing exists or is needed anywhere in the engine. This story's job for AC #3 is purely a **content-authoring** one: wire a gotcha choice whose target is a hard-fail node one hop away from a choice node, so the existing generic behavior is exercised and tested. Resist the urge to add an explicit "if target is hardFail, transition immediately" branch to `selectChoice(_:)` — it would be dead code duplicating what `phase`'s derivation already guarantees.

### Existing tree/tests you must not break

`ForkedEchoesTests/StoryRunEngineTests.swift` has ~40 existing tests, many of which hard-code exact paths through the current tree (`.firstChoice` → `.boat` → `.boatEcho` → `.endingHomeward`; `.firstChoice` → `.shore` → `.shoreArrival` (interstitial) → `.endingElsewhere`). This story's changes must be strictly additive to `firstChoice.options` (two new options appended) and must not alter `.boat`'s or `.shore`'s existing targets, alignment deltas, or the `.boatEcho`/`.shoreArrival` nodes in between. Run `swift test` after Task 3's tree changes, before writing any new tests, to confirm nothing existing broke from adding the `kind:` argument to the two pre-existing `EndingPayload(...)` call sites.

### `EndingPayload`'s existing doc comment already anticipated this story

`StoryNode.swift`'s comment above `EndingPayload` (line ~19-22) says it's "struct-backed ... so Story 3.1 can add an `EndingKind` field here later without breaking existing `case .ending(let payload):` call sites — a positional second associated value would break their arity, a new struct field with a default does not." Note the discrepancy: that comment describes a *defaulted* field, but Task 1 above calls for a **non-optional, non-defaulted** field instead, specifically so the compiler forces every terminal node's authoring site to supply a kind (this is the mechanism that makes AC #1/#4/#5's "compiler-guaranteed" claim literally true). This is a deliberate correction to that comment's original plan, not an oversight — update the comment itself when you touch this file so it describes what's actually implemented, not the discarded defaulted-field approach.

### Architecture citations

- **AD-1** (Content structure is a compiled Swift tree): terminal-node exhaustiveness and the "no representable dead end" guarantee are what Task 1's non-optional `kind` field leans on.
- **AD-6** (Ending kind is a direct property of the terminal node reached): this story *is* AD-6's implementation. "Alignment score plays no role in which terminal node a path reaches" — do not add any score-based branching anywhere in this story's engine or content changes.
- **AD-5** (phase is derived, not stored): `phase`'s existing generic `.ending` derivation is why Task 1-3 (content-only changes) are sufficient for AC #2/#3 — see the two caution notes above.
- **AD-4** (RunSnapshot persistence): AC #7's clearing behavior — see the dedicated note above.
- **AD-7/NFR3** (testing surface, corrected 2026-08-05 pre-implementation review): scope is "every terminal node resolves to exactly one `EndingKind`" (compiler-guaranteed, no test needed) + "hard-fail reachable only via its designated gotcha choice" + "immediate transition" (both need tests, Task 5) + existing pager-gating/round-trip coverage (untouched by this story).

### Project Structure Notes

- Files touched (all `UPDATE`, none `NEW`): `ForkedEchoes/Content/StoryNode.swift`, `ForkedEchoes/Content/NodeID.swift`, `ForkedEchoes/Content/StoryTree.swift`, `ForkedEchoes/Resources/Localizable.xcstrings`, `ForkedEchoesTests/StoryRunEngineTests.swift`.
- No `Package.swift` change needed — `Content`/`Engine` are already exposed as one target (project-context.md Environment section); this story doesn't add new source directories.
- No `.pbxproj` edit needed — no files added or removed, only existing files edited (project-context.md File organization section covers add/rename/delete only).

### Testing Standards Summary

- `swift test` from the repo root is the only way to actually execute this suite in this devcontainer (project-context.md Testing section) — `xcodebuild test` is unavailable here.
- Every new test must use the existing `freshDefaults()` / `defer { defaults.removePersistentDomain(forName: suiteName) }` pattern already used by all ~40 tests in `StoryRunEngineTests.swift` — do not write to `.standard`.
- No Xcode/Simulator manual-verification AC applies to this story — it's engine/content-only, no UI. Task 6's `swift test` run is this story's complete verification.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

`swift test` run 4x total during implementation: once immediately after Task 3's tree changes (before any new tests existed) to confirm the pre-existing 65 tests were untouched, then 3 consecutive full runs after Task 5's new tests were added — 69/69 passing every time, 0 flakes.

### Completion Notes List

- `EndingKind` (home/stay/limbo/hardFail) added as a **non-optional, non-defaulted** field on `EndingPayload` (Content/StoryNode.swift) — deliberately not following the defaulted-parameter pattern `.reading`'s `echoBodyKey`/`arrival` used, since every existing `EndingPayload(nodeId:)` call site needed to become a compile error until it supplied a kind. This is what makes "every terminal node resolves to exactly one `EndingKind`" a compiler guarantee (AD-1/AD-6/AC #1/#4/#5), not a runtime check. Updated `EndingPayload`'s doc comment to describe this, correcting its earlier note (written during Story 2.1) that anticipated a defaulted field.
- AC #2 (ending read directly from the terminal node's `EndingKind`, no computation) and AC #3 (immediate `selectChoice(_:)`-to-Ending transition) required **zero engine code changes** — `StoryRunEngine.phase`'s existing generic `case .ending` derivation and `selectChoice(_:)`'s synchronous `currentNodeId` assignment already produce both behaviors for any terminal node, including the two new ones this story adds. Likewise AC #7 (RunSnapshot cleared on reaching Ending) was already generically implemented in `persistOrClearSnapshot()`'s `case .ending` branch (from Story 2.4/2.9). This story's actual work was content-tree wiring (Tasks 1-4) plus new tests giving the new nodes their own explicit traceability (Task 5) — confirmed via `swift test` both before and after, with no regressions.
- Extended the placeholder tree (`StoryTree.swift`) with two new terminal nodes reached directly from `firstChoice`: `.endingHardFail` (via the new designated gotcha choice, `ChoiceOptionID.gotcha`) and `.endingLimbo` (via `.driftLimbo`). Both are one hop from `firstChoice`, satisfying AC #3's "immediate transition, no intervening `advancePage()`" requirement directly. The pre-existing `.endingHomeward`/`.endingElsewhere` (now `.home`/`.stay`) and everything on the `.boat`/`.shore` paths leading to them are completely untouched — verified by running the full pre-existing 65-test suite immediately after the tree edit, before writing any new tests.
- Added `story.firstChoice.choice.3`/`.4` to `Localizable.xcstrings`, placed immediately after `.choice.2` (alphabetical order preserved), each with `comment`/`extractionState: "manual"`/translated `en` `stringUnit`, matching the existing two entries' shape exactly. Validated with `python3 -m json.tool`.
- 4 new Swift Testing cases added to `StoryRunEngineTests.swift`, all using the existing `freshDefaults()`/`defer { removePersistentDomain }` isolation pattern: immediate hard-fail transition, hard-fail-reachable-only-via-gotcha (checked against all three other `firstChoice` options), and snapshot-clearing for both new endings.
- **`swift test` result: 69/69 passing** (65 pre-existing + 4 new), confirmed across 3 consecutive full runs post-implementation, 0 flakes.
- This story is engine/content-only, per its own scope (no `EndingView` — that's Story 3.2); **correction below** narrows this to "no new View *code*," not "no UI impact."

**Code review, 2026-08-05 — 4 patches applied:**

- `EndingKind` given `Equatable` conformance, and a new test (`eachTerminalNodeResolvesToItsAuthoredEndingKind`) added asserting each of the four terminal nodes' `EndingPayload.kind` matches what `StoryTree.swift` actually authors — closes the gap where only `NodeID` reachability was tested, not `EndingKind` correctness (the compiler guarantees a kind is *present*, never that it's the *correct* one).
- `.driftLimbo`'s `alignmentDelta` changed from `0` to `2`, matching Task 3's own "non-zero placeholder deltas" requirement, which this option had violated.
- `onlyTheGotchaChoiceReachesTheHardFailEnding` (one `@Test` bundling three scenarios) split into three independent tests (`selectingBoatNeverReachesTheHardFailEnding`, `selectingShoreNeverReachesTheHardFailEnding`, `selectingDriftLimboNeverReachesTheHardFailEnding`) so a failure identifies exactly which option's targeting broke.
- Corrected the "no UI impact" framing in Dev Notes — `firstChoice` now renders 4 choice cards instead of 2 through the existing `StoryChoiceView`/`ChoiceCardView`. **A manual Xcode/Simulator check is requested**: open the `.firstChoice` choice page (4 cards, longer placeholder copy) at an accessibility Dynamic Type size and confirm all four cards render, are tappable, and don't clip/overflow. Not yet performed — please run this check and report back.

**`swift test` result after patches: 72/72 passing** (69 prior + 1 new kind-correctness test + 2 net from the 1-test-split-into-3), confirmed across 3 consecutive full runs, 0 flakes.

**Manual Xcode/Simulator verification confirmed by user, 2026-08-05:** Xcode build and `swift test` both succeeded; on the Simulator, `firstChoice` renders all 4 choice cards, and selecting either of the two new options (the gotcha hard-fail choice or the limbo choice) correctly navigates straight to the Ending placeholder page — confirming AC #3's immediate-transition behavior end-to-end on a real build, not just in the engine-level test suite.

### File List

- `ForkedEchoes/Content/StoryNode.swift` (UPDATE) — added `EndingKind` enum, non-optional `kind` field on `EndingPayload`, two new `ChoiceOptionID` cases (`gotcha`, `driftLimbo`)
- `ForkedEchoes/Content/NodeID.swift` (UPDATE) — added `endingLimbo`, `endingHardFail` cases
- `ForkedEchoes/Content/StoryTree.swift` (UPDATE) — assigned `EndingKind` to all four terminal nodes, added two new terminal-node cases and two new `firstChoice` options, updated header comment
- `ForkedEchoes/Resources/Localizable.xcstrings` (UPDATE) — added `story.firstChoice.choice.3`/`.4`
- `ForkedEchoesTests/StoryRunEngineTests.swift` (UPDATE) — added 4 new Swift Testing cases
- `_bmad-output/implementation-artifacts/3-1-ending-kind-resolution.md` (UPDATE) — this story file
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (UPDATE) — status tracking
