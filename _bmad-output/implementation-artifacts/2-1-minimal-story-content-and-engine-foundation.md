---
baseline_commit: 3d23a74546435d6c6f5faa693383bd4e23958dd4
---

# Story 2.1: Minimal Story Content & Engine Foundation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a minimal placeholder Content tree and a StoryRunEngine skeleton,
so that later stories have real data and engine plumbing to build against.

## Acceptance Criteria

1. **Given** `Content/` needs data
   **When** a minimal `indirect enum` tree is authored
   **Then** it contains at least one reading node, one choice node with 2 options, and terminal placeholder ending nodes, per AD-1 (every case resolves to a choice or an ending; the tree never reconverges — no two paths merge back into a shared node)

2. **Given** the engine needs to exist
   **When** `StoryRunEngine` (`@Observable`) is created
   **Then** it exposes `selectChoice(_:)`, `advancePage()`, `goBack()`, and tracks `currentNodeId`, `choiceHistory`, `alignmentScore` in memory (persistence lands in Story 2.4 — no `UserDefaults` read/write in this story)

3. **Given** Home's placeholder destination (Story 1.2)
   **When** "Start Story"/"Resume Story" is activated
   **Then** it now navigates to a real, content-minimal Story/Choice view backed by `StoryRunEngine`, replacing the Story 1.2/2.1-interim `StoryChoicePlaceholderView` placeholder entirely (delete the placeholder type — nothing else references it)

4. **Given** the minimal placeholder tree includes terminal ending nodes, but Epic 3 (which implements phase-derivation for `.ending` and the real Ending screen) doesn't exist yet at this point in the build
   **When** the engine's current node is a terminal node
   **Then** the view renders a simple placeholder screen ("Run complete — Ending screen coming in Epic 3") instead of crashing or showing undefined content — a temporary stand-in Epic 3 Story 3.2 replaces, not a permanent behavior. Use `Text(verbatim:)` for this specific label (see Dev Notes — it is a dev-facing stand-in expected to be deleted in Epic 3, not authored story content, matching the precedent already set by `StoryChoicePlaceholderView.swift`'s own placeholder text)

5. **Given** `Content/` is a new top-level source directory (per the Structural Seed) that `StoryRunEngine` (in `Engine/`) must depend on
   **When** this story is complete
   **Then** the root `Package.swift` is updated so the real `Content` tree is actually included in what `swift test` builds and exercises in this devcontainer — not merely present on disk while silently excluded from the SwiftPM graph (see Dev Notes — this is a build-graph correctness requirement, not a suggestion)

6. **And** a Swift Testing suite (new file, `ForkedEchoesTests/StoryRunEngineTests.swift`) verifies the engine skeleton's basic contract (AD-7, NFR3 scope): the engine initializes with `currentNodeId` at the tree's designated root/start node and empty `choiceHistory`/zero `alignmentScore`; `selectChoice(_:)` appends to `choiceHistory`, accumulates the selected option's alignment delta into `alignmentScore`, and moves `currentNodeId` to that option's target node; `advancePage()`/`goBack()` move `currentNodeId` forward/backward across the minimal tree's linear reading segment. Run via `swift test` from the repo root (real execution in this devcontainer per `project-context.md`'s Environment section — not `swiftc -parse`). Full pager-gating/choice-permanence semantics are Story 2.2/2.3's job; this suite only proves the skeleton's state transitions are wired correctly, not the full FR-3/FR-5 rule set.

7. **Given** this devcontainer has no Xcode/Simulator access (see `project-context.md` Environment section)
   **When** AC #3 and AC #4 are verified
   **Then** each of the tree's three node kinds (reading, choice, ending) is confirmed to render without crashing via a dedicated `#Preview` per kind (each seeding `StoryRunEngine` with a different starting `currentNodeId`) at minimum; if/when Simulator access is available, tapping "Start Story"/"Resume Story" from Home is also confirmed to reach the real view (not placeholder text). Record what was actually checked (previews only, or previews + Simulator) and when, in this story's Completion Notes List — per the verification-reporting process agreement (`project-context.md` Process Agreements; Epic 1 sprint-demo follow-up, 2026-07-26).

## Tasks / Subtasks

