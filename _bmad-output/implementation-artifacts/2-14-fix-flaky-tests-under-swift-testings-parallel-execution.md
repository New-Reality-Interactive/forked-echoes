---
baseline_commit: fbdfd3c
---

# Story 2.14: Fix Flaky Tests Under Swift Testing's Parallel Execution

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer running `swift test`,
I want the engine-logic test suite to pass reliably every run,
so that a red run always means a real regression, never noise I have to explain away or rerun past.

*(Bug surfaced during Story 2.13's own `swift test` verification, 2026-08-04 — repeated runs intermittently failed `observerRefreshPicksUpASnapshotWrittenAfterConstruction` (`RunSnapshotPresenceTests.swift`), `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, and `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately` (`StoryRunEngineTests.swift`) — none of them touched by Story 2.13's changes, and none new. Confirmed pre-existing, not a 2.13 regression, by `git stash`-ing 2.13's diff and rerunning the unmodified baseline suite repeatedly (no failures observed in that particular sample, but the failure signature is unrelated to anything 2.13 touched, and the same shape of failure recurred on 2.13's branch across ~10 runs). Every failure observed so far has the same shape: a value just written to a `UserDefaults(suiteName:)` instance isn't visible on an immediate subsequent read from that same instance — consistent with a race under Swift Testing's default parallel execution, not a logic bug in the engine or in `RunSnapshotPresence`/`StoryRunEngine` themselves. `TestSupport.swift`'s `freshDefaults()` already mints a UUID-suffixed suite name per test specifically to avoid cross-test collisions (code review, 2026-08-01, Story 2.4) — this bug means that isolation isn't actually complete under Linux's `swift-corelibs-foundation` `UserDefaults` implementation, or isn't complete under concurrent access to it, and needs root-causing, not just a symptom-level retry.)*

## Acceptance Criteria

1. **Given** the full `ForkedEchoesTests` suite
   **When** `swift test` is run repeatedly from the repo root (at least 10 consecutive runs)
   **Then** every run passes with zero flaky failures — no test that was previously observed to intermittently fail (`observerRefreshPicksUpASnapshotWrittenAfterConstruction`, `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately`, or any other test sharing the same write-then-immediate-read-on-a-fresh-`UserDefaults`-suite shape) fails on any run

