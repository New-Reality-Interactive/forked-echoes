---
baseline_commit: f0789a8e5db871563dab8b9ec5a73624b45164e5
---

# Story 1.4: Home & Tutorial Visual Identity + Accessibility Pass

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player, including one using assistive technology,
I want Home and Tutorial to follow the app's visual identity and be fully usable with VoiceOver and Dynamic Type,
so that the app is usable and on-brand regardless of ability.

## Acceptance Criteria

1. **Given** DESIGN.md tokens needed by Home/Tutorial (headline, body, eyebrow typography; surface/ink colors; spacing scale), **when** applied, **then** Home/Tutorial render per DESIGN.md, with no circuit frame on either screen (UX-DR9, UX-DR10 — the frame is reserved for reading surfaces). [Source: epics.md#Story 1.4, lines 271-275]
2. **Given** VoiceOver is active, **when** navigating Home/Tutorial, **then** every action exposes an accessible label and is operable via standard VoiceOver activation, meeting the 44pt minimum tap target (FR11, NFR6). [Source: epics.md#Story 1.4, lines 277-279]
3. **Given** Dynamic Type is set to an accessibility size, **when** Home/Tutorial render, **then** text scales without truncation or clipping (FR11, NFR8). [Source: epics.md#Story 1.4, lines 281-283]

## ⚠️ RESOLVED CONFLICT — Read Before Starting

Story 1.3's Dev Notes flagged an unresolved conflict between `epics.md`'s Story 1.4 AC ("no circuit frame on either screen") and DESIGN.md/`UX-DR1`/EXPERIENCE.md/both `home.html`+`tutorial.html` mockups, which all independently say Tutorial **is** a reading surface that gets the dormant-brass frame and only Home never does.

**Team decision (this story, 2026-07-26): neither Home nor Tutorial gets the circuit frame.** Follow `epics.md`'s literal AC text. Do **not** add the frame to Tutorial. `DESIGN.md` (Brand & Style, "Home/Tutorial chrome", Do/Don't table), `UX-DR1`, `EXPERIENCE.md`, and the mockups are the ones that need correcting to match this decision — that doc cleanup is not this story's job, just don't let it steer the implementation.

## Tasks / Subtasks

- [x] Task 1: Add DESIGN.md color tokens as Asset Catalog Color Sets (AC: #1)
  - [x] Subtask 1.1: In `ForkedEchoes/Resources/Assets.xcassets`, add four Color Sets, each with an "Any Appearance" (light) and a "Dark" appearance entry, using DESIGN.md's hex values exactly:
    - `SurfaceBase`: `#FAF6EE` / dark `#1C1712`
    - `InkPrimary`: `#241C14` / dark `#F3ECDD`
    - `InkSecondary`: `#6A5A45` / dark `#B7A78D`
    - `SelectedFill`: `#F0DDAF` / dark `#3A2E1E`
    [Source: DESIGN.md frontmatter `colors:` block]
  - [x] Subtask 1.2: `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` is already set in both build configs (`ForkedEchoes.xcodeproj/project.pbxproj` lines 231, 287) — no project setting change needed. These four Color Sets will auto-generate `Color.surfaceBase`, `Color.inkPrimary`, `Color.inkSecondary`, `Color.selectedFill` static members; use those generated symbols, never `Color("SurfaceBase")` string lookups (same "generated symbols, never raw string names" precedent AD-2 already establishes for illustrations). [Source: ARCHITECTURE-SPINE.md AD-2]
  - [x] Subtask 1.3: Do **not** add `surface-raised` or `accent-ember`/`accent-ember-text` — Home/Tutorial have no card-on-page, frame, or echo state, so those tokens have no use here. Only the four colors above are needed. Adding unused tokens now is scope creep against this story's ACs.

- [x] Task 2: Add a typography helper for the eyebrow/headline/body roles (AC: #1, #3)
  - [x] Subtask 2.1: Create `ForkedEchoes/Views/DesignSystem/Typography.swift` (`Views/` is a filesystem-synchronized Xcode group — a new nested folder needs no `project.pbxproj` edit). Add `View` extension methods (not `Font` statics — tracking and `textCase` are `View`/`Text` modifiers, not part of `Font`, so a chainable `some View`-returning method is the right shape, not a computed `Font` property):
    - `.eyebrowStyle()` → `.font(.caption2.weight(.heavy)).tracking(0.1 * captionPointSize).textCase(.uppercase).foregroundStyle(Color.inkSecondary)` — binds to `caption2` (DESIGN.md `iosTextStyle`), weight 800/heavy, tracking `0.1em`, uppercase. [Source: DESIGN.md typography.eyebrow, lines 58-64]
    - `.headlineStyle()` → binds to `largeTitle`, weight 900/black, tracking `-0.02em`, color `Color.inkPrimary`. **Do not uppercase** — DESIGN.md's typography note says "Uppercase" but the approved `home.html`/`tutorial.html` mockups render the story title in Title Case ("The Long Way Home"), and uppercasing a multi-word title would visibly regress against the shipped mockup. Treat the "Uppercase" note as not applicable to this specific use and follow the mockups; flag in your completion notes if you disagree so it can be corrected at review. [Source: DESIGN.md typography.headline, lines 30-36; mockups/home.html line 78]
    - `.bodyStyle()` → binds to `body`, weight 500/medium, color `Color.inkPrimary`. [Source: DESIGN.md typography.body, lines 44-49]
  - [x] Subtask 2.2: `tracking(_:)` takes points, not `em`; DESIGN.md's `em` values are relative to the token's own font size (eyebrow: 12px base × 0.1em ≈ 1.2pt; headline: 34px base × -0.02em ≈ -0.68pt). Use the approximate point values directly (`tracking(1.2)`, `tracking(-0.68)`) — exact fractional precision doesn't matter, matching the mockup's visual proportions does.
  - [x] Subtask 2.3: These three roles are the only ones this story needs (matches AC #1's explicit list: "headline, body, eyebrow"). Do not add `choice-label`, `echo-callback`, `stat`, `meta`, or `caption` roles — those belong to reading-surface stories (Epic 2/3) and have no use on Home/Tutorial.

- [x] Task 3: Add shared primary/secondary action button styling (AC: #1, #2)
  - [x] Subtask 3.1: In the same `Views/DesignSystem/` folder, add button styling matching `mockups/home.html`'s `.btn-primary`/`.btn-secondary` (verified against DESIGN.md's Shapes section: `{rounded.DEFAULT}` = 0px, sharp corners everywhere in the reading UI, no rounded corners on buttons):
      - Primary (e.g. "Start/Resume Story"): `Color.selectedFill` background, `Color.inkPrimary` text, sharp corners (no `cornerRadius`/`RoundedRectangle` — a plain `Rectangle` fill or flat `.background(Color.selectedFill)` with no clip shape).
      - Secondary (e.g. "Start Tutorial", "Back Home"): transparent background, `Color.inkPrimary` text, `2pt` `Color.inkPrimary` border, sharp corners.
  - [x] Subtask 3.2: iOS 26's default `.buttonStyle(.borderedProminent)`/`.bordered)` render with heavily rounded ("Liquid Glass") shapes — that's why this story can't just recolor the existing system button styles and must replace them. A `ButtonStyle` conforming type is the idiomatic reuse point (needed again by later reading-surface stories), but a simpler `.buttonStyle(.plain)` + manual `.background()`/`.overlay(Rectangle().stroke())` on the label works too if you judge the `ButtonStyle` abstraction premature for two call sites — your call, either is acceptable as long as corners stay sharp and colors match Subtask 3.1.
  - [x] Subtask 3.3: Preserve every button's existing `.frame(maxWidth: .infinity, minHeight: 44)` sizing exactly — that already satisfies AC #2's 44pt minimum; this task only changes fill/border/corner treatment, not layout.

- [x] Task 4: Apply tokens to `HomeView.swift` (AC: #1)
  - [x] Subtask 4.1: Replace `Text("home.appTitle")`'s `.font(.subheadline).textCase(.uppercase).foregroundStyle(.secondary)` with `.eyebrowStyle()`.
  - [x] Subtask 4.2: Replace `Text("home.storyTitle")`'s `.font(.largeTitle.bold())` with `.headlineStyle()` (keep `.multilineTextAlignment(.center)`).
  - [x] Subtask 4.3: Apply the primary button style (Task 3) to the `HomeDestination.storyChoice` `NavigationLink` (label: `primaryActionLabel`, i.e. "Start Story"/"Resume Story") and the secondary style to the `HomeDestination.tutorial` `NavigationLink` (label: "Start Tutorial"), replacing `.buttonStyle(.borderedProminent)`/`.buttonStyle(.bordered)`.
  - [x] Subtask 4.4: Set the screen background to `Color.surfaceBase` (currently unset, falling through to the system background). Apply via `.background(Color.surfaceBase)` on the outer `GeometryReader` or `ScrollView`, ignoring safe area as needed so it fills edge-to-edge.
  - [x] Subtask 4.5: Align the actions `VStack`'s `spacing: 14` to the DESIGN.md 8pt spacing scale (UX-DR2) — change to `spacing: 16` (`{spacing.4}`). The outer `spacing: 24` (`{spacing.6}`) and title `spacing: 8` (`{spacing.2}`) are already on-scale; leave them as-is. [Source: DESIGN.md spacing scale, lines 87-95]

- [x] Task 5: Apply tokens to `TutorialView.swift` (AC: #1)
  - [x] Subtask 5.1: Replace `Text("tutorial.eyebrow")`'s styling with `.eyebrowStyle()`.
  - [x] Subtask 5.2: Replace the three mechanic-paragraph `Text` views' `.font(.body)` with `.bodyStyle()`.
  - [x] Subtask 5.3: Apply the secondary button style to "Back Home" and the primary button style to "Start Story"/"Resume Story" (`primaryActionLabel`), replacing `.buttonStyle(.bordered)`/`.buttonStyle(.borderedProminent)`.
  - [x] Subtask 5.4: Set the screen background to `Color.surfaceBase`, same approach as Home (Subtask 4.4).
  - [x] Subtask 5.5: Align the actions `VStack`'s `spacing: 14` to `spacing: 16` (`{spacing.4}`), same fix as Home (Subtask 4.5). The `680pt` landscape width cap on the mechanics text block (added in 1.3's code review) is unrelated to this story's tokens — leave it untouched.
  - [x] Subtask 5.6: Confirm no circuit frame is added — per the Resolved Conflict section above, this is a **deliberate non-change**, not an oversight.

- [x] Task 6: VoiceOver and Dynamic Type verification (AC: #2, #3)
  - [x] Subtask 6.1: Confirm every button/`NavigationLink`'s accessible label still equals its visible text after Tasks 4-5's styling changes (custom `ButtonStyle`/manual background+border approaches can accidentally swallow the label if the content view isn't passed through — verify `configuration.label` or the original `Text(...)` is still rendered, not replaced).
  - [x] Subtask 6.2: Confirm all four action buttons (Home ×2, Tutorial ×2) still measure `minHeight: 44` after the styling change (AC #2) — Task 3 Subtask 3.3 should already guarantee this if followed.
  - [x] Subtask 6.3: Confirm `.eyebrowStyle()`/`.headlineStyle()`/`.bodyStyle()` all bind to named iOS text styles (`caption2`/`largeTitle`/`body`) rather than fixed point sizes, so Dynamic Type continues to scale them automatically (AC #3) — this should already hold if Task 2 is implemented as specified, but verify no `Font.system(size:)` fixed-point usage crept in.
  - [x] Subtask 6.4: Confirm no `.lineLimit()` or `.fixedSize()` was introduced anywhere in Home/Tutorial that would truncate/clip text at accessibility Dynamic Type sizes (AC #3) — none should be needed; the existing `GeometryReader`+`ScrollView`+`minHeight: proxy.size.height` pattern (Story 5.3) already handles overflow by scrolling.

- [ ] Task 7: Manual verification (AC: #1-#3)
  - [ ] Subtask 7.1: **Flag for user — not verifiable by dev agent.** This devcontainer has no Xcode/Swift toolchain (consistent with every prior story). Build and run in Simulator; check: (a) Home/Tutorial render with the new warm-paper/ink/brass-adjacent palette and sharp-cornered buttons in both light and dark mode, matching `mockups/home.html`/`mockups/tutorial.html`; (b) VoiceOver reads each action's label and activates it; (c) Dynamic Type at an accessibility size (e.g. AX5) shows no truncated/clipped text on either screen, in both portrait and landscape.
  - [x] Subtask 7.2: No automated UI test required per AD-7; this story introduces no new engine logic, only view styling. [Source: ARCHITECTURE-SPINE.md AD-7]

### Review Findings

- [x] [Review][Patch] Button label weight uses `.fontWeight(.bold)` (SwiftUI ~700) instead of the 800/heavy weight both `mockups/home.html` and `mockups/tutorial.html`'s `.btn` class specify — the code's own header comment claims fidelity to that mockup. **Applied:** changed to `.fontWeight(.heavy)` in both button styles. [ForkedEchoes/Views/DesignSystem/ButtonStyles.swift]
- [x] [Review][Patch] `.tracking()` in `eyebrowStyle()`/`headlineStyle()` is a fixed point offset computed from the token's `em` value at default Dynamic Type size only — SwiftUI's `tracking(_:)` doesn't scale with the bound text style, so the letter-spacing-to-font-size ratio drifts from DESIGN.md's `-0.02em`/`0.1em` at accessibility sizes. **Applied:** refactored both into `ViewModifier` structs using `@ScaledMetric(relativeTo:)` so tracking now scales proportionally with Dynamic Type. [ForkedEchoes/Views/DesignSystem/Typography.swift]
- [x] [Review][Patch] `SecondaryActionButtonStyle` has no `.contentShape(Rectangle())` — its background is fully transparent (only a stroke overlay), a known SwiftUI pitfall where hit-testing across the whole visual frame isn't guaranteed without an explicit content shape, which matters directly for AC #2's 44pt-operable requirement. **Applied:** added `.contentShape(Rectangle())` to both button styles. [ForkedEchoes/Views/DesignSystem/ButtonStyles.swift]
- [x] [Review][Patch] Neither custom `ButtonStyle` reads `configuration.isEnabled` — the native `.borderedProminent`/`.bordered` styles they replace auto-dim on disabled state; this contract was silently dropped. No current call site disables these buttons, but the styles are intended for reuse by later reading-surface stories, so the gap should close now while the file is small. **Applied:** both styles now read `@Environment(\.isEnabled)` and drop to 0.4 opacity when disabled. [ForkedEchoes/Views/DesignSystem/ButtonStyles.swift]
- [x] [Review][Patch] `headlineStyle()`'s deliberate un-uppercased override (Home's story title) isn't documented as scoped away from `typography.stat`, which DESIGN.md says shares the same `largeTitle` binding and is expected to "scale in lockstep" with `headline` — a future Memory-screen story could wrongly reuse this un-uppercased helper. **Applied:** strengthened the doc comment with an explicit warning against reuse for `stat` without re-deciding the uppercase question. [ForkedEchoes/Views/DesignSystem/Typography.swift]
- [x] [Review][Defer] `.background(Color.surfaceBase.ignoresSafeArea())` is duplicated per-screen (`HomeView.swift`, `TutorialView.swift`) rather than centralized (e.g. on `RootView`'s `NavigationStack`) — deferred, pre-existing pattern: centralizing was out of this story's declared scope (Dev Notes explicitly forbid touching `RootView.swift`), and only two screens currently need it. Revisit once a third frame-free screen needs the same background.

**Dismissed as noise/false positive/handled elsewhere (6):** a reviewer-reported "wrong" dark-mode hex on `SelectedFill` was a transcription artifact in the review prompt, not the actual file — verified byte-for-byte against DESIGN.md and the real `Contents.json` on disk, which is correct (`#3A2E1E`); a claim that Tutorial's eyebrow should use the DESIGN.md `eyebrow-tag` chip component rather than plain styled text — the story's AC #1 asks for one shared `eyebrow` typographic role applied uniformly to both screens, not two divergent components, and the Acceptance Auditor found no AC violation; a claim that a `TutorialView.swift` hunk removes and re-adds an identical line — misread of the diff (it's `-borderedProminent`/`+primaryAction`, a real change); a claim of zero contrast-table verification — resolved, all four new hex values were independently verified against DESIGN.md's token block and match exactly; a claim that the new `ButtonStyle`s drop content padding versus the native styles — overstated given the existing `.frame(minHeight: 44, maxWidth: .infinity)` plus the 320pt action-stack width cap already provide adequate visual breathing room for these short labels; a call for dark/light-mode preview/screenshot evidence — redundant with the already-flagged Subtask 7.1 manual Simulator verification. — per AD-7, Swift Testing coverage is scoped to `StoryRunEngine` logic only; this story introduces no new engine logic, only view styling. [Source: ARCHITECTURE-SPINE.md AD-7]

## Dev Notes

- **Scope boundary:** This story is styling-only. Do not touch `RootView.swift`'s navigation wiring, `RunSnapshotPresence`, or any `Localizable.xcstrings` string *values* (existing keys/copy are correct and already reviewed in 1.2/1.3) — only `Text` modifier chains and two new `Views/DesignSystem/` files are in scope.
- **Frame conflict — resolved, see banner above.** Do not re-litigate; Home and Tutorial stay frame-free per this story's team decision, contradicting DESIGN.md/UX-DR1/mockups, which are the artifacts that need correcting later, not this code.
- **No prior design-system code exists in the project** — `Views/DesignSystem/` is new. This is the first story to introduce reusable styling helpers; keep the two new files narrowly scoped to exactly what Tasks 2-3 need (eyebrow/headline/body text styles, primary/secondary button styling). Don't preemptively build `choice-label`, `echo-callback`, frame, or other reading-surface tokens — those belong to the stories that actually need them (Epic 2/3) and speculative scaffolding here would be unreviewed, untested surface area.
- **Color asset naming:** DESIGN.md's token names use kebab-case (`surface-base`); Xcode Color Set names conventionally use PascalCase (`SurfaceBase`), generating camelCase Swift symbols (`Color.surfaceBase`). Follow that convention — it's what `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` expects and produces automatically.
- **Localization precedent still holds:** per 1.3's Dev Notes, this codebase's actual localization pattern is plain `Text("key.path")` / `LocalizedStringKey`-typed constants, not codegen'd symbols (no string codegen setting exists despite AD-2's stated aspiration) — this story adds no new strings, so this only matters if you touch existing `Text(...)` calls; don't change their string-key arguments, only their modifier chains.
- **Spacing scale note:** DESIGN.md's 8pt scale (UX-DR2) is `{1}:4, {2}:8, {3}:12, {4}:16, {5}:20, {6}:24, {7}:32, {8}:40`. Both `HomeView` and `TutorialView` are already close (24/8/16 pattern) except the `14`pt action-stack gap flagged in Tasks 4.5/5.5 — that's the one concrete on-scale fix needed; don't otherwise restructure spacing that's already correct.
- **Not required by this story, but flagged if you want to opportunistically fix it:** `deferred-work.md` notes rapid-double-tap re-entrancy on the `NavigationLink`s isn't guarded, and its 1.2 deferral entry explicitly suggested "a Story 1.4 polish pass" as a candidate fix point. It's not in this story's ACs — leave it alone unless it's a trivial one-line addition; don't let it expand scope.
- **Testing standard:** Per AD-7, Swift Testing covers `StoryRunEngine` logic only. This story has no new engine logic — no automated test additions expected, consistent with Stories 1.2/1.3/5.3.

### Project Structure Notes

- New files: `ForkedEchoes/Views/DesignSystem/Typography.swift`, and either a `ButtonStyles.swift` (or similarly named) file in the same folder, or inline styling helpers if you judge a separate file unnecessary for two call sites — either is fine as long as it's reusable, not duplicated per-view.
- `Views/` is a filesystem-synchronized Xcode group (`PBXFileSystemSynchronizedRootGroup`); a new `DesignSystem/` subfolder under it requires no `project.pbxproj` changes, same precedent as `Views/Tutorial/` in Story 1.3.
- New Color Sets go in the existing `ForkedEchoes/Resources/Assets.xcassets` catalog (already present, currently holds only `AppIcon`/`AccentColor`) — no new catalog needed.
- Modified files: `ForkedEchoes/Views/Home/HomeView.swift`, `ForkedEchoes/Views/Tutorial/TutorialView.swift`.
- No conflicts detected with the unified project structure.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4, lines 265-283]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-DR1/UX-DR2/UX-DR9/UX-DR10, lines 87-90, 103-105]
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md — AD-2, AD-7, AD-8]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md — frontmatter `colors`/`typography`/`spacing` blocks (lines 12-95); Colors (190-215); Typography (217-227); Layout & Spacing (229-239); Shapes (245-247); "Home / Tutorial chrome" (263); Do's and Don'ts (279-293)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md — Accessibility Floor (93-103)]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/mockups/home.html, tutorial.html — reference CSS for button/text treatment]
- [Source: _bmad-output/implementation-artifacts/1-3-tutorial-screen.md — Dev Notes (frame conflict flag), Review Findings, Completion Notes]
- [Source: _bmad-output/implementation-artifacts/deferred-work.md — "better addressed systematically (e.g. a Story 1.4 polish pass)"]
- [Source: ForkedEchoes/Views/Home/HomeView.swift, ForkedEchoes/Views/Tutorial/TutorialView.swift, ForkedEchoes/Views/RootView.swift, ForkedEchoes/Resources/Assets.xcassets, ForkedEchoes.xcodeproj/project.pbxproj — current source, read in full]

## Previous Story Intelligence

- **From Story 1.3:** The DESIGN.md-vs-epics.md frame conflict was explicitly deferred here — now resolved (see banner above). The `GeometryReader`+`ScrollView`+`minHeight: proxy.size.height` centering pattern and the Spacer-free flat `VStack` structure are both load-bearing for landscape correctness (Story 5.3's fix) — this story's token/styling changes must not reintroduce a `Spacer` or restructure the `VStack` nesting, only change modifiers on existing `Text`/`Button` elements. Ternary-driven `LocalizedStringKey` needs explicit typing to avoid `Text` overload bugs (already correctly typed in both views' `primaryActionLabel`; don't disturb it).
- **From Story 1.2:** `hasInProgressRun`/`primaryActionLabel` computed fresh in `body` (not reactively observed) is a known, accepted gap — deferred to Story 2.4's real engine wiring. Not this story's concern.
- **Cross-cutting, app-wide, not this story's bug:** `deferred-work.md` documents a cold-launch orientation mismatch (Home/Tutorial render portrait layout if the Simulator is already rotated to landscape before launch) traced to Epic 5. If you see it while manually verifying this story, don't attempt to fix it here — it predates and is unrelated to this story's changes.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- No Xcode/Swift toolchain available in this devcontainer (`xcodebuild`/`swiftc` absent, consistent with every prior story). Verified instead via: `python3 -m json.tool` on all four new/edited `.colorset/Contents.json` files (all valid JSON); brace-balance check on all four touched/added `.swift` files (`HomeView.swift` 13/13, `TutorialView.swift` 14/14, `Typography.swift` 4/4, `ButtonStyles.swift` 9/9); `grep` confirming no `.lineLimit()`/`.fixedSize()`/`Font.system(size:)` was introduced (AC #3 truncation-risk check). Actual Simulator build/run (visual palette check, VoiceOver, Dynamic Type at accessibility sizes, light/dark mode) is flagged for the user — see Subtask 7.1.

### Completion Notes List

- Resolved the DESIGN.md-vs-epics.md circuit-frame conflict per the user's decision recorded in this story's "RESOLVED CONFLICT" banner: neither Home nor Tutorial gets the circuit frame. No frame code was added to either view.
- Added four DESIGN.md color tokens as Asset Catalog Color Sets (`SurfaceBase`, `InkPrimary`, `InkSecondary`, `SelectedFill`), each with light + dark appearance entries matching DESIGN.md's hex values exactly. `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` was already `YES` in both build configs, so these auto-generate `Color.surfaceBase`/`Color.inkPrimary`/`Color.inkSecondary`/`Color.selectedFill` — used those generated symbols throughout, never string-keyed `Color("...")` lookups.
- Added `ForkedEchoes/Views/DesignSystem/Typography.swift`: `View` extension methods `.eyebrowStyle()`, `.headlineStyle()`, `.bodyStyle()` binding to `caption2`/`largeTitle`/`body` named text styles (so Dynamic Type keeps scaling them) with DESIGN.md's weight/tracking overrides layered on top. Deliberately did **not** uppercase the headline role — DESIGN.md's typography note says "Uppercase" but both `home.html`/`tutorial.html` mockups render the story title in Title Case; followed the mockups and flagged the doc inconsistency in the story file for review.
- Added `ForkedEchoes/Views/DesignSystem/ButtonStyles.swift`: `PrimaryActionButtonStyle`/`SecondaryActionButtonStyle` (`ButtonStyle` conforming, exposed as `.primaryAction`/`.secondaryAction` static members matching system style ergonomics) giving sharp-cornered, `selectedFill`/transparent+bordered treatment per `mockups/home.html`'s `.btn-primary`/`.btn-secondary` CSS — replacing the previous `.buttonStyle(.borderedProminent)`/`.buttonStyle(.bordered)`, whose iOS 26 default shape is rounded and doesn't match DESIGN.md's "sharp everywhere" Shapes rule.
- Applied all of the above to `HomeView.swift` and `TutorialView.swift`: app title → `.eyebrowStyle()`, story title → `.headlineStyle()`, mechanic paragraphs → `.bodyStyle()`, all four action buttons → `.primaryAction`/`.secondaryAction`, screen background → `Color.surfaceBase.ignoresSafeArea()`. Also fixed the actions `VStack`'s `spacing: 14` → `spacing: 16` in both views to land on DESIGN.md's 8pt spacing scale (UX-DR2) — the one concrete spacing gap the story flagged.
- Did **not** touch: `RootView.swift` navigation wiring, `RunSnapshotPresence`, any `Localizable.xcstrings` string values, the existing `GeometryReader`/`ScrollView`/`minHeight: proxy.size.height` centering pattern, the Spacer-free `VStack` structure, or Tutorial's 680pt landscape width cap — all explicitly out of scope per Dev Notes, and none needed changes for this story's ACs.
- No new Swift Testing coverage added — this story introduces no new `StoryRunEngine`/engine logic, only view styling, consistent with AD-7's test scope and Stories 1.2/1.3/5.3's precedent.
- **Outstanding:** Subtask 7.1 (Simulator build/run — visual check against mockups in light/dark, VoiceOver smoke test, Dynamic Type at an accessibility size, both orientations) could not be performed — no macOS/Xcode available in this environment. Please build and run in Xcode before merging.
- **Code review (bmad-code-review, 2026-07-26):** 3-layer adversarial review (Blind Hunter, Edge Case Hunter, Acceptance Auditor) ran against the diff plus this story file. 0 decision-needed, 5 patch, 1 defer, 6 dismissed as noise/false-positive/handled-elsewhere. All 5 patches applied:
  - Button label weight changed from `.fontWeight(.bold)` (700) to `.fontWeight(.heavy)` (800), matching both mockups' `.btn` CSS.
  - `eyebrowStyle()`/`headlineStyle()` refactored from plain `View` extension methods into `ViewModifier` structs using `@ScaledMetric(relativeTo:)` for their tracking values, so letter-spacing now scales proportionally with Dynamic Type instead of staying fixed at the default-size value.
  - `.contentShape(Rectangle())` added to both button styles, closing a tap-hit-testing gap on `SecondaryActionButtonStyle`'s fully transparent (border-only) interior.
  - Both button styles now read `@Environment(\.isEnabled)` and drop to 0.4 opacity when disabled, restoring the dimming contract the native `.borderedProminent`/`.bordered` styles they replaced provided for free.
  - `headlineStyle()`'s doc comment strengthened to warn against reuse for `typography.stat` (Memory screen, Epic 3) without re-deciding the uppercase question.
  - 1 finding deferred to `deferred-work.md` (duplicated `surfaceBase` background per-screen instead of centralized on `RootView` — out of this story's declared scope).
  - 6 findings dismissed, including one confirmed false positive: a reviewer flagged `SelectedFill`'s dark-mode hex as wrong, but this was a transcription error in the review prompt, not the actual file — verified byte-for-byte against DESIGN.md and the real `Contents.json`, which is correct.

### File List

- `ForkedEchoes/Resources/Assets.xcassets/SurfaceBase.colorset/Contents.json` (added)
- `ForkedEchoes/Resources/Assets.xcassets/InkPrimary.colorset/Contents.json` (added)
- `ForkedEchoes/Resources/Assets.xcassets/InkSecondary.colorset/Contents.json` (added)
- `ForkedEchoes/Resources/Assets.xcassets/SelectedFill.colorset/Contents.json` (added)
- `ForkedEchoes/Views/DesignSystem/Typography.swift` (added)
- `ForkedEchoes/Views/DesignSystem/ButtonStyles.swift` (added)
- `ForkedEchoes/Views/Home/HomeView.swift` (modified — tokens applied, spacing fix, background)
- `ForkedEchoes/Views/Tutorial/TutorialView.swift` (modified — tokens applied, spacing fix, background)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 1-4 status progression: ready-for-dev → in-progress → review)
- `_bmad-output/implementation-artifacts/1-4-home-and-tutorial-visual-identity-and-accessibility-pass.md` (this story file)

## Change Log

- 2026-07-26: Story created (create-story workflow). Resolved the DESIGN.md-vs-epics.md circuit-frame conflict flagged by Story 1.3 (user decision: neither Home nor Tutorial gets the frame, per epics.md's literal AC). Scoped to: four new DESIGN.md color tokens as Asset Catalog Color Sets, a new `Views/DesignSystem/` folder with eyebrow/headline/body text-style helpers and primary/secondary button styling, applied to both `HomeView.swift` and `TutorialView.swift`, plus a spacing-scale alignment fix (14pt → 16pt action-stack gap) and VoiceOver/Dynamic Type verification.
- 2026-07-26: Implemented (dev-story workflow). Added `SurfaceBase`/`InkPrimary`/`InkSecondary`/`SelectedFill` Color Set assets, `Views/DesignSystem/Typography.swift` (eyebrow/headline/body text-style helpers), and `Views/DesignSystem/ButtonStyles.swift` (sharp-cornered primary/secondary button styles). Applied all of it to `HomeView.swift` and `TutorialView.swift`, fixed the 14pt→16pt spacing-scale gap in both, and set both screens' background to `Color.surfaceBase`. No circuit frame added to either screen (per the resolved conflict). No automated tests added (no new engine logic, per AD-7). Simulator build/run/VoiceOver/Dynamic Type verification could not be performed in this devcontainer (no Xcode toolchain) — flagged for the user. Status moved to review.
- 2026-07-26: Code review (3-layer adversarial + acceptance audit against this story file). Applied 5 patches: button-label weight corrected to 800/heavy, tracking values made Dynamic-Type-scalable via `@ScaledMetric`, `.contentShape(Rectangle())` added to both button styles for reliable tap hit-testing, disabled-state dimming restored via `@Environment(\.isEnabled)`, and a doc-comment warning added against reusing `headlineStyle()` for `typography.stat`. Deferred 1 finding (duplicated background per-screen — see `deferred-work.md`). Dismissed 6, including one false positive traced to a transcription error in the review process itself, not the codebase. Status moved to done; Simulator verification (Subtask 7.1) remains the one outstanding manual step for the user.