- [x] Task 1: Define the Content tree and the minimal placeholder story (AC: #1, #5)
  - [x] Create `ForkedEchoes/Content/` (new top-level group, per Structural Seed — sibling to `App/`, `Engine/`, `Views/`, `Resources/`)
  - [x] Author `NodeID` as a `Hashable` Swift enum (not a raw `String`) — see Dev Notes: AD-1's "dangling reference is a compile error" guarantee depends on this
  - [x] Author the `indirect enum` story node type per AD-1: every case resolves to a choice node or an ending (terminal) node — no representable dead end
  - [x] Author the minimal placeholder tree: 1 reading node → 1 choice node (2 options) → 2 distinct terminal ending nodes (one per option) — satisfies "tree never reconverges"
  - [x] Wire each option's alignment delta as a field on the choice edge (AD-1) — placeholder value (e.g. `0`) is fine; the field must exist so Story 2.3 doesn't have to change the node shape
  - [x] Add this story's placeholder prose (reading body, 2 choice labels) to `Resources/Localizable.xcstrings` using the `story.<nodeId>.body` / `story.<nodeId>.choice.<n>` key convention (`ARCHITECTURE-SPINE.md` Consistency Conventions) — **plain dot-path keys** (`Text("story.introReading.body")`), per `project-context.md`'s Localization section, **not** the generated-symbol approach `ARCHITECTURE-SPINE.md`'s AD-2 describes (see RESOLVED CONFLICT in Dev Notes)
  - [x] Update `Package.swift`: add a `Content` target at path `ForkedEchoes/Content`, and add `dependencies: ["Content"]` to the existing `ForkedEchoes` (Engine) target, so the dependency direction matches the architecture diagram (Engine → Content) and `ForkedEchoesTests` transitively builds against the real tree
  - [x] Run `swift build` and `swift test` from the repo root and confirm both succeed (confirms AC #5's build-graph requirement, not just that the files exist on disk)

- [x] Task 2: Implement the `StoryRunEngine` skeleton (AC: #2)
  - [x] Create `ForkedEchoes/Engine/StoryRunEngine.swift`, `@Observable`, exposing `selectChoice(_:)`, `advancePage()`, `goBack()`, and in-memory `currentNodeId`, `choiceHistory`, `alignmentScore`
  - [x] No `UserDefaults`/`RunSnapshot` read or write anywhere in this file — that is Story 2.4's job; this story is memory-only state
  - [x] Views must only call these intent methods — never mutate `currentNodeId`/`choiceHistory`/`alignmentScore` directly from a View (AD-3)

- [x] Task 3: Wire the real Story/Choice view into navigation (AC: #3, #4)
  - [x] Create `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` — renders whatever the engine's `currentNodeId` currently resolves to (reading / choice / ending), no styling requirements yet (Story 2.8's job) and no page-turn/choice-selection gestures yet (Stories 2.2/2.3's job) — this story only proves the engine→view data flow
  - [x] Instantiate `StoryRunEngine` once (e.g. `@State private var engine = StoryRunEngine()` at `RootView`) and inject via `.environment(engine)` (AD-3 — single owner, injected via `@Environment`)
  - [x] Update `RootView.swift`'s `navigationDestination(for: HomeDestination.self)` `.storyChoice` case to render `StoryChoiceView()` instead of `StoryChoicePlaceholderView()`
  - [x] Delete `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift` and remove its remaining reference in `HomeView.swift`'s `#Preview`
  - [x] In `StoryChoiceView`, when the current node is a terminal (ending) node, render `Text(verbatim: "Run complete — Ending screen coming in Epic 3")` instead of the reading/choice content

- [x] Task 4: Preview coverage for all three node kinds (AC: #7)
  - [x] Add a `#Preview` for `StoryChoiceView` seeded at the reading node
  - [x] Add a `#Preview` for `StoryChoiceView` seeded at the choice node
  - [x] Add a `#Preview` for `StoryChoiceView` seeded at a terminal node

- [x] Task 5: Swift Testing coverage (AC: #6)
  - [x] Create `ForkedEchoesTests/StoryRunEngineTests.swift`
  - [x] Test: fresh engine starts at the tree's root node, empty history, zero score
  - [x] Test: `selectChoice(_:)` records history, accumulates alignment delta, moves `currentNodeId` to the option's target
  - [x] Test: `advancePage()`/`goBack()` move `currentNodeId` across the tree's linear reading segment
  - [x] Run `swift test` from repo root; confirm pass

- [x] Task 6: Manual/preview verification and reporting (AC: #7)
  - [x] Confirm each `#Preview` renders without crashing
  - [x] If Simulator access is available this session, confirm Home → "Start Story" reaches the real view — not available in this devcontainer (no Xcode/Simulator); **confirmed by the user separately in Xcode/Simulator on 2026-07-31** (build, Xcode test run, and Simulator check all succeeded) — see Completion Notes
  - [x] Record what was checked (and when) in Completion Notes List

### Review Findings

Three parallel layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) against the full diff, 2026-07-31. 15 unique findings after dedup; 7 patch, 8 dismissed (0 decision-needed, 0 defer — see Dev Agent Record → Completion Notes for the dismiss reasoning on each).

- [x] [Review][Patch] `StoryNode.ending` has no associated payload, contradicting the Dev Notes' explicit "keep the extension additive" instruction for Story 3.1 [ForkedEchoes/Content/StoryNode.swift:9]
- [x] [Review][Patch] `ChoiceOption.id: String` contradicts AD-1's "Content node/choice IDs are Swift enum cases" convention already applied to `NodeID` [ForkedEchoes/Content/StoryNode.swift:15]
- [x] [Review][Patch] `selectChoice(_:)` has no guard against being called twice on the same already-decided choice node (via `goBack()` then re-selecting) — double-records `choiceHistory` and double-counts `alignmentScore`, contradicting this file's own claimed FR-5/AD-3 permanence guarantee [ForkedEchoes/Engine/StoryRunEngine.swift:26]
- [x] [Review][Patch] Choice-node `options` arrays have no validation against duplicate option ids or an empty array — both are unvalidated content-authoring hazards that compound at Epic 4 scale [ForkedEchoes/Content/StoryTree.swift:15]
- [x] [Review][Patch] `alignmentDelta: 1` / `alignmentDelta: -1` read as intentional narrative values, not scaffolding, despite Task 1's own subtask suggesting `0` is fine — risks Epic 4 content authors misreading them as meaningful [ForkedEchoes/Content/StoryTree.swift:27,33]
- [x] [Review][Patch] `.ending` placeholder text ("Run complete — Ending screen coming in Epic 3") has no forced-removal tracking for Story 3.2 — the same class of "silently forgotten placeholder" this story already fixed twice for `StoryChoicePlaceholderView` [ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift:32]
- [x] [Review][Patch] `project-context.md`'s "Last Updated" trailer has grown to three stacked entries ("Last Updated" / "(previous)" / "(earlier)") from this story's own edits, contradicting the file's stated "keep this file lean" maintenance guidance [_bmad-output/project-context.md:148]

## Dev Notes

### RESOLVED CONFLICT: prose key style (AD-2 vs. project-context.md)

`ARCHITECTURE-SPINE.md`'s AD-2 and `EXPLAINER.md` describe `Localizable.xcstrings` keys as consumed via "type-safe generated symbols." This is stale/aspirational: `project-context.md`'s Localization section documents that this was checked empirically during Story 1.2 — no codegen setting exists in this project, and Xcode auto-extracts literal strings instead of generating accessors. The project-wide rule (most recent, empirically verified, and already followed by every shipped story) is: **plain dot-path string keys**, e.g. `Text("story.introReading.body")` — never a generated symbol. Follow `project-context.md` for this story's new Content-tree prose too; do not re-litigate this in a later story.

### Architecture compliance (AD-1, AD-3)

- **AD-1**: `NodeID` must be a Swift enum, not a raw `String` — this is what makes "a dangling reference is a compile error" literally true. A `String`-keyed tree would only fail at runtime. The tree must never reconverge: the two ending nodes in the minimal tree must be distinct cases, not both pointing at one shared terminal.
- **AD-3**: `StoryRunEngine` is the *only* thing that can be in a `currentNodeId`-mutating position. `StoryChoiceView` reads engine state and (in later stories) forwards intents — it never touches `currentNodeId`/`choiceHistory`/`alignmentScore` directly. This story doesn't wire any gesture/tap path yet, so there's nothing calling `selectChoice`/`advancePage`/`goBack` from the UI in this story — that's fine, the ACs only require the methods exist and are individually correct (verified by Task 5's Swift Testing suite), not that they're reachable from a running screen yet.
- Ending kind (`EndingKind` home/stay/limbo/hardFail) is **out of scope for this story** — Story 3.1 adds it to the terminal-node case. Don't invent an `EndingKind`-shaped field now; just make sure the terminal-node case is structured so 3.1 can extend it later without a breaking rewrite of the whole tree (e.g., a case with an associated `NodeID` that 3.1 can add a second associated value to, or a struct-backed terminal payload — your call, but keep the extension additive).

### File organization

- `Views/<ScreenName>/<ScreenName>View.swift`, one `struct <ScreenName>View: View` per file, with a `#Preview` (project-context.md convention, already followed by Home/Tutorial) — `StoryChoiceView.swift` follows the same pattern.
- `Views/` is a `PBXFileSystemSynchronizedRootGroup` — adding `Content/` as a new top-level group and new files under `Views/StoryChoice/`/`Engine/` needs **zero** `project.pbxproj` edits; Xcode auto-discovers on disk. (This applies to the Xcode project only — the separate `Package.swift` SwiftPM manifest, used for `swift test` in this devcontainer, is *not* auto-discovering and must be edited by hand per Task 1's `Package.swift` step.)

### Package.swift — why this needs an explicit edit, not just new files on disk

**Superseded during this story's own implementation — see Completion Notes for the full account.** `Package.swift` originally declared one target, `ForkedEchoes`, at path `ForkedEchoes/Engine`. Adding `Content/` requires it to be in the SwiftPM graph too, or `swift build`/`swift test` won't see it. The first implementation attempt gave `Content` its own target with `Engine` depending on it — that compiles and tests fine in the devcontainer, but breaks the real Xcode build (`No such module 'Content'`), because Xcode has no such module boundary: `Content/`, `Engine/`, and `Views/` all compile into one single app target there. The correct shape is **one SwiftPM target spanning both directories**, matching Xcode's structure exactly:

```swift
.target(
    name: "ForkedEchoes",
    path: "ForkedEchoes",
    exclude: ["App", "Views", "Resources"],
    sources: ["Content", "Engine"]
),
.testTarget(
    name: "ForkedEchoesTests",
    dependencies: ["ForkedEchoes"],
    path: "ForkedEchoesTests"
),
```

No cross-target import, `#if canImport` guard, or `public` access level is needed anywhere in `Content/` or `Engine/` with this shape — internal (Swift's default) is correct everywhere, same as the rest of the project. If a future story's `Package.swift` diff reintroduces a second target for anything under `ForkedEchoes/`, that's a regression back toward the broken first attempt, even if `swift test` still passes here.

### Testing standards summary (AD-7, project-context.md)

- Swift Testing (`import Testing`), not XCTest. `swift test` from repo root genuinely builds and runs the Engine-target suite in this devcontainer (confirmed working since Story 5.4's `Package.swift`) — use it, don't just eyeball the code.
- This story's suite is deliberately narrow: engine skeleton state transitions only. Don't try to test pager-gating (2.2), choice-permanence/commit-state-machine (2.3), or `RunSnapshot` round-trip (2.4) here — those stories own their own AD-7 test cases and will fail review if this story tries to preempt them with a half-correct version.
- No UI test target/pattern exists in this project (project-context.md Testing section) — `StoryChoiceView`'s correctness for this story is covered by Task 4's previews plus Task 6's manual note, not an automated UI test.

### Environment reminder

- `swiftc -parse <file>.swift` for real syntax verification on individual edited files; `swift build`/`swift test` from repo root for the Engine+Content target (genuinely executes, not parse-only). Full app compilation, Simulator run, and visual verification remain unavailable in this devcontainer — say so explicitly in Completion Notes rather than claiming they passed (project-context.md Environment section).

### Project Structure Notes

- New: `ForkedEchoes/Content/` (Content tree types + minimal placeholder tree), `ForkedEchoes/Engine/StoryRunEngine.swift`, `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`, `ForkedEchoesTests/StoryRunEngineTests.swift`.
- Removed: `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift` (superseded by the real view — AC #3).
- Modified: `Package.swift` (new `Content` target + `Engine` dependency), `ForkedEchoes/Views/RootView.swift` (`.storyChoice` destination), `ForkedEchoes/Views/Home/HomeView.swift` (`#Preview` only — its `NavigationLink(value: HomeDestination.storyChoice)` call site is unchanged), `Resources/Localizable.xcstrings` (new `story.*` keys, inserted alphabetically per existing convention).
- No conflicts detected against the current on-disk structure — `Content/` is a genuinely new top-level group per the Structural Seed, not a rename/move of anything existing.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1: Minimal Story Content & Engine Foundation]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2: Story Reader, Choice Echo & Branch Realities] (Content note, Art note — placeholder tree persists across Epic 2, full authoring is Epic 4's job)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-1] (compiled Swift tree, no reconvergence)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-2] (prose/keys — see RESOLVED CONFLICT above)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-3] (StoryRunEngine sole mutator, intent surface)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-7] (testing surface scope)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#Structural Seed] (Content/Engine/Views layout, Package.swift precedent)
- [Source: _bmad-output/project-context.md#Environment] (toolchain limits, swiftc -parse / swift test)
- [Source: _bmad-output/project-context.md#Localization] (dot-path keys, Text(verbatim:) for throwaway text)
- [Source: _bmad-output/project-context.md#Testing (AD-7)] (swift test scope, StoryRunEngine doesn't exist yet as of Epic 5)
- [Source: _bmad-output/project-context.md#File organization]
- [Source: ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift] (Text(verbatim:) precedent for throwaway placeholder copy)
- [Source: Package.swift] (current single-target manifest, path gap this story closes)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/macOS toolchain (`xcodebuild`, Apple SDKs, Simulator) in this devcontainer; Linux `swiftc` 6.3.3 and SwiftPM are available (project-context.md Environment section).
- Content + Engine targets, and the new `StoryRunEngineTests.swift` suite, actually **build and run** via `swift build`/`swift test` from the repo root (not parse-only) — full output captured: `swift build` → "Build complete!" with both `Content` and `ForkedEchoes` targets compiling; `swift test` → 12/12 tests passed across 3 suites (`ForkedEchoesTests`, `StoryRunEngineTests`, `RunSnapshotPresenceTests` — the last two pre-existing, confirming no regression).
- View-layer files (`RootView.swift`, `HomeView.swift`, `StoryChoiceView.swift`) are Xcode-project-only and not part of the SwiftPM graph — verified with `swiftc -parse` on each (all exit 0). No `xcodebuild`/Simulator run was possible.
- Self-review against `project-context.md`'s Pre-Completion Self-Check caught a real bug before it shipped: `Text(bodyKey)` where `bodyKey: String` resolves to SwiftUI's verbatim `StringProtocol` overload, not `LocalizedStringKey` — meaning the catalog lookup would silently not happen and the raw key string would render. Fixed by explicitly wrapping every Content-sourced key in `LocalizedStringKey(...)` in `StoryChoiceView.swift` before passing to `Text(_:)`. Re-ran `swiftc -parse` and `swift build`/`swift test` after the fix — all still green.
- `grep`-checked all new/touched files for the banned patterns in project-context.md's self-check (`Font.system(size:)`, `.lineLimit(`, `.fixedSize(`) — none found.
- `python3 -m json.tool` confirmed `Localizable.xcstrings` stayed valid JSON after the new entries were inserted.

### Completion Notes List

- Added `ForkedEchoes/Content/` (new top-level group): `NodeID.swift` (Hashable/Sendable enum — `.intro`, `.firstChoice`, `.endingHomeward`, `.endingElsewhere`), `StoryNode.swift` (`indirect enum StoryNode` with `.reading`/`.choice`/`.ending` cases, plus `ChoiceOption` struct carrying `id`/`labelKey`/`alignmentDelta`/`target`), `StoryTree.swift` (the minimal placeholder tree: `intro` reading node → `firstChoice` choice node with 2 options → `endingHomeward`/`endingElsewhere` terminal nodes, never reconverging). All `internal` (Swift's default) — no `public` needed; see the `Package.swift` note below for why.
- Added `ForkedEchoes/Engine/StoryRunEngine.swift`: `@Observable final class`, in-memory-only (`currentNodeId`, `choiceHistory: [ChoiceRecord]`, `alignmentScore: Int`), exposing `selectChoice(_:)`, `advancePage()`, `goBack()`. Uses an internal `visitedNodeIds` stack for `goBack()` — deliberately does **not** pop `choiceHistory` or reverse `alignmentScore` on `goBack()`, since AD-3/FR-5 require a committed choice to stay committed regardless of later back-navigation (a design decision made during implementation, not spelled out verbatim in the AC — documented in the file's own header comment and covered by `goBackAfterACommittedChoiceDoesNotUndoTheChoice()` in the test suite).
- Added `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`: reads `@Environment(StoryRunEngine.self)`, switches on `StoryTree.node(for: engine.currentNodeId)` to render reading/choice/ending content. No gestures, no choice-commit wiring, no DESIGN.md styling — out of scope per epics.md's own Epic 2 sequencing note (Stories 2.2/2.3/2.8). Ending case renders `Text(verbatim: "Run complete — Ending screen coming in Epic 3")`, matching the `Text(verbatim:)` precedent the now-deleted `StoryChoicePlaceholderView.swift` set.
- `RootView.swift`: added `@State private var engine = StoryRunEngine()`, injected via `.environment(engine)` on the `.storyChoice` destination; `.storyChoice` now renders `StoryChoiceView()` instead of the placeholder.
- Deleted `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift`; updated `HomeView.swift`'s `#Preview` to construct `StoryChoiceView()` with a fresh `StoryRunEngine()` instead of the removed placeholder type. `HomeView.swift`'s actual `NavigationLink(value: HomeDestination.storyChoice)` call site was untouched (already correct).
- `Package.swift`: final shape is **one** target covering both `Content/` and `Engine/` (`path: "ForkedEchoes"`, `exclude: ["App", "Views", "Resources"]`, `sources: ["Content", "Engine"]`) — not the two-target-with-a-dependency-edge design this story shipped with first. See "Post-review correction" below for the full story; this bullet describes the state actually left in the repo.
- Content types (`NodeID`, `StoryNode`, `ChoiceOption`, `StoryTree` and its members) are plain `internal` (Swift's default) — no `public` anywhere in `Content/` or `Engine/`. An earlier pass had marked them `public` because a first (later reverted) `Package.swift` design gave `Content` its own SwiftPM target; with the single-target design, there's no module boundary to cross, so `internal` is both correct and simpler.
- Swift 6 strict concurrency required `NodeID: Sendable` and `StoryNode: Sendable` (a `static let` in `StoryTree` triggered `#MutableGlobalVariable` otherwise) — added explicit `Sendable` conformance to both; both are plain value types with `Sendable` payloads, so this is a correct, non-workaround fix.
- Added `ForkedEchoes/Resources/Localizable.xcstrings` entries: `story.firstChoice.body`, `story.firstChoice.choice.1`, `story.firstChoice.choice.2`, `story.intro.body` — inserted alphabetically per the catalog's existing convention, each with `extractionState: "manual"` and a `comment` explaining it's Story 2.1 placeholder content. Confirmed valid JSON after editing.
- Added `ForkedEchoesTests/StoryRunEngineTests.swift`: 9 tests covering initial state, `advancePage()` (reading→next, no-op on non-reading), `selectChoice(_:)` (records history/accumulates score/moves node, no-op on non-choice node, no-op on an already-decided node — added during code review, see below), and `goBack()` (moves back, no-op with empty history, and confirms it never undoes a committed choice). All pass via `swift test`.
- **Verification performed, devcontainer (2026-07-31): previews + parser-level checks.** All three `#Preview` variants in `StoryChoiceView.swift` are syntactically valid (`swiftc -parse` exit 0) and each seeds a distinct node kind so a rendered check exercises AC #4's terminal-node branch directly. `swift build`/`swift test` genuinely compiled and ran the Content/Engine/Tests targets — real execution, not parse-only, for that portion.
- **Verification performed, Xcode/Simulator (2026-07-31, confirmed by user after the `TutorialView.swift` fix): Xcode build succeeded, Xcode's own test run succeeded, and a Simulator check confirmed the app itself.** This closes out AC #3 (Home → "Start Story"/"Resume Story" reaches the real `StoryChoiceView`, not the deleted placeholder) and AC #4/#7 (all three node kinds render without crashing) on the actual running app, not just static/parse checks. Recorded here per the project's verification-reporting Process Agreement — the user did not report which specific node kinds/flows were exercised in the Simulator beyond the general confirmation, so a future story shouldn't assume more granular coverage (e.g. the choice-node and ending-node `#Preview`s specifically) than "build + tests + a Simulator check" implies.
- **Post-review correction (2026-07-31), two passes.** The user attempted an actual Xcode build and hit `No such module 'Content'` on `StoryRunEngine.swift`'s `import Content` — root cause: the `Content`/`Engine` module split this story's Task 1 first shipped only exists for the devcontainer's SwiftPM graph; the real Xcode project compiles `Content/`, `Engine/`, `Views/` as one single app target with no module boundary at all. **First fix attempt:** guarded the import with `#if canImport(Content)` — technically correct (verified `swift build`/`swift test` still passed, 12/12), but the user pushed back that this was papering over a fictional module boundary rather than removing it, and was right: it left a permanent, easy-to-forget special case on every future `Engine/` file that touches `Content/`, undetectable by this devcontainer if a later story regressed it. **Actual fix:** collapsed `Package.swift` back to a single target spanning both directories (`sources: ["Content", "Engine"]`, `exclude: ["App", "Views", "Resources"]`), matching Xcode's real structure exactly. Removed the `canImport` guards and the now-unnecessary `public`/`public init` from every `Content/` type — plain `internal` again, since there's no module boundary left to cross. Re-verified from a clean `.build/` (`rm -rf .build && swift build && swift test`) — clean build, no warnings, 12/12 tests still passing. Documented the corrected rule (and explicitly the rejected `canImport` approach, so it isn't tried again) in `project-context.md`'s Environment section.
- **Code review (2026-07-31): Blind Hunter + Edge Case Hunter + Acceptance Auditor, run in parallel against the full diff.** 15 unique findings after dedup; 7 patch (all applied — see below), 8 dismissed. One dismissal is worth recording explicitly: the Blind Hunter's top finding claimed `HomeView.swift`/`TutorialView.swift` each register a duplicate `navigationDestination` with an unshared, throwaway `StoryRunEngine`, defeating `RootView`'s single-owner injection (AD-3). Verified directly against the diff before accepting it — **false positive**: both changed hunks are entirely inside `#Preview` blocks (lines 61–74 and 71–84 respectively), not the real view `body`; git's hunk-header heuristic had grabbed the enclosing `struct` name as context instead of `#Preview { }`, which its function-context regex doesn't match well. Full findings list and dismiss reasoning: see the code-review conversation; only the 7 patch items are recorded in Review Findings above per this workflow's own rules.
- **Applied all 7 patches:**
  - `StoryNode.ending` → `case ending(EndingPayload)` (new `EndingPayload` struct wrapping `NodeID`) instead of a bare case with no payload — Story 3.1 can now add an `EndingKind` field to `EndingPayload` without breaking existing `case .ending:` call sites (a struct field addition is additive; a second positional associated value, which the original Dev Notes also suggested as an option, would not have been — noted this refinement explicitly since it improves on the letter of the original guidance).
  - `ChoiceOption.id`/`selectChoice(_:)`/`ChoiceRecord.chosenOptionId` changed from `String` to a new `ChoiceOptionID` enum (`.boat`, `.shore`), mirroring `NodeID`'s existing flat-enum pattern per AD-1. Removed `selectChoiceWithUnknownOptionIdIsNoOp` from the test suite — the bug class it tested (a typo'd/stale option-id string) is now structurally impossible to construct, a strictly stronger guarantee than the runtime test it replaced.
  - `selectChoice(_:)` gained a guard against firing on a node that already has a `choiceHistory` entry — closes a real bug where `goBack()` to a decided choice node left it re-selectable, double-recording history and double-counting `alignmentScore`. Added `selectChoiceDoesNotFireTwiceOnAnAlreadyDecidedNode` reproducing the exact repro sequence (`selectChoice` → `goBack` → `selectChoice` again).
  - `StoryTree.node(for:)` now validates any `.choice` node's `options` array (non-empty, unique ids) via `precondition`, crashing loudly on a content-authoring mistake instead of silently misbehaving — not unit-tested directly (Swift Testing has no first-class trap-testing API), but exercised transitively by every existing test via `swift test`.
  - Added a one-line comment at `StoryTree.swift`'s `alignmentDelta: 1`/`-1` clarifying they're non-narrative placeholder values.
  - Added a `deferred-work.md` entry tracking `StoryChoiceView.swift`'s `.ending` placeholder text for removal in Story 3.2.
  - Collapsed `project-context.md`'s three stacked "Last Updated" entries into one current line.
  - Re-verified from a clean `.build/` after all patches: clean build, no warnings, 12/12 tests passing.

### File List

- `ForkedEchoes/Content/NodeID.swift` (new)
- `ForkedEchoes/Content/StoryNode.swift` (new)
- `ForkedEchoes/Content/StoryTree.swift` (new)
- `ForkedEchoes/Engine/StoryRunEngine.swift` (new)
- `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (new)
- `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift` (deleted — superseded by `StoryChoiceView.swift`)
- `ForkedEchoes/Views/RootView.swift` (modified — engine instantiation/injection, `.storyChoice` destination)
- `ForkedEchoes/Views/Home/HomeView.swift` (modified — `#Preview` only)
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` (modified — `#Preview` only; missed in the initial placeholder deletion, fixed after user's second Xcode build report)
- `ForkedEchoes/Resources/Localizable.xcstrings` (modified — 4 new `story.*` keys)
- `ForkedEchoesTests/StoryRunEngineTests.swift` (new)
- `Package.swift` (modified — single target spanning `Content/` + `Engine/` via `sources`, matching Xcode's structure; superseded an interim two-target design)
- `_bmad-output/project-context.md` (modified — Environment-section rule: `Package.swift` must be one target covering `Content/` + `Engine/`, never split them; documents the rejected `canImport`-guard alternative; changelog trailer consolidated per code review)
- `_bmad-output/implementation-artifacts/deferred-work.md` (modified — new entry tracking the `.ending` placeholder for Story 3.2 removal, per code review)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — epic-2/story 2-1 status progression)
- `_bmad-output/implementation-artifacts/2-1-minimal-story-content-and-engine-foundation.md` (this story file)

## Change Log

- 2026-07-31: Story created via `create-story` (auto-discovered as next backlog story; epic-2 moved `backlog` → `in-progress`).
- 2026-07-31: Implemented via `dev-story`. Content tree, `StoryRunEngine` skeleton, real `StoryChoiceView` wired into navigation, `Package.swift` updated with a `Content` target, `Localizable.xcstrings` entries added, `StoryRunEngineTests.swift` added (8 tests, all passing alongside the 4 pre-existing tests — 12/12 total). Caught and fixed a `Text(_:)` overload-resolution bug (verbatim vs. `LocalizedStringKey`) during self-review against `project-context.md`'s Pre-Completion Self-Check before marking any task complete. All tasks/subtasks complete; Simulator-level verification of AC #3/#4 not possible in this devcontainer (no Xcode) — flagged in Completion Notes rather than claimed. Status moved to `review`.
- 2026-07-31: User attempted a real Xcode build and hit `No such module 'Content'` — a devcontainer/Xcode dual-build-graph gap the SwiftPM-only verification in this environment could not have caught. First fix (guarding `import Content` with `#if canImport(Content)`) was flagged by the user as papering over the real problem. Corrected properly: collapsed `Package.swift` to a single target spanning `Content/` + `Engine/`, matching Xcode's actual single-module structure, removing the need for any cross-target import/guard/`public` anywhere. Re-verified from a clean `.build/` — clean build, no warnings, 12/12 tests still passing. `project-context.md` updated to document the corrected rule and explicitly record the rejected `canImport` approach. Status remains `review`.
- 2026-07-31: User retested in Xcode and hit a second, unrelated gap from the same deletion: `TutorialView.swift`'s own `#Preview` (a separate standalone `NavigationStack` mock, same pattern as `HomeView.swift`'s) also referenced the deleted `StoryChoicePlaceholderView` at line 77 — missed because the original placeholder-removal check only grepped `RootView.swift` and `HomeView.swift`. Fixed by `grep -rn "StoryChoicePlaceholderView"` across the whole tree (not just the two files checked before) and updating the one remaining code reference to `StoryChoiceView().environment(StoryRunEngine())`, matching `HomeView.swift`'s preview fix. Verified via `swiftc -parse` plus a full `swift build`/`swift test` (12/12 still passing) and a repo-wide grep confirming zero remaining `StoryChoicePlaceholderView` references outside historical story/retro docs. Status remains `review`.
- 2026-07-31: Xcode build confirmed working by the user after the `TutorialView.swift` fix. At the user's request, `project-context.md` was updated with three durable process rules following this story's two Xcode-build round-trips: a general "Xcode's structure is the source of truth" principle in Environment, a Pre-Completion Self-Check item requiring a repo-wide grep before/after any delete or rename, and a Process Agreement to actively request Xcode/Simulator verification at session end going forward.
- 2026-07-31: User confirmed Xcode build succeeded, Xcode's test run succeeded, and a Simulator check confirmed the app — closing out AC #3/#4/#7's real-app verification, the last open item. All tasks/ACs satisfied; no regressions reported. Ready for `code-review`.
- 2026-07-31: `code-review` run — Blind Hunter, Edge Case Hunter, Acceptance Auditor in parallel. 7 patch findings, 0 decision-needed, 8 dismissed (including a verified false positive from the Blind Hunter about duplicate `navigationDestination`/unshared-engine registrations, which was actually confined to `#Preview` blocks). All 7 patches applied at the user's request: `StoryNode.ending` given an additive struct payload (`EndingPayload`), `ChoiceOption.id`/`selectChoice(_:)`/`ChoiceRecord.chosenOptionId` converted from `String` to a new `ChoiceOptionID` enum, a permanence guard added to `selectChoice(_:)` (closing a real double-commit bug reachable via `goBack()` then re-selecting), content-validation `precondition`s added for choice-node option arrays, a clarifying comment on placeholder `alignmentDelta` values, a `deferred-work.md` tracking entry for the `.ending` placeholder, and `project-context.md`'s changelog trailer consolidated. Re-verified clean from a fresh `.build/` — 12/12 tests passing. All patch/decision-needed findings resolved, no unresolved high/medium issues remain. Status moved to `done`.
