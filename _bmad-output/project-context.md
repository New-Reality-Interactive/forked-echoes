---
project_name: 'game'
user_name: 'Vscode'
date: '2026-07-26'
sections_completed: ['technology_stack', 'localization', 'navigation', 'landscape', 'centering_pattern', 'testing', 'accessibility', 'design_tokens', 'buttons', 'file_organization', 'cross_story_contracts', 'doc_conflicts', 'pre_completion_checklist']
status: 'complete'
rule_count: 46
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

- **This devcontainer has a Linux Swift toolchain (`swiftc`, Swift 6.3.3) but no Xcode/Apple SDKs** (`xcodebuild` unavailable; `UIKit`/`SwiftUI` don't resolve — `swiftc -typecheck` on a file importing either fails with `no such module`). That means real parser-level syntax validation is available and should be used: run `swiftc -parse <file>.swift` on new/edited `.swift` files for genuine syntax verification, instead of eyeballing brace/paren balance. Full compilation, build/run, and Simulator verification (visual check, VoiceOver, Dynamic Type, rotation) still cannot happen here — always flag those explicitly for the user rather than claiming they passed. Other static checks remain: JSON validity (`python3 -m json.tool` on `.xcstrings`/`Contents.json`), brace/paren balance checks on touched `.pbxproj` files (no parser-level tool covers these), and `grep` for banned patterns (see below).

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

Add a new item here whenever a future code review catches something that should have been self-caught — that's the signal this checklist is missing an entry, not that the rule doesn't belong somewhere else in this file.

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

Last Updated: 2026-07-28 (added Pre-Completion Self-Check, from Epic 1 retrospective)
