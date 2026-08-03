---
baseline_commit: 8d64e22
---

# Story 2.10: Persist Back-Navigation Across App Relaunch

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to swipe back through pages I've already read even after force-quitting and relaunching the app,
so that resuming a run doesn't strand me on a forward-only path.

*(Follow-up gap surfaced during Story 2.9 Simulator testing, 2026-08-02 — deferred by explicit user decision rather than blocking Story 2.9. Pre-existing since Story 2.4: `StoryRunEngine.visitedNodeIds`, the back-navigation stack `goBack()` pops, has never been part of `RunSnapshot` — `resumingFromSnapshot(defaults:)`'s own doc comment documents an empty post-resume back-stack as "an accepted, deliberate consequence" of `RunSnapshot`'s original four-field shape. In practice this means `goBack()` is silently a no-op immediately after any relaunch, on every page in the app, until the player advances forward at least once in the new session — not specific to the branch-arrival interstitial, just first surfaced there. See `sprint-status.yaml`'s `epic: 2` action item for the same gap, recorded 2026-08-02.)*

## Acceptance Criteria

1. **Given** a mid-run `RunSnapshot` persisted before the app terminates, at a node reached via one or more forward page-turns from earlier in the run
   **When** the app relaunches and resumes from that snapshot
   **Then** `goBack()` can navigate backward through those same previously-visited pages exactly as it could before the relaunch — not silently a no-op until the player advances forward again first

2. **Given** `RunSnapshot`'s schema
   **When** extended to carry whatever backward-navigation history this story needs
   **Then** it decodes gracefully (a sensible default, not a rejected/corrupted snapshot) for any snapshot written before this story ships, which has no such field — mirroring Story 2.9's `visitedArrivalNodeIds` precedent for extending the snapshot schema

3. **Given** the branch-arrival interstitial (Story 2.9)
   **When** its own dismissal-persistence and revisit-rendering behavior is exercised together with this story's fix
   **Then** nothing regresses: a dismissed arrival node still renders ungated on any revisit, including a relaunch-then-`goBack()`-into-it path this story newly makes reachable

4. **And** a Swift Testing case verifies: a snapshot capturing a multi-step-forward run position, when resumed via `resumingFromSnapshot(defaults:)` on a freshly-constructed engine, supports `goBack()` navigating backward through that history correctly — not just forward (AD-7, NFR3)

5. **And** a manual-verification AC: in Xcode/Simulator, advance forward through at least two pages, force-quit, relaunch, tap "Resume Story," and confirm swiping/tapping backward now works through the pages visited before the relaunch, not just forward. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

## Tasks / Subtasks

- [x] Task 1: Add persisted back-navigation history to `RunSnapshot` (AC #1, #2, #4)
  - [x] Added `visitedNodeIds: [NodeID] = []` to `ForkedEchoes/Engine/RunSnapshot.swift`, mirroring `StoryRunEngine.visitedNodeIds`'s ordered-stack shape.
  - [x] Extended the existing custom `Codable` implementation: `decodeIfPresent(...) ?? []` in `init(from:)`, added to `CodingKeys` and `encode(to:)`.
  - [x] Updated the struct's top-of-file doc comment to describe the sixth field and Story 2.10.
  - [x] No content-tree-drift validation added to `loadValid(from:)` for this field, per the `visitedArrivalNodeIds` precedent.

- [x] Task 2: Wire the persisted history through `StoryRunEngine` (AC #1, #3, #4)
  - [x] `resumingFromSnapshot(defaults:)` now seeds `engine.visitedNodeIds = snapshot.visitedNodeIds`.
  - [x] `persistOrClearSnapshot()`'s `RunSnapshot(...)` construction now passes `visitedNodeIds: visitedNodeIds`.
  - [x] Updated the stale "not part of RunSnapshot / accepted deliberate consequence" doc comments on `resumingFromSnapshot(defaults:)` and the `visitedNodeIds` property itself to describe the new persisted behavior.
  - [x] Verified `resetRunState()` already clears `visitedNodeIds = []`; added a regression test (Task 3) proving the clear propagates to the next persisted snapshot.

- [x] Task 3: Swift Testing coverage (AC #4)
  - [x] Added `resumedEngineCanNavigateBackwardThroughPersistedHistory` (`StoryRunEngineTests.swift`): a snapshot at `.shoreArrival` reached via `[.intro, .firstChoice]`, resumed on a fresh engine, `goBack()`s through the full persisted history back to `.intro`, then confirms a further `goBack()` is a no-op (stack exhausted).
  - [x] Added `startingAFreshRunAfterEndingClearsPersistedBackNavigationHistoryOnNextSnapshotWrite`, mirroring Story 2.9's `startingAFreshRunAfterEndingClearsPersistedArrivalVisitationOnNextSnapshotWrite` pattern for this field.
  - [x] Added `resumedEngineComposesPersistedBackStackWithDismissedArrivalState` (AC #3): drives a real engine through dismissing `.shoreArrival`, advancing past it, and backing up to it once (the only way to leave a genuinely resumable non-ending on-disk snapshot in the current placeholder tree — reaching the ending itself clears the snapshot, AC #5), then resumes a **fresh** engine instance from that on-disk state and confirms it lands on the dismissed arrival node ungated (composing correctly with Story 2.9) and that `goBack()` from there still walks further back through this story's persisted history. (An earlier draft of this test hand-constructed a snapshot with `currentNodeId: .endingElsewhere` directly — `RunSnapshot.loadValid(from:)` correctly rejects any snapshot pointing at an ending node per AC #5's own intent, which silently fell back to a fresh root engine and failed the test; the real-engine-driven approach above is the fix, and also more faithful to an actual player flow.)
  - [x] Added `RunSnapshotTests.decodingASnapshotWithoutTheVisitedNodeIdsKeyDefaultsToEmpty` and extended `encodeDecodeRoundTripPreservesAllFields` to cover the new field.
  - [x] `swift test` from repo root: 58/58 passing (net +4 new tests, 0 removed/replaced — purely additive, as expected).

- [x] Task 4: Manual verification (AC #5)
  - [x] Requested from user (see Completion Notes List) — this devcontainer has no Xcode/Simulator and cannot verify a real build or run.
  - [x] Result recorded in Completion Notes List, 2026-08-03: primary AC #5 case (advance ≥2 pages, force-quit, relaunch, swipe backward) confirmed working by user. Story 2.9's cross-relaunch arrival-node-revisit re-confirmation was not testable against the current placeholder content tree — see Completion Notes for the full explanation; that composition is covered by the automated `resumedEngineComposesPersistedBackStackWithDismissedArrivalState` test instead.

## Dev Notes

### What already exists — do not re-create any of this

This story is narrowly scoped: extend `RunSnapshot`'s schema by one field and wire it through two existing methods. It follows the exact precedent Story 2.9 set for extending `RunSnapshot` — read that story's Dev Notes and Completion Notes in full (linked below) before starting; the shape of the fix here is structurally identical, just for a different field.

`ForkedEchoes/Engine/RunSnapshot.swift` (primary edit target):
- Currently 5 fields (`currentNodeId`, `choiceHistory`, `alignmentScore`, `tutorialSeen`, `visitedArrivalNodeIds`), all `Codable` via a **custom** `init(from:)`/`encode(to:)` (not synthesized) specifically so `visitedArrivalNodeIds` can default to `[]` on a missing key. This story adds a sixth field the same way — extend the existing custom `Codable`, do not add a second parallel mechanism.
- `loadValid(from:)` validates `choiceHistory` entries still resolve against the current `StoryTree` (content-tree-drift rejection) but does no such validation for `visitedArrivalNodeIds` — `visitedNodeIds` (this story's new field) should follow the `visitedArrivalNodeIds` precedent (no drift validation needed), not the `choiceHistory` one; see Task 1's callout on why.

`ForkedEchoes/Engine/StoryRunEngine.swift` (primary edit target):
- `visitedNodeIds: [NodeID]` (private stored property, currently ~line 66) is the **existing, unrelated-by-name-collision-risk-only** back-navigation stack — already fully implemented: `selectChoice(_:)` and `advancePage()` both `.append(currentNodeId)` before moving forward, `goBack()` does `.popLast()`. This story does NOT change any of that push/pop logic — it only makes the *existing* stack survive a relaunch by (a) reading it from the snapshot in `resumingFromSnapshot(defaults:)` and (b) writing it in `persistOrClearSnapshot()`. Do not confuse this with `RunSnapshot.visitedArrivalNodeIds` (Story 2.9's field, a `Set`, tracking dismissed interstitials) — same naming-adjacent gotcha Story 2.9's own Dev Notes warned about in reverse.
- `resumingFromSnapshot(defaults:)` (~line 92-111) and `persistOrClearSnapshot()` (~line 269-289) are the two edit sites — both already exist and already handle every other field the same way this story's field needs to be handled. Follow the exact pattern already used for `choiceHistory`/`alignmentScore` (simple assignment on resume, simple pass-through on persist) — no special-casing needed, unlike `visitedArrivalNodeIds`'s Set-based dismissal semantics.
- `resetRunState()` (~line 249) already clears `visitedNodeIds = []` — this was already correct before this story (it resets the in-memory stack for a fresh run); this story doesn't need to touch it, only verify + test that the clear now also propagates to disk via the next `persistOrClearSnapshot()` call, since previously there was no persisted field for it to propagate to.

`ForkedEchoesTests/StoryRunEngineTests.swift` — 49 tests as of Story 2.9's final Change Log entry. Existing fixtures already construct multi-step `RunSnapshot`s and drive `resumingFromSnapshot(defaults:)` against `.intro`/`.firstChoice`/`.shoreArrival`/`.boatEcho` — reuse those patterns rather than inventing new ones.

`ForkedEchoesTests/RunSnapshotTests.swift` — has the exact backward-compat-decode pattern to mirror (`decodingASnapshotWithoutTheVisitedArrivalNodeIdsKeyDefaultsToEmpty`), including the hand-written legacy-JSON-literal technique. Story 2.9's Completion Notes flag a wire-format gotcha worth re-reading: `NodeID`'s synthesized `Codable` (no associated values) encodes as `{"caseName": {}}`, not a bare string — matters when hand-writing the legacy JSON literal for this story's own backward-compat test.

### Architecture compliance (AD-1, AD-3, AD-4, AD-5, AD-7)

- **AD-1**: no content-tree shape change — `NodeID` stays a closed enum, nothing here touches `StoryTree`/`StoryNode`.
- **AD-3**: `StoryRunEngine` remains the sole mutator; the new persisted field is populated only from the engine's existing private `visitedNodeIds` property (already only ever mutated within the engine's own intent methods), never written from the View layer.
- **AD-4**: this is the second story (after 2.9) to grow `RunSnapshot` beyond its originally-declared field count — again an explicit, documented exception via the same backward-compatible-decode mechanism, not accidental drift. Update the struct's own doc comment (Task 1) the same way Story 2.9 did.
- **AD-5**: no phase-derivation change — `phase` is unaffected by this story; only `goBack()`'s reachable history changes, not what any node's phase derives to (AC #3 explicitly guards against unintended interaction with Story 2.9's phase logic).
- **AD-7**: extends `StoryRunEngineTests.swift`'s existing Swift Testing surface (same file, same `@testable import ForkedEchoes` pattern) rather than introducing a new testing category.

### Testing standards summary

- Swift Testing (`import Testing`), `@testable import ForkedEchoes`. Extend `StoryRunEngineTests.swift` and `RunSnapshotTests.swift` (both existing scope, no new test files).
- No UI test target exists — the actual swipe/tap-driven backward navigation has no automated coverage; Task 4's manual Simulator check is the only verification for the real force-quit/relaunch case this story exists to fix, same as Story 2.9's own force-quit-relaunch verification gap.
- `swift test` from repo root genuinely builds/runs this suite in this devcontainer (project-context.md Environment section) — report the new total against Story 2.9's 49/49 baseline.

### Project Structure Notes

- Modified (expected, no new files): `ForkedEchoes/Engine/RunSnapshot.swift` (new field, custom Codable extension), `ForkedEchoes/Engine/StoryRunEngine.swift` (wire existing `visitedNodeIds` into resume/persist, doc-comment corrections), `ForkedEchoesTests/StoryRunEngineTests.swift`, `ForkedEchoesTests/RunSnapshotTests.swift`.
- No new files anticipated — this is a narrow schema-and-wiring extension to existing Story 2.4/2.9 components, not new surface area. `Package.swift` unaffected (no new SwiftPM-covered source files; both touched Engine files are already covered).
- No View-layer changes anticipated — `goBack()`'s call sites (swipe/tap gesture handlers in `StoryChoiceView.swift`) already call the engine method unconditionally; they don't need to know whether the underlying stack came from a fresh session or a resumed snapshot. If implementation reveals a View-layer touch point is actually needed, treat that as a signal to re-read this Dev Notes section — it wasn't anticipated by design.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.10: Persist Back-Navigation Across App Relaunch]
- [Source: _bmad-output/implementation-artifacts/2-9-branch-arrival-interstitial-first-visit-only-gate.md] (direct precedent for extending `RunSnapshot`'s schema with a backward-compatible field — same mechanism this story reuses; also the source of the deferred action item this story resolves, see its Completion Notes' final entry and Change Log's final entry)
- [Source: ForkedEchoes/Engine/RunSnapshot.swift] (current 5-field shape, custom `Codable`, `loadValid(from:)` — read in full before editing)
- [Source: ForkedEchoes/Engine/StoryRunEngine.swift] (current `visitedNodeIds` private stack, `resumingFromSnapshot(defaults:)`, `persistOrClearSnapshot()`, `resetRunState()`, `goBack()` — read in full before editing)
- [Source: ForkedEchoesTests/StoryRunEngineTests.swift] (existing 49 tests, multi-step-forward fixtures to reuse)
- [Source: ForkedEchoesTests/RunSnapshotTests.swift] (backward-compat-decode pattern and `NodeID` JSON wire-format gotcha to reuse)
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml#action_items] (the `epic: 2` action item this story exists to close)
- [Source: _bmad-output/project-context.md#Process Agreements (from retrospectives)] (Xcode/Simulator manual-verification request requirement, applied in Task 4)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swiftc -parse` on every touched `Engine/`/`Content/` file and both touched test files — clean, no syntax errors.
- `swift build` — clean.
- `swift test` from repo root — 58/58 passing (net +4 new tests over baseline, 0 removed/replaced).

### Completion Notes List

- Implemented per Dev Notes exactly as scoped: added `RunSnapshot.visitedNodeIds: [NodeID]` (sixth field, backward-compatible custom `Codable` decode, no content-tree-drift validation — mirrors Story 2.9's `visitedArrivalNodeIds` precedent) and wired it through `StoryRunEngine.resumingFromSnapshot(defaults:)` (seed) and `persistOrClearSnapshot()` (write). No new files; no View-layer changes were needed, as anticipated.
- One test-design correction during implementation: an initial draft of the AC #3 composition test (`resumedEngineComposesPersistedBackStackWithDismissedArrivalState`) hand-constructed a `RunSnapshot` with `currentNodeId: .endingElsewhere` to simplify the fixture — this fails, because `RunSnapshot.loadValid(from:)` correctly rejects any snapshot pointing at an ending node (AC #5's own "nothing to resume" contract), so `resumingFromSnapshot(defaults:)` silently fell back to a fresh root engine instead of the intended dismissed-arrival state, and the test's assertion caught it immediately. Rewrote the test to drive a real prior-session `StoryRunEngine` through the actual dismiss → advance → back-up sequence and read its genuinely-written on-disk snapshot, rather than hand-authoring an invalid one — this is also more faithful to an actual player flow. See Task 3's checklist entry for the full trace.
- **Xcode/Simulator manual verification, user-confirmed 2026-08-03** (AC #5, project-context.md Process Agreement): the literal AC #5 scenario — advance forward through at least two pages from Home, force-quit, relaunch, tap "Resume Story," swipe/tap backward — **confirmed working**, closing the gap this story exists to fix.
- **Story 2.9 cross-relaunch arrival-node-revisit case: not manually testable against the current placeholder content tree, same known gap Story 2.9's own Completion Notes documented.** User's report: `.shoreArrival`'s only forward path is directly to an ending (`.endingElsewhere`) — force-quitting *after* tapping Continue means the run is already finished on relaunch (nothing to swipe back through), and force-quitting *before* tapping Continue (mid-interstitial) correctly re-gates on relaunch, but a gated interstitial blocks all navigation until Continue is tapped, so there's still no reachable state that exercises "swipe back into an already-dismissed arrival node after a fresh relaunch." This is not a gap introduced or left unfixed by this story — it's the identical placeholder-content-tree limitation Story 2.9 hit and worked around by testing the reverse order (back up before force-quitting, not after). This story's own automated coverage closes the loop instead: `resumedEngineComposesPersistedBackStackWithDismissedArrivalState` (Task 3) drives a real engine through dismiss → advance → back-up, resumes a **fresh** engine instance from the genuinely-written on-disk snapshot, and confirms the dismissed arrival node still renders ungated — the exact mechanism this manual case would have exercised, verified at the engine level since the content tree can't support it at the UI level yet. A real Epic 4 tree with content past the arrival node will make this manually reachable without a workaround, same as Story 2.9 noted for its own equivalent gap.

### File List

- Modified: `ForkedEchoes/Engine/RunSnapshot.swift`
- Modified: `ForkedEchoes/Engine/StoryRunEngine.swift`
- Modified: `ForkedEchoesTests/StoryRunEngineTests.swift`
- Modified: `ForkedEchoesTests/RunSnapshotTests.swift`

## Change Log

- 2026-08-03: Story 2.10 created via create-story workflow, on branch `2-10-persist-back-navigation-across-app-relaunch`. Scoped narrowly to extending `RunSnapshot` with a persisted `visitedNodeIds` back-navigation stack, mirroring Story 2.9's `visitedArrivalNodeIds` precedent exactly — same backward-compatible-decode mechanism, same two engine wiring sites (`resumingFromSnapshot(defaults:)`, `persistOrClearSnapshot()`), no new files or View-layer changes anticipated.
- 2026-08-03: Story 2.10 implemented — added `RunSnapshot.visitedNodeIds` (backward-compatible decode), wired it through `resumingFromSnapshot(defaults:)`/`persistOrClearSnapshot()`, corrected the now-stale "unpersisted, deliberate consequence" doc comments this story's own fix removes, and added 4 new Swift Testing cases (58/58 passing). No View-layer changes needed. Xcode/Simulator manual verification (AC #5) requested from user, pending confirmation.
- 2026-08-03: User confirmed AC #5's literal scenario (advance ≥2 pages, force-quit, relaunch, swipe backward) works. The additional re-confirmation of Story 2.9's cross-relaunch arrival-node-revisit case was not manually reachable against the current placeholder content tree (`.shoreArrival` leads directly to an ending — same known gap Story 2.9's own Completion Notes documented) — that composition is instead covered by this story's `resumedEngineComposesPersistedBackStackWithDismissedArrivalState` automated test. All of this story's own AC now considered satisfied. Status set to `review`; ready for `code-review`.
