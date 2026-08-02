---
baseline_commit: 36a5abc
---

# Story 2.6: Branch-Arrival Interstitial & Illustrations

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want a full-bleed illustration and caption when I arrive in a new branch reality,
so that the shift feels distinct and grounded.

## Acceptance Criteria

1. **Given** the content tree extended with a branch-reality transition (a `.reading` node reached via `.firstChoice`'s `.shore` option, authored with non-nil arrival data, per AD-1's compile-time tree shape)
   **When** the player's choice leads into that node
   **Then** the engine's phase derives to `.interstitial` and `StoryChoiceView` renders a full-bleed illustration + flavor caption instead of the node's ordinary prose (UX-DR6), using placeholder art for now (final generated art is separate tracked work per the Epic 2 Art note — see Scoping Note below for what "placeholder" means here)

2. **Given** the interstitial is showing (`engine.phase == .interstitial`)
   **When** the player swipes or taps a page zone (the existing page-turn gesture / left-right tap zones)
   **Then** nothing happens — the interstitial blocks both forward and back until its own Continue affordance is tapped (AD-5, amended: "blocks both forward and back unconditionally while phase == .interstitial ... releasing only via their own dismiss affordance" — closes the architecture adversarial review's Finding 6, which flagged that AD-5's original wording named only the forward-block-on-unresolved-choice case)

3. **Given** the interstitial's Continue affordance is tapped
   **When** activated
   **Then** it calls `engine.advancePage()` (AD-3: `advancePage()` is documented as also serving "Continue past the branch-arrival interstitial" — the same "move forward past the current blocking beat" intent as ordinary paging) and phase returns to `.reading`, revealing that same node's ordinary body prose (no `currentNodeId` change — the interstitial is a one-time blocking prelude to the node the player already arrived at, not a separate node to navigate past; see Dev Notes' Phase Derivation section for why)

4. **Given** the illustration is referenced
   **When** wired
   **Then** it uses a generated `ImageResource` symbol from `Assets.xcassets` — never a raw string name (AD-2) — and is never fetched over the network (FR12)

5. **Given** the branch-arrival interstitial is showing
   **When** inspected
   **Then** the run-options button is absent — present only on Story/Choice and Tutorial pages, never during the interstitial (UX-DR11). (Story 2.7 hasn't landed the real run-options control yet; this applies to `StoryChoiceView`'s current temporary "Exit to Home" stand-in button, which is playing that role until then — it must also be hidden during the interstitial.)

6. **Given** the interstitial's flavor caption
   **When** rendered
   **Then** its text is sourced from `Localizable.xcstrings` by stable key, matching the same convention as story body prose (AD-2)

7. **And** a Swift Testing case verifies: entering the branch-arrival node sets `engine.phase == .interstitial`; calling `advancePage()` while `.interstitial` dismisses to `.reading` at the *same* `currentNodeId` (not a different node); `goBack()` is a no-op while `.interstitial`; a subsequent `advancePage()` after dismissal moves on to the node's real `next` target normally; the `.boat`/`.boatEcho` path (unaffected by this story) never reports `.interstitial` anywhere along it (AD-7, NFR3)

8. **Given** this story adds a second visual-only component (the interstitial) that this devcontainer cannot render, screenshot, or Simulator-test
   **When** implementation is complete
   **Then** the user is asked to confirm in Xcode/Simulator: choosing "shore" from the first choice shows the full-bleed illustration + caption; swiping/tapping the page zones does nothing while it's showing; the Continue button reveals the ordinary reading prose for that same node; the run-options/exit-to-home button is absent while the interstitial is showing and reappears once dismissed; VoiceOver reads a distinct, descriptive label for the illustration (not merely repeating the caption); rotating the device while the interstitial is showing keeps the Continue-gate/blocking behavior intact and the art recomposes to the new aspect ratio without breaking layout (AD-8, EXPERIENCE.md Responsive & Platform) — result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

