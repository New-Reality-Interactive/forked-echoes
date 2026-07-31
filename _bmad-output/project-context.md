---
project_name: 'game'
user_name: 'Vscode'
date: '2026-07-31'
sections_completed: ['technology_stack', 'localization', 'navigation', 'landscape', 'centering_pattern', 'testing', 'accessibility', 'design_tokens', 'buttons', 'file_organization', 'cross_story_contracts', 'doc_conflicts', 'pre_completion_checklist', 'pre_creation_ac_checklist', 'process_agreements']
status: 'complete'
rule_count: 55
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Swift 6.3, Swift 6 language mode (strict concurrency)
- iOS 18.0 minimum deployment target (N-1), built against iOS 26 SDK
- Xcode 26.6
- SwiftUI (bundled with SDK) — no UIKit
- Swift Testing (`import Testing`) — never XCTest
- No third-party dependencies (no SPM packages) — keep it that way unless a story explicitly calls for one
- Device target: iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait + landscape (no upside-down)
- Re-verify this table before starting new work if enough time has passed — Xcode/Swift ship fast; each story so far has re-confirmed these are still current-stable rather than assuming

## Critical Implementation Rules

### Environment

- **This devcontainer has a Linux Swift toolchain (`swiftc`, Swift 6.3.3) but no Xcode/Apple SDKs** (`xcodebuild` unavailable; `UIKit`/`SwiftUI` don't resolve — `swiftc -typecheck` on a file importing either fails with `no such module`). That means real parser-level syntax validation is available and should be used: run `swiftc -parse <file>.swift` on new/edited `.swift` files for genuine syntax verification, instead of eyeballing brace/paren balance. Full app compilation, build/run, and Simulator verification (visual check, VoiceOver, Dynamic Type, rotation) still cannot happen here — always flag those explicitly for the user rather than claiming they passed. Other static checks remain: JSON validity (`python3 -m json.tool` on `.xcstrings`/`Contents.json`), brace/paren balance checks on touched `.pbxproj` files (no parser-level tool covers these), and `grep` for banned patterns (see below).
- **Exception — engine-logic Swift Testing suites genuinely run here, not just parse.** The root `Package.swift` (added Story 5.4, 2026-07-27; extended Story 2.1, 2026-07-31 with a `Content` target) exposes `ForkedEchoes/Engine` (depending on `ForkedEchoes/Content`) as SwiftPM library targets with `ForkedEchoesTests` as the test target, entirely separate from `ForkedEchoes.xcodeproj`. `swift test` from the repo root builds and executes that suite for real (confirmed empirically: technical research 2026-07-29/30, re-verified live 2026-07-31 — Story 2.1's 12/12 tests passed, Swift Testing runner output, not `swiftc -parse`). No `swift-testing` package dependency is needed in the manifest — Swift 6 toolchains (Linux included) bundle `import Testing` natively; a `Package.swift` entry for it would be redundant, not required. **Implication for future engine work:** any new engine-logic code meant to be Swift-Testing-covered (e.g. `StoryRunEngine`, extended across Epic 2) must live under `ForkedEchoes/Engine/` (with tests under `ForkedEchoesTests/`) to inherit real Linux test execution — engine code written directly into the Xcode app target elsewhere would silently fall back to parse-only verification in this devcontainer.
- **General principle: this devcontainer's SwiftPM package is a testing convenience, not a source of truth — `ForkedEchoes.xcodeproj`'s single-app-target structure is.** One Xcode target means one Swift module: there is no per-folder or per-layer module boundary anywhere in this project unless a story deliberately adds a second target to the `.xcodeproj` itself (none exist as of Story 2.1). Any `Package.swift` change should default to mirroring that single-module reality rather than whatever's most convenient for `swift test` — when the two goals conflict, Xcode's structure wins, because this devcontainer cannot verify an Xcode build and a design that only "works for testing" can silently ship broken. The `Content`/`Engine` rule below is the concrete case this bit; treat any future `Package.swift` diff that introduces a new target, or a new top-level source directory not yet folded into the existing target's `sources`, with the same suspicion.
- **`Package.swift` is one single target covering both `Content/` and `Engine/` — never split them into separate SwiftPM targets.** The real Xcode project has no module boundary between `Content/`, `Engine/`, and `Views/` at all — they're all `PBXFileSystemSynchronizedRootGroup`s inside **one single app target**, so a file in `Engine/` sees a `Content/` type with zero import needed (exactly like `HomeView.swift` referencing `RunSnapshotPresence` today). An earlier version of `Package.swift` (Story 2.1, first pass, 2026-07-31) split `Content` and `Engine` into two SwiftPM targets with a dependency edge — that invents a module boundary that doesn't exist in production, and the fix attempted first (`#if canImport(Content)` guarding the import) was itself the wrong direction: patching around a fictional boundary instead of removing it. The real fix, in place since: one `.target` with `path: "ForkedEchoes"`, `exclude: ["App", "Views", "Resources"]`, `sources: ["Content", "Engine"]` — mirroring Xcode's actual single-module structure exactly, so no file in either directory ever needs a cross-target import, guard, or `public` access level in either build graph (both are `internal` by default, same as everywhere else in this project). This devcontainer's `swift build`/`swift test` cannot itself detect a regression back toward a multi-target split — that class of bug only surfaces in an actual Xcode build — so if a future story's `Package.swift` diff reintroduces separate targets for anything under `ForkedEchoes/`, treat it as a red flag regardless of whether `swift test` passes.

### Localization (`Localizable.xcstrings`)

- Reference strings by plain dot-path key: `Text("home.storyTitle")` — **not** compiler-generated type-safe symbols. No codegen setting exists in this project despite AD-2's aspirational language; this was confirmed empirically (Story 1.2) when Xcode auto-extracted literal strings instead of generating accessors.
- Every catalog entry needs: `comment` (describes where/how it's used), `extractionState: "manual"`, one `en` `stringUnit` with `state: "translated"`.
- Existing keys are in alphabetical order — insert new keys to preserve that, even if it means placing "immediately before" rather than "after" a related key.
- A `LocalizedStringKey`-typed value chosen by a ternary (e.g. `hasInProgressRun ? "a" : "b"`) needs an **explicit `LocalizedStringKey` type annotation** on the constant — otherwise `Text(_:)` can resolve the wrong initializer overload (`String` vs `LocalizedStringKey`).
- Throwaway/placeholder view text that is *not* meant to be localized (e.g. a stand-in view fully replaced by a later story) should use `Text(verbatim:)` — a plain string literal gets auto-extracted into the catalog as a stray empty entry by Xcode's build-time string scanning.

### Navigation

- One `Hashable` enum (`HomeDestination`) + `.navigationDestination(for:)`, registered **once** at `RootView`'s `NavigationStack` level — reserved for the coarse top-level flow only (Home ↔ Tutorial ↔ Story session ↔ Ending ↔ Memory). Never use `NavigationStack`/this pattern for individual in-story reading pages (AD-5) — the story pager is engine-driven, not a navigation push/pop.
- New destinations reuse the existing enum/resolver — add a case only when a genuinely new top-level screen is introduced; don't create per-screen navigation plumbing.

### Landscape / Orientation (AD-8)

- Detect orientation via `@Environment(\.verticalSizeClass)` only (`.compact` = landscape, `.regular` = portrait) — **never** `UIDevice.orientation`/`UIDeviceOrientationDidChangeNotification` (fragile, manual lifecycle) and **never** `horizontalSizeClass` (reports `.compact` in *both* orientations on standard iPhones, can't distinguish them). Treat `verticalSizeClass == nil` as `.regular` (portrait) — the safer default.
- Sanctioned exception (Story 5.4): a single, one-shot `UIWindowScene.interfaceOrientation` read at `.onAppear`, used only to correct a stale cold-launch layout pass (see `ColdLaunchOrientationFix.swift`), is allowed alongside the `verticalSizeClass` rule above — it's a bounded correctness check, not a second ongoing orientation-detection mechanism. Don't generalize this into a pattern for structural layout decisions; those still go through `verticalSizeClass` only.
- **Do not reuse `ColdLaunchOrientationFix`'s `.id(layoutGeneration)` mechanism as-is on the reading surface (Epic 2).** It forces a full subtree teardown/rebuild on correction, discarding all nested `@State` — harmless on Home/Tutorial (no meaningful child state) but destructive once real state exists (pager position, in-flight choice-hold gesture). Flagged in Epic 1's retrospective (2026-07-28); see the comment in `ColdLaunchOrientationFix.swift` for the same warning at the source.
- Two different fixes for two different problems, don't conflate them:
  - **Structural** change (e.g. a stack becoming a row) → branch on `verticalSizeClass`.
  - **Geometry-only** constraint (e.g. a max-width cap) → an unconditional `.frame(maxWidth:)` that's simply a no-op in portrait, **no branch at all**.
- One view hierarchy per screen, always — never a separate `*LandscapeView` type.

### The `GeometryReader` + `ScrollView` centering pattern

- Home/Tutorial-style screens use: `GeometryReader { proxy in ScrollView { content.frame(maxWidth: .infinity, minHeight: proxy.size.height) } }` so content centers when it fits but scrolls instead of clipping when Dynamic Type + landscape's reduced height push it past the frame.
- **Never use `Spacer()` inside this pattern** to push content apart — it measures as zero/`minLength` here and caused a real shipped bug (Story 1.3: "Start Story" button unreachable in landscape). Use a flat, `Spacer`-free `VStack` with real `spacing` values instead.
- This flat `VStack` nesting is load-bearing for landscape correctness — don't restructure it as a side effect of an unrelated change.

### Testing (AD-7)

- Swift Testing coverage is scoped to `StoryRunEngine`/engine logic only (ending resolution, echo reachability, pager-gating, `RunSnapshot` round-trip). **There is no UI test target and no UI-test pattern in this project** — SwiftUI view correctness (layout, VoiceOver, Dynamic Type) is verified manually in Simulator, not automated. Don't add UI tests as a side effect of a view-only story; that would be introducing a new, unscoped pattern.
- Run `swift test` from the repo root (not `xcodebuild test`, which is unavailable here) to actually execute the engine-logic suite in this devcontainer — see the Environment section above. `StoryRunEngine` itself doesn't exist yet (not started as of Epic 5 completion; specced for Epic 2) — as of now `ForkedEchoes/Engine/` contains only `RunSnapshotPresence.swift`.

### Dynamic Type & Accessibility

- Always bind to a **named iOS text style** (`.largeTitle`, `.body`, `.subheadline`, `.caption2`, etc.) via `.font(...)`, never `Font.system(size:)` — this is what makes Dynamic Type scaling automatic and testable rather than aspirational.
- 44pt minimum tap target is a **day-one baseline** for every actionable element, never deferred to a later "polish" story.
- `tracking(_:)` takes **points, not `em`** — when converting a DESIGN.md `em`-relative tracking value, compute the approximate point value at the token's base font size, and wrap it in `@ScaledMetric(relativeTo:)` (not a fixed literal) so the letter-spacing-to-font-size ratio keeps holding at accessibility Dynamic Type sizes, not just the default category.

### Design tokens (colors, spacing, sizing)

- DESIGN.md's kebab-case token names (e.g. `surface-base`) map to PascalCase Xcode Color Set names (`SurfaceBase`) → generated camelCase Swift symbols (`Color.surfaceBase`). Always use the generated symbol, never a string-keyed `Color("...")` lookup.
- **Numeric layout literals (spacing, width/height caps, opacity, border width) must trace to a source, not float free:**
  - If DESIGN.md defines a token for the value (the 8pt spacing scale, `min-tap-target`, `column-max-width-landscape`, etc.), reference a named Swift constant derived from that token — not an inline literal.
  - If there's no DESIGN.md token, define a descriptively-named local constant instead of an inline literal.
  - If the same value shows up in more than one place with the same semantic meaning (e.g. an action-stack width cap used identically on two screens), those call sites must share **one** constant, not duplicate definitions.
  - (Formalized as Story 1.6 — "Named Design Constants for Layout Values" — since the codebase currently has several of these as bare literals; new code should follow the rule above even before 1.6 lands.)

### Buttons

- iOS 26's default `.buttonStyle(.borderedProminent)`/`.bordered` render rounded ("Liquid Glass") — incompatible with DESIGN.md's sharp-corners-everywhere rule. Use a custom `ButtonStyle` instead of trying to recolor the system styles.
- Custom `ButtonStyle`s must: read `@Environment(\.isEnabled)` and dim when disabled (the native styles provide this for free — easy to silently drop when replacing them), and add `.contentShape(Rectangle())` whenever the background is transparent/border-only (otherwise hit-testing only covers the stroke pixels, not the full frame).

### File organization

- `Views/<ScreenName>/<ScreenName>View.swift`, one `struct <ScreenName>View: View` per file, with a `#Preview`. No per-screen ViewModel — `StoryRunEngine` is the single shared source of state (AD-3).
- `Views/` (and other top-level source groups) are `PBXFileSystemSynchronizedRootGroup`s — adding, renaming, or deleting `.swift` files/folders under them needs **zero** `project.pbxproj` edits; Xcode auto-discovers on disk.

### Cross-story contracts

- When a story establishes something a *later* story must reuse exactly (e.g. `RunSnapshotPresence`'s `UserDefaults` key, later consumed by Story 2.4's real `RunSnapshot`), document the literal value prominently in that story's Completion Notes so the later story's dev agent finds it — a silent mismatch breaks the feature with no compile-time signal.

### Resolving doc conflicts

- When `epics.md`/`DESIGN.md`/`EXPERIENCE.md`/mockups disagree (has happened at least twice — the circuit-frame-on-Tutorial question, and Home's headline case), the most recent explicit team/user decision wins and gets recorded directly in the story file (a "RESOLVED CONFLICT" banner). Don't re-litigate a resolved conflict in a later story; don't silently pick a side without recording the decision.

## Pre-Completion Self-Check

Before moving a story to review, re-scan the diff against this checklist — these are all rules stated above that were missed on first pass in Epic 1 and only caught by code review (Story 1.4). Reading the rules once at story start isn't enough; re-check against them right before handoff:

- [ ] Any `tracking()`/letter-spacing value wrapped in `@ScaledMetric(relativeTo:)`, not a fixed point offset
- [ ] Any button with a transparent/border-only background has `.contentShape(Rectangle())`
- [ ] Any custom `ButtonStyle` reads `@Environment(\.isEnabled)` and dims when disabled
- [ ] Any ternary-selected `LocalizedStringKey` has an explicit type annotation
- [ ] `grep` for `Font.system(size:)`, `.lineLimit()`, `.fixedSize()` — none introduced without a documented reason
- [ ] Any type/file deleted or renamed this session: `grep -rn "<old name>"` across the **whole repo** (not just the files you remember touching) both before deleting and again after, confirming zero remaining code references — only historical story/retro docs referencing the old name are expected to remain. (Story 2.1, 2026-07-31 — `StoryChoicePlaceholderView` was deleted after checking only 2 of 3 actual call sites; `TutorialView.swift`'s own `#Preview` was missed and broke the Xcode build. A repo-wide grep, not a remembered file list, is the only version of this check that's actually reliable.)

Add a new item here whenever a future code review catches something that should have been self-caught — that's the signal this checklist is missing an entry, not that the rule doesn't belong somewhere else in this file.

## Pre-Creation Acceptance-Criteria Check

Before a story is marked ready-for-dev, `create-story` must run this check against its own draft AC — added from Epic 5's retrospective (2026-07-28), after two stories (5.2, 5.3) shipped without an AC that would have surfaced the cold-launch orientation bug before a sprint demo caught it manually:

- [ ] Every AC set includes an explicit testing clause: a Swift Testing AC when engine logic (AD-7 scope) is touched, or a manual-verification AC (concrete steps + where to log the result, e.g. Completion Notes) when it isn't. Model the manual-verification AC on Story 5.4's AC #3 ("the result is recorded in the story's Completion Notes List").
- [ ] Ask explicitly, for this story: "what could surface after implementation that this AC doesn't already probe for?" — if the answer isn't "nothing," add an AC that closes the gap before the story leaves planning.

## Process Agreements (from retrospectives)

- **Out-of-band work stays transparent in real time.** If any agent does work outside `create-story`/`dev-story` (e.g. a direct design pass), it gets a story file and a `sprint-status.yaml` entry in the same session the work happens — not backfilled later once someone notices the tracking gap. (Epic 5 retro, 2026-07-28 — Story 5.1's design work was done directly and only got a story file during Story 5.2's kickoff.)
- **Report Simulator/manual verification inline, when it happens.** A story's Completion Notes gets a one-line confirmation (date + what was checked) at the moment verification happens, not retroactively. (Epic 1 sprint-demo follow-up, 2026-07-26; reinforced by the Pre-Creation Acceptance-Criteria Check above.)
- **Actively request the user's Xcode build/Simulator check at the end of every session that touches app code — don't just passively note it's unverified.** The user (new to Swift/iOS, 25 years of general engineering experience) has explicitly asked to keep being told this is required and to be the one who reports the result back, rather than the agent inferring or assuming success. This devcontainer has no Xcode/Simulator and genuinely cannot verify a real build (confirmed twice in Story 2.1: a `Package.swift` module-structure bug and a missed deleted-symbol reference both passed every check available here and were only caught by the user's own Xcode build). Treat `Package.swift` edits, any deletion/rename, and any multi-file change as higher-risk and say so explicitly when handing off — not as a disclaimer buried in Completion Notes, but as a direct ask for the specific thing to check. (Added 2026-07-31, after Story 2.1 needed two rounds of user-reported Xcode build failures to reach a working state.)

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code (both `create-story` and `dev-story` load it automatically as a persistent fact on every run).
- Follow ALL rules exactly as documented.
- When in doubt, prefer the more restrictive option.
- Update this file if new patterns emerge — future stories' code reviews are the natural source of new entries.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update when the technology stack changes.
- Review periodically for outdated rules (e.g. once Story 1.6 lands, the magic-number rule's "formalized as Story 1.6" note can drop the forward reference).
- Remove rules that become obvious over time.

Last Updated: 2026-07-31 (Story 2.1: `Package.swift` must be ONE target spanning `Content/` + `Engine/` via `sources`/`exclude`, matching Xcode's real single-target structure — never split them, and never guard a cross-target import as a workaround (both were tried and rejected during this story; see its Change Log for the full account). Also added: engine-logic Swift Testing suites genuinely execute via `swift test` here (not just parse-check) since Story 5.4's `Package.swift`; a rule that any `Package.swift`/deletion/rename change should default to matching Xcode's real structure and get a repo-wide grep check, since this devcontainer cannot verify an actual Xcode build; and a Process Agreement to actively request the user's Xcode/Simulator verification at session end. Full narrative history consolidated here from this story's own Change Log — see `2-1-minimal-story-content-and-engine-foundation.md` for the blow-by-blow.)
