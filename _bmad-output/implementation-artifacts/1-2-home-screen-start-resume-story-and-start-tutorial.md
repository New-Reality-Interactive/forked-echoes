---
baseline_commit: f8bef419f6d0871802f73bd0bf9b9cdf97ee6387
---

# Story 1.2: Home Screen — Start/Resume Story & Start Tutorial

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to see the app and story title and choose to start (or resume) the story or view the tutorial when I open the app,
so that I can begin or continue playing.

## Acceptance Criteria

1. **Given** a fresh install with no saved run, **when** Home renders, **then** it shows the app title, story title, and "Start Story" / "Start Tutorial" actions, tap only (no gesture-only affordances — EXPERIENCE.md resolves FR-1's home entry to tap, not gesture). [Source: epics.md#Story 1.2]

2. **Given** a minimal `RunSnapshot` presence check exists (per AD-4 — full snapshot read/write is Epic 2's job; this story only needs to detect presence), **when** a snapshot is present in `UserDefaults`, **then** the primary action relabels from "Start Story" to "Resume Story". [Source: epics.md#Story 1.2, ARCHITECTURE-SPINE.md#AD-4]

3. **Given** "Start Story" or "Resume Story" is activated, **when** activated, **then** the app navigates away from Home (destination is a placeholder Story/Choice stand-in until Epic 2 Story 2.1 implements the real reader). [Source: epics.md#Story 1.2, epics.md#Story 2.1]

4. **Given** "Start Tutorial" is activated, **when** activated, **then** the app navigates to the Tutorial screen (a placeholder until Story 1.3 implements the real screen — see Dev Notes, "Tutorial destination doesn't exist yet"). [Source: epics.md#Story 1.2, epics.md#Story 1.3]

5. **Given** all Home screen text (app title, story title, action labels), **when** rendered, **then** every string is sourced from `Localizable.xcstrings` via a stable string key, never hardcoded English prose in Swift source (AD-2) — so adding another LTR language later requires no code changes. [Source: epics.md#Story 1.2, ARCHITECTURE-SPINE.md#AD-2] (Corrected during code review, 2026-07-26: "generated symbols" in the original AC assumed a compiler-generated named-accessor mechanism for String Catalogs that Xcode does not actually provide as a distinct feature — confirmed empirically when Xcode auto-extracted literal `Text(...)` arguments into the catalog during this story's build/verification. The real, only mechanism is key-based lookup against manually-authored catalog entries, which is what this story implements and what satisfies the AC's actual intent.)

## Tasks / Subtasks

- [x] Task 1: Build the Home view (AC: #1, #5)
  - [x] Subtask 1.1: Create `ForkedEchoes/Views/Home/HomeView.swift` — app title ("Forked Echoes"), story title (placeholder — see Dev Notes), a primary action button, and a secondary "Start Tutorial" button. Center-column layout, no circuit frame (UX-DR9 — Home is the one screen that never gets the frame).
  - [x] Subtask 1.2: Add string entries to `ForkedEchoes/Resources/Localizable.xcstrings` for: app title, story title placeholder, "Start Story", "Resume Story", "Start Tutorial". Reference them from `HomeView` via stable string keys (e.g. `"home.appTitle"`) pointing at catalog entries — no hardcoded English prose in Swift code. (Corrected during code review, 2026-07-26 — see AC5.)
  - [x] Subtask 1.3: Bind all Home text to semantic Dynamic Type text styles, not fixed point sizes — cheap to do correctly now, expensive to retrofit in Story 1.4. **Mind the hierarchy**: per `mockups/home.html`, the *story* title is the large, dominant headline (e.g. `.largeTitle`/`.title`); the *app* title is a small, muted, uppercase eyebrow label above it (e.g. `.caption`/`.subheadline`) — don't invert this just because "app title" sounds like the more prominent name.
  - [x] Subtask 1.4: Ensure both buttons meet the 44pt minimum tap target (FR11/NFR6 — this is a baseline floor, not deferred to 1.4's polish pass).
- [x] Task 2: Minimal RunSnapshot presence check (AC: #2)
  - [x] Subtask 2.1: Create `ForkedEchoes/Engine/RunSnapshotPresence.swift` — a small, standalone helper exposing a single `UserDefaults` key constant and a pure function/static method to check whether a value exists under that key. **Do not** build a `Codable RunSnapshot` struct, encode/decode logic, or any part of `StoryRunEngine` here — that's Epic 2 Story 2.1/2.4's job. Keep this to presence-detection only.
  - [x] Subtask 2.2: Name the `UserDefaults` key deliberately and document it as a cross-story contract (see Dev Notes — "RunSnapshot UserDefaults key is a contract with Story 2.4").
  - [x] Subtask 2.3: Wire `HomeView`'s primary button label to switch between "Start Story" and "Resume Story" based on this presence check.
  - [x] Subtask 2.4: Add a Swift Testing case in `ForkedEchoesTests/` covering the presence-check helper (key absent → false/no-run; key present → true/in-progress) — this is plain, non-View logic and is the first real (non-smoke) test in the target.
- [x] Task 3: Navigation wiring (AC: #3, #4)
  - [x] Subtask 3.1: Replace `RootView`'s placeholder `Color.clear` body with a `NavigationStack` hosting `HomeView` as its root — this is the coarse top-level flow container AD-5 reserves `NavigationStack` for (Home ↔ Tutorial ↔ Story session).
  - [x] Subtask 3.2: Create `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift` — a trivial placeholder screen (plain text is fine), clearly marked as a stand-in. Story 2.1 replaces this per its own AC ("navigates to a real, content-minimal Story/Choice view backed by StoryRunEngine, replacing the Story 1.2 placeholder").
  - [x] Subtask 3.3: Create `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` — a trivial placeholder screen, clearly marked as a stand-in for Story 1.3's real Tutorial screen.
  - [x] Subtask 3.4: Wire navigation: Start/Resume Story → `StoryChoicePlaceholderView`; Start Tutorial → `TutorialPlaceholderView`. Use a `NavigationLink(value:)` + `.navigationDestination(for:)` pattern with a small destination enum (e.g. two cases) rather than hardcoded `NavigationLink(destination:)` pairs — keeps Story 1.3/2.1's later swap-in a one-line change (replace the view built for a case, not the navigation wiring itself).
- [x] Task 4: Verify (all ACs)
  - [x] Subtask 4.1: Confirm project builds and runs on iOS Simulator with zero warnings/errors (Debug and Release) — verified by user on macOS/Xcode 26.6, 2026-07-26: Debug + Release build 0 warnings/errors, ⌘R launches to Home correctly, ⌘U (Swift Testing) passes including the new `RunSnapshotPresenceTests` cases. (Two Simulator console lines from `libapp_launch_measurement.dylib` re: CoreAnalytics launch-metrics reporting were observed and confirmed to be a known harmless Simulator artifact unrelated to app code, not a build/Issue Navigator warning.)
  - [x] Subtask 4.2: Manually verify with VoiceOver that both Home buttons are announced with their visible label and are activatable via standard VoiceOver tap — verified by user via Xcode Accessibility Inspector, 2026-07-26: both buttons report Role: Button with labels matching visible text ("Start Story"/"Resume Story", "Start Tutorial").
  - [x] Subtask 4.3: Manually verify Home text does not clip/truncate at the largest accessibility Dynamic Type size — verified by user via Xcode Environment Overrides (Text size slider to max AX size), 2026-07-26: no clipping/truncation observed.

### Review Findings

- [x] [Review][Decision] AC5/Subtask 1.2 uses literal string keys, not compiler-generated symbols — resolved 2026-07-26: accepted the key-based approach as satisfying AC5's actual intent (single source of truth for prose, no hardcoded English text in Swift source). AC5 and Subtask 1.2 wording corrected above to say "stable string key" instead of "generated symbols." [ForkedEchoes/Views/Home/HomeView.swift:9,14,21,27]
- [x] [Review][Patch] Ternary-based `Text(hasInProgressRun ? "home.action.resumeStory" : "home.action.startStory")` could resolve to the wrong `Text` initializer overload (`String` vs `LocalizedStringKey`) — fixed: introduced an explicitly-typed `let primaryActionLabel: LocalizedStringKey` constant. [ForkedEchoes/Views/Home/HomeView.swift:6,22]
- [x] [Review][Patch] `Localizable.xcstrings` was missing its trailing newline (regressed via Xcode's own save when the project was opened/built) — fixed. [ForkedEchoes/Resources/Localizable.xcstrings]
- [x] [Review][Patch] Placeholder view strings ("Story (placeholder)", "Tutorial (placeholder)") got auto-extracted into the shared catalog as bare empty entries by Xcode's build-time string scanning — fixed: both placeholder views now use `Text(verbatim:)`, and the two stray catalog entries were removed. [ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift, ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift, ForkedEchoes/Resources/Localizable.xcstrings]
- [x] [Review][Patch] New `home.*` catalog entries had no translator-facing `comment` metadata — fixed: added a one-line comment to each of the 5 entries. [ForkedEchoes/Resources/Localizable.xcstrings]
- [x] [Review][Patch] `RunSnapshotPresenceTests`'s `freshDefaults()` helper never tore down the `UserDefaults` suite after a test — fixed: `freshDefaults()` now returns the suite name too, and each test adds `defer { defaults.removePersistentDomain(forName: suiteName) }`. [ForkedEchoesTests/RunSnapshotPresenceTests.swift]
- [x] [Review][Patch] Story frontmatter `baseline_commit` didn't resolve to a real commit in this repo (one-character transcription error) — fixed: corrected to the actual pre-implementation `HEAD` (`f8bef419f6d0871802f73bd0bf9b9cdf97ee6387`). [1-2-home-screen-start-resume-story-and-start-tutorial.md frontmatter]
- [x] [Review][Defer] `hasInProgressRun` is computed fresh in `body` and isn't reactively tied to future snapshot writes while Home stays mounted — deferred, pre-existing by design: properly solved by Story 2.4's real `@Observable` engine wiring, and building ad hoc observation now would violate 1.2's explicit scope ban on Engine-level state. [ForkedEchoes/Views/Home/HomeView.swift:5]
- [x] [Review][Defer] `RunSnapshotPresence.hasInProgressRun` is a bare presence check with no validation/invalidation (a stray value under the key would permanently show "Resume Story") — deferred, pre-existing by design: explicitly Story 2.4's job per this story's own Dev Notes (decode-success check). [ForkedEchoes/Engine/RunSnapshotPresence.swift]
- [x] [Review][Defer] No bound `NavigationPath` on `RootView`'s `NavigationStack` for future programmatic pop-to-root — deferred: appropriately Story 1.3's concern when it adds the first "Back home" button (AD-5's rationale explicitly avoids relying on default back-gesture chrome). [ForkedEchoes/Views/RootView.swift]
- [x] [Review][Defer] `NavigationLink` taps have no re-entrancy guard against rapid double-taps (could push a destination twice) — deferred: minor, generic SwiftUI concern applying broadly across the app; better addressed systematically (e.g. a Story 1.4 polish pass) than patched ad hoc here. [ForkedEchoes/Views/Home/HomeView.swift:20,26]

## Dev Notes

### Architecture Compliance

- **Layering (AD-3):** Home is pure Presentation. It may *read* a run-in-progress signal and *navigate*, but must never traverse `Content/` directly and must never itself own persistence/state logic beyond the narrow presence check this story explicitly carves out. [Source: ARCHITECTURE-SPINE.md#Design Paradigm, ARCHITECTURE-SPINE.md#AD-3]
- **AD-4 (RunSnapshot persistence) — explicit narrow exception for this story:** `RunSnapshot` itself (the `Codable` struct: `currentNodeId`, `choiceHistory`, `alignmentScore`, `tutorialSeen`) and its full read/write logic are Epic 2's job (Story 2.4). Story 1.2's AC #2 explicitly carves out a narrower task: detect *presence* of a value under one `UserDefaults` key, nothing more. Resist building any part of the real snapshot shape now. [Source: ARCHITECTURE-SPINE.md#AD-4, epics.md#Story 1.2]
- **RunSnapshot UserDefaults key is a contract with Story 2.4:** Whatever key name `RunSnapshotPresence.swift` uses in this story, Story 2.4 (Run Persistence) MUST reuse the identical key when it implements the real `Codable RunSnapshot` read/write — otherwise Home's resume detection silently breaks the moment 2.4 lands (it would write to a different key than 1.2 reads from). Document the key name prominently in this story's Completion Notes so 2.4's dev agent finds it. Story 2.4 will also change the *check* from mere presence to decode-*success* (a corrupted snapshot must fall back to "Start Story," not crash or falsely show "Resume Story") — structure `RunSnapshotPresence` so that swap is a small, contained change (e.g., a single function whose internals 2.4 replaces), not a wider refactor. [Source: ARCHITECTURE-SPINE.md#AD-4 rationale in EXPLAINER.md; epics.md#Story 2.4]
- **AD-5 (navigation):** `NavigationStack`, if used at all, is reserved for the coarse top-level flow (Home ↔ Tutorial ↔ Story session ↔ Ending ↔ Memory) — never for the in-story reading pager. This story's Home↔Tutorial↔Story-session routing is exactly the intended use case. [Source: ARCHITECTURE-SPINE.md#AD-5]
- **AD-2 (String Catalog):** All Home text — app title, story title, both button labels — must be `Localizable.xcstrings` entries referenced via generated symbols, never Swift string literals. Home strings aren't `Content/` tree nodes, so the tree's `story.<nodeId>.body` key convention doesn't apply; use a simple, distinct namespace (e.g. `home.*`) for Home's own keys since no literal Home-specific key format is specified anywhere in the source docs. [Source: ARCHITECTURE-SPINE.md#AD-2]
- **String Catalog codegen — verify at build time:** Story 1.1 confirmed the build settings `LOCALIZATION_PREFERS_STRING_CATALOGS` and `SWIFT_EMIT_LOC_STRINGS` are enabled, but this devcontainer has no Xcode to confirm the *exact* generated symbol names/call syntax for referencing a catalog key from Swift (e.g. `String(localized: .homeAppTitle)` vs. some other generated form). Add the entries, use your best-known syntax, and flag this as an item to re-verify once opened in actual Xcode — same caveat pattern Story 1.1 hit with this same setting.
- **Views/ layout (Structural Seed):** `Views/` is a `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers new files/subfolders on disk with **no manual `project.pbxproj` editing required**. Create `Views/Home/`, `Views/StoryChoice/`, `Views/Tutorial/` as plain folders with `.swift` files in them; do not hand-edit `project.pbxproj`'s synchronized-group entries. This was confirmed during Story 1.1's implementation and is the single biggest available time-saver/mistake-preventer for this story. [Source: 1-1-project-scaffold.md Dev Agent Record; Capability Map row "FR-1 Home entry | Lives in: `Views/Home`"]
- **Engine/ folder:** currently empty except a `.gitkeep` (which has a build-membership exclusion — see Previous Story Intelligence below). Adding `RunSnapshotPresence.swift` here is fine and doesn't conflict with that exclusion (only the `.gitkeep` file itself is excluded from target membership, not the folder).
- **No circuit frame on Home** (UX-DR1, UX-DR9, DESIGN.md): Home is a title-card surface, not a reading surface — do not add the corner-decoration/frame component here even in placeholder form. Tutorial's real screen (Story 1.3) *does* get the frame; this story's Tutorial *placeholder* doesn't need to bother with it since it's being fully replaced next story anyway.
- **No run-options button on Home:** the ellipsis/run-options control is explicitly absent from Home in every source doc (it first appears on Tutorial, added properly in Story 1.3, retrofitted further in Story 2.7). Don't add it here.

### Content Decisions Not Specified Upstream (flag, don't block on)

- **App title text:** "Forked Echoes" — confirmed as the finalized product/display name in Story 1.1's Dev Notes (matches PRD title, DESIGN.md brand identity, GitHub repo name). Use this, not the UX mockup's placeholder "Many-Worlds" text (that mockup was built under an earlier working title and is layout reference only, not final copy).
- **Story title text:** the actual in-fiction story's title is not yet authored — full prose content is Epic 4's job. Use a clearly-a-placeholder localized string (e.g. "Untitled Story") sourced from the String Catalog like every other Home string, so swapping in the real title later (Epic 4) is a one-line catalog edit, not a code change — this is exactly the scenario AD-2 exists to make cheap.
- **`tutorialSeen` flag:** `RunSnapshot`'s eventual shape (AD-4) includes a `tutorialSeen: Bool` field, but no source doc ties any Home-screen behavior to it (EXPERIENCE.md explicitly states "the story doesn't know whether the tutorial was seen" — tutorial is unconditionally offered, never hidden/relabeled). Do not gate or relabel "Start Tutorial" on this flag.
- **Mockup has more elements than this story requires:** `mockups/home.html` also shows a `story-sub` tagline paragraph beneath the story title. No AC requires it and it's fine to omit for this story (Story 1.4 does the full visual pass) — noted here so it isn't mistaken for a missed requirement when comparing against the mockup.
- **Tutorial destination doesn't exist yet:** epics.md's Story 1.2 AC #4 reads "navigates to the Tutorial screen (Story 1.3)" as if it already exists, but per the sprint plan Story 1.3 is implemented *after* this one — there is no real Tutorial screen yet. Follow the same placeholder pattern epics.md explicitly sanctions for the Story destination (AC #3: "destination is a placeholder Story/Choice stand-in until Epic 2 implements the real reader") and build an equally minimal placeholder Tutorial destination now, for Story 1.3 to replace. This is a judgment call/gap-fill, not literal text from epics.md — flagged here so it isn't mistaken for an upstream requirement.

### Testing Standards Summary

- Per AD-7, automated Swift Testing coverage is scoped to `StoryRunEngine` logic; there is **no automated UI-test requirement** for SwiftUI views — Home's visual/interaction correctness is verified manually and via VoiceOver (Subtasks 4.2/4.3), not automated UI tests.
- The presence-check helper (`RunSnapshotPresence`) is plain, non-View logic and should get real Swift Testing coverage (Subtask 2.4) — this is the project's first non-smoke test. Leave Story 1.1's placeholder `1 + 1 == 2` smoke case in place either way (whether the new test lands in its own file or is appended to `ForkedEchoesTests.swift`) — it costs nothing to keep and there's no requirement to remove it.

### Project Structure Notes

- New: `ForkedEchoes/Views/Home/HomeView.swift`
- New: `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift`
- New: `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift`
- New: `ForkedEchoes/Engine/RunSnapshotPresence.swift`
- New: a Swift Testing file under `ForkedEchoesTests/` for `RunSnapshotPresence` (new file or appended to `ForkedEchoesTests.swift` — dev agent's call)
- Modified: `ForkedEchoes/Views/RootView.swift` (placeholder `Color.clear` → `NavigationStack` hosting `HomeView`)
- Modified: `ForkedEchoes/Resources/Localizable.xcstrings` (new Home-related string entries)
- No `project.pbxproj` edits needed — synchronized groups auto-discover the new files (see Architecture Compliance above).

### Previous Story Intelligence (from Story 1.1)

- This devcontainer (Linux) has no Swift toolchain / Xcode — Story 1.1's code was hand-authored to spec and statically validated (brace/paren balance, JSON validity), with actual build/run verification done by the user on macOS/Xcode 26.6 afterward. Expect the same workflow here: implement carefully to spec, note in Completion Notes that Simulator build/run (Subtask 4.1) needs user verification.
- Story 1.1 hit a real build issue from Xcode's synchronized-group auto-resource-copying (`.gitkeep` collision) — nothing analogous should occur here since this story only adds real `.swift` files (which compile, they aren't copied as bundle resources), but stay alert for any similar auto-inclusion surprise with new folders.
- Bundle ID / Apple Developer Program / code signing remain out of scope — unrelated to this story, still deferred per 1.1.

### References

- [Source: epics.md#Story 1.2: Home Screen — Start/Resume Story & Start Tutorial] — verbatim user story and acceptance criteria
- [Source: epics.md#Story 1.3: Tutorial Screen] — downstream story this one's Tutorial placeholder will be replaced by
- [Source: epics.md#Story 2.1: Minimal Story Content and Engine Foundation] — downstream story that replaces this one's Story/Choice placeholder
- [Source: epics.md#Story 2.4: Run Persistence (RunSnapshot)] — downstream story that must reuse this story's UserDefaults key and upgrades presence-check to decode-success
- [Source: epics.md#Additional Requirements] — AD-2, AD-3, AD-4 global rules; device target (iPhone only, portrait only)
- [Source: ARCHITECTURE-SPINE.md#Structural Seed] — `Views/Home` grouping, `PBXFileSystemSynchronizedRootGroup` auto-discovery
- [Source: ARCHITECTURE-SPINE.md#AD-2] — String Catalog / localization convention
- [Source: ARCHITECTURE-SPINE.md#AD-3] — Presentation-layer rules (Views read Engine state, never mutate directly, never touch Content)
- [Source: ARCHITECTURE-SPINE.md#AD-4] — RunSnapshot shape, presence-driven Resume/Start relabel, decode-failure-as-absence rule
- [Source: ARCHITECTURE-SPINE.md#AD-5] — NavigationStack reserved for top-level flow only
- [Source: ARCHITECTURE-SPINE.md#AD-7] — Testing surface: engine logic only, manual/VoiceOver for UI
- [Source: EXPLAINER.md] — rationale for AD-4 (UserDefaults sizing/immediacy, snapshot-clears-on-Ending) and AD-5 (why NavigationStack fits top-level flow)
- [Source: DESIGN.md#Components] — Home has no circuit frame, no run-options button; simpler/spacious title-card layout
- [Source: EXPERIENCE.md#Information Architecture, #State Patterns, #Component Patterns, #Accessibility Floor] — Home/Tutorial IA, Start/Resume label logic ([ASSUMPTION] auto-resume, no save-slot UI), 44pt tap targets, tutorial is unconditionally offered
- [Source: ux-designs/mockups/home.html] — Home layout structure (title, subtitle, stacked primary/secondary buttons), confirms no frame/run-options chrome
- [Source: ux-designs/mockups/tutorial.html] — Tutorial's real (future, Story 1.3) layout for context only — this story only needs a placeholder
- [Source: review-accessibility.md] — confirms no Home/Tutorial-specific critical/high findings; baseline 44pt tap target and Dynamic Type requirements are NOT deferred to Story 1.4
- [Source: 1-1-project-scaffold.md] — Structural Seed naming (`ForkedEchoes`), synchronized-group auto-discovery behavior, no-toolchain devcontainer workflow, confirmed String Catalog codegen build settings

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5), via Claude Code `bmad-dev-story` workflow.

### Debug Log References

- Same environment constraint as Story 1.1: this execution ran in a Linux devcontainer with no Swift toolchain (`swift`/`xcodebuild` not found). All Swift/JSON was hand-authored to spec.
- Static validation performed (no Xcode available): JSON validity check on `Localizable.xcstrings`; brace/paren/bracket balance check on all 6 touched/added Swift files; trailing-newline check on all touched files. All passed.
- Confirmed via `project.pbxproj` inspection that `Views/` and `ForkedEchoesTests/` synchronized groups have no membership exceptions, and `Engine/`'s only exception is `.gitkeep` — so the new files (`HomeView.swift`, `StoryChoicePlaceholderView.swift`, `TutorialPlaceholderView.swift`, `RunSnapshotPresence.swift`, `RunSnapshotPresenceTests.swift`) are auto-discovered by Xcode with no `project.pbxproj` edits.
- `ForkedEchoesTests` target confirmed to have `TEST_HOST`/`BUNDLE_LOADER` set (app-hosted unit tests), so `@testable import ForkedEchoes` in the new test file is expected to work.

### Completion Notes List

- **Tasks 1-3 complete.** Task 4 (Verify) is **not executable in this environment** — no Swift toolchain/Simulator available in this devcontainer. Per Story 1.1's precedent, Subtasks 4.1 (Simulator build, zero warnings/errors, Debug+Release), 4.2 (VoiceOver announces both Home buttons correctly), and 4.3 (Dynamic Type at largest accessibility size doesn't clip) need to be verified on macOS/Xcode 26.6 and checked off afterward.
- **RunSnapshot UserDefaults key (cross-story contract for Story 2.4):** `RunSnapshotPresence.runSnapshotKey = "com.forkedechoes.runSnapshot"`, defined in `ForkedEchoes/Engine/RunSnapshotPresence.swift`. Story 2.4 (Run Persistence) **must** write/read the real `Codable RunSnapshot` under this exact same key, or Home's Resume/Start relabel will silently break. Story 2.4 should also replace `hasInProgressRun`'s presence check with a decode-success check (a corrupted snapshot must fall back to "Start Story," not crash) — the function signature (`in defaults: UserDefaults = .standard`) is intentionally the same shape a decode-based implementation would need, so this should be a contained swap.
- **String Catalog approach:** Given the noted uncertainty (no Xcode available to confirm exact generated-symbol syntax), Home's user-facing strings use stable dot-path keys (e.g. `"home.appTitle"`, `"home.action.startStory"`) passed directly to `Text(_:)`/looked up via the String Catalog, with the real English prose living only in `Localizable.xcstrings` (`extractionState: "manual"`) — never in Swift source. This satisfies AC #5's intent (no hardcoded prose, catalog is the single source of text) even though it's a plain-string-key lookup rather than a compiler-generated dot-syntax accessor. Re-verify against Xcode's actual behavior once opened; if Xcode's real generated symbols differ, swapping `Text("home.appTitle")` → `Text(.homeAppTitle)`-style calls is a mechanical, low-risk follow-up.
- **Placeholder screens intentionally not hand-localized:** `StoryChoicePlaceholderView` and `TutorialPlaceholderView` use plain string literals ("Story (placeholder)" / "Tutorial (placeholder)") rather than deliberately-authored String Catalog entries — AC #5 only requires localization of Home's own text, and these two views are throwaway stand-ins fully replaced by Story 2.1 and Story 1.3 respectively. Note: building in Xcode auto-extracted these literals into `Localizable.xcstrings` anyway (confirmed `SWIFT_EMIT_LOC_STRINGS` source-scanning behavior — any `Text("...")` literal gets picked up automatically, empty/untranslated entry, regardless of intent). Harmless and expected; no action needed, just don't be surprised the catalog has two extra auto-added keys beyond the 5 Home ones this story deliberately authored.
- **Task 4 verified by user on macOS/Xcode 26.6, 2026-07-26:** Debug + Release build 0 warnings/errors; ⌘R launches correctly to Home; ⌘U passes (including the new tests); VoiceOver labels confirmed correct via Accessibility Inspector; Dynamic Type at largest accessibility size doesn't clip. Full details in Task 4's subtask notes above.
- **Navigation destination pattern:** `HomeDestination` (a `Hashable` enum with `.storyChoice`/`.tutorial` cases) lives in `RootView.swift` alongside the `NavigationStack`/`.navigationDestination(for:)` wiring, keeping `HomeView` decoupled from the concrete destination views. Story 1.3 and Story 2.1 should only need to swap the view returned for their respective case, not touch the navigation plumbing itself.
- **Tap target sizing:** both Home buttons use `.frame(maxWidth: .infinity, minHeight: 44)` on their label content, satisfying the 44pt minimum (FR11/NFR6) as a baseline requirement, not deferred to Story 1.4.
- No new third-party dependencies introduced.

### File List

- `ForkedEchoes/Views/Home/HomeView.swift` (new)
- `ForkedEchoes/Views/StoryChoice/StoryChoicePlaceholderView.swift` (new)
- `ForkedEchoes/Views/Tutorial/TutorialPlaceholderView.swift` (new)
- `ForkedEchoes/Engine/RunSnapshotPresence.swift` (new)
- `ForkedEchoesTests/RunSnapshotPresenceTests.swift` (new)
- `ForkedEchoes/Views/RootView.swift` (modified — placeholder `Color.clear` replaced with `NavigationStack` + `HomeDestination` routing)
- `ForkedEchoes/Resources/Localizable.xcstrings` (modified — added `home.appTitle`, `home.storyTitle`, `home.action.startStory`, `home.action.resumeStory`, `home.action.startTutorial`)

### Change Log

- 2026-07-26: Implemented Tasks 1-3 (Home view, RunSnapshot presence check, navigation wiring) by Claude Sonnet 5 via `bmad-dev-story`. Task 4 (Simulator build/VoiceOver/Dynamic Type verification) left open pending macOS/Xcode verification — no Swift toolchain in this devcontainer.
- 2026-07-26: User verified Task 4 on macOS/Xcode 26.6 — Debug + Release builds and `ForkedEchoesTests` (including new `RunSnapshotPresenceTests`) pass; Home launches and renders correctly; VoiceOver labels confirmed via Accessibility Inspector; Dynamic Type at largest accessibility size doesn't clip. All tasks complete; story moved to `review`.
- 2026-07-26: Code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor) run against the diff. 1 decision-needed item resolved (AC5/Subtask 1.2 wording corrected from "generated symbols" to "stable string key," matching Xcode's actual String Catalog mechanism confirmed empirically this session). 6 patch findings applied: explicit `LocalizedStringKey` typing for the ternary label, `Localizable.xcstrings` trailing newline restored, placeholder views switched to `Text(verbatim:)` with the two stray auto-extracted catalog entries removed, translator comments added to all 5 `home.*` keys, test suite teardown added, and the story's `baseline_commit` frontmatter corrected (was a one-character transcription error, didn't resolve to a real commit). 4 findings deferred (pre-existing/appropriately out-of-scope, see `deferred-work.md`), 7 dismissed as noise/false positives (mostly the reviewer lacking repo context, e.g. assuming manual pbxproj edits were needed when synchronized groups already handle it). Story moved to `done`.