2. **Given** the root cause of the flakiness
   **When** it is investigated
   **Then** the investigation identifies why a `UserDefaults(suiteName:)` instance's own immediately-prior synchronous write is sometimes not visible on the very next read from that same instance under Swift Testing's parallel execution, despite each test using a unique UUID-suffixed suite name (`TestSupport.swift`'s `freshDefaults()`) — findings recorded in the story's Completion Notes List (project-context.md Process Agreement)

3. **Given** the fix
   **When** applied
   **Then** it addresses the actual race (e.g. serializing the affected UserDefaults-suite-creation/read/write sequence, disabling parallel execution only if genuinely unavoidable and justified in Completion Notes, or a correctness fix to how `freshDefaults()` isolates suites) rather than papering over it with retries, `sleep`s, or `.serialized` applied blanket across the whole suite without first understanding why isolation is failing

4. **Given** this story's own changes
   **When** complete
   **Then** all 64 pre-existing tests (60 before Story 2.13, plus 2.13's 4 new tests) still pass, with no test *logic* changed except what's needed to fix the race itself — this is an infrastructure/reliability fix, not a behavior change

5. **And** a verification AC: run `swift test` at least 10 consecutive times from the repo root and record the pass count (expect 10/10) in the story's Completion Notes List, alongside a one-line description of the actual root cause found

## Tasks / Subtasks

- [ ] Task 1: Reproduce and characterize the flakiness (AC #1, #2)
  - [ ] Read `ForkedEchoesTests/TestSupport.swift` in full (already loaded — see Dev Notes) before editing anything
  - [ ] Run `swift test` at least 10-15 times in a row from the repo root, capturing full output each time, to establish a reliable failure rate baseline and confirm which specific tests flake (this story's own investigation, not just the three named above — Story 2.13's dev agent only sampled ~10 runs and saw a slightly different failing test each time, always the same *shape*: a `UserDefaults(suiteName:)` write not visible on an immediate next read from that same instance)
  - [ ] For each flake observed, note: which test, what was written vs. what was read back, and whether Swift Testing's console output shows it running concurrently with other tests that also call `freshDefaults()` (Swift Testing parallelizes across `@Test` functions by default unless a suite/test opts into `.serialized` — confirm this is actually what's happening here, don't assume)
  - [ ] Do not fix anything yet in this task — the goal is a confident, written-down root-cause hypothesis before touching code (AC #2 requires this recorded regardless of what the eventual fix looks like)

- [ ] Task 2: Root-cause the isolation failure (AC #2)
  - [ ] Investigate whether `UserDefaults(suiteName:)` on Linux's `swift-corelibs-foundation` provides genuine per-suite-name isolation under concurrent access, or whether suite creation/lookup shares mutable global state (e.g. a shared `CFPreferences`-style cache/registry) that races when many `@Test` functions construct different suites concurrently — this is a plausible root cause given the failure shape (unrelated tests' values bleeding into each other), but confirm it rather than assuming it; check the installed Swift toolchain's `swift-corelibs-foundation` version/source if accessible in this devcontainer, or find authoritative documentation/known-issue references via WebSearch if the toolchain source isn't locally inspectable
  - [ ] Consider and rule out (or confirm) alternative causes before committing to a fix: e.g. `defaults.set(...)` on Linux not being fully synchronous despite the Darwin contract implying it is; `RunSnapshot.loadValid(from:)` or `RunProgressObserver` reading a cached/stale value rather than re-querying `UserDefaults`; test-process-level shared temp-file-backed storage for suite-named domains colliding on disk despite differing UUIDs
  - [ ] Record the confirmed root cause in this story's Completion Notes List in plain language, precise enough that a future story wouldn't need to re-investigate from scratch

- [ ] Task 3: Apply the targeted fix (AC #3)
  - [ ] Implement the fix that addresses the confirmed root cause from Task 2 — likely one of: a `TestSupport.swift` change that makes `freshDefaults()` genuinely race-free (e.g. serializing suite creation itself, or switching to a storage mechanism immune to the identified race), or a `.serialized` trait applied narrowly (e.g. per-suite or per-test-that-touches-UserDefaults, not blanket across the whole `ForkedEchoesTests` target) if targeted serialization turns out to be the only sound fix
  - [ ] Do not disable Swift Testing's parallel execution wholesale (e.g. a blanket `.serialized` on the whole test target, or a global concurrency-limiting flag) unless Task 2's investigation genuinely concludes that's the only correct fix — prefer fixing the isolation bug at its source so tests keep running in parallel and stay fast; if blanket serialization turns out to be the right call, justify why in Completion Notes (project-context.md Process Agreement's standard for any non-obvious tradeoff)
  - [ ] Do not add retries, sleeps, or other timing-based workarounds anywhere — those hide the race instead of fixing it and would violate AC #3 explicitly
  - [ ] If the fix touches `TestSupport.swift`, keep `freshDefaults()`'s existing call-site contract identical (`(defaults: UserDefaults, suiteName: String)` tuple, same `defer { defaults.removePersistentDomain(forName: suiteName) }` cleanup pattern used at all ~48 call sites in `StoryRunEngineTests.swift` and elsewhere) — this is a fix to how isolation is achieved, not a redesign of the test-support API surface everything else depends on

- [ ] Task 4: Verify the fix (AC #1, #4, #5)
  - [ ] Run `swift test` at least 10 consecutive times from the repo root; confirm 10/10 pass with zero flakes across the previously-identified failing tests and the suite as a whole
  - [ ] Confirm the full suite is still 64/64 tests (60 pre-2.13 + 2.13's 4 new) with no test logic changes beyond what Task 3 required
  - [ ] Record the pass count and the one-line root-cause summary in this story's Completion Notes List (AC #5)

## Dev Notes

### What already exists — read before touching anything

`ForkedEchoesTests/TestSupport.swift` (11 lines, read in full during Story 2.13's own investigation):
```swift
func freshDefaults() -> (defaults: UserDefaults, suiteName: String) {
    let suiteName = "ForkedEchoesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, suiteName)
}
```
This already exists specifically to avoid cross-test collisions (its own doc comment cites code review, 2026-08-01, Story 2.4: "a test never writes to the real `.standard` domain, which pollutes real app state and races other tests"). The bug this story exists to fix means that fix was necessary but not sufficient — collisions are still happening, just no longer against `.standard`, and no longer merely "state left over from a previous test" but an active read-after-write race between concurrently-running tests each using their own distinct suite name.

Every test file in `ForkedEchoesTests/` uses this same helper (~48 call sites in `StoryRunEngineTests.swift` alone, plus `RunSnapshotTests.swift` and `RunSnapshotPresenceTests.swift`) in the identical pattern:
```swift
let (defaults, suiteName) = freshDefaults()
defer { defaults.removePersistentDomain(forName: suiteName) }
// ... use `defaults` ...
```
Any fix should preserve this call-site shape exactly — this pattern is load-bearing across the whole test suite, not something to redesign as part of a flakiness fix.

### The three tests observed flaking (illustrative, not necessarily exhaustive — Task 1 re-characterizes)

- `RunSnapshotPresenceTests.swift`, `observerRefreshPicksUpASnapshotWrittenAfterConstruction()` — writes a snapshot via `defaults.set(...)`, calls `observer.refresh()`, then expects `observer.hasInProgressRun == true`. Observed failure: `false == true`.
- `StoryRunEngineTests.swift`, `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase()` (around line 562) — writes a `RunSnapshot` pointing at `.shoreArrival`, constructs `StoryRunEngine.resumingFromSnapshot(defaults:)`, expects `engine.currentNodeId == .shoreArrival`. Observed failure: resolved to `.intro` (`StoryTree.root`) instead — i.e. `RunSnapshot.loadValid(from:)` returned `nil`, so `resumingFromSnapshot` fell back to a fresh engine, exactly as it's designed to do on any decode/read failure (see `StoryRunEngine.swift`'s `resumingFromSnapshot(defaults:)` doc comment) — meaning the write that should have preceded this read wasn't visible yet.
- `StoryRunEngineTests.swift`, `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately()` (around line 421-438) — same shape: `defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)` immediately followed by `StoryRunEngine.resumingFromSnapshot(defaults: defaults)`, expecting `engine.currentNodeId == .firstChoice`. Observed failure: resolved to `.intro`.

All three share the exact same shape — write to a freshly-minted `UserDefaults(suiteName:)`, then immediately read from that same instance, and the read doesn't see the write. This is the concrete evidence Task 1/2 should build on, not a full description of every possible occurrence — different runs surfaced different individual tests failing (always this same shape), so Task 1's job is establishing the full, current picture before Task 2 commits to a specific cause.

### Environment (project-context.md)

This devcontainer has a Linux Swift toolchain (`swiftc`, Swift 6.3.3) but no Xcode/Apple SDKs. `swift test` genuinely builds and executes the `ForkedEchoesTests` suite here (not just parse-level checking) — see project-context.md's Environment section, "Exception — engine-logic Swift Testing suites genuinely run here, not just parse." This means Task 4's repeated `swift test` runs are real, meaningful verification in this environment, not something that needs Xcode/Simulator to confirm — unlike most other stories in this project, this one's manual-verification-style AC (#5) is fully executable in this devcontainer.

### Testing standards summary

- This is itself a testing-infrastructure story — there's no separate "add tests for this" task, because the verification *is* running the existing suite repeatedly and confirming stability (AC #1, #4, #5).
- Do not change what any test asserts — only how test isolation is achieved, if that's what the root cause calls for. If the eventual fix requires understanding Swift Testing's parallelization/traits API (e.g. `.serialized`), confirm current syntax/semantics against this project's Swift 6.3 toolchain rather than assuming based on older Swift Testing documentation — the API has evolved across Swift Testing's early releases.

### Project Structure Notes

- Expected modified: `ForkedEchoesTests/TestSupport.swift` (most likely), possibly individual test files if the fix requires per-test/per-suite serialization traits rather than a `TestSupport.swift`-level fix — exact scope depends on Task 2's root-cause finding.
- Explicitly **not** expected to change: any file under `ForkedEchoes/Engine/`, `ForkedEchoes/Views/`, or `ForkedEchoes/Resources/` — this is a test-target-only fix. If Task 2's investigation somehow finds the root cause is in production code (e.g. `RunSnapshotPresence`/`StoryRunEngine` themselves reading a cached value incorrectly), stop and reconsider scope before proceeding — that would be a different, more serious bug than what this story was written to describe.

### Previous Story Intelligence (Story 2.13)

- This story exists entirely because of an observation made during Story 2.13's Task 5 verification (`swift test` run repeatedly to confirm 2.13's own new tests). 2.13's dev agent confirmed the flakiness was pre-existing (not caused by 2.13's changes) by stashing 2.13's diff and rerunning the unmodified baseline — that specific baseline sample happened not to flake, but the failure signature recurred on 2.13's branch across further runs and involves tests untouched by 2.13. Treat "pre-existing, unrelated to 2.13" as confirmed context, not something this story needs to re-verify.
- 2.13 itself is a completed, working reference for this project's `swift test`/`freshDefaults()` conventions if a second example of the pattern is useful context — see `ForkedEchoesTests/StoryRunEngineTests.swift`'s `exitAndClearProgress*` tests (added by 2.13, all passing, never observed to flake themselves).

### References

- [Source: ForkedEchoesTests/TestSupport.swift] (edit target — `freshDefaults()`, the shared per-test isolation helper)
- [Source: ForkedEchoesTests/RunSnapshotPresenceTests.swift] (`observerRefreshPicksUpASnapshotWrittenAfterConstruction` — one of the observed-flaking tests)
- [Source: ForkedEchoesTests/StoryRunEngineTests.swift] (`anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately` — the other two observed-flaking tests; also the ~48-call-site precedent for `freshDefaults()`'s usage pattern that any fix must preserve)
- [Source: ForkedEchoes/Engine/StoryRunEngine.swift#resumingFromSnapshot(defaults:)] (the fallback-to-fresh-engine-on-any-read-failure behavior that makes this race manifest as "silently resolved to `.intro`" rather than a crash — read-only context, not an edit target)
- [Source: _bmad-output/project-context.md#Environment] (confirms `swift test` genuinely executes this suite in this devcontainer, not just parses it)
- [Source: _bmad-output/implementation-artifacts/2-13-run-options-sheet-exit-and-clear-progress.md] (the story whose own verification surfaced this bug — Debug Log References section documents the specific flaky runs observed)

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

## Change Log

- 2026-08-04: Story 2.14 created via create-story workflow. Scoped to root-causing and fixing pre-existing test flakiness discovered during Story 2.13's `swift test` verification — a write-then-immediate-read race on freshly-minted `UserDefaults(suiteName:)` instances under Swift Testing's parallel execution, affecting `observerRefreshPicksUpASnapshotWrittenAfterConstruction`, `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, and `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately` (and possibly others sharing the same shape). Test-infrastructure-only fix; no production code expected to change.
