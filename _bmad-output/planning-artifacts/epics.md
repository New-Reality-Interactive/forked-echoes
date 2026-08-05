---
stepsCompleted: [1, 2, 3]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-game-2026-07-25/prd.md
  - _bmad-output/planning-artifacts/prds/prd-game-2026-07-25/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-game-2026-07-25/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-game-2026-07-25/EXPERIENCE.md
  - _bmad-output/specs/spec-game/SPEC.md
  - _bmad-output/specs/spec-game/glossary.md
---

# game - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for the Many-Worlds CYOA iOS App (v1), decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Home screen entry — Player can choose "Start Story" or "Start Tutorial" from the home screen, each bound to a distinct gesture with an accessible tap equivalent. Home screen displays app title and story title; both entry actions are reachable via VoiceOver/standard tap, not gesture-only.

FR2: Tutorial screen — Player can view a tutorial screen explaining the game's mechanics, then return home or start the story. Tutorial is optional and reachable only from the home screen; both exit actions are gesture-selectable with accessible tap equivalents.

FR3: Page navigation — Player can advance a page (swipe left) or return to the previous page (swipe right) within a story branch, with an accessible non-gesture equivalent. Forward navigation is blocked on a page containing an unresolved choice; backward navigation is always available once at least one page has been read.

FR4: Choice presentation and selection — Player can select one of the presented choices on a choice page, each bound to a distinct gesture with a standard accessible tap/VoiceOver equivalent. A choice page presents at least two independently selectable choices; making a choice unblocks forward navigation past that page.

FR5: Choice permanence — Once a choice is made, the player cannot change it by re-navigating to that page. Revisiting an already-decided choice page displays the choice already made and offers no alternate-choice control.

FR6: Narrative callback (choice echo) — The story text explicitly references an earlier choice's consequence 2-3 times later in the same run. Each echoed choice's callback text is distinguishable in-prose as a reference to the earlier decision, not merely implied by branching.

FR7: Silent alignment scoring — Each choice carries a small +/- alignment value (author-assigned at write-time); the system sums this silently during play without surfacing it. This running total is a reflective statistic only — it has no bearing on which ending the run reaches (see FR8). No alignment value or running total is visible to the player during a run; the accumulated total influences no navigation, resolution, or ending outcome — only the Memory screen's display (FR10).

FR8: Ending resolution — At the end of a branch, the run resolves to whichever ending kind (home, stay, limbo, or hard-fail) is authored directly on the terminal node the player's path reaches; hard-fail terminal nodes are reached only via a designated gotcha choice. Every possible branch terminates in exactly one of the four ending types, fixed by which terminal node is authored there — not computed from alignment score. Content-authoring guidance: author roughly 1-2 distinct terminal nodes as home endings and 3-4 as stay endings, remaining non-hard-fail terminals as limbo.

FR9: Ending screen — The system displays an ending screen using a single shared template across all four ending types, with outcome-specific text. Home/stay/limbo/hard-fail endings render through the same screen component, differing only in text content.

FR10: End-of-run recap (memory screen) — After the ending screen, the system shows a memory screen listing the choices made during the run, what each one caused, and the alignment score/tier — for every ending type, including hard-fail. Memory screen is shown for 100% of completed runs; from it, the player can return home or start a new run (each gesture-selectable with accessible tap equivalent).

FR11: Accessible interaction parity — Every gesture-based interaction (navigation and choice selection alike) has a standard, VoiceOver-compatible tap alternative; the story text area follows Apple HIG accessibility guidance (Dynamic Type, VoiceOver labeling, sufficient contrast). No interaction in the app is reachable only via a custom gesture; the story text area passes VoiceOver navigation and responds to Dynamic Type sizing.

FR12: Bundled branch-reality illustrations — The app ships with one pre-generated illustration per distinct branch-reality flavor (~10-15 total), bundled in the app binary. No illustration is fetched over the network at runtime.

### NonFunctional Requirements

NFR1: Platform — Native iOS, on-device only. No network calls, no backend, no external integrations of any kind.

NFR2: Compatibility — Support the current major iOS release and the previous one (N-1). Deployment target: iOS 18.0 minimum, iOS 26 SDK.

NFR3: Automated test coverage — Engine logic (`StoryRunEngine`) must be covered by Swift Testing: every terminal node resolves to exactly one `EndingKind` with no ambiguity, echo-callback reachability as authored in the tree, hard-fail terminal nodes reachable only via their designated gotcha choice, pager-gating (forward blocked on unresolved choice; locked display on revisit), and `RunSnapshot` encode/decode round-trip (including the alignment-score field, verified only for correct accumulation/persistence, not for any ending-resolution role).

NFR4: Persistence resilience — A `RunSnapshot` decode failure of any kind (missing key, malformed JSON, unrecognized node id) is treated identically to "no saved run": the engine falls back to a fresh run at Home rather than crashing.

NFR5: Reduce Motion support — The choice-card charge-fill animation and the frame's echo power-up glow/transition collapse to an instant state change under Reduce Motion (no 3s wait, no transition). Page-turn and the branch-arrival interstitial's entrance/exit collapse to instant cuts. Nothing in the system produces continuous or looping motion under Reduce Motion.

NFR6: Minimum tap targets — All interactive elements (choice cards, page tap zones, run-options button, Home/Tutorial/Ending/Memory actions) meet a 44pt minimum tap target.

NFR7: Color contrast — All text/color pairs meet WCAG AA thresholds (4.5:1 normal text, 3:1 large text ≥24px/bold) in both light and dark themes, per the verified contrast table in DESIGN.md.

NFR8: Dynamic Type — Every text role scales via its bound named iOS text style through accessibility Dynamic Type sizes without clamping or truncation; layout (not type) absorbs the growth.

### Additional Requirements

