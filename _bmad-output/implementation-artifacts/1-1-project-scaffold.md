---
baseline_commit: f51ec66a8113ae66fba6ebf8519cd218a3721dcb
---

# Story 1.1: Project Scaffold

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a working Xcode project matching the Architecture's Structural Seed layout,
so that every later story has a consistent place to add code.

## Acceptance Criteria

1. **Given** no existing Xcode project, **when** the project is created, **then** it targets iOS 18.0 minimum (iOS 26 SDK), Swift 6.3, SwiftUI app lifecycle.
2. **Given** the project is created, **when** inspected, **then** it contains `App/`, `Content/`, `Engine/`, `Views/`, `Resources/` groups matching the Structural Seed, plus a `ForkedEchoesTests/` target using Swift Testing (not XCTest).
3. **Given** the project's `Resources/` group, **when** inspected, **then** `Resources/Localizable.xcstrings` and `Resources/Assets.xcassets` exist (empty, ready for content) per AD-2.
4. **Given** the project is opened in Xcode 26.6, **when** built and run on the iOS Simulator, **then** it builds with no warnings/errors and launches to an empty placeholder root view.

[Source: epics.md#Story 1.1: Project Scaffold]

## Tasks / Subtasks

- [x] Task 1: Create the Xcode project from scratch, not a template clone (AC: #1)
  - [x] Subtask 1.1: New iOS App project, SwiftUI app lifecycle, product name `ForkedEchoes` (see Dev Notes — Naming below)
  - [x] Subtask 1.2: Set deployment target to iOS 18.0; SDK/build with iOS 26 SDK; language: Swift 6.3, Swift 6 language mode (strict concurrency)
  - [x] Subtask 1.3: Choose and record a placeholder bundle identifier (see Dev Notes — Bundle ID below)
- [x] Task 2: Build the Structural Seed group layout (AC: #2)
  - [x] Subtask 2.1: Create groups/folders: `App/`, `Content/`, `Engine/`, `Views/`, `Resources/` (empty except App's entry point)
  - [x] Subtask 2.2: Add a `ForkedEchoesTests/` test target using the **Swift Testing** framework (`import Testing`) — verify Xcode didn't default it to XCTest
  - [x] Subtask 2.3: Add one trivial `@Test` smoke case in `ForkedEchoesTests/` to prove the test target actually compiles and runs (not required by any AC, but the cheapest possible guard against a misconfigured test target going unnoticed until Story 2.2's real tests)
- [x] Task 3: Wire up empty Resources (AC: #3)
  - [x] Subtask 3.1: Add `Resources/Localizable.xcstrings` (empty String Catalog, type-safe generated symbols enabled — this is an Xcode project build setting, verify it's on)
  - [x] Subtask 3.2: Add `Resources/Assets.xcassets` (empty asset catalog, default AppIcon/AccentColor placeholders are fine)
- [x] Task 4: Placeholder root view + app entry point (AC: #4)
  - [x] Subtask 4.1: `App/ForkedEchoesApp.swift` — `@main` `App` struct, SwiftUI `WindowGroup` scene
  - [x] Subtask 4.2: `Views/` empty placeholder root `View` (plain text or empty `Color` — Home doesn't exist until Story 1.2) shown by the app scene
  - [x] Subtask 4.3: Confirm project builds and runs on iOS Simulator with zero warnings/errors in both Debug and Release configurations — verified by user on macOS/Xcode 26.6, 2026-07-26: Debug build 0 warnings/errors, Release build 0 warnings/errors, app launches to empty placeholder view, `ForkedEchoesTests` smoke test passes via ⌘U.

### Review Findings

- [x] [Review][Patch] Add `SWIFT_STRICT_CONCURRENCY = complete` to the `ForkedEchoesTests` target's Debug and Release build settings [ForkedEchoes.xcodeproj/project.pbxproj]
- [x] [Review][Patch] Add the two Xcode-generated files (`project.xcworkspace/contents.xcworkspacedata`, `xcshareddata/xcschemes/ForkedEchoes.xcscheme`) to the Dev Agent Record's File List [1-1-project-scaffold.md:File List]
- [x] [Review][Patch] Add trailing newline to `Localizable.xcstrings` [ForkedEchoes/Resources/Localizable.xcstrings]
- [x] [Review][Defer] No `DEVELOPMENT_TEAM` set in any build configuration (`CODE_SIGN_STYLE = Automatic`) — blocks device/Archive builds; Simulator builds (all AC #4 requires) are unaffected [ForkedEchoes.xcodeproj/project.pbxproj] — deferred, pre-existing: the story's own Dev Notes already defer the Apple Developer Program/team decision until the account type is chosen
- [x] [Review][Defer] `AppIcon.appiconset` declares a 1024x1024 slot with no image asset — will fail Release Archive/App Store validation once attempted [ForkedEchoes/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json] — deferred, pre-existing: real app icon art is Epic 4's job (Story 4.6, App Store listing/submission assets), not this scaffold story

## Dev Notes

### Architecture Compliance

- **Layering (paradigm):** Content → Engine → Presentation, one-directional dependency; this story only stands up the empty folders — no code in `Content/`/`Engine/` yet, and no dependency violations are possible because nothing exists there yet. [Source: ARCHITECTURE-SPINE.md#Design Paradigm]
- **AD-1 (Content is compiled Swift, never Decodable):** Not exercised yet in this story (Content/ stays empty), but do not scaffold any JSON-loading or `Decodable` machinery anywhere — Story 2.1 is the first to add real Content, and it must be `indirect enum` literals only. [Source: ARCHITECTURE-SPINE.md#AD-1]
- **AD-2 (Text/assets live outside the tree):** This story's only AD-2 obligation is standing up the empty `Localizable.xcstrings` and `Assets.xcassets` files with type-safe symbol generation enabled — confirm the "Generate Swift Constants" / string-catalog codegen build setting is on so later stories get generated symbols for free. [Source: ARCHITECTURE-SPINE.md#AD-2]
- **AD-3/AD-4/AD-5/AD-6 (Engine, persistence, pager, ending):** None of these apply yet — `Engine/` stays an empty folder. Do not pre-build `StoryRunEngine`, `RunSnapshot`, or any phase-derivation logic in this story; that's Story 2.1 (engine skeleton) and Story 2.4 (persistence). Resist the urge to scaffold "just a little" of the engine here — scope creep into Epic 2's territory is exactly the kind of thing this story must not do.
- **AD-7 (Testing surface):** The `ForkedEchoesTests/` target must exist and use Swift Testing now, because Story 2.2 onward adds real `@Test` cases against `StoryRunEngine` there — if this story accidentally creates an XCTest-based target instead, every later story's testing AC breaks silently until someone notices. [Source: ARCHITECTURE-SPINE.md#AD-7]

### Naming

The product name is finalized as **Forked Echoes** (PRD title, DESIGN.md brand identity, GitHub repo `New-Reality-Interactive/forked-echoes`), and the Architecture Spine's Structural Seed now uses that same name for the Xcode project/target layout (corrected 2026-07-26 — an earlier draft used the working title `ManyWorldsCYOA`, now fully retired):

```text
ForkedEchoes/
  App/ Content/ Engine/ Views/ Resources/
ForkedEchoesTests/
```

Use `ForkedEchoes` as the Xcode project name, app target name, and test target name — this now matches the in-app **display title** (Home screen's app title, per FR-1 — Story 1.2's job to render from the String Catalog) exactly, so there's no naming mismatch to navigate. [Source: ARCHITECTURE-SPINE.md#Structural Seed]

### Bundle ID (open decision, not architecture-specified)

No bundle identifier convention is specified anywhere in the PRD, Architecture, or UX docs. Apple Developer Program enrollment and the individual-vs-organization account decision are explicitly **unresolved** (epics.md's Pre-Submission Checklist) and out of scope for this epic. Use any placeholder reverse-DNS identifier for local development and Simulator builds (e.g. `com.example.forkedechoes`) — this requires no signing team for Simulator-only builds, so it does not block this story. Flag in the story completion notes that the real bundle ID/Team must be revisited once the Developer Program account type is decided.

### Tech Stack (verified current as of 2026-07-26)

| Name | Version | Note |
| --- | --- | --- |
| Swift | 6.3 | Swift 6 language mode (strict concurrency) — matches `@Observable`'s Swift 6-native design used starting Story 2.1 |
| iOS deployment target | 18.0 minimum (N-1) | Per NFR2 |
| iOS SDK | 26 (build against iOS 26.5-era SDK bundled with Xcode 26.6) | |
| Xcode | 26.6 | **Confirmed still current-stable** as of this story's creation — re-verified via web search, not just carried over from the Architecture doc's own "re-verify before starting" caveat |
| Swift Testing | Bundled, Xcode 26.6 | Use `import Testing`, not XCTest |

**Re-verification note:** The Architecture Spine flagged its stack table as "seed, not a pin" and asked to re-verify before implementation, because Xcode 27 beta (Swift 6.4, iOS 27 SDK) had just entered public beta at authoring time. As of 2026-07-26, Xcode 27 is still beta-only (beta 2-4, requires macOS Tahoe 26.4+, Apple Silicon only; GA still expected ~September 2026) — **do not** target Xcode 27/Swift 6.4/iOS 27 for this story. Xcode 26.6 / Swift 6.3 / iOS 26 SDK, targeting iOS 18.0 minimum, remains correct. [Source: ARCHITECTURE-SPINE.md#Stack; web search 2026-07-26]

### Project Structure Notes

- This is a from-scratch scaffold, explicitly **not** a starter/greenfield template clone (per epics.md's Additional Requirements) — do not use Xcode's default "App" template's `ContentView.swift`/`Item.swift`/SwiftData boilerplate; delete or never generate that scaffolding, and build the group structure to match the Structural Seed exactly.
- No existing code exists anywhere in this repo yet (confirmed: repo root has no `.xcodeproj`/`.swift` files) — there is nothing to preserve or avoid breaking. This is the one story in the whole plan where that's true.
- Device target: iPhone only, portrait only (Info.plist orientation lock can be deferred to whichever story first adds UI needing it — Story 1.2 — but no harm in setting it now since it's a one-line Info.plist setting).

### Testing Standards Summary

- NFR3 (engine logic test coverage) does not apply yet — there's no engine. This story's only testing obligation is that `ForkedEchoesTests/` exists, targets the app correctly, and demonstrably runs (Subtask 2.3's smoke test) using Swift Testing, since Stories 2.2/2.3/2.4/2.5/3.1 all add real `@Test` cases to this same target and cannot do so if it's missing or misconfigured.

### References

- [Source: epics.md#Story 1.1: Project Scaffold] — acceptance criteria (verbatim BDD)
- [Source: epics.md#Additional Requirements] — "no starter/greenfield template" constraint
- [Source: ARCHITECTURE-SPINE.md#Structural Seed] — literal folder/target layout and naming
- [Source: ARCHITECTURE-SPINE.md#Stack] — version table and re-verification caveat
- [Source: ARCHITECTURE-SPINE.md#AD-2] — String Catalog / Asset Catalog conventions
- [Source: ARCHITECTURE-SPINE.md#AD-7] — Swift Testing as the test framework
- [Source: EXPLAINER.md#Everything else] — rationale for Swift Testing over XCTest

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5), via Claude Code `bmad-dev-story` workflow.

### Debug Log References

- This execution ran in a Linux devcontainer with no Swift toolchain and no Xcode installed (`swift`/`xcodebuild` not found). The `.xcodeproj`/`project.pbxproj`, Swift sources, and resource catalogs were hand-authored to the exact spec in Dev Notes rather than generated by Xcode itself.
- `project.pbxproj` uses Xcode 16+ `PBXFileSystemSynchronizedRootGroup` (synchronized folder groups) for `App/`, `Content/`, `Engine/`, `Views/`, `Resources/`, and `ForkedEchoesTests/` — Xcode auto-discovers file membership from disk, so no per-file `PBXBuildFile`/`PBXFileReference` bookkeeping was needed for source/resource files.
- `objectVersion = 77` (Xcode 16.0's value) was used as a conservative, known-good baseline since the exact Xcode 26.6 object-version number isn't independently verifiable from this environment. Xcode auto-upgrades older-but-compatible project formats silently; this is expected to open cleanly, but is an explicit item to confirm on first open.
- Static validation performed (no Xcode available): brace/paren balance check and full object-ID cross-reference check on `project.pbxproj` (all 31 defined objects, all references resolve, zero orphaned/undefined IDs); JSON validation on `Contents.json` (x3) and `Localizable.xcstrings`; brace-balance check on all 3 Swift files. None of this substitutes for an actual Xcode build.

### Completion Notes List

- Tasks 1-3 and Subtasks 4.1-4.2 complete and statically validated. Subtask 4.3 and AC #4 (build/run on iOS Simulator, zero warnings, Debug + Release) are **not verifiable in this environment** — flagged as an explicit open item below.
- Bundle identifier used: `com.example.forkedechoes` (app), `com.example.forkedechoes.tests` (test target) — placeholder only, per Dev Notes' "Bundle ID (open decision)" section. Must be revisited once Apple Developer Program account type is decided.
- **Verified on macOS/Xcode 26.6 (2026-07-26):** project opened cleanly (no format-upgrade issues beyond the expected prompt), Debug and Release builds both succeed with 0 warnings/errors, app launches to the empty placeholder view, and the `ForkedEchoesTests` smoke test passes.
- **Build issue found and fixed during verification:** the initial scaffold's `.gitkeep` placeholders in `Content/` and `Engine/` (added purely so git would track the otherwise-empty directories) were auto-included as bundle resources by Xcode's file-system-synchronized groups, and both collided on the same output filename (`ForkedEchoes.app/.gitkeep`) → "Multiple commands produce" build error. Fixed by adding `PBXFileSystemSynchronizedBuildFileExceptionSet` membership exceptions on the `Content` and `Engine` synchronized groups, excluding `.gitkeep` from target membership. Re-verified: build succeeds.
- **String Catalog codegen confirmed:** no distinct "Generate String Symbols" toggle exists in Xcode 26.6 (contra the original assumption it'd be a per-file inspector checkbox). The actual mechanism is two target Build Settings under Localization — `LOCALIZATION_PREFERS_STRING_CATALOGS` ("Localization Prefers String Catalogs") and `SWIFT_EMIT_LOC_STRINGS` ("Use Compiler to Extract Swift Strings") — both set `YES` in `project.pbxproj` and confirmed present/enabled by user inspection in Xcode's Build Settings UI, 2026-07-26. This satisfies Subtask 3.1's "verify it's on."
- No new third-party dependencies introduced.

### File List

- `ForkedEchoes.xcodeproj/project.pbxproj` (new; amended post-verification to add `.gitkeep` membership exceptions for `Content`/`Engine`; amended post-review to add `SWIFT_STRICT_CONCURRENCY` to the test target)
- `ForkedEchoes.xcodeproj/project.xcworkspace/contents.xcworkspacedata` (new, Xcode-generated)
- `ForkedEchoes.xcodeproj/xcshareddata/xcschemes/ForkedEchoes.xcscheme` (new, Xcode-generated)
- `ForkedEchoes/App/ForkedEchoesApp.swift` (new)
- `ForkedEchoes/Views/RootView.swift` (new)
- `ForkedEchoes/Content/.gitkeep` (new)
- `ForkedEchoes/Engine/.gitkeep` (new)
- `ForkedEchoes/Resources/Localizable.xcstrings` (new; amended post-review to add trailing newline)
- `ForkedEchoes/Resources/Assets.xcassets/Contents.json` (new)
- `ForkedEchoes/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` (new)
- `ForkedEchoes/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` (new)
- `ForkedEchoesTests/ForkedEchoesTests.swift` (new)

### Change Log

- 2026-07-26: Initial scaffold implementation (Tasks 1-3, Subtasks 4.1-4.2) by Claude Sonnet 5 via `bmad-dev-story`. Subtask 4.3 / AC #4 left open pending macOS/Xcode verification.
- 2026-07-26: User verified build/run on macOS/Xcode 26.6. Found and fixed a `.gitkeep` resource-copy collision (duplicate output file) via synchronized-group membership exceptions. Debug + Release builds and test target confirmed passing. Subtask 4.3 checked off; story moved to `review`.
- 2026-07-26: Confirmed String Catalog codegen build settings (`LOCALIZATION_PREFERS_STRING_CATALOGS`, `SWIFT_EMIT_LOC_STRINGS`) enabled via Xcode's Build Settings UI, resolving Subtask 3.1's "verify it's on" note.
- 2026-07-26: Code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor) run; 3 patch findings applied (test target `SWIFT_STRICT_CONCURRENCY`, File List completeness, `Localizable.xcstrings` trailing newline), 2 findings deferred (no `DEVELOPMENT_TEAM` set; `AppIcon` has no image asset — both pre-existing/expected per spec), 9 dismissed as noise. See `deferred-work.md` for deferred items.