*(Scoping note, resolved at story creation: DESIGN.md's real interstitial token set (`surface-inverse` background, `ink-on-inverse` caption text) needs Color Set assets that don't exist yet — confirmed still only `AccentColor`, `InkPrimary`, `InkSecondary`, `SelectedFill`, `SurfaceBase` exist (Story 2.5's confirmed list, unchanged). Per the `ChoiceCardView`/`FrameView`/echo-callback placeholder-color precedent (Stories 2.3, 2.5), this story reuses `Color.inkPrimary` as the `surface-inverse` stand-in background and `Color.surfaceBase` as the `ink-on-inverse` stand-in caption text — `Color.selectedFill` already exists and is a real match for the headline/Continue-button token, so that one is NOT a placeholder substitution. Story 2.8 owns introducing the real WCAG-verified palette for every Epic 2 reading-surface component at once. Do not attempt full DESIGN.md contrast compliance in this story.*

*Separately, "placeholder/SF Symbol art" (epics.md's Art note) is reconciled with AC #4's "generated `ImageResource`, never a raw string name" as follows: this story adds one real `.imageset` to `Assets.xcassets` (e.g. `ShoreArrivalPlaceholder.imageset`) containing a small, genuinely valid placeholder image — not an `Image(systemName:)` call, which would be exactly the raw-string-name pattern AC #4 forbids. This devcontainer has no design tooling, so Task 1 below gives the exact steps to synthesize a minimal valid PNG with the Python standard library alone (no Xcode, no third-party packages) and wire it into the asset catalog. The Content layer stays SwiftUI-free per its existing layering rule (`StoryChoiceView.swift`'s comment on `bodyKey`/`LocalizedStringKey` boxing): it references illustrations by a plain `BranchIllustration` enum case, and only the Views layer maps that case to the generated `ImageResource`.)*

## Tasks / Subtasks

- [x] Task 1: Add a real placeholder illustration asset (AC: #4)
  - [x] Create `ForkedEchoes/Resources/Assets.xcassets/ShoreArrivalPlaceholder.imageset/Contents.json` following the exact shape of the existing color sets' `Contents.json` (`"info": {"author": "xcode", "version": 1}`), but for an image set: one `images` entry with `"idiom": "universal"` and `"filename"` pointing at the PNG added below (no `@2x`/`@3x` variants needed — this is throwaway placeholder art, not shipping content; Epic 4/6's real generated illustrations replace it wholesale per epics.md line 827, same "expected to be replaced, not preserved" framing Story 2.1's placeholder tree used).
  - [x] Generate a small, genuinely valid placeholder PNG using only the Python standard library (`zlib` + manual PNG chunk writing — no PIL/Pillow, not installed here) and save it as e.g. `shore-arrival-placeholder.png` inside the imageset folder. A flat mid-tone solid-color square (e.g. 64×64) is sufficient; content doesn't matter, validity does. Verify with `python3 -c "import zlib,struct; ..."` or simply confirm the file has a valid PNG signature (`89 50 4E 47 0D 0A 1A 0A`) and a non-trivial byte size — this genuinely produces a file Xcode can compile into the asset catalog, unlike a `Contents.json`-only stub with no backing image (which is a build risk this devcontainer cannot verify — flag this explicitly per Task 5).
  - [x] Confirm `python3 -m json.tool` on the new `Contents.json` reports valid JSON (same static check every other `.xcstrings`/asset `Contents.json` gets in this devcontainer).

- [x] Task 2: Extend the content tree with a branch-arrival node (AC: #1, #4, #6)
  - [x] In `ForkedEchoes/Content/StoryNode.swift`, add a fourth defaulted associated value to `.reading`: `case reading(bodyKey: String, next: NodeID, echoBodyKey: String? = nil, arrival: BranchArrival? = nil)`. Defaulted, so every existing 2- and 3-argument `.reading(...)` construction (`.intro`, `.boatEcho`) keeps compiling unchanged — only the new arrival node passes a non-nil fourth value. Mirrors exactly the pattern Story 2.5 used to add `echoBodyKey` (confirmed empirically: Swift supports multiple defaulted trailing associated values).
  - [x] Add two new types alongside `EndingPayload`/`ChoiceOption` in `StoryNode.swift` (or a new `BranchIllustration.swift` file in `Content/` — dev's call, but keep it in `Content/`, SwiftUI-free):
    ```swift
    struct BranchArrival: Hashable, Sendable {
        let illustration: BranchIllustration
        let captionKey: String
    }

    // AD-1: one case per authored branch-reality flavor, a compile-time-checked identifier —
    // never a raw asset-name string. The Views layer (not Content) maps each case to its
    // generated ImageResource, keeping Content SwiftUI-free (see StoryChoiceView.swift's
    // existing bodyKey/LocalizedStringKey boxing precedent for the same layering rule).
    enum BranchIllustration: Sendable {
        case shoreArrival
    }
    ```
  - [x] In `ForkedEchoes/Content/NodeID.swift`, add one new case, `.shoreArrival` (named for the choice that reaches it, matching `.boatEcho`'s convention). No code iterates `NodeID.allCases` (re-confirm via repo-wide grep before assuming this still holds — Story 2.5 confirmed it then, but re-check since new code has landed since).
  - [x] In `ForkedEchoes/Content/StoryTree.swift`'s `resolvedNode(for:)`: rewire `firstChoice`'s `.shore` option's `target` from `.endingElsewhere` to `.shoreArrival`, and add a case for `.shoreArrival` returning `.reading(bodyKey: "story.shoreArrival.body", next: .endingElsewhere, arrival: BranchArrival(illustration: .shoreArrival, captionKey: "story.shoreArrival.caption"))`. The tree still never reconverges (AD-1): `.shore` now flows through exactly one new node before reaching `.endingElsewhere`; `.boat`'s path through `.boatEcho` to `.endingHomeward` is untouched.
  - [x] Add three new `Localizable.xcstrings` entries, alphabetically inserted, each matching every existing entry's exact shape (`comment`, `extractionState: "manual"`, one `en` `stringUnit` with `state: "translated"`): `story.shoreArrival.body` (ordinary prose for the node, shown only after Continue), `story.shoreArrival.caption` (the interstitial's flavor caption — distinct from the body prose, evokes the new branch reality per UX-DR6), and `storyChoice.interstitial.continue` (the Continue button's label). Also add `story.shoreArrival.illustration.accessibilityLabel` for the illustration's VoiceOver label — per `EXPERIENCE.md`'s Accessibility Floor: "every illustration exposes a distinct, descriptive `accessibilityLabel` — not restating the interstitial's caption, but conveying the illustration's specific visual content" (AC #8's manual-verification checklist covers confirming this in Simulator).

- [x] Task 3: Add phase derivation and interstitial dismissal to the engine (AC: #1, #2, #3, #7)
  - [x] Add a `Phase` enum to `StoryRunEngine.swift` (or a new small file, dev's call): `enum Phase: Equatable { case reading, interstitial, ending }`. (`.memory` isn't reachable yet — Epic 3 — omit it; adding it later is additive, not a breaking change to this enum's existing cases.)
  - [x] Add a private, non-persisted `var interstitialDismissed = false` to `StoryRunEngine`. Reset it to `false` at the top of `selectChoice(_:)`, `advancePage()`, and `goBack()`'s state-changing paths — anywhere `currentNodeId` is about to change — so a *newly arrived* node's own arrival (if any) always starts undismissed. (Simpler than scoping the reset to arrival nodes only: resetting unconditionally on every node change is harmless, since `phase` only consults this flag when the current node actually has non-nil `arrival` data.)
  - [x] Add a computed `var phase: Phase`, purely derived from `StoryTree.node(for: currentNodeId)` and `interstitialDismissed` — no other stored state (AD-5's "phase derived, not stored" ethos, same as `isEchoActive`):
    ```swift
    var phase: Phase {
        switch StoryTree.node(for: currentNodeId) {
        case .reading(_, _, _, let arrival):
            return (arrival != nil && !interstitialDismissed) ? .interstitial : .reading
        case .choice:
            return .reading
        case .ending:
            return .ending
        }
    }
    ```
  - [x] Update `advancePage()`: at the very top, if `phase == .interstitial`, set `interstitialDismissed = true` and `return` — this is the "Continue" behavior (AC #3): it does NOT follow the node's `next` link, does NOT touch `visitedNodeIds`, and does NOT call `persistOrClearSnapshot()` (nothing persisted about phase per AD-5 — "Interstitial is a derived, non-persisted phase... if the app terminates while it's showing, relaunch resumes straight into the node's reading content without re-showing the arrival announcement"; a relaunch mid-interstitial should NOT re-show the arrival banner, which is exactly what NOT persisting `interstitialDismissed` achieves — see Dev Notes' Phase Derivation section). Existing `.reading`/`.choice`/`.ending` branches below are otherwise unchanged.
  - [x] Update `goBack()`: at the very top, if `phase == .interstitial`, `return` immediately (no-op) — blocks backward navigation unconditionally while the interstitial shows (AC #2, AD-5 amendment). Existing behavior otherwise unchanged.
  - [x] Do not add `phase`/`interstitialDismissed` to `RunSnapshot` — AD-4's four fields are exhaustive and this is explicitly a non-persisted phase per AD-5.

- [x] Task 4: Render the interstitial in the view layer (AC: #1, #2, #4, #5, #6)
  - [x] Add `ForkedEchoes/Views/StoryChoice/BranchArrivalInterstitialView.swift`, a new full-bleed view taking the current node's `BranchArrival` and rendering: the illustration (`Image(illustration.imageResource)` — see the `BranchIllustration -> ImageResource` mapping below), an oversized headline-styled text (reuse `.selectedFill` for its color — a real DESIGN.md token match, not a placeholder substitution), a caption bar showing `Text(LocalizedStringKey(arrival.captionKey))`, and a Continue button (reuse `.primaryAction` `ButtonStyle` — same placeholder-reuse precedent as `ChoiceCardView`/`FrameView`) labeled via `storyChoice.interstitial.continue`, calling `engine.advancePage()` when tapped. Background: `Color.inkPrimary` (this story's `surface-inverse` stand-in, matching the Scoping Note above); caption text color: `Color.surfaceBase` (this story's `ink-on-inverse` stand-in). Apply the illustration's `accessibilityLabel` (from `story.shoreArrival.illustration.accessibilityLabel`) directly to the `Image`.
  - [x] **Landscape (AD-8):** build this view with flexible, full-bleed sizing throughout (`.frame(maxWidth: .infinity, maxHeight: .infinity)`-style layout, proportional/relative image sizing) — no fixed portrait-oriented pixel dimensions anywhere. `ARCHITECTURE-SPINE.md`'s Landscape layout strategy paragraph names the branch-arrival interstitial explicitly as reflowing "to the new aspect ratio" with "no new layout" needed; `EXPERIENCE.md`'s Responsive & Platform section is more specific still: the Continue-gate/blocking behavior must survive rotation untouched, and the art must recompose to the new aspect ratio "without a jarring cut." No `verticalSizeClass` branch is needed here (this is a geometry-only reflow, not a structural stack→row change like `choice-card`'s) — just don't hardcode anything that only works in one orientation. This is a real, unaddressed gap the UX review (`review-rubric-landscape.md`) flagged before it got folded into EXPERIENCE.md's current text — treat it as a first-class requirement, not a nice-to-have, since Epic 5's landscape retrofit work is already done and there's no later story queued to catch a portrait-only assumption here.
  - [x] **No animated transition for the interstitial's entrance/exit** — same placeholder-scope precedent as the circuit Frame's dormant/active swap (Story 2.5): an instant show/hide is correct for now. Story 2.8 owns transitions/Reduce Motion handling for every Epic 2 reading-surface component at once (per this story's Scoping Note); don't add a fade-in/cross-fade here even though it might feel natural for a full-bleed reveal — that would be scope Story 2.8 would then have to unwind under Reduce Motion.
  - [x] Add the `BranchIllustration -> ImageResource` mapping as a small extension in the Views layer (not Content — keeps Content SwiftUI-free), e.g. in `BranchArrivalInterstitialView.swift` itself:
    ```swift
    private extension BranchIllustration {
        var imageResource: ImageResource {
            switch self {
            case .shoreArrival: .shoreArrivalPlaceholder
            }
        }
    }
    ```
    (Exhaustive `switch` over `BranchIllustration`'s cases — adding a future flavor without adding its mapping arm here is a compile error, matching AD-1's compile-time-safety spirit.)
  - [x] In `StoryChoiceView.swift`'s `body`, branch on `engine.phase == .interstitial` at the top: when true, render `BranchArrivalInterstitialView` full-bleed instead of the existing `content`/gesture/tap-zone/exit-button composition entirely (AC #2, #5 — no page-turn gesture, no tap zones, no exit/run-options button attached at all while the interstitial shows, not merely visually hidden). This isn't just tidiness: Task 3 makes `advancePage()` itself perform the Continue/dismiss behavior whenever `phase == .interstitial`, so if the ordinary swipe gesture/tap zones stayed attached and merely relied on the engine to "block" them the way `.ending` is blocked, a swipe would actually *dismiss* the interstitial early (via that same `advancePage()` call) — silently violating AC #2's "nothing happens." Detaching the gesture/tap-zone recognizers entirely, so only the dedicated Continue button can call `advancePage()` while interstitial, is what actually satisfies AC #2. When false, render exactly the existing composition unchanged.
  - [x] Update `content`'s `.reading` pattern match (currently `case .reading(let bodyKey, _, let echoBodyKey):`, 3-arity) to the new 4-arity shape: `case .reading(let bodyKey, _, let echoBodyKey, _):` — the arrival value itself isn't needed here (this switch only ever runs when `phase != .interstitial`, i.e., either an ordinary reading node or a dismissed arrival node showing its normal body prose), but the pattern must still match the case's real arity or it fails to compile.
  - [x] Extend `isFrameEligibleNode` (or the equivalent gating) so the circuit Frame never appears during the interstitial phase either — DESIGN.md's Components section is explicit: "No circuit frame here — this screen is the one moment the reading frame steps aside for pure art." (The existing `isFrameEligibleNode` switches on node *type*, which will still be `.reading` for the arrival node even while `phase == .interstitial` — this check needs to also account for phase, not just node type, or the Frame overlay would incorrectly render behind/around the interstitial. Since Task 4's branch already renders `BranchArrivalInterstitialView` as a full replacement of `content` — not wrapped inside the same `.overlay { FrameView(...) }` modifier chain — this may already be structurally satisfied; confirm it explicitly rather than assuming, since it's an easy thing to get subtly wrong depending on exactly where the `if engine.phase == .interstitial` branch is placed in the modifier chain.)

- [x] Task 5: Swift Testing coverage (AC: #7)
  - [x] Extend `ForkedEchoesTests/StoryRunEngineTests.swift` (existing engine-behavior scope, same precedent as Story 2.5's `isEchoActive` tests — a property/behavior addition to the existing `StoryRunEngine`, not a new type):
    - a test that `selectChoice(.shore)` moves `currentNodeId` to `.shoreArrival` and `engine.phase == .interstitial`
    - a test that calling `advancePage()` once from there sets `engine.phase == .reading` while `currentNodeId` is still `.shoreArrival` (dismissal, not navigation)
    - a test that `goBack()` while `engine.phase == .interstitial` is a no-op (`currentNodeId` unchanged)
    - a test that after dismissal (one `advancePage()` call), a second `advancePage()` call moves `currentNodeId` on to `.endingElsewhere` normally
    - a test that the `.boat`/`.boatEcho` path never reports `engine.phase == .interstitial` at any node reached along it (this story doesn't touch that path, but the existing `theShorePathNeverReportsIsEchoActiveTrueAnywhereAlongIt`-style walk assumptions need re-checking — see Dev Notes' "existing tests that assumed `.shore` reaches an ending directly" callout below)
    - recommended: a test that an engine constructed via `resumingFromSnapshot(defaults:)` onto a snapshot whose `currentNodeId` is `.shoreArrival` reports `engine.phase == .reading`, NOT `.interstitial` — this is the AD-5 "relaunch doesn't re-show the arrival announcement" guarantee, and it's exactly the kind of restored-vs-fresh gap Story 2.4/2.5's second review passes each caught once, so it's worth proving directly rather than assuming the derivation logic gets it right
  - [x] **Existing tests that need updating, not just new tests added** — two tests in `StoryRunEngineTests.swift` currently walk the `.shore` path expecting it to reach `.endingElsewhere` *directly* (Story 2.5's Completion Notes: `startFreshRunIfCurrentRunHasEndedResetsAFinishedRunToRoot` and `reachingAnEndingNodeClearsTheStoredSnapshot` were deliberately switched from `.boat` to `.shore` in Story 2.5 specifically *because* `.shore` reached an ending directly at the time — that's no longer true now that `.shoreArrival` sits between them). Fix by switching these two back to the `.boat`/`.boatEcho` path (which still reaches `.endingHomeward` directly, one `advancePage()` from `.boatEcho`, unaffected by this story) — same fix shape Story 2.5 itself made when `.boat` stopped being a direct-to-ending path. Also re-check `theShorePathNeverReportsIsEchoActiveTrueAnywhereAlongIt`: its walk of the `.shore` branch now needs an extra `advancePage()` call (interstitial dismissal) before `.shoreArrival` actually moves on to `.endingElsewhere` — verify it still asserts what it means to assert once that extra step is accounted for.
  - [x] Run `swift test` from repo root; report the new total (38 prior, per Story 2.5's final Change Log count, plus whatever this story adds/removes net).

- [x] Task 6: Manual verification (AC: #8)
  - [x] This devcontainer cannot render SwiftUI, take a screenshot, or confirm an asset catalog with a newly-added `.imageset` actually compiles cleanly in Xcode — Task 1's placeholder PNG is a first for this project (no prior story has added a real bundled image asset) and is real build risk, not routine. Request the user: build and run; from Home, start/resume the story, advance to `firstChoice`, select the shore option; confirm the full-bleed illustration + caption interstitial appears; confirm swiping and tapping the page zones do nothing while it's showing; tap Continue and confirm the node's ordinary body prose then renders (same page, no jump); confirm the "Exit to Home" button is absent while the interstitial shows and reappears once dismissed; turn on VoiceOver and confirm the illustration announces a distinct, descriptive label (not the caption text repeated); rotate the device while the interstitial is showing and confirm the Continue-gate/blocking behavior survives and the art recomposes cleanly without clipping or a broken layout (AC #8, AD-8); confirm no build warnings/errors reference the new `ShoreArrivalPlaceholder` image set.
  - [x] Record what was checked and when in Completion Notes List (project-context.md Process Agreement — "actively request... don't just passively note it's unverified").

## Dev Notes

### What already exists — do not re-create any of this

`ForkedEchoes/Content/StoryNode.swift` / `NodeID.swift` / `StoryTree.swift` (Stories 2.1–2.5):
- `.reading` is currently a 3-value case (`bodyKey`, `next`, `echoBodyKey`, the last defaulted) — Task 2 adds a fourth, also defaulted, value. The one arity-sensitive pattern-match call site outside `StoryTree.swift` is `StoryChoiceView.swift`'s `content` switch (`case .reading(let bodyKey, _, let echoBodyKey):`), which this story is already touching (Task 4).
- The tree is currently 5 nodes (`.intro` → `.firstChoice` → `.boatEcho`/direct → `.endingHomeward`/`.endingElsewhere`) — Epic 4 replaces it wholesale. This story's one new node (`.shoreArrival`) is expected to be replaced along with everything else then, not preserved as permanent content.
- `StoryTree.node(for:)`'s content-authoring `precondition`s (empty options, duplicate option ids) apply only to `.choice` nodes — irrelevant to this story's new `.reading` node.

`ForkedEchoes/Engine/StoryRunEngine.swift` (Stories 2.1–2.5, primary edit target alongside the View):
- `selectChoice(_:)`/`advancePage()`/`goBack()` already implement all mutation + persistence logic. This story's changes are additive/gating within `advancePage()`/`goBack()` (the new interstitial-block short-circuit at the top of each), plus one new derived property (`phase`) and one new private ephemeral field (`interstitialDismissed`) — no change to `RunSnapshot`'s shape, no change to `selectChoice(_:)` itself (arrival is discovered on the node the player lands on, not something `selectChoice` needs to know about).
- `resumingFromSnapshot(defaults:)` exists (Story 2.4) — reuse it for the recommended resume-onto-arrival-node test in Task 5.
- `isEchoActive` (Story 2.5) is the closest existing precedent for a purely-derived, non-persisted property — read it before writing `phase`, same file, same pattern.

`ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` / `ChoiceCardView.swift` / `FrameView.swift` (Stories 2.1–2.5):
- `StoryChoiceView.content` already directly calls `StoryTree.node(for: engine.currentNodeId)` and pattern-matches on it — same established practice this story continues (Task 4 adds a phase check *before* reaching that switch, doesn't replace the switch itself).
- `isFrameEligibleNode` (Story 2.5, code review 2026-08-01) already excludes `.ending` from the Frame overlay — Task 4 needs the interstitial excluded too, by construction if the `phase == .interstitial` branch fully replaces the modifier chain rather than being layered inside it (see Task 4's explicit callout — this is exactly the kind of thing Story 2.5's own review caught once already for a different node-type gate, worth getting right the first time here).
- The temporary `exitButton` (code review, 2026-08-01 — stand-in for Story 2.7's real run-options control) needs to not render during the interstitial (AC #5) — naturally satisfied if Task 4's branch replaces the whole composition rather than layering the interstitial on top of the existing one.

`ForkedEchoes/Views/DesignSystem/LayoutMetrics.swift`/`ButtonStyles.swift` (Story 1.6/2.3/2.5 pattern):
- `.primaryAction`/`.secondaryAction` `ButtonStyle`s already exist and are reused as-is for the Continue button (Task 4) — no new button style needed. No new `LayoutMetrics` numeric constants are anticipated for this story (the interstitial's DESIGN.md tokens are colors, not new geometry values); if a genuine new numeric literal turns out to be needed while implementing, it still needs a named constant here per project-context.md's "Design tokens" rule — don't let one slip in as a bare literal.

`Assets.xcassets` — confirmed contents: `AccentColor`, `InkPrimary`, `InkSecondary`, `SelectedFill`, `SurfaceBase` color sets (+ `AppIcon`, which itself has no backing PNG file, only a `Contents.json` — not a precedent to copy for Task 1's real image set, which does need actual backing image data to render). No image sets exist yet anywhere in this project — this story is the first.

`Localizable.xcstrings` — confirmed existing keys are alphabetically ordered (see Task 2's list for full current contents).

### Phase derivation — why Continue doesn't change `currentNodeId`

This is the one non-obvious design decision in this story, worth re-reading before implementing Task 3: AD-5 states the interstitial "is a derived, non-persisted phase, not a distinct RunSnapshot state: if the app terminates while it's showing, relaunch resumes straight into the node's reading content without re-showing the arrival announcement." That sentence only makes sense if the interstitial and the node's ordinary reading content are **the same `currentNodeId`**, distinguished only by an ephemeral, non-persisted flag (`interstitialDismissed`) — if Continue instead advanced to a *different* node, there would be nothing left to "resume straight into" on relaunch; the arrival announcement would just be silently skipped with no reading content to fall back to in its place. So: arriving at `.shoreArrival` via `selectChoice(.shore)` sets `currentNodeId = .shoreArrival` immediately (ordinary `selectChoice` behavior, unchanged) — `phase` derives `.interstitial` from that same node because `interstitialDismissed` starts `false`. Tapping Continue calls `advancePage()`, which (per Task 3) recognizes `phase == .interstitial` and flips `interstitialDismissed = true` **without** moving `currentNodeId` — `phase` now derives `.reading` from the *same* node, and the view's ordinary `.reading` rendering path (`content`'s existing switch) shows that node's `bodyKey` prose. A second, later `advancePage()` call behaves completely normally (moves to `next`, i.e., `.endingElsewhere`) because by then `phase` is `.reading`, not `.interstitial`, and the interstitial short-circuit at the top of `advancePage()` no longer applies.

### Architecture compliance (AD-1, AD-2, AD-3, AD-5, AD-7)

- **AD-1**: arrival, like echo wiring, is a tree-shape/authoring-time property — "does this node show an interstitial" is answered purely by whether the current node's `arrival` is non-nil, never by a runtime `choiceHistory` scan.
- **AD-2**: every new string (body, caption, Continue label, illustration a11y label) goes through `Localizable.xcstrings` with a stable dot-path key. The illustration itself goes through a generated `ImageResource`, never `Image(systemName:)`/a raw string — this is the one place this story deliberately does MORE work than the epics.md Art note's "SF Symbol art" phrasing might suggest, precisely because AC #4 is explicit and takes precedence (see this story's Scoping Note above for the reconciliation).
- **AD-3**: `StoryRunEngine` remains the sole mutator; `phase` is a read-only derived projection, `interstitialDismissed` is a private field only the engine's own intent methods touch. The Continue button is still just calling `engine.advancePage()` — the same intent method every other "move forward" interaction already uses (AD-3's explicit list names this exact reuse).
- **AD-5**: phase is derived from `currentNodeId` + the new ephemeral `interstitialDismissed` flag, never separately persisted — this is the first story to actually implement the `Phase` enum AD-5's state diagram has described since the spine was written (Stories 2.1–2.5 only ever needed to reason about `.reading`/`.choice`/`.ending` informally via the Content node type directly; this story is what makes `phase` a real, named engine API for the first time).
- **AD-7**: this story is the first to exercise the "interstitial blocks both directions, dismisses via Continue, doesn't persist" testing surface — Stories 2.1–2.5 covered ending resolution, pager-gating, persistence round-trip, and echo reachability, but not phase/interstitial behavior yet.

### Testing standards summary

- Swift Testing (`import Testing`), `@testable import ForkedEchoes`. Extend `StoryRunEngineTests.swift` (existing scope, same reasoning Story 2.5 used for `isEchoActive` — `phase` is a property addition to the existing `StoryRunEngine`, not a new type).
- No UI test target exists — `BranchArrivalInterstitialView`'s *visual* output has no automated coverage; Task 6's manual Simulator check is the only verification for that, same pattern as every prior visual-only story (1.4, 2.5, 5.3, 5.4).
- `swift test` from repo root genuinely builds/runs this suite in this devcontainer (project-context.md Environment section) — currently 38 tests per Story 2.5's final Change Log entry; report the new total, and remember Task 5 also touches two *existing* tests, not just adds new ones.

### Project Structure Notes

- New files: `ForkedEchoes/Views/StoryChoice/BranchArrivalInterstitialView.swift`; `ForkedEchoes/Resources/Assets.xcassets/ShoreArrivalPlaceholder.imageset/Contents.json` + its backing PNG. `Views/` is a `PBXFileSystemSynchronizedRootGroup` (Story 1.1) and so is `Resources/Assets.xcassets` — Xcode auto-discovers new files with zero `project.pbxproj` edits.
- Modified: `ForkedEchoes/Content/StoryNode.swift` (`.reading` gains a fourth defaulted associated value; new `BranchArrival`/`BranchIllustration` types), `ForkedEchoes/Content/NodeID.swift` (new `.shoreArrival` case), `ForkedEchoes/Content/StoryTree.swift` (new node, rewired `.shore` target), `ForkedEchoes/Engine/StoryRunEngine.swift` (`Phase` enum, `phase` computed property, `interstitialDismissed` field, `advancePage()`/`goBack()` short-circuits), `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift` (phase branch, Frame-eligibility gating), `ForkedEchoes/Resources/Localizable.xcstrings` (four new keys), `ForkedEchoesTests/StoryRunEngineTests.swift` (new phase tests + two existing tests fixed up, per Task 5).
- No `Package.swift` change expected — `BranchArrivalInterstitialView.swift` lands under `Views/`, which the SwiftPM manifest doesn't include (only `Content`/`Engine` are SwiftPM-covered, per project-context.md's Environment section); it's Xcode-project-only and gets parse-check-only verification here. The `Content/`-layer additions (`BranchArrival`, `BranchIllustration`, `StoryNode`/`NodeID`/`StoryTree` edits) and the `Engine/`-layer additions (`Phase`, `phase`, `interstitialDismissed`) ARE covered by the SwiftPM package and genuinely build/test via `swift test`.
- No conflicts detected against current on-disk structure.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.6: Branch-Arrival Interstitial & Illustrations]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2: Story Reader, Choice Echo & Branch Realities] (Art note on placeholder-first sequencing; Capability → Architecture Map's `FR-12 Bundled illustrations` row)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-3] (advancePage() explicitly named as serving the interstitial's Continue affordance)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md#AD-5] (phase derived from current node type; interstitial non-persisted; amended bidirectional block language)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md] (Run phase mermaid state diagram: `Reading --> Interstitial: enters new branch reality`, `Interstitial --> Reading: Continue tapped`)
- [Source: _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/reviews/review-adversarial.md#Finding 6] (interstitial's bidirectional block gap in AD-5's original wording, since folded into the spine text this story implements against)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md#Components] (`components.interstitial` token values: surface-inverse background, selected-fill headline, ink-on-inverse caption, accent-ember caption-bar accent; "no circuit frame here" rule)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md#Layout & Spacing] (Dynamic Type headroom: headline may wrap to 2 lines at accessibility sizes, art never contests that space)
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md] (Component Patterns / State Patterns rows for the branch-arrival interstitial: full-bleed, blocks page-turn until Continue, "symmetric to Echo active as a distinct, transient, blocking beat"; Accessibility Floor's illustration-`accessibilityLabel` requirement)
- [Source: _bmad-output/project-context.md#Design tokens (colors, spacing, sizing)] (numeric-literal-traces-to-a-token rule)
- [Source: _bmad-output/implementation-artifacts/2-5-narrative-callback-choice-echo.md] (previous story — defaulted-associated-value precedent, placeholder-color-reuse precedent, Scoping Note banner style, and the `.shore`-path test-fixup precedent Task 5 repeats one story later)
- [Source: ForkedEchoes/Content/StoryNode.swift] (existing `.reading`/`.choice`/`.ending` case shapes, `.reading`'s current 3-value arity)
- [Source: ForkedEchoes/Content/StoryTree.swift] (existing 5-node placeholder tree to extend)
- [Source: ForkedEchoes/Engine/StoryRunEngine.swift] (existing intents, `isEchoActive`'s derived-property precedent, `resumingFromSnapshot`)
- [Source: ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift] (existing `content` switch, `isFrameEligibleNode`, temporary `exitButton`, gesture/tap-zone wiring all needing a phase gate)
- [Source: ForkedEchoes/Views/StoryChoice/FrameView.swift] (nearest precedent for a small, self-contained, placeholder-colored visual component)
- [Source: ForkedEchoes/Views/DesignSystem/ButtonStyles.swift] (`.primaryAction` reused as-is for Continue)
- [Source: ForkedEchoes/Resources/Localizable.xcstrings] (existing key shapes, alphabetical ordering)
- [Source: ForkedEchoes/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json] (existing image-set-shaped `Contents.json` to model Task 1's `Contents.json` on — note its own lack of a backing file is NOT a pattern to copy)
- [Source: ForkedEchoesTests/StoryRunEngineTests.swift] (existing 38 tests to extend, and two to fix up per Task 5)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `swiftc -parse` on every touched `Content/`/`Engine/`/`Views/` file — clean, no syntax errors.
- `python3 -m json.tool` on `Localizable.xcstrings` and the new `Contents.json` — both valid.
- `swift test` from repo root — 45/45 tests passed (38 prior + 7 new; net +7, no removals — Task 5's two test fixups changed assertions in place, they didn't remove/re-add tests).

### Completion Notes List

- Task 2's Dev Notes named `StoryChoiceView.swift`'s `content` switch as the one arity-sensitive `.reading` pattern-match call site outside `StoryTree.swift` — this was incomplete. `StoryRunEngine.isEchoActive` (`StoryRunEngine.swift`) also pattern-matches `.reading` at the old 3-arity and would have failed to compile once Task 2 added the fourth associated value. Fixed as part of Task 3, flagged here since it's a real gap in the story's own Dev Notes, not something introduced by this session.
- `StoryRunEngine.resumingFromSnapshot(defaults:)` now explicitly sets `interstitialDismissed = true` on the engine it constructs. This wasn't spelled out in Task 3's checklist, but is required to satisfy the Task 5 "recommended" test (AD-5's "relaunch doesn't re-show the arrival announcement" guarantee) — a freshly-constructed `StoryRunEngine` always starts with `interstitialDismissed = false`, so without this, resuming onto `.shoreArrival` would incorrectly derive `.interstitial`.
- `BranchArrivalInterstitialView` renders one text element, not two. Task 4's prose describes "an oversized headline-styled text" and separately "a caption bar showing `Text(arrival.captionKey)`," which reads as two distinct strings — but only one caption-shaped key (`story.shoreArrival.caption`) was authored in Task 2, and AC #1/#6 both refer to a single "flavor caption." Resolved by rendering `arrival.captionKey` once, styled as the oversized headline in `Color.selectedFill` (DESIGN.md's real `headline-color` token, per Task 4's explicit instruction) — `Color.surfaceBase`, the Scoping Note's caption-text stand-in, is not used since there's no second text element left to color with it. If a future story wants DESIGN.md's separate headline/caption texts, that needs a second authored string key.
- Task 5's existing-test fixups: `startFreshRunIfCurrentRunHasEndedResetsAFinishedRunToRoot` and `reachingAnEndingNodeClearsTheStoredSnapshot` switched from `.shore` back to `.boat`/`.boatEcho` (which still reaches `.endingHomeward` directly) since `.shore` no longer reaches an ending directly now that `.shoreArrival` sits in between — same fix shape Story 2.5 made the previous time this happened, just in the opposite direction. `theShorePathNeverReportsIsEchoActiveTrueAnywhereAlongIt` gained one extra `advancePage()` call (interstitial dismissal) before `.shoreArrival` proceeds to `.endingElsewhere`.
- **Manual verification confirmed by user, 2026-08-02**: all AC #8 checks passed in Xcode/Simulator — (1) shore choice shows the full-bleed illustration + caption interstitial; (2) swiping/tapping page zones does nothing while showing; (3) Continue reveals the node's ordinary body prose on the same page; (4) "Exit to Home" button absent while showing, reappears once dismissed; (5) VoiceOver announces a distinct, descriptive illustration label, not the caption repeated; (6) rotation mid-interstitial keeps the Continue-gate intact and the art recomposes cleanly; (7) no build warnings/errors on the new `ShoreArrivalPlaceholder` image set — first bundled image asset in the project compiles cleanly.
  - User also flagged: after dismissing the interstitial (Continue tapped) and swiping right/back from `.shoreArrival`'s reading prose, the app goes to the choice page (`firstChoice`), not back to the interstitial. Investigated against AD-5 and this story's own Dev Notes ("Phase derivation" section) — this is correct, intended behavior, not a bug. The interstitial is not a distinct node/state; it's a one-time blocking overlay on `.shoreArrival` itself, gated by the ephemeral `interstitialDismissed` flag. Once dismissed, `goBack()` behaves exactly like ordinary back-navigation from any reading node — it moves `currentNodeId` back to the previous node in history (the choice page). There is no "interstitial state" to return to, by design (AD-5: "if the app terminates while it's showing, relaunch resumes straight into the node's reading content" — the interstitial is not preserved as separate navigable state in either direction). No code change made.

### File List

- Added: `ForkedEchoes/Resources/Assets.xcassets/ShoreArrivalPlaceholder.imageset/Contents.json`
- Added: `ForkedEchoes/Resources/Assets.xcassets/ShoreArrivalPlaceholder.imageset/shore-arrival-placeholder.png`
- Added: `ForkedEchoes/Views/StoryChoice/BranchArrivalInterstitialView.swift`
- Modified: `ForkedEchoes/Content/StoryNode.swift`
- Modified: `ForkedEchoes/Content/NodeID.swift`
- Modified: `ForkedEchoes/Content/StoryTree.swift`
- Modified: `ForkedEchoes/Engine/StoryRunEngine.swift`
- Modified: `ForkedEchoes/Views/StoryChoice/StoryChoiceView.swift`
- Modified: `ForkedEchoes/Resources/Localizable.xcstrings`
- Modified: `ForkedEchoesTests/StoryRunEngineTests.swift`

## Change Log

- 2026-08-01: Story 2.6 implemented — branch-arrival interstitial, `.shoreArrival` content node, engine `Phase` derivation, view-layer rendering, and Swift Testing coverage (45/45 passing). Status set to `review`; Xcode/Simulator manual verification (AC #8) requested from user, pending confirmation.
- 2026-08-02: User confirmed all AC #8 manual verification checks pass in Xcode/Simulator. One behavior question raised (back-swipe after dismissal goes to choice page, not interstitial) — confirmed as intended per AD-5, no code change needed. Status set to `done`.