- No starter/greenfield template specified by Architecture — Epic 1 Story 1 is a from-scratch Xcode project scaffold matching the Structural Seed layout (`App/`, `Content/`, `Engine/`, `Views/`, `Resources/`), not a template clone.
- Story topology (nodes, choice targets, ending kind, alignment deltas, echo wiring) must be authored as Swift `indirect enum` literals in `Content/` — never `Decodable`/runtime-loaded — so an unterminated branch or dangling reference is a compile error (AD-1).
- All player-facing text (body prose, choice labels, echo callbacks, tutorial/ending copy, VoiceOver labels) lives in an Xcode String Catalog (`Localizable.xcstrings`) with type-safe generated symbols, referenced from `Content/` nodes by stable key (AD-2).
- Illustrations live in `Assets.xcassets`, one image set per branch-reality flavor, referenced only via generated `ImageResource` symbols — never raw string names (AD-2).
- A single `@Observable` `StoryRunEngine`, injected via `@Environment`, is the sole mutator of run state, with a fixed intent surface: `selectChoice(_:)`, `advancePage()`, `goBack()`, `exitToHome()`, `restartRun()`, `startNewRun()` (AD-3).
- A choice's press-and-hold charge and tap-then-undo-window are View-local transient `@State`, never committed to the engine until finalized; app termination before finalization leaves the choice undecided on relaunch (AD-3).
- `RunSnapshot` is one `Codable` struct, JSON-encoded, in a single `UserDefaults` key (`currentNodeId`, `choiceHistory: [ChoiceRecord]` as IDs only, `alignmentScore`, `tutorialSeen`); writes are synchronous and immediate on every completed mutating intent (AD-4).
- `RunSnapshot` represents an in-progress run only — cleared on reaching Ending, and on `restartRun()`/`startNewRun()` (AD-4). Home's "Resume Story" vs. "Start Story" label is driven purely by snapshot presence.
- The story pager is engine-driven (a derived phase: reading / branch-arrival interstitial / ending / memory), not a native `NavigationStack` push/pop or `TabView(.page)`; `NavigationStack`, if used at all, is reserved for coarse top-level flow only and never wraps individual story pages (AD-5).
- Ending kind (home/stay/limbo/hard-fail) is authored directly on each terminal node in the content tree, fixed at write-time — not computed from alignment score (AD-1, AD-6). Content-authoring ratio: roughly 1-2 home-ending terminal nodes, 3-4 stay-ending terminal nodes, remaining non-hard-fail terminals as limbo (addendum.md, corrected).
- Alignment score is accumulated per choice (AD-3/AD-4) purely as Memory-screen display data — it plays no role in ending resolution (FR7, FR8, AD-6).
- The story tree must always contain an ideal path leading home, even if not obvious to the player while choosing (authoring guidance, addendum.md).
- Safe-looking choices must not always guarantee the safe outcome (narrative pushback so players aren't trained to always pick "safest"); no spendable resource backs this in v1 (addendum.md).
- Device target: iPhone only, supporting both portrait and landscape orientation (see Epic 5: Landscape Support), single Xcode app target, Debug/Release configurations only.
- Illustrations (~10-15 total) are produced with generative AI image tools at development time and bundled at build time — an asset-production dependency, not a runtime concern (FR-12, addendum.md).
- Distribution is via App Store Connect, with TestFlight for solo/friends playtesting pre-submission. Apple Developer Program enrollment is a blocking external prerequisite for either and is **not yet in place** — an unresolved dependency this epics/stories set cannot close, tracked here for visibility.
- App Store content rating / age disclosure for the dark-comedy hard-fail content is unresolved and needs settling before submission (PRD Open Question 3) — not an engineering story, but a pre-submission checklist item.

### UX Design Requirements

UX-DR1: Circuit-trace Frame component — brass dormant / ember powered-up states (via-diameter grow + pad-fill shape cue, never color alone), wraps every reading surface (Story/Choice, Ending); never appears on Home or Tutorial. (Corrected 2026-07-26 — Story 1.4 resolved a conflict between this record and epics.md's own Story 1.4 AC by ruling Tutorial out of the frame entirely; this record originally listed Tutorial alongside Story/Choice and Ending, which was the stale reading. See `deferred-work.md`'s "Follow-ups from: sprint demo" section.)

UX-DR2: Full design token implementation — colors, typography (each role bound to a named iOS text style), 8pt spacing scale, and corner radii per DESIGN.md, with light/dark mode parity throughout.

UX-DR3: Choice card component — press-and-hold (~3s) charge-to-commit, cancellable by releasing at any point; quick tap (or VoiceOver double-tap) commits instantly then opens a 1.5s undo window; only one card can charge at a time (holding a second cancels the first); locks to selected styling once finalized, per FR-5.

UX-DR4: Invisible page-tap-zones (left/right thirds of the reading card, full card height, ≥44pt) as the accessible tap equivalent to swipe-left/right page-turn gestures, per FR-3/FR-11.

UX-DR5: Echo callback block — inverse-surface inline block tagged "The story remembers" in the text-safe `accent-ember-text` color (not decorative `accent-ember`), always paired 1:1 with the Frame's powered-up state, appearing 2-3 times per run per FR-6.

UX-DR6: Branch-arrival interstitial — full-bleed art + caption, blocks page-turn (swipe and tap-zone alike) until its own tap-to-continue affordance is used; no circuit frame on this screen; headline may wrap to 2 lines at accessibility Dynamic Type sizes without art contesting that space.

UX-DR7: Ending screen — one shared template across all four outcomes (home/stay/limbo/hard-fail), differing only in copy/illustration; Frame rests permanently in its powered-up ember state (a resting condition, not a transition); tap anywhere to advance to Memory.

UX-DR8: Memory/Recap screen — read-only list of choice → consequence rows, alignment score/tier header (score at `{typography.stat}` size), no frame, always exactly two exits (Return Home, Start New Run).

UX-DR9: Home screen — title, story title, "Start Story"/"Start Tutorial" actions (relabels to "Resume Story" when a run is in progress per snapshot presence); no circuit frame; simpler/more spacious layout than reading surfaces.

UX-DR10: Tutorial screen — explains page-turn (swipe/tap-zone) and choice (hold/tap) mechanics in words before the player reaches a real choice; "Start Story" is a fixed, always-visible primary action (pinned outside scrolling content, both orientations); leaving Tutorial uses standard iOS back navigation (nav-bar button/edge-swipe), no separate "Back Home" button. *(Amended 2026-08-02 — see Story 2.11 and `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md`; originally specified "Back Home / Start Story actions, tap only" as implemented by Story 1.3.)*

UX-DR11: Run-options action sheet — ellipsis-circle icon, top-right of the reading card content area, present on every Story/Choice page (absent from interstitial, Home, and Tutorial); opens platform-native action sheet with Exit to Home (non-destructive, preserves snapshot), Restart This Run (destructive-styled, requires a second explicit confirmation, clears progress and score), Exit and Clear Progress (destructive-styled, requires a second explicit confirmation matching Restart This Run's weight, clears progress and score and navigates to Home), Cancel. *(Amended 2026-08-02 — see Story 2.11 and `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md`; originally added to Tutorial by Story 2.7 as "present on every Story/Choice and Tutorial page." Tutorial is a pre-run explainer, not a page within a run — its own back navigation already covers the "leave" case, and "Restart This Run" needed a hasInProgressRun guard to avoid describing progress that might not exist, a sign the control didn't fit the screen it was retrofitted onto. Amended again 2026-08-03 — see Story 2.13 and a Sally/UX discussion of deferred-work.md's "2-7-run-options-action-sheet" open design questions; the sheet previously had no single action that both cleared progress and returned to Home, only a two-step Restart-then-Exit workaround. The interstitial exclusion was separately discussed and reconfirmed as-is: the first-visit-only gate (Story 2.9) already means a revisited interstitial behaves like an ordinary page, so no gap actually exists there. Amended again 2026-08-04 — see Story 2.12: "platform-native action sheet" is redefined for this control from a bottom-sliding sheet to iOS 26's button-anchored popover style — Apple changed `confirmationDialog`/`actionSheet` to anchor to their triggering view on iPhone starting in iOS 26, matching iPadOS's long-standing popover presentation (confirmed via WWDC 2025 Session 284), and this app is built against the iOS 26 SDK. This is accepted as the new native behavior rather than fought — the actionable defect was the missing Cancel row, not the presentation style itself; that row is restored by dropping the `.cancel` role from its Button declaration, since popover-style action sheets have always auto-suppressed `.cancel`-role actions (documented `UIAlertController` behavior since iOS 8) in favor of tap-outside-to-dismiss.)*

UX-DR12: VoiceOver support — every choice card exposes role/label/state (including the 1.5s undo-window announcement); Story page exposes "Next Page"/"Previous Page" as VoiceOver custom actions (rotor-accessible, since swipe is otherwise consumed by VoiceOver navigation); run-options button carries an explicit `accessibilityLabel` of "Run options"; focus traversal follows reading order (eyebrow → prose → choices → pager, run-options last).

UX-DR13: Dynamic Type support — all text roles scale through accessibility sizes without truncation; frame-well padding and circuit corner clearance sized with headroom for the largest accessibility category; content (not the frame) scrolls inside the fixed frame when it exceeds visible height.

UX-DR14: Reduce Motion behavior — skip the choice-card charge-fill animation (instant commit instead) and the frame's echo power-up glow/transition (final state applied immediately); page-turn and interstitial entrance/exit collapse to instant cuts.

UX-DR15: Verified WCAG AA contrast — use `accent-ember-text`/`accent-ember-text-dark` (not decorative `accent-ember`/`accent-ember-dark`) for any ember-colored text under 24px/bold, per the DESIGN.md contrast table (this fixes a contrast failure caught and resolved during UX review — see below).

### FR Coverage Map

| FR | Epic |
| --- | --- |
| FR1 | Epic 1 |
| FR2 | Epic 1 |
| FR3 | Epic 2 |
| FR4 | Epic 2 |
| FR5 | Epic 2 |
| FR6 | Epic 2 |
| FR12 | Epic 2 |
| FR7 | Epic 3 |
| FR8 | Epic 3 |
| FR9 | Epic 3 |
| FR10 | Epic 3 |
| FR11 | Epic 1, Epic 2, Epic 3 (cross-cutting acceptance criteria) + Epic 3 closing accessibility validation story |

## Epic List

### Epic 1: Home & Onboarding

Player can open the app, optionally learn the mechanics via a tutorial, and enter a story — every entry action reachable by gesture or accessible tap, never gesture-only.

**FRs covered:** FR1, FR2 (+ FR11 accessibility AC on Home/Tutorial actions)

### Epic 2: Story Reader, Choice Echo & Branch Realities

Player can read a branching story, make permanent choices (gesture or tap), watch the story explicitly call back to an earlier choice 2-3 times, and see a bundled illustration on arriving in a new branch reality.

**FRs covered:** FR3, FR4, FR5, FR6, FR12 (+ FR11 accessibility AC on page-turn/choice interactions)

**Design rationale:** Consolidated deliberately — page nav, choice selection/permanence, echo, and interstitial+art share the same `StoryRunEngine`/`Content`/Story-Choice-view surface (AD-1, AD-3, AD-5); splitting these would mean repeatedly touching the same three files across multiple epics with no genuine feedback-loop benefit.

**Content note:** Story 1 stands up a minimal placeholder content tree (2-3 nodes) to exercise the engine/UI. Authoring the full v1 story tree (10-15 branches, real prose, echo wiring) is separate, tracked work — not implicitly bundled into "build the reader."

**Art note:** Use placeholder/SF Symbol art first to unblock engine/UI work. Producing and swapping in the final ~10-15 generative-AI illustrations is separate, trackable work — not assumed to arrive "for free" alongside the engineering.

**Sequencing note (for Step 3):** sequence stories so basic paging + locked choice selection lands as a visible interim milestone before the echo/interstitial layer, rather than one large simultaneous drop.

### Epic 3: Alignment Scoring, Ending & Memory Recap

When a run terminates (naturally or via hard-fail), it silently resolves to one of four endings through a shared template, followed by a memory screen recapping every choice, its consequence, and the alignment score/tier — for every run, no exceptions.

**FRs covered:** FR7, FR8, FR9, FR10 (+ FR11 accessibility AC)

**Testing note (revised):** ending resolution no longer requires a boundary-case score function — `scoreToEnding` was removed after a mid-planning correction (see `addendum.md`'s correction note); ending kind is now a direct per-node property guaranteed by the content tree's compile-time shape (AD-1, AD-6). Epic 3's testing responsibility is simpler: verify every terminal node resolves to exactly one `EndingKind` and hard-fail is reachable only via its designated gotcha choice.

**Accessibility validation note:** a dedicated end-to-end accessibility pass (VoiceOver navigation, Dynamic Type at max accessibility size, Reduce Motion, contrast) across all screens should be its own explicit closing story — not assumed to be fully caught by per-story AC scattered across the three epics.

**Pre-Submission Checklist** *(non-epic — tracked for visibility, not a story with user-facing value)*
- Apple Developer Program enrollment (blocking prerequisite for TestFlight/App Store distribution — not yet in place)
- Decide developer account type — individual (personal legal name as Seller, faster ~24-48hr approval, no D-U-N-S needed) vs. organization under the LLC (LLC's legal name as Seller, requires a D-U-N-S number + entity email + active website, slower approval) — a legal/tax call outside this document's scope
- App Store content rating self-assessment: front-loaded to Epic 4 Story 4.5, run against the full v1 content — not deferred to submission time
- Complete Agreements, Tax, and Banking in App Store Connect (required before the paid app can go live)
- Export compliance declaration at submission (expected: no custom encryption, given zero networking)

### Epic 4: Story Content & Illustration Production

The player experiences the actual v1 story — real branches, real prose, real echoes, real illustrations — replacing every placeholder Epic 2/3 stood up to unblock engineering work.

**FRs covered:** none new — Epics 1-3 already cover full FR capability; this epic delivers the content volume/completeness that realizes it at scale.

**Dependency:** builds on Epics 1-3 being complete (needs the real Content tree shape and working echo/interstitial/ending mechanics before it's worth writing real branches against them).

### Epic 5: Landscape Support

Player can use the app in either portrait or landscape orientation on iPhone, with every screen reflowing correctly rather than locking to portrait.

**FRs covered:** None new — extends FR1/FR2/FR11's existing screens to a second orientation; a device-support/NFR-level change, not new functionality.

**Sequencing note:** Numbered 5 to avoid renumbering Epics 2-4 (already cross-referenced by number in Story 1.2's implementation and Dev Notes), but scheduled in `sprint-status.yaml` to execute immediately after Epic 1 and before Epic 2 — the landscape layout strategy needs to exist before Epic 2 builds the reading-surface/pager mechanics, to avoid an expensive retrofit later.

## Epic 1: Home & Onboarding

Player can open the app, optionally learn the mechanics via a tutorial, and enter a story — every entry action reachable by gesture or accessible tap, never gesture-only.

### Story 1.1: Project Scaffold

As a developer,
I want a working Xcode project matching the Architecture's Structural Seed layout,
So that every later story has a consistent place to add code.

**Acceptance Criteria:**

**Given** no existing Xcode project
**When** the project is created
**Then** it targets iOS 18.0 minimum (iOS 26 SDK), Swift 6.3, SwiftUI app lifecycle

**And** the project contains `App/`, `Content/`, `Engine/`, `Views/`, `Resources/` groups matching the Structural Seed, plus a `ForkedEchoesTests/` target using Swift Testing

**And** `Resources/Localizable.xcstrings` and `Resources/Assets.xcassets` exist (empty, ready for content) per AD-2

**Given** the project is opened in Xcode 26.6
**When** built and run on the iOS Simulator
**Then** it builds with no warnings/errors and launches to an empty placeholder root view

### Story 1.2: Home Screen — Start/Resume Story & Start Tutorial

As a player,
I want to see the app and story title and choose to start (or resume) the story or view the tutorial when I open the app,
So that I can begin or continue playing.

**Acceptance Criteria:**

**Given** a fresh install with no saved run
**When** Home renders
**Then** it shows the app title, story title, and "Start Story" / "Start Tutorial" actions, tap only (no gesture-only affordances — EXPERIENCE.md resolves FR-1's home entry to tap, not gesture)

**Given** a minimal `RunSnapshot` presence check exists (per AD-4 — full snapshot read/write is Epic 2's job; this story only needs to detect presence)
**When** a snapshot is present in `UserDefaults`
**Then** the primary action relabels from "Start Story" to "Resume Story"

**Given** "Start Story" or "Resume Story" is activated
**When** activated
**Then** the app navigates away from Home (destination is a placeholder Story/Choice stand-in until Epic 2 implements the real reader)

**Given** "Start Tutorial" is activated
**When** activated
**Then** the app navigates to the Tutorial screen (Story 1.3)

**Given** all Home screen text (app title, story title, action labels)
**When** rendered
**Then** every string is sourced from `Localizable.xcstrings` via generated symbols, never a hardcoded Swift string literal (AD-2) — so adding another LTR language later requires no code changes

### Story 1.3: Tutorial Screen

As a first-time player,
I want to view a tutorial that explains the game's mechanics in words,
So that I understand how to read and choose before I reach a real decision.

**Acceptance Criteria:**

**Given** the player navigates to Tutorial from Home
**When** it renders
**Then** it explains page-turning (swipe or tap-zone) and choice-making (hold or tap) mechanics in words, per EXPERIENCE.md Voice and Tone

**Given** Tutorial is shown
**When** inspected
**Then** it offers "Back Home" and "Start Story" actions, tap only

**Given** any other screen in the app
**When** checked for a path to Tutorial
**Then** Tutorial is reachable only from Home (FR2)

**Given** all Tutorial screen text (mechanic explanations, action labels)
**When** rendered
**Then** every string is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)

### Story 1.4: Home & Tutorial Visual Identity + Accessibility Pass

As a player, including one using assistive technology,
I want Home and Tutorial to follow the app's visual identity and be fully usable with VoiceOver and Dynamic Type,
So that the app is usable and on-brand regardless of ability.

**Acceptance Criteria:**

**Given** DESIGN.md tokens needed by Home/Tutorial (headline, body, eyebrow typography; surface/ink colors; spacing scale)
**When** applied
**Then** Home/Tutorial render per DESIGN.md, with no circuit frame on either screen (UX-DR9, UX-DR10 — the frame is reserved for reading surfaces)

**Given** VoiceOver is active
**When** navigating Home/Tutorial
**Then** every action exposes an accessible label and is operable via standard VoiceOver activation, meeting the 44pt minimum tap target (FR11, NFR6)

**Given** Dynamic Type is set to an accessibility size
**When** Home/Tutorial render
**Then** text scales without truncation or clipping (FR11, NFR8)

### Story 1.5: Home Story Subtitle

As a player,
I want a short one-line description of the story beneath its title on Home,
So that I know what I'm about to start before committing to it.

**Acceptance Criteria:**

**Given** Home renders, fresh install or run-in-progress
**When** displayed
**Then** a subtitle line appears directly below the story title (`home.storyTitle`) and above the action buttons, matching `mockups/home.html`/`mockups/home-landscape.html`'s `.story-sub` placement — present in both Home states shown in those mockups

**Given** all Home screen text (AD-2)
**When** the subtitle renders
**Then** its copy is sourced from `Localizable.xcstrings` via a stable key (e.g. `home.storySubtitle`), never hardcoded — placeholder English copy is acceptable for now, same pattern `home.storyTitle` already uses ("Untitled Story") pending Epic 4's full prose authoring

**Given** the accessibility bar Story 1.4 already established for Home (VoiceOver labels, Dynamic Type scaling without truncation, 44pt tap targets on actions)
**When** the subtitle is added
**Then** it meets the same bar — included in VoiceOver reading order between story title and actions, scales with Dynamic Type without clipping — no new exceptions introduced

**Given** Story 5.3's landscape retrofit of Home (capped/centered content, `GeometryReader` + `ScrollView`)
**When** the subtitle is added
**Then** it participates in that existing layout without requiring new landscape-specific handling

*(Owner: Developer. Added via sprint-demo/party-mode review, 2026-07-26 — the user noticed `mockups/home.html`'s `.story-sub` field was never carried into Story 1.2's implementation or any later Home story. Not a regression: Story 1.2's AC never specified a subtitle, so this was a mockup-vs-story gap present from the start, not something later work broke.)*

### Story 1.6: Named Design Constants for Layout Values

As a developer,
I want numeric layout literals (spacing, sizing, opacity) in view code to reference named constants — sourced from a DESIGN.md token where one exists, or a suitably named local constant where one doesn't,
So that values stay traceable to design intent and are never silently duplicated or drifted between call sites.

**Acceptance Criteria:**

**Given** a numeric layout literal in `Views/Home/HomeView.swift` or `Views/Tutorial/TutorialView.swift` that corresponds to a DESIGN.md token (the 8pt spacing scale `{spacing.1}`–`{spacing.8}`, `{components.reading-surface.min-tap-target}` = 44pt, `{components.reading-surface.column-max-width-landscape}` = 680px)
**When** it is used
**Then** it references a named Swift constant derived from that token, not an inline literal

**Given** a numeric layout literal with no corresponding DESIGN.md token (e.g. the action-stack width cap, the subtitle width cap, `SecondaryActionButtonStyle`'s border width, the pressed/disabled opacity values in `ButtonStyles.swift`)
**When** it is used
**Then** it is defined as a named Swift constant with a descriptive name, not an inline literal

**Given** two or more literals across the touched files that share the same value and the same semantic context (e.g. the `320`pt action-stack cap used identically in both `HomeView.swift` and `TutorialView.swift`)
**When** they are extracted
**Then** they reference one shared constant, not separate per-file definitions

**Given** the existing `Views/DesignSystem/` folder (established in Story 1.4) already holds `Typography.swift`/`ButtonStyles.swift` as the project's design-token home
**When** new constants are added
**Then** they live in a new file in that same folder, following its existing naming/organization conventions

**Given** this is a pure refactor of existing, already-shipped Home/Tutorial/ButtonStyles code
**When** the change is complete
**Then** rendered output, layout, and behavior are pixel-for-pixel unchanged — no visual or functional diff

*(Owner: Developer. Added via post-1.5 code-review discussion, 2026-07-26 — the user noticed several magic numbers across `HomeView.swift`/`TutorialView.swift`/`ButtonStyles.swift` while reviewing Story 1.5 and asked for a dedicated cleanup story: DESIGN.md-sourced values get a named constant tied to their token, valueless numbers get a descriptive name, and duplicate same-context values collapse to one shared constant.)*

## Epic 2: Story Reader, Choice Echo & Branch Realities

Player can read a branching story, make permanent choices (gesture or tap), watch the story explicitly call back to an earlier choice 2-3 times, and see a bundled illustration on arriving in a new branch reality.

*Note: FR7 (silent alignment scoring) is formally owned by Epic 3, but its accumulation mechanism (`selectChoice(_:)` adding a delta to `alignmentScore`) is wired in Story 2.3, since it's part of `RunSnapshot` (AD-4) from the moment choices exist.*

### Story 2.1: Minimal Story Content & Engine Foundation

As a developer,
I want a minimal placeholder Content tree and a StoryRunEngine skeleton,
So that later stories have real data and engine plumbing to build against.

**Acceptance Criteria:**

**Given** `Content/` needs data
**When** a minimal `indirect enum` tree is authored
**Then** it contains at least one reading node, one choice node with 2 options, and terminal placeholder ending nodes, per AD-1 (every case resolves to a choice or an ending; tree never reconverges)

**Given** the engine needs to exist
**When** `StoryRunEngine` (`@Observable`) is created
**Then** it exposes `selectChoice(_:)`, `advancePage()`, `goBack()`, and tracks `currentNodeId`, `choiceHistory`, `alignmentScore` in memory (persistence lands in Story 2.4)

**Given** Home's placeholder destination (Story 1.2)
**When** "Start Story"/"Resume Story" is activated
**Then** it now navigates to a real, content-minimal Story/Choice view backed by `StoryRunEngine`, replacing the Story 1.2 placeholder

**Given** the minimal placeholder tree includes terminal ending nodes, but Epic 3 (which implements phase-derivation for `.ending`) doesn't exist yet at this point in the build
**When** the engine's current node is a terminal node
**Then** the view renders a simple placeholder screen ("Run complete — Ending screen coming in Epic 3") instead of crashing or showing undefined content — a temporary stand-in Epic 3 Story 3.2 replaces, not a permanent behavior

### Story 2.2: Page Navigation

As a player,
I want to advance and return through story pages via swipe, tap zones, or VoiceOver actions,
So that I can read at my own pace regardless of input method.

**Acceptance Criteria:**

**Given** a reading page
**When** the player swipes left or taps the right third of the reading card (UX-DR4)
**Then** `advancePage()` is called and the next page renders

**Given** at least one page has been read
**When** the player swipes right or taps the left third
**Then** `goBack()` is called and the previous page renders

**Given** VoiceOver is active
**When** the player uses the "Next Page"/"Previous Page" custom rotor actions
**Then** the same advance/back behavior occurs (UX-DR12 — swipe is otherwise consumed by VoiceOver navigation)

**Given** a page contains an unresolved choice
**When** the player attempts to advance
**Then** forward navigation is blocked (FR3)

**And** a Swift Testing case verifies pager-gating — forward blocked on unresolved choice, locked display on revisit (AD-7, NFR3)

*(Flagged during Epic 1 retrospective, 2026-07-28: do not reuse `ColdLaunchOrientationFix`'s `.id(layoutGeneration)` mechanism as-is on this screen. It forces a full subtree teardown/rebuild on correction, discarding all nested `@State` — harmless on Home/Tutorial, destructive here once real pager position / in-flight choice-hold state exists. See the warning comment in `ColdLaunchOrientationFix.swift` and `project-context.md`'s Landscape/Orientation section.)*

### Story 2.3: Choice Presentation, Selection & Permanence

As a player,
I want to make a permanent choice via press-and-hold or a quick tap,
So my decision sticks and the story moves forward.

**Acceptance Criteria:**

**Given** a choice page with ≥2 options
**When** rendered
**Then** each is an independently selectable Choice card (UX-DR3); only one card can charge at a time (holding a second cancels the first)

**Given** a press-and-hold on a choice card
**When** the hold reaches ~3s
**Then** the choice commits via `selectChoice(_:)`; releasing early cancels to idle with no partial memory

**Given** a quick tap (or VoiceOver double-tap)
**When** activated
**Then** it commits instantly and opens a 1.5s undo window (tap again to revert) — never less forgiving than the hold path

**Given** a choice finalizes
**When** `selectChoice(_:)` fires
**Then** forward navigation unblocks, the card locks to selected styling with a checkmark, and the choice's alignment delta accumulates into the engine's running score (FR7's accumulation mechanism — never exposed in any Epic 2 UI)

**Given** a decided choice page revisited via back-navigation
**When** rendered
**Then** it shows the made choice locked, with no alternate-choice control at all (FR5)

**Given** the app terminates mid-charge or mid-undo-window
**When** relaunched
**Then** the choice page shows undecided — nothing was committed (AD-3)

**Given** a quick tap has committed a choice and its 1.5s undo window is still open
**When** the player pages forward before the window elapses
**Then** forward navigation is already unblocked (commit unblocks navigation immediately, independent of the undo window) and the choice remains locked; the undo affordance has nothing left to act on once the page has changed

**Given** `DESIGN.md`'s specified timings (3000ms charge, 1500ms undo window) are unvalidated placeholder-quality values
**When** implemented and tried by hand on a real device
**Then** these durations may be tuned by feel — they are a reasonable starting point, not a locked spec; if adjusted, update `DESIGN.md`'s token values to match what actually shipped

**And** a Swift Testing case verifies the choice-commit state machine: charge-then-release-early cancels to idle with no partial memory, a tap-commit reverts if tapped again within the undo window, holding a second card while one is charging cancels the first, and no engine mutation occurs unless a commit path (hold-complete or tap-commit) actually fires (AD-3, AD-7, NFR3)

### Story 2.4: Run Persistence (RunSnapshot)

As a player,
I want my in-progress run saved automatically,
So a relaunch or backgrounding doesn't lose my place.

**Acceptance Criteria:**

**Given** any completed mutating intent (`selectChoice`, `advancePage`, `goBack`)
**When** it completes
**Then** `RunSnapshot` (`currentNodeId`, `choiceHistory` as ID pairs, `alignmentScore`, `tutorialSeen`) is encoded and written synchronously to its single `UserDefaults` key (AD-4)

**Given** a cold launch with a valid snapshot
**When** the app starts
**Then** the engine decodes it and resumes at the saved node with full history and score restored

**Given** a decode failure of any kind (missing key, malformed JSON, unresolved `currentNodeId`)
**When** encountered
**Then** the engine falls back to a fresh run at Home exactly as if no snapshot existed — no crash (NFR4)

**Given** Home's Story 1.2 presence-only check
**When** this story's decode-failure handling lands
**Then** Home's Resume/Start label is driven by decode *success*, not mere key presence — a corrupted snapshot falls back to fresh Home and shows "Start Story," never "Resume Story" followed by a silent fresh-start

**And** a Swift Testing case verifies `RunSnapshot` encode/decode round-trip, including the decode-failure fallback (AD-7, NFR3)

### Story 2.5: Narrative Callback (Choice Echo)

As a player,
I want an earlier choice's consequence to resurface explicitly in the prose,
So I feel like my choices mattered.

**Acceptance Criteria:**

**Given** the content tree extended with at least one echo-wired node (referencing an earlier choice by construction, per AD-1)
**When** that node renders
**Then** an Echo callback block appears inline, tagged "The story remembers" in `accent-ember-text` (UX-DR5, UX-DR15)

**Given** an echo block is on-screen
**When** rendered
**Then** the circuit Frame powers up brass → ember with the via-grow/pad-fill shape cue (UX-DR1), for exactly that page's duration, returning to dormant on the next page turn

**Given** each echoed choice
**When** authored
**Then** its callback text is distinguishable in-prose as a reference to the earlier decision, not merely implied by branching (FR6)

**And** a Swift Testing case verifies echo-callback reachability as authored in the tree (AD-7, NFR3)

### Story 2.6: Branch-Arrival Interstitial & Illustrations

As a player,
I want a full-bleed illustration and caption when I arrive in a new branch reality,
So the shift feels distinct and grounded.

**Acceptance Criteria:**

**Given** the content tree extended with a branch-reality transition
**When** the player's choice leads into a new branch reality
**Then** the engine's phase derives to `.interstitial` and a full-bleed illustration + caption renders (UX-DR6), using placeholder/SF Symbol art for now (final generated art is separate tracked work per the Epic 2 Art note)

**Given** the interstitial is showing
**When** the player swipes or taps a page zone
**Then** nothing happens — the interstitial blocks both forward and back until its own Continue affordance is tapped (closes the architecture review's Finding 1 — must block both directions, not just forward)

**Given** the interstitial's Continue affordance is tapped
**When** activated
**Then** phase returns to `.reading` at the new node

**Given** the illustration is referenced
**When** wired
**Then** it uses a generated `ImageResource` symbol from `Assets.xcassets` — never a raw string name (AD-2) — and is never fetched over the network (FR12)

**Given** the branch-arrival interstitial is showing
**When** inspected
**Then** the run-options button is absent — present only on Story/Choice and Tutorial pages, never during the interstitial (UX-DR11)

**Given** the interstitial's flavor caption
**When** rendered
**Then** its text is sourced from `Localizable.xcstrings` by stable key, matching the same convention as story body prose (AD-2)

*Note: gating/permanence behavior amended by Story 2.9 — see that story for current behavior.*

### Story 2.7: Run Options Action Sheet

As a player mid-run,
I want to exit to Home or restart my run from a run-options control,
So I have an escape hatch without losing progress unintentionally.

**Acceptance Criteria:**

**Given** a Story/Choice or Tutorial page
**When** rendered
**Then** a run-options ellipsis icon appears top-right of the reading card (absent from the interstitial and Home) (UX-DR11) — this retrofits Tutorial (Story 1.3) with the control it was missing

**Given** the run-options icon is activated
**When** tapped
**Then** a native action sheet presents: "Exit to Home", "Restart This Run", "Cancel"

**Given** "Exit to Home" is selected
**When** activated
**Then** the app returns to Home and the in-progress `RunSnapshot` is preserved (non-destructive) via `exitToHome()`

**Given** "Restart This Run" is selected
**When** activated
**Then** a second explicit confirmation is required before anything clears; only on confirming does `restartRun()` reset to the initial node and alignment score (AD-3, destructive)

**Given** the run-options button
**When** inspected with VoiceOver
**Then** it carries an explicit `accessibilityLabel` of "Run options" (UX-DR12), not the SF Symbol's default name

**Given** the run-options action sheet's labels ("Exit to Home", "Restart This Run", "Cancel")
**When** rendered
**Then** every label is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)

### Story 2.8: Reading Surface Visual Identity, Dynamic Type & Reduce Motion

As a player, including one using accessibility features,
I want the reading surface to follow the app's visual identity and remain fully usable under Dynamic Type and Reduce Motion,
So the core experience is accessible end-to-end.

**Acceptance Criteria:**

**Given** the remaining DESIGN.md tokens for reading surfaces (frame, choice-card, echo-callback, interstitial, continue-button)
**When** applied
**Then** all Epic 2 screens render per DESIGN.md with verified WCAG AA contrast (NFR7, UX-DR15)

**Given** Dynamic Type set to an accessibility size
**When** reading content or a 3-choice decision point renders
**Then** content scrolls inside the fixed frame (frame itself never resizes), headroom sized for the largest accessibility category, no text clamped (FR11, NFR8, UX-DR13)

**Given** Reduce Motion is enabled
**When** a choice charges or an echo/interstitial transition occurs
**Then** the charge-fill animation is skipped (instant commit) and frame/interstitial/page-turn transitions collapse to instant cuts — nothing produces continuous or looping motion (NFR5, UX-DR14)

**Given** VoiceOver is active on a Story/Choice page
**When** focus traversal occurs
**Then** order follows eyebrow → prose → choices → pager, with run-options last (UX-DR12)

### Story 2.9: Branch-Arrival Interstitial — First-Visit-Only Gate

As a player,
I want the branch-arrival illustration to stay part of the story when I revisit that point,
So re-reading doesn't lose the moment or force me through an artificial gate again.

*(Amendment to Story 2.6, raised via Sprint Change Proposal 2026-08-02 after Simulator playtesting — see `sprint-change-proposal-2026-08-02.md` and `ARCHITECTURE-SPINE.md`#AD-5's 2026-08-02 amendment.)*

**Acceptance Criteria:**

**Given** a branch-arrival node visited for the true first time (not yet in `visitedNodeIds`)
**When** the player arrives
**Then** phase derives to `.interstitial`: full-bleed illustration + caption renders as the node's permanent content (no separate ordinary-prose reveal), swipe/tap-zone do nothing, only Continue advances

**Given** a branch-arrival node already present in `visitedNodeIds`
**When** the player arrives there again (backing up to it, or after an app relaunch)
**Then** the identical illustration + caption renders, but swipe/tap-zone/back all behave like an ordinary page — no Continue-only gate

**Given** Story 2.6 shipped the original one-shot/prose-swap behavior
**When** this story lands
**Then** `ARCHITECTURE-SPINE.md` AD-5 and `EXPERIENCE.md`'s interstitial rows (already updated per the Sprint Change Proposal) match the shipped behavior, and Story 2.6's Swift Testing coverage is revised: no test may still assert the node reverts to ordinary body prose after dismissal

### Story 2.10: Persist Back-Navigation Across App Relaunch

As a player,
I want to swipe back through pages I've already read even after force-quitting and relaunching the app,
So that resuming a run doesn't strand me on a forward-only path.

*(Follow-up gap surfaced during Story 2.9 Simulator testing, 2026-08-02 — deferred by explicit user decision rather than blocking Story 2.9. Pre-existing since Story 2.4: `StoryRunEngine.visitedNodeIds`, the back-navigation stack `goBack()` pops, has never been part of `RunSnapshot` — `resumingFromSnapshot(defaults:)`'s own doc comment documents an empty post-resume back-stack as "an accepted, deliberate consequence" of `RunSnapshot`'s original four-field shape. In practice this means `goBack()` is silently a no-op immediately after any relaunch, on every page in the app, until the player advances forward at least once in the new session — not specific to the branch-arrival interstitial, just first surfaced there. See `sprint-status.yaml`'s `epic: 2` action item for the same gap, recorded 2026-08-02.)*

**Acceptance Criteria:**

**Given** a mid-run `RunSnapshot` persisted before the app terminates, at a node reached via one or more forward page-turns from earlier in the run
**When** the app relaunches and resumes from that snapshot
**Then** `goBack()` can navigate backward through those same previously-visited pages exactly as it could before the relaunch — not silently a no-op until the player advances forward again first

**Given** `RunSnapshot`'s schema
**When** extended to carry whatever backward-navigation history this story needs
**Then** it decodes gracefully (a sensible default, not a rejected/corrupted snapshot) for any snapshot written before this story ships, which has no such field — mirroring Story 2.9's `visitedArrivalNodeIds` precedent for extending the snapshot schema

**Given** the branch-arrival interstitial (Story 2.9)
**When** its own dismissal-persistence and revisit-rendering behavior is exercised together with this story's fix
**Then** nothing regresses: a dismissed arrival node still renders ungated on any revisit, including a relaunch-then-`goBack()`-into-it path this story newly makes reachable

**And** a Swift Testing case verifies: a snapshot capturing a multi-step-forward run position, when resumed via `resumingFromSnapshot(defaults:)` on a freshly-constructed engine, supports `goBack()` navigating backward through that history correctly — not just forward (AD-7, NFR3)

**And** a manual-verification AC: in Xcode/Simulator, advance forward through at least two pages, force-quit, relaunch, tap "Resume Story," and confirm swiping/tapping backward now works through the pages visited before the relaunch, not just forward. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

### Story 2.11: Tutorial Navigation & Fixed-Actions Layout

As a player,
I want a single, obvious way back to Home from Tutorial, the "Start Story" button always reachable without scrolling, and no run-management controls on a screen where there's no run yet to manage,
So the screen isn't cluttered with two overlapping exits, an escape hatch for a run that may not exist, and I'm never stuck scrolling past the mechanics copy just to start the story.

*(UX design pass with Sally, 2026-08-02, prompted by user observation on this branch — see `sprint-change-proposal-2026-08-02-tutorial-navigation-and-fixed-actions.md` for the full discussion and rationale, including its 2026-08-02 addendum. Amends UX-DR10, UX-DR11, and Story 1.3/2.7's shipped ("done") implementations; those stories are left historically intact per the Story 2.6→2.9 precedent.)*

**Acceptance Criteria:**

**Given** the Tutorial screen as it ships today (Story 1.3/1.4)
**When** this story lands
**Then** the in-content "Back Home" button is removed; leaving Tutorial is via the standard `NavigationStack` back button (top-left nav bar) and its default edge-swipe gesture — no `.navigationBarBackButtonHidden` suppression, no replacement in-content exit control

**Given** the Tutorial screen's "Start Story" / "Resume Story" action
**When** rendered in either portrait or landscape, and regardless of Dynamic Type category
**Then** the button is pinned outside the scrollable region (fixed position, always visible without scrolling) — only the mechanic-explanation copy scrolls, using a restructure of the shared `GeometryReader`/`ScrollView` centering pattern (project-context.md's "Never use `Spacer()` inside this pattern" rule still applies to whatever internal layout replaces it)

**Given** `TutorialView.swift`'s `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` (added by Story 2.7 per UX-DR11)
**When** this story lands
**Then** the run-options button and its `onExitToHome`/`onRestartRun` closures are removed from `TutorialView.swift` entirely — Tutorial is a pre-run explainer screen, not a page within a run, and its "Exit to Home"/"Restart This Run" actions duplicated exits/state-mutation already covered by Tutorial's own back navigation and the fact that no run is guaranteed to exist yet (Story 2.7's own `onRestartRun` guard, `guard runProgress.hasInProgressRun else { return }`, was already a sign this control didn't fully fit the screen it was retrofitted onto)

**Given** this is a Tutorial-only change
**When** implemented
**Then** `HomeView.swift` and its `GeometryReader`/`ScrollView` centering pattern are untouched — Home is not in scope for this story; the run-options button's presence on Story/Choice pages (UX-DR11) is also untouched — only Tutorial loses it

**And** a manual-verification AC: in Xcode/Simulator, confirm (1) tapping the nav-bar back chevron and (2) an edge-swipe-back gesture both return to Home from Tutorial; (3) "Start Story"/"Resume Story" is reachable with zero scrolling in landscape at both default and an accessibility Dynamic Type size; (4) the mechanic-explanation text still scrolls independently when it overflows; (5) no run-options icon renders anywhere on Tutorial, regardless of `hasInProgressRun` state. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

### Story 2.12: Run-Options Sheet — Fix Popover Presentation & Missing Cancel

As a player,
I want the run-options control to present as the native bottom action sheet with a visible Cancel, exactly as designed,
So I always have a clearly-labeled way to back out without accidentally triggering Exit or Restart.

*(Bug surfaced via user-reviewed Simulator screenshot, 2026-08-03 — `Simulator Screenshot - iPhone 17 - 2026-08-03 at 08.14.12.png`, taken on `RunOptionsButton`'s options dialog. UX-DR11 specifies a "platform-native action sheet" with three options — "Exit to Home", "Restart This Run", "Cancel" — and `RunOptionsButton.swift` (Story 2.7) declares an explicit `Button("runOptions.cancel", role: .cancel)` in both its options dialog and its restart-confirmation dialog. The screenshot instead shows a popover anchored to the ellipsis button (callout arrow, not a bottom sheet) with only two rows — "Exit to Home" and "Restart This Run" — no Cancel visible. iOS auto-suppresses an explicit `.cancel`-role button only when a dialog renders in popover style (regular horizontal size class or an anchor-based presentation), since tap-outside-to-dismiss already covers that case there — so the missing Cancel is a symptom of the wrong presentation style, not two independent bugs. `TARGETED_DEVICE_FAMILY` is iPhone-only (1) and no `.popover`/`presentationCompactAdaptation`/size-class override exists anywhere in the codebase, so the root cause is not yet understood and needs investigation, not just a style override.)*

**Acceptance Criteria:**

**Given** `RunOptionsButton`'s options `confirmationDialog` or its restart-confirmation `confirmationDialog`
**When** invoked on an iPhone simulator or device, in portrait or landscape
**Then** it presents as a bottom-anchored native action sheet (UX-DR11), never as a button-anchored popover

**Given** either of `RunOptionsButton`'s two confirmation dialogs
**When** presented
**Then** the explicit `runOptions.cancel` row is visible and dismisses the dialog with no side effects, in addition to the existing "Exit to Home"/"Restart This Run" rows

**Given** the popover presentation seen in the 2026-08-03 screenshot
**When** root-caused
**Then** the investigation identifies why this build resolved a regular/anchor-based presentation despite `TARGETED_DEVICE_FAMILY = 1` and no popover-forcing code, and the fix addresses that cause (not just a superficial style override) — findings recorded in the story's Completion Notes List (project-context.md Process Agreement)

**And** a manual-verification AC: in Xcode/Simulator, on an iPhone target, reproduce the original bug (screenshot above), apply the fix, and confirm both dialogs now render as bottom action sheets with all three rows ("Exit to Home"/"Restart This Run", "Cancel") visible. Result + date recorded in the story's Completion Notes List

### Story 2.13: Run-Options Sheet — Exit and Clear Progress

As a player mid-run,
I want a single action that clears my progress and returns me to a clean Home screen,
So I don't have to Restart and then separately Exit just to fully bail on a run.

*(UX design pass with Sally, 2026-08-03 — resolves the second of two open design questions logged in `deferred-work.md`'s "2-7-run-options-action-sheet" entry and `sprint-status.yaml`'s epic-2 action items, 2026-08-02. Today's two options — "Exit to Home" (non-destructive, preserves `RunSnapshot`, stays where left off) and "Restart This Run" (destructive, clears progress, but resets in place at the intro rather than leaving the run) — cover stay+keep, stay+clear, and leave+keep, but not leave+clear. The companion open question (whether the branch-arrival interstitial should also carry the run-options control) was discussed and closed with no code change needed: Story 2.9's first-visit-only gate means a revisited interstitial already behaves like an ordinary page, so the "no escape hatch" concern only ever applied to a true first-visit interstitial, which the user confirmed should stay a pure art moment. Amends UX-DR11 — see that entry's 2026-08-03 addendum.)*

**Acceptance Criteria:**

**Given** the run-options action sheet (`RunOptionsButton`)
**When** invoked
**Then** it presents four rows in order: "Exit to Home", "Restart This Run", "Exit and Clear Progress", "Cancel"

**Given** "Exit and Clear Progress" is selected
**When** activated
**Then** a second explicit confirmation is required before anything clears, styled and worded consistently with "Restart This Run"'s existing confirmation (destructive role, same interaction pattern)

**Given** the "Exit and Clear Progress" confirmation is confirmed
**When** the action completes
**Then** progress and alignment score are cleared (same reset performed by `restartRun()`) and the app navigates to Home, landing on Home's fresh-install state — not the "Resume Story" state

**Given** the "Exit and Clear Progress" action and its confirmation dialog's labels
**When** rendered
**Then** every label is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2), following the same `runOptions.*` naming convention as the sheet's existing options

**Given** the run-options action sheet's four rows
**When** their order is verified
**Then** it is fixed as "Exit to Home", "Restart This Run", "Exit and Clear Progress", "Cancel" — in that sequence, never reordered by role/destructive styling — and this ordering is asserted by an automated test (closing the gap 2.7's code review flagged: no automated coverage existed for `RunOptionsButton`'s button ordering)

**Given** Story 2.12 (popover-presentation/missing-Cancel bug fix)
**When** this story lands
**Then** it builds on the corrected bottom-action-sheet presentation from 2.12 — this story does not independently re-fix the presentation bug, only adds the new row and confirmation to the already-corrected sheet

**And** a manual-verification AC: in Xcode/Simulator, start a run, advance a few pages, invoke run options, select "Exit and Clear Progress," confirm, and verify (1) the app lands on Home in its fresh-install state, (2) a new run starts clean with no carried-over progress or score, (3) VoiceOver announces the new option and its confirmation correctly. Result + date recorded in the story's Completion Notes List (project-context.md Process Agreement)

### Story 2.14: Fix Flaky Tests Under Swift Testing's Parallel Execution

As a developer running `swift test`,
I want the engine-logic test suite to pass reliably every run,
So that a red run always means a real regression, never noise I have to explain away or rerun past.

*(Bug surfaced during Story 2.13's own `swift test` verification, 2026-08-04 — repeated runs intermittently failed `observerRefreshPicksUpASnapshotWrittenAfterConstruction` (`RunSnapshotPresenceTests.swift`), `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, and `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately` (`StoryRunEngineTests.swift`) — none of them touched by Story 2.13's changes, and none new. Confirmed pre-existing, not a 2.13 regression, by `git stash`-ing 2.13's diff and rerunning the unmodified baseline suite repeatedly (no failures observed in that sample, but the failure signature — a freshly-written `RunSnapshot` not read back on the very next line, same `UserDefaults` suite — is unrelated to anything 2.13 touched). Every failure observed so far has the same shape: a value just written to a `UserDefaults(suiteName:)` instance isn't visible on an immediate subsequent read from that same instance, sometimes off by exactly one prior test's state — consistent with a race under Swift Testing's default parallel execution, not a logic bug in the engine or in `RunSnapshotPresence`/`StoryRunEngine` themselves. `TestSupport.swift`'s `freshDefaults()` already mints a UUID-suffixed suite name per test specifically to avoid cross-test collisions (code review, 2026-08-01, Story 2.4) — this bug means that isolation isn't actually complete under Linux's `swift-corelibs-foundation` `UserDefaults` implementation, or isn't complete under concurrent access to it, and needs root-causing, not just a symptom-level retry.)*

**Acceptance Criteria:**

**Given** the full `ForkedEchoesTests` suite
**When** `swift test` is run repeatedly from the repo root (at least 10 consecutive runs)
**Then** every run passes with zero flaky failures — no test that was previously observed to intermittently fail (`observerRefreshPicksUpASnapshotWrittenAfterConstruction`, `anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase`, `anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately`, or any other test sharing the same write-then-immediate-read-on-a-fresh-`UserDefaults`-suite shape) fails on any run

**Given** the root cause of the flakiness
**When** it is investigated
**Then** the investigation identifies why a `UserDefaults(suiteName:)` instance's own immediately-prior synchronous write is sometimes not visible on the very next read from that same instance under Swift Testing's parallel execution, despite each test using a unique UUID-suffixed suite name (`TestSupport.swift`'s `freshDefaults()`) — findings recorded in the story's Completion Notes List (project-context.md Process Agreement)

**Given** the fix
**When** applied
**Then** it addresses the actual race (e.g. serializing the affected UserDefaults-suite-creation/read/write sequence, disabling parallel execution only if genuinely unavoidable and justified in Completion Notes, or a correctness fix to how `freshDefaults()` isolates suites) rather than papering over it with retries, `sleep`s, or `.serialized` applied blanket across the whole suite without first understanding why isolation is failing

**Given** this story's own changes
**When** complete
**Then** all 64 pre-existing tests (60 before Story 2.13, plus 2.13's 4 new tests) still pass, with no test logic changed except what's needed to fix the race itself — this is an infrastructure/reliability fix, not a behavior change

**And** a verification AC: run `swift test` at least 10 consecutive times from the repo root and record the pass count (expect 10/10) in the story's Completion Notes List, alongside a one-line description of the actual root cause found

## Epic 3: Alignment Scoring, Ending & Memory Recap

When a run terminates (naturally or via hard-fail), it silently resolves to one of four endings through a shared template, followed by a memory screen recapping every choice, its consequence, and the alignment score/tier — for every run, no exceptions.

### Story 3.1: Ending Kind Resolution

As a developer,
I want each terminal node in the content tree to carry its `EndingKind` directly, and the engine to resolve a run's ending from whichever terminal node is reached,
So ending resolution requires no runtime computation.

**Acceptance Criteria:**

**Given** Content/'s minimal tree (from Epic 2, Story 2.1) extended with terminal nodes
**When** each terminal node is authored
**Then** it carries an `EndingKind` case (home/stay/limbo/hardFail) fixed at write-time (AD-1, AD-6)

**Given** the engine's current node is a terminal node
**When** the phase derives to `.ending` (per AD-5)
**Then** the run's ending is read directly as that node's `EndingKind` — no computation, no score check

**Given** a designated gotcha (hard-fail) choice is selected
**When** `selectChoice(_:)` targets a hard-fail terminal node
**Then** the engine transitions to Ending the instant the choice fires (AD-5), not on a later `advancePage()` discovery

**Given** the content tree
**When** traced across all branches
**Then** every branch terminates in exactly one of the four ending types (FR8), enforced by AD-1's tree shape

**And** a Swift Testing case verifies hard-fail nodes are reachable only via their designated gotcha choice, and that the Ending transition fires immediately at `selectChoice(_:)` time rather than being deferred to a subsequent `advancePage()` (AD-7, NFR3) — `EndingKind` coverage itself is already guaranteed by the compiler (AD-1), not something a test needs to re-verify

**And** content-authoring guidance is documented for later story-tree writing: roughly 1-2 terminal nodes as home endings and 3-4 as stay endings across the full v1 tree (addendum.md) — both this ratio and AD-9's score→tier boundaries are placeholder until Epic 4 authors the real v1 tree and finalizes them together against actual score distribution; this story's placeholder tree only needs enough terminal nodes to exercise all four `EndingKind` cases at least once each

**Given** the engine's phase derives to `.ending`
**When** the transition completes
**Then** `RunSnapshot` is cleared from `UserDefaults` as part of that same transition (AD-4) — Memory (Story 3.3) can rely on this having already happened by the time it reads snapshot state

### Story 3.2: Ending Screen

As a player,
I want to see an ending screen that matches how my run concluded,
So I understand how my choices resolved.

**Acceptance Criteria:**

**Given** a run reaches a terminal node (whether through ordinary branch traversal or a hard-fail gotcha choice)
**When** the Ending phase is entered
**Then** a single shared Ending template renders, differing only in outcome-specific text/illustration across home/stay/limbo/hard-fail (FR9), driven by that node's `EndingKind` (Story 3.1)

**Given** the Ending screen
**When** rendered
**Then** the circuit Frame rests permanently in its powered-up ember state — a resting condition, not a transition (UX-DR7)

**Given** the Ending screen
**When** the player taps anywhere
**Then** the app advances to Memory (Story 3.3) — no auto-advance

**Given** a hard-fail ending
**When** it renders
**Then** it uses the same shared template with tone-appropriate dark-comedy copy, arriving directly from the gotcha choice rather than through normal page-turn flow (FR8, FR9)

**Given** the Ending screen's "tap to continue" affordance text
**When** rendered
**Then** it is sourced from `Localizable.xcstrings`, consistent with the ending body copy's own per-node localization (AD-2)

**Given** the app is backgrounded or terminated while on the Ending or Memory screen
**When** it relaunches
**Then** Home renders in its fresh-install "Start Story" state — `RunSnapshot` was already cleared on entering Ending (Story 3.1, AD-4), so there is no in-progress run to resume and no persisted recap to restore; this is expected, not a bug

### Story 3.3: Memory / Recap Screen

As a player,
I want a recap of every choice I made, what it caused, and my alignment score/tier after every run,
So the run becomes a story about me.

**Acceptance Criteria:**

**Given** the Ending screen is tapped
**When** advancing
**Then** Memory renders a read-only list of choice → consequence rows sourced from `RunSnapshot.choiceHistory`, re-resolving display text from the current String Catalog by ID at render time — never stale frozen prose (AD-4, UX-DR8)

**Given** any run, including hard-fail
**When** it completes
**Then** Memory is shown for 100% of completed runs with no ending-type exception (FR10)

**Given** the Memory screen
**When** rendered
**Then** it shows the alignment score at the top in `{typography.stat}` styling (UX-DR8) — a purely reflective stat with no bearing on the ending already shown on the previous screen (closing FR7's display-only exposure rule from Epic 2's silent accumulation)

**Given** a descriptive tier label is derived from the score for display
**When** shown alongside the score
**Then** it is cosmetic only — the tier label never changes or predicts which ending (Story 3.2) was already reached; the two are fully independent

**Given** "Return Home" is selected
**When** activated
**Then** the app navigates to Home; `RunSnapshot` was already cleared on entering Ending (AD-4), so no destructive confirmation is needed

**Given** "Start New Run" is selected
**When** activated
**Then** `startNewRun()` resets the engine to the initial node with cleared history/score and the app enters a fresh run — no confirmation required (AD-3)

**Given** a run that hard-failed on its very first choice (a `choiceHistory` of exactly one entry)
**When** Memory renders
**Then** it still shows a valid recap with that single choice-and-consequence row and the correspondingly small alignment score — no empty-state or crash at the minimum possible history length

**Given** the Memory screen's "Return Home"/"Start New Run" action labels and any tier-label copy
**When** rendered
**Then** every string is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)

**Given** `scoreToTier(score:)` (AD-9)
**When** the accumulated alignment score is negative, zero, or any value outside a placeholder band's current bounds
**Then** it still resolves to exactly one tier — no unmapped/crash state — because the lowest band is open-ended

### Story 3.4: Ending & Memory Visual Identity

As a player,
I want Ending and Memory to follow the app's visual identity with correct contrast and typography,
So run resolution feels consistent with the rest of the app.

**Acceptance Criteria:**

**Given** the remaining DESIGN.md tokens (`ending-frame`, `memory-row`, `memory-score`)
**When** applied
**Then** both screens render per DESIGN.md with verified WCAG AA contrast (NFR7)

**Given** Dynamic Type at an accessibility size
**When** Ending/Memory render
**Then** text scales without truncation (FR11, NFR8)

**Given** VoiceOver is active
**When** navigating Ending/Memory
**Then** all actions (tap-to-continue, Return Home, Start New Run) expose accessible labels and meet the 44pt tap target (FR11, NFR6)

### Story 3.5: End-to-End Accessibility Validation

As a player using any assistive technology,
I want the complete app — Home through Memory — verified end-to-end for VoiceOver, Dynamic Type, Reduce Motion, and contrast,
So nothing scattered across individual stories was missed.

**Acceptance Criteria:**

**Given** the full app (Epics 1-3) is complete
**When** walked end-to-end using VoiceOver only, no sighted/gesture interaction
**Then** every screen and action is reachable, correctly labeled, and announces state changes (choice selected, undo window, echo firing, ending reached) (FR11)

**Given** Dynamic Type at the largest accessibility category
**When** every screen is inspected
**Then** no text is clipped or truncated anywhere (FR11, NFR8)

**Given** Reduce Motion enabled
**When** a full run is played
**Then** no continuous or looping motion occurs anywhere in the app (NFR5)

**Given** every text/color pairing across DESIGN.md
**When** measured
**Then** all meet WCAG AA thresholds in both light and dark themes (NFR7)

**Given** any interaction in the app
**When** audited
**Then** none is reachable only via a custom gesture — every one has a standard tap/VoiceOver equivalent (FR11's hard constraint)

**Given** every illustration in the app
**When** audited with VoiceOver
**Then** each announces its authored descriptive label — none is silent (hidden) and none announces a meaningless default label

## Epic 4: Story Content & Illustration Production

The player experiences the actual v1 story — real branches, real prose, real echoes, real illustrations — replacing every placeholder Epic 2/3 stood up to unblock engineering work.

### Story 4.1: Story Tree Outline & Structure

As a solo developer/writer,
I want to plan the full v1 branch structure before writing final prose,
So the tree satisfies FR-8's ending taxonomy and the addendum's content ratio from the start.

**Acceptance Criteria:**

**Given** PRD Open Question 1 (story scale undetermined)
**When** the outline is created
**Then** it specifies a concrete target branch count and total choice-point count for v1

**Given** the addendum's content ratio
**When** ending nodes are planned
**Then** the outline allocates 1-2 terminal nodes as home, 3-4 as stay, remaining non-hard-fail terminals as limbo, plus at least one hard-fail gotcha choice

**Given** the addendum's "always an ideal path home" principle
**When** the outline is reviewed
**Then** at least one traceable path from the root to a home ending is identified and marked

**Given** FR-6 (echo)
**When** the outline is built
**Then** each planned echo callback identifies which earlier choice it references and where (2-3 per run)

### Story 4.2: Full Prose Authoring

As a player,
I want to read the actual v1 story, not placeholder text,
So the app delivers the real experience.

**Acceptance Criteria:**

**Given** the outline (Story 4.1)
**When** prose is written
**Then** every planned node's body, choice labels, echo callbacks, and ending/tutorial copy are added to `Localizable.xcstrings` with stable keys following the node-id + role convention (AD-2)

**Given** the "safe choice unreliable" mechanic (addendum.md)
**When** choices are authored
**Then** at least one choice reads as safe but doesn't guarantee the safe outcome

**Given** hard-fail choices
**When** authored
**Then** they read as obviously absurd dark-comedy gotchas, not fair telegraphed warnings (FR-8 notes)

**Given** v1 scope
**When** all user-facing text is authored — story prose plus every UI chrome label from Epics 1-3
**Then** it exists in `Localizable.xcstrings` in English only for v1, but because every screen sources 100% of its text from the catalog with zero hardcoded strings, adding another LTR language later is purely additive: translate the catalog, ship no code changes (Architecture's Deferred section, AD-2)

**Given** each of the ~10-15 branch-reality illustrations
**When** authored
**Then** a distinct, descriptive VoiceOver description of what the illustration depicts is written and added to `Localizable.xcstrings` alongside the caption — not restating the caption, but conveying the illustration's specific visual content so VoiceOver users get equivalent access to the branch reality's atmosphere

### Story 4.3: Story Tree Wiring

As a developer,
I want the full outline and prose wired into `Content/`'s Swift tree, replacing the Epic 2 placeholder,
So the real story is playable.

**Acceptance Criteria:**

**Given** the outline and prose
**When** the tree is authored
**Then** it replaces the placeholder 2-3 node tree from Epic 2 Story 2.1 with the full v1 branch structure

**Given** AD-1
**When** compiled
**Then** every node resolves to a choice or an ending — no dead ends possible

**Given** the ratio guidance
**When** the final tree is inspected
**Then** it matches Story 4.1's planned home/stay/limbo distribution

**Given** echo wiring
**When** the tree is complete
**Then** each planned echo correctly references its earlier choice by tree position (AD-1)

### Story 4.4: Branch-Reality Illustration Production

As a player,
I want to see a distinct illustration for each branch reality I visit,
So each reality feels visually grounded.

**Acceptance Criteria:**

**Given** the ~10-15 distinct branch-reality flavors identified in the outline
**When** illustrations are produced
**Then** each is generated via a generative AI image tool at development time, per the addendum's art pipeline note

**Given** each illustration
**When** added
**Then** it's bundled into `Assets.xcassets` as its own image set, replacing Epic 2 Story 2.6's placeholder art, referenced only via generated `ImageResource` symbols (AD-2)

**Given** FR-12
**When** illustrations are wired
**Then** none are fetched over the network at runtime — bundled in the app binary

**Given** each illustration's authored VoiceOver description (Story 4.2)
**When** the interstitial renders
**Then** the illustration exposes that description as its `accessibilityLabel` — VoiceOver users hear a real description of the branch reality's visual flavor, not a meaningless default label and not silence

### Story 4.5: Content Playtesting & App Store Rating Self-Assessment

As a developer,
I want to playtest the complete v1 story and self-assess its App Store content rating before final polish,
So compellingness and rating risk are addressed while there's still room to adjust content.

**Acceptance Criteria:**

**Given** the full tree (Story 4.3) and illustrations (Story 4.4)
**When** played end-to-end by the developer and friends (PRD's informal validation plan, Open Question 4)
**Then** at least one full playthrough of each ending type (home/stay/limbo/hard-fail) is exercised

**Given** the dark-comedy hard-fail content
**When** Apple's App Store Connect content-rating self-assessment is completed
**Then** a target age rating is determined with enough runway left to adjust content if the rating comes back stricter than expected — not deferred to the Pre-Submission Checklist

**Given** the "ideal path home" design principle
**When** playtested
**Then** at least one tester finds a path to a home ending following only the story's own cues (informal validation)

### Story 4.6: App Store Listing & Submission Assets

As a developer,
I want the mandatory App Store Connect listing assets completed,
So the app can actually be submitted (SM-1).

**Acceptance Criteria:**

**Given** `DESIGN.md`'s warm-ink/circuit-frame visual identity, with no app icon spec anywhere in it
**When** an app icon is designed
**Then** it translates the in-app aesthetic into Apple's required icon sizes — closing this gap, not cropping an existing screenshot

**Given** the app's on-device-only architecture (no network calls, no data collection)
**When** App Store Connect's privacy nutrition label questionnaire is completed
**Then** it accurately declares zero data collection

**Given** screenshots are required for submission
**When** captured
**Then** they're taken from the actual running app across required device sizes, showing representative moments (a choice page, an echo firing, an ending)

**Given** a title, subtitle, description, and keywords field are required
**When** written
**Then** they describe the app honestly — category, mechanic, and feeling — without overclaiming features that don't exist

**Given** this is explicitly "not a business" (PRD Non-Goals)
**When** this story is scoped
**Then** it covers only mandatory listing requirements for submission — no ASO strategy, no keyword-ranking optimization, no iterative marketing copy testing

## Epic 5: Landscape Support

Player can use the app in either portrait or landscape orientation on iPhone, with every screen reflowing correctly rather than locking to portrait.

**FRs covered:** None new — extends FR1/FR2/FR11 to a second orientation.

**Added via Sprint Change Proposal (2026-07-26):** originally the app was scoped iPhone-only, portrait-only (v1 architecture decision). This epic reverses that constraint before Epic 2's reading-surface/pager work builds further portrait-only assumptions. See `sprint-change-proposal-2026-07-26.md` for full impact analysis.

### Story 5.1: Landscape UX Design Pass

As a UX Designer,
I want a documented landscape layout strategy for every screen type (Home, Tutorial, Story/Choice, Interstitial, Ending, Memory),
So that Epic 5 and all subsequent epics can build landscape-aware screens consistently.

**Acceptance Criteria:**

**Given** DESIGN.md/EXPERIENCE.md's current portrait-only specs
**When** this story is complete
**Then** both docs include an explicit landscape section covering: reading-surface reflow (column/margin/max-width behavior), circuit-frame behavior in landscape, gesture-zone geometry (swipe/tap-zone page-turn, hold-to-choose) adapted for landscape's wider/shorter aspect ratio, and Home/Tutorial's title-card layout in landscape

**Given** the 7 existing portrait mockups
**When** this story is complete
**Then** Home and Tutorial have landscape companion mockups at minimum (Story/Choice, Ending, Memory landscape mockups may follow when their own epics are built, informed by this story's design language)

*(Owner: UX Designer agent, via the `bmad-ux` skill — not the Developer agent.)*

### Story 5.2: Landscape Architecture Decision & Orientation Unlock

As a developer,
I want the orientation lock lifted and the architecture doc updated with the landscape layout strategy,
So that landscape becomes a first-class, documented constraint for all future stories.

**Acceptance Criteria:**

**Given** Story 5.1's landscape design language
**When** this story is complete
**Then** `ARCHITECTURE-SPINE.md`'s Structural Seed documents the landscape layout strategy in full (replacing the "TBD" note added by the 2026-07-26 Sprint Change Proposal), including any new Architecture Decision needed (e.g. a landscape reflow AD)

**Given** the current orientation lock (`INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait`)
**When** this story is complete
**Then** both Debug and Release configurations support the orientations Story 5.1 designed for

*(Owner: Architect agent + Developer.)*

### Story 5.3: Home & Tutorial Landscape Retrofit

As a player,
I want Home and Tutorial to work correctly in landscape,
So that rotating my device doesn't break the two screens that already exist.

**Acceptance Criteria:**

**Given** Story 5.1's landscape design and Story 5.2's unlocked orientation
**When** Home/Tutorial render in landscape
**Then** they reflow per the documented design, not a stretched/clipped portrait layout

**Given** FR11 accessibility parity
**When** in landscape
**Then** Dynamic Type/VoiceOver/tap-target requirements still hold (same bar Story 1.4 already establishes for portrait, extended to the landscape variant)

*(Owner: Developer.)*

### Story 5.4: Cold-Launch Orientation Fix

As a player,
I want the app to render in the correct layout the moment it launches, regardless of which orientation my device is already in,
So that I never see a wrong, stretched, or clipped layout that only corrects itself after I rotate my device.

**Acceptance Criteria:**

**Given** the device is already rotated to landscape before the app is launched
**When** Home or Tutorial first renders
**Then** it renders the landscape layout immediately, with no portrait-then-landscape flash and no rotation required to self-correct

**Given** the device is already in portrait before the app is launched
**When** Home or Tutorial first renders
**Then** it renders the portrait layout immediately (regression guard — confirms the fix doesn't invert the bug for the other starting orientation)

**Given** the fix is in place
**When** either cold-launch case is exercised in the Simulator
**Then** the result is recorded in the story's Completion Notes List (date + orientation(s) checked), per the verification-reporting agreement adopted 2026-07-26

*(Owner: Developer. Added via sprint-demo/party-mode review, 2026-07-26 — see `deferred-work.md`'s "Follow-ups from: sprint demo" section for the original repro and candidate fix (reading the window scene's `interfaceOrientation`, or subscribing to `UIDevice.orientationDidChangeNotification`, on `.onAppear` instead of trusting the first `GeometryReader` layout pass). Take into the sprint ahead of Story 2.1 — Epic 2's reading surface is expected to reuse the same `GeometryReader`-based centering pattern and would otherwise inherit the bug.)*

**Downstream note:** Starting with Epic 2 (whose stories are created after Epic 5 lands), every screen-building story should incorporate Story 5.1's landscape design language directly — no separate landscape-retrofit story should be needed for Epic 2/3/4's screens if this is done from the start.

## What's Next

Completing Epics 1-4 means the app is fully built, content-complete, and playable end-to-end. Remaining before submission: the Pre-Submission Checklist (Apple Developer Program enrollment and account-type decision; App Store content rating self-assessment front-loaded to Epic 4 Story 4.5; Agreements/Tax/Banking; export compliance declaration).
