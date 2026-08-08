# Deferred Work

**Status as of 2026-08-08: every entry below is closed — resolved in code/docs, dismissed as accepted/non-issue with rationale, or tracked into a specific story. Nothing in this file represents open, un-owned work.** New entries get appended above as future reviews surface them; each new entry should reach one of those three end states before this file is next audited, not accumulate indefinitely.

## Deferred from: code review of 3-4-ending-and-memory-visual-identity (2026-08-06)

- **[RESOLVED — tracked as Story 3.6, 2026-08-06]** ~~`ending-frame`/`memory-row`'s `background: {colors.surface-raised}` token is never applied anywhere in the Reading/Ending/Memory view chain~~ — no `.background(Color.surfaceBase)`/`.background(Color.surfaceRaised)` call exists in `StoryChoiceView.swift`, `FrameView.swift`, `EndingView.swift`, `MemoryView.swift`, or `RootView.swift` (only `HomeView.swift`, `TutorialView.swift`, and `ChoiceCardView.swift` apply it). Screens render on the plain system default background instead of DESIGN.md's warm paper-cream (`surface-base`)/raised-card (`surface-raised`) tones in either theme. Pre-dates Story 3.4 (traces to Story 2.5) and spans Reading, not just Ending/Memory. See `epics.md` Story 3.6 ("Reading & Ending Surface Background and Frame Inset Rule") for the full AC.
- **[RESOLVED — tracked as Story 3.6, 2026-08-06, same story as above]** ~~`components.frame`'s `inset-rule-width`/`inset-rule-color`/`inset-rule-color-active` (a 1px border line around the card, distinct from the corner via/pad marks) is never drawn~~ — `FrameView.swift` only renders the four corner via/pad marks; no `Rectangle().stroke(...)` or path traces the card edge anywhere in the codebase. `ending-frame` (DESIGN.md `components.ending-frame.rule-color`) explicitly re-specifies this as part of the same inherited-token family as the `background` gap above. Pre-dates Story 3.4 (traces to Story 2.5) — bundled with the `background` gap into Story 3.6 since both live in `FrameView`.
- **[RESOLVED — Story 3.5 audit, confirmed 2026-08-08]** ~~EndingView's swipe-back gesture may be unreachable at accessibility Dynamic Type sizes~~ — the structural conflict (`EndingView.swift`'s outer `.gesture(backSwipeGesture)`, line 49, sits above/outside the `GeometryReader`/`ScrollView` that `.accessibilitySizeFramedScroll()` mounts only at accessibility sizes) was confirmed real via code inspection 2026-08-07, but the theorized touch-arbitration outcome was unconfirmed pending a live AX5 Simulator test. **User-verified 2026-08-08: at AX5 on the Ending screen, a right-swipe still correctly triggers `engine.goBack()`** — the `ScrollView`'s `UIPanGestureRecognizer` does not swallow the swipe in practice, despite the structural risk being real. No fix needed; genuinely resolved, not just tracked.
- **[RESOLVED — tracked as Story 3.8, 2026-08-06]** ~~Memory score renders "+0" for a neutral (zero) alignment score~~ — `MemoryView.swift`'s `.formatted(.number.sign(strategy: .always()))` always shows a sign, so a genuinely neutral run reads as "positive." Now an explicit AC on Story 3.8 (Memory & Tutorial Polish and Deferred-Item Cleanup).
- **[RESOLVED — Story 3.5 audit, 2026-08-07]** ~~Non-text color pairs (the secondary-button border stroke, Memory's row divider fill) are not covered by DESIGN.md's text-contrast table~~ — formally verified against WCAG 1.4.11 (3:1 graphical-object threshold) using real sRGB component values pulled directly from `Assets.xcassets` (relative-luminance method): `ink-primary` border on `surface-base` 15.57:1 (light) / 15.12:1 (dark), on `surface-raised` 16.78:1 (light) / 13.70:1 (dark); `trace-brass` Memory row divider on `surface-base` 4.37:1 (light) / 7.92:1 (dark). All three clear 3:1 with wide margin in both themes. Added as a new, visually distinct 1.4.11 table in DESIGN.md (Color section) alongside the existing 1.4.3 text-contrast table.

## Deferred from: code review of 3-3-memory-recap-screen (2026-08-06)

- **[RESOLVED — doc fix applied directly, 2026-08-06]** ~~AC #8's literal wording ("sourced from `Localizable.xcstrings` via generated symbols") contradicts project-context.md's binding Localization rule~~ — a RESOLVED CONFLICT banner is now recorded directly in `project-context.md`'s Localization section: the binding plain-dot-path-key rule wins, and any AC using "generated symbols" phrasing (a project-wide, pre-existing wording gap across many stories' ACs) should be read as "sourced from `Localizable.xcstrings` by stable key." No story needed; existing shipped story files are left historically intact per convention.

## Deferred from: code review of 3-2-ending-screen (2026-08-05)

- **[RESOLVED — Story 3.3, 2026-08-05]** No exit-to-Home affordance on Ending/Memory — carried as Story 3.3 AC #5/#6; the real `MemoryView` renders both "Return Home" and "Start New Run," user-verified in Simulator per that story's Task 7.
- **[RESOLVED — Story 3.3, 2026-08-05]** `preconditionFailure` crash risk in the `.ending` arm — confirmed as a real, user-hit crash (rendering-timing race, not phase/node-type drift as originally suspected); fixed by rendering `EmptyView()` instead. See Story 3.3's Completion Notes for the full root-cause writeup.
- **[RESOLVED — tracked into Story 4.2, 2026-08-06]** ~~`story.endingElsewhere`/`story.endingLimbo` ending copy is invented placeholder text~~ — Story 4.2 (Full Prose Authoring) already requires "every planned node's body, choice labels, echo callbacks, and ending/tutorial copy" to be authored, which inherently replaces this placeholder; no separate AC needed.
- **[RESOLVED — sprint-status.yaml fix applied directly, 2026-08-06]** ~~`sprint-status.yaml`'s `last_updated` field continues as one unbounded growing line~~ — see the 2-14 review entry below for the fix; this entry and the 3-1 entry below were the same recurring problem, now closed together.

## Deferred from: code review of 3-1-ending-kind-resolution (2026-08-05)

- **[RESOLVED — sprint-status.yaml fix applied directly, 2026-08-06]** ~~`sprint-status.yaml`'s `last_updated` field keeps growing unboundedly~~ — full history through 2026-08-06 archived to the new `sprint-log.md`; `last_updated` now holds only the current entry going forward (convention documented in `sprint-status.yaml`'s own header comments). Closes this entry, the 3-2 entry above, and the 2-14 entry below — all three flagged the same recurring problem.

## Deferred from: code review of 2-14-fix-flaky-tests-under-swift-testings-parallel-execution (2026-08-04)

- **[RESOLVED — sprint-status.yaml fix applied directly, 2026-08-06]** ~~`sprint-status.yaml`'s `last_updated` field is one ever-growing, unbounded single-line string~~ — see resolution above (archived to `sprint-log.md`, field now holds only the current entry).

## Deferred from: code review of 2-13-run-options-sheet-exit-and-clear-progress (2026-08-04)

- **[ACCEPTED — no action, 2026-08-06]** `runOptionsRowOrderIsFixed()` only asserts row order, not the `switch`'s label/action mapping. Same class as the `RunOptionsButton` UI-test-coverage gap below (2-7 review) — genuinely requires a UI-test target this project has deliberately chosen not to build (AD-7). User decision 2026-08-06: leave as accepted debt rather than reopen AD-7 right now.
- **[ACCEPTED — no action, 2026-08-06]** `onExitAndClearProgress`'s call-order (clear then exit) has no automated regression coverage — same UI-test-infra gap as above, same acceptance.
- **[RESOLVED — root-caused, 2026-08-06]** ~~`StoryRunEngine.resumingFromSnapshot(defaults:)` (production code) has the identical write-then-immediate-read `UserDefaults` access shape as the test-flakiness race~~ — Story 2.14's own root-cause finding (see its Completion Notes / `sprint-log.md`) traced the flakiness specifically to `swift-corelibs-foundation`'s `CFPreferences` process-global domain cache, a Linux-only artifact of the devcontainer's test toolchain. Real iOS uses Apple's own Foundation/CFPreferences implementation, not `swift-corelibs-foundation`, so this race does not reach the shipped app. No production-code action needed.

## Deferred from: code review of 2-10-persist-back-navigation-across-app-relaunch (2026-08-03)

- **[RESOLVED — tracked into Story 4.3, 2026-08-06]** ~~AC #3's literal scenario (relaunch-then-`goBack()`-into-a-dismissed-arrival-node) is not actually exercised~~ — structurally unreachable in the Epic 2 placeholder tree; now an explicit testing note on Story 4.3 (Story Tree Wiring), once the real tree provides a reachable post-arrival node.
- **[ACCEPTED — no action, 2026-08-06]** `loadValid(from:)` has no drift-check for `visitedNodeIds` equivalent to `visitedArrivalNodeIds`'s — low real-world reachability (`NodeID` is a closed enum; drift requires a future content-tree restructuring, which Story 4.3 will exercise directly if it matters).
- **[ACCEPTED — no action, 2026-08-06]** No consistency check between a resumed `visitedNodeIds` stack and `currentNodeId`/`choiceHistory` — only reachable via manual `UserDefaults` tampering; no security boundary needed on local single-player save data.
- **[ACCEPTED — no action, 2026-08-06]** `goBack()` has no guard against a persisted `visitedNodeIds` entry being an `.ending` node — normal play can never push one; only reachable via tampered save data.
- **[RESOLVED — tracked into Story 4.3, 2026-08-06]** ~~`visitedNodeIds` grows unbounded, re-serialized synchronously on every mutating call~~ — immaterial at placeholder-tree scale; now an explicit decision point on Story 4.3, to be revisited against the real full-length tree's actual run lengths.
- **[ACCEPTED — no action, 2026-08-06]** A malformed-but-present `visitedNodeIds` key discards the entire snapshot via `loadValid(from:)`'s catch-all — pre-existing behavior inherited from the `choiceHistory`/`visitedArrivalNodeIds` pattern since Story 2.4; a deliberate fail-safe-by-discarding choice, not a defect.

## Deferred from: code review of 2-5-narrative-callback-choice-echo (2026-08-01)

- **[ACCEPTED — no action, 2026-08-06]** Story file's Dev Notes reference a stale force-unwrap (`echoBodyKey!`) that doesn't match the shipped `if let` code — cosmetic doc drift in an already-shipped story file only; the shipped code is the safer form. Historical story files are left intact per project convention rather than retroactively edited.
- **[RESOLVED — tracked into Story 4.3, 2026-08-06]** ~~Only one node in the placeholder tree has a non-nil `echoBodyKey`, so `isEchoActive`'s optional-check logic has no second data point~~ — now an explicit testing note on Story 4.3, once the real tree provides a genuine nil-echo `.reading` node.
- **[RESOLVED — adopted as process rule, 2026-08-06]** ~~Manual verification checklist recorded as one generic sentence, not itemized against AC #7's explicit checklist~~ — added directly to `project-context.md`'s Process Agreements: a visual-only manual-verification Task must confirm each AC sub-item explicitly going forward.

## Deferred from: story validation of 5-4-cold-launch-orientation-fix (2026-07-27)

- **[RESOLVED 2026-07-27]** `project-context.md`'s devcontainer-toolchain note was half-stale (a Linux `swiftc` toolchain exists; `xcodebuild`/Apple SDKs still don't) — corrected directly in `project-context.md`'s Environment section.

## Deferred from: code review of 5-4-cold-launch-orientation-fix (2026-07-28)

- **[RESOLVED — accepted by user, 2026-07-28]** `Package.swift` target names shadow the Xcode project's own target names — intentional devcontainer test tooling; Xcode never reads `Package.swift`, so no real functional conflict. Kept as-is.
- **[RESOLVED — accepted by user, 2026-07-28]** New `.claude/settings.local.json` Bash allowlist entries added this session — kept as-is, useful for ongoing devcontainer Swift work.
- **[RESOLVED — concern did not materialize, 2026-08-06]** ~~`.id(layoutGeneration)`'s full subtree teardown/rebuild could discard real nested `@State` if Epic 2's reading surface reused this exact pattern~~ — confirmed by direct code inspection: `layoutGeneration` remains confined to `ColdLaunchOrientationFix.swift`, used only by Home/Tutorial. Epic 2's reading surface used a different architecture entirely (the AD-5 `.fullScreenCover` rewrite, Story 2.2) rather than reusing this pattern, so the risk never materialized.
- **[ACCEPTED — no action, 2026-08-06]** The `swiftc -parse` Bash allowlist entry is scoped to a one-off `/tmp` path, not real repo `.swift` files — a deliberate, narrow tooling-scope decision; broaden only if a future story actually needs it.
- **[RESOLVED — confirmed in practice, 2026-07-28]** AC#1/AC#3 evidence concerns (single prose Completion Notes line, synchronous corrective toggle) — user reported empirical Simulator confirmation of no flash in either orientation; the flagged timing risk did not materialize.
- **[ACCEPTED — no action, 2026-08-06]** The fix compares `UIWindowScene.interfaceOrientation` against `verticalSizeClass` rather than `GeometryReader`'s stale `proxy.size` directly — theoretical desync risk, never observed in Simulator verification.

## Deferred from: code review of 1-5-home-story-subtitle (2026-07-26)

- **[ACCEPTED — no action, 2026-08-06]** No automated existence/regression test for `home.storySubtitle` — same UI-test-infra gap as every other UI-existence concern in this project (AD-7 scopes automated coverage to `StoryRunEngine` logic only); not a gap this story introduced.

## Deferred from: code review of 1-4-home-and-tutorial-visual-identity-and-accessibility-pass (2026-07-26)

- **[RESOLVED — decision point now lives in Story 3.6, 2026-08-06]** ~~`.background(Color.surfaceBase.ignoresSafeArea())` is duplicated per-screen rather than centralized~~ — Story 3.6 (Reading & Ending Surface Background and Frame Inset Rule) now explicitly requires deciding and documenting whether background application is centralized at an outer container or kept per-view, closing this exact question across the Reading/Ending/Memory chain.

## Deferred from: code review of 1-1-project-scaffold (2026-07-26)

- **[RESOLVED — already tracked, no new action needed]** No `DEVELOPMENT_TEAM` set — already covered by `epics.md`'s Pre-Submission Checklist (Apple Developer Program enrollment/account-type decision).
- **[RESOLVED — already covered by Story 4.6]** `AppIcon.appiconset`'s empty 1024x1024 slot — Story 4.6 (App Store Listing & Submission Assets) already has an explicit AC requiring a designed app icon closing this exact gap.

## Deferred from: code review of 1-2-home-screen-start-resume-story-and-start-tutorial (2026-07-26)

- **[RESOLVED — Story 2.4 + Story 3.7, 2026-08-06]** ~~`hasInProgressRun` isn't reactively tied to future snapshot writes~~ — Story 2.4 shipped the real `@Observable` `RunProgressObserver`/`refresh()` wiring; Story 3.7 (Run-Progress Refresh-on-Dismiss) now formalizes and test-covers exactly when `refresh()` is called.
- **[RESOLVED — Story 2.4, 2026-08-06]** ~~`RunSnapshotPresence.hasInProgressRun` is a bare presence check with no validation/invalidation~~ — Story 2.4's AC #4 explicitly requires decode-*success*, not mere presence, to drive the Resume/Start label; shipped and done.
- **[RESOLVED — implemented, 2026-08-06]** ~~No bound `NavigationPath` on `RootView`'s `NavigationStack`~~ — confirmed by direct code inspection: `RootView.swift` has `@State private var navigationPath = NavigationPath()`, bound to the `NavigationStack` and used for programmatic pop-to-root (the run-options "Exit to Home" flow).
- **[ACCEPTED — no action, 2026-08-06]** No re-entrancy guard against rapid double-tap on `NavigationLink`s — generic, low-severity SwiftUI concern; never observed as a real bug across the many stories and manual verification passes since. Same class as the identical 1-3 review item below.

## Deferred from: code review of 5-2-landscape-architecture-decision-and-orientation-unlock (2026-07-26)

- **[RESOLVED — administrative, accepted by user, 2026-07-26]** `sprint-status.yaml` flipping `5-1` to `done`/`epic-5` to `in-progress` with no `5-1-*.md` story file — reflects the user's own confirmation that 5.1's directly-completed design work is done; not a tracking defect.
- **[RESOLVED — window closed, 2026-08-06]** ~~Orientation unlock ships ahead of the Home/Tutorial landscape retrofit~~ — Story 5.3 shipped immediately after in the same sprint sequence as `epics.md` always specified; both are `done`, so the window this flagged no longer exists.

## Deferred from: code review of 5-3-home-and-tutorial-landscape-retrofit (2026-07-26)

- **[RESOLVED — superseded, 2026-08-06]** ~~`StoryChoicePlaceholderView.swift` has no landscape centering treatment, unlike `TutorialPlaceholderView.swift`~~ — this placeholder no longer exists; Story 2.1 replaced it with the real `StoryRunEngine`-backed reader.

## Deferred from: code review of 1-3-tutorial-screen (2026-07-26)

- **[ACCEPTED — no action, VoiceOver out of v1 scope, 2026-08-07]** ~~No VoiceOver-specific alternative wording for the gesture-only page-turn mechanic~~ — was tracked into Story 4.2 (Full Prose Authoring, 2026-08-06) as an AC requiring Tutorial's `tutorial.mechanic.pageTurn` copy to mention the VoiceOver rotor alternative. **Superseded by the 2026-08-07 Sprint Change Proposal:** VoiceOver is not officially tested/supported for v1, and Tutorial copy explaining a VoiceOver-specific rotor action would be confusing/irrelevant given that. Story 4.2's AC dropped accordingly (see `epics.md`).
- **[RESOLVED — tracked into Story 3.8, 2026-08-06]** ~~No `tutorialSeen` persistence flag written when Tutorial is dismissed~~ — confirmed by direct code inspection still true today: `RunSnapshot.tutorialSeen` exists in the schema (Story 2.4) but is always encoded `false` with zero producers or consumers anywhere in the codebase. Now an explicit AC on Story 3.8: either wire a real producer/consumer or remove the field entirely as dead scope.
- **[ACCEPTED — no action, 2026-08-06]** Rapid double-tap on the "Start Story" `NavigationLink` before push transition completes — identical, already-accepted risk to the 1-2 review item above; not introduced by this diff.

## Deferred from: user testing during 1-3-tutorial-screen (2026-07-26) — app-wide bug, not scoped to this story

- **[RESOLVED — fixed by Story 5.4, 2026-08-06]** ~~Cold-launch orientation mismatch: Home/Tutorial render the wrong initial layout if the Simulator is already rotated before launch~~ — Story 5.4 (Cold-Launch Orientation Fix) shipped exactly this fix (reading `UIWindowScene.interfaceOrientation` on `.onAppear` instead of trusting the first `GeometryReader` pass), user-verified in both cold-launch directions. Duplicate of the "Follow-ups from sprint demo" entry below — both close together.

## Follow-ups from: sprint demo / party-mode review of Epic 1 + Epic 5 (2026-07-26)

- **[RESOLVED — fixed by Story 5.4, 2026-08-06]** ~~Cold-launch orientation mismatch is real and reproducible, not a platform limitation~~ — see resolution above; Story 5.4 shipped the fix using exactly the candidate approach this entry proposed.
- **[RESOLVED 2026-07-26]** Design-doc drift from two mid-implementation decisions (circuit-frame-on-Tutorial question, Home headline case) — fully reconciled across `epics.md`/DESIGN.md/EXPERIENCE.md/mockups; no remaining drift.
- **[ADOPTED as ongoing process, 2026-08-06]** "Report Simulator verification inline, when it happens" — adopted into `project-context.md`'s Process Agreements (see "Report Simulator/manual verification inline" entry) and followed consistently in every story's Completion Notes since (each records date + what was checked at verification time, not retroactively).

## Deferred from: code review of 2-1-minimal-story-content-and-engine-foundation (2026-07-31)

- **[RESOLVED — Story 3.2, 2026-08-05]** `.ending` case hardcoded placeholder — replaced with the real `EndingView`.
- **[RESOLVED — Story 3.3, 2026-08-05]** `.memory` phase hardcoded placeholder — replaced with the real `MemoryView`.

## Deferred from: code review of 2-2-page-navigation (2026-08-01)

- **[RESOLVED 2026-08-05 (pre-Epic-3 planning review)]** `StoryRunEngine.goBack()` has no node-type guard on `.ending` — decided as intentional, not a gap: `choiceHistory` permanence already prevents any re-decision, so paging back through locked choices from Ending is harmless, arguably a nice "look back" affordance. No guard needed.
- **[RESOLVED — Story 3.5 audit, 2026-08-07]** ~~VoiceOver "Next Page"/"Previous Page" custom actions stay exposed and silently no-op when blocked~~ — confirmed via code inspection: `StoryChoiceView.swift`'s rotor action (lines 195-200) calls `engine.advancePage()` directly; `StoryRunEngine.advancePage()`'s `.choice` branch (`StoryRunEngine.swift` lines 188-195) is a `guard let decision = ... else { return }` with zero side effects when the current choice is unresolved — a genuine, total no-op (no state mutation, no haptic/sound trigger anywhere in the call chain). Judgment call: accepted as shipped — this mirrors the equally-silent behavior of attempting a swipe/tap-zone page-turn on the same blocked page (no differing treatment for the VoiceOver path), and EXPERIENCE.md's Accessibility Floor does not require blocked-navigation feedback. Not escalated as a fast-follow. **Update, 2026-08-07 (Sprint Change Proposal):** VoiceOver is no longer officially tested/supported for v1 (see project-context.md Process Agreements) — this finding is now lower-stakes than originally scoped (a no-op in an unofficially-tested interaction path), but the underlying code-level finding stands unchanged: `advancePage()`'s blocked-choice case is a true, harmless no-op. No further action needed.
- **[ACCEPTED — not applicable, 2026-08-06]** No RTL/`layoutDirection` handling for swipe/tap-zone left=back/right=forward — `Localizable.xcstrings` is English-only and no RTL locale is planned anywhere in current planning artifacts; nothing exercises this path.
- **[ACCEPTED — no action, 2026-08-06]** The horizontal-dominance swipe guard only checks the final `.onEnded` translation vector, not the drag's path — closes the specific bug found this story (swipe-up misfiring); a path-aware guard is tunable-by-feel gesture polish, not a regression, and no user-reported recurrence since.
- **[TRACKED — in action_items, not duplicated here]** The process/retro note about sizing gesture/navigation-architecture stories with more slack, and whether AD-7's "no UI test target" stance should be revisited, is already tracked as its own `sprint-status.yaml` action item ("flag gesture/nav-architecture stories as higher-risk at story-creation time," status: open, owner: Amelia/Winston) — not duplicated as a separate deferred-work entry.

## Deferred from: code review of 2-3-choice-presentation-selection-and-permanence (2026-08-01)

- **[ACCEPTED — no action, 2026-08-06]** No automated tests cover `ChoiceCardView`'s state machine (charge timing, tap/undo-window transitions, VoiceOver activation path) — same UI-test-infra gap as the `RunOptionsButton`/`RunOptionsRow` items elsewhere in this file (AD-7). User decision 2026-08-06: leave as accepted debt rather than reopen AD-7 right now.
- **[ACCEPTED — no action, 2026-08-06]** `ChoiceCardView`'s two timer paths duplicate the same "sleep, check not-cancelled, check state, finalize" shape with no shared helper — style-only duplication, no behavioral risk; revisit only if a third path arises.

## Deferred from: code review of 2-4-run-persistence-runsnapshot (2026-08-01)

- **[RESOLVED — tracked into Story 4.3, 2026-08-06]** ~~`RunSnapshot.loadValid`'s `choiceHistory` validation calls `StoryTree.node(for:)`, which runs content-authoring `precondition()` traps that could crash decode validation instead of returning `nil`~~ — not reachable with today's placeholder tree; now an explicit decision point on Story 4.3, to be settled once the real tree exists.
- **[RESOLVED 2026-08-01]** Reusing one long-lived `StoryRunEngine` instance re-presented a finished run on "Start Story" — user-hit during manual verification, fixed immediately per the project's "fix broken windows immediately" policy (`startFreshRunIfCurrentRunHasEnded()`). The broader mid-run `startNewRun()`/`exitToHome()`/`restartRun()` surface this didn't cover was itself completed by Story 2.7/2.13.

## Deferred from: user testing during 2-7-run-options-action-sheet (2026-08-02)

- **[RESOLVED — via sprint-status.yaml action_items, discussed with Sally 2026-08-03]** Design question: should the interstitial carry the run-options control too? — left as-is, no story needed. Story 2.9's first-visit-only gate means a revisited interstitial already behaves like an ordinary page (run-options included); the "no escape hatch" concern only applied to a true first-visit interstitial, which stays a deliberate "pure art moment." See UX-DR11's 2026-08-03 addendum in `epics.md`.
- **[RESOLVED — Story 2.13, 2026-08-06]** Design question: run-options sheet missing a single action that both clears progress and returns to Home — resolved by Story 2.13 ("Exit and Clear Progress"), done.

## Deferred from: code review of 2-8-reading-surface-visual-identity-dynamic-type-and-reduce-motion (2026-08-02)

- **[ACCEPTED — architecturally moot, 2026-08-06]** `components.interstitial.caption-color` token is defined but unused — `BranchArrival`'s content model structurally has only one caption field, so the token has nothing to apply to; not a code gap. Would only become actionable if a future content-model change adds a second caption-role field, which nothing in Epic 4's scope plans to do.
- **[SUPERSEDED — Simulator-confirmed real overlap, see "Deferred from: Story 3.5 audit" below, 2026-08-08]** ~~`runOptionsButtonClearance` unverified at AX5~~ — confirmed via code inspection: both call sites (`StoryChoiceView.swift` lines 279 and 312, ordinary-size and accessibility-size layout paths respectively) use the same fixed `LayoutMetrics.runOptionsButtonClearance` (60pt, `minTapTarget + Spacing.small * 2`) as `readingCardPadding(top:)`. This value does not scale with Dynamic Type, but `RunOptionsButton`'s `Image(systemName: "ellipsis.circle")` (`RunOptionsButton.swift` line 50) has no explicit `.font()`/`.imageScale()` cap, so the glyph itself follows the environment's Dynamic Type size by default — meaning the fixed 60pt clearance and the button's actual rendered footprint at AX5 are not guaranteed to track together. This is a real rendering question this devcontainer cannot answer (no Simulator). Flagged to the user as an explicit Simulator checkpoint in Story 3.5's Completion Notes — now answered, see below.
- **[ACCEPTED — already documented trade-off, 2026-08-06]** `ScrollView` vs. page-turn-swipe vs. hold-to-charge gesture race at accessibility Dynamic Type sizes — already an accepted, documented trade-off (mirrors Story 2.9's identical precedent for the interstitial), covered by Story 2.8's own AC #5 manual verification.
- **[RESOLVED — tracked into Story 4.3, 2026-08-06]** ~~`.transition(.opacity)`/`.animation(value: engine.phase)` won't animate a same-phase `.id()`-forced swap between two consecutive not-yet-dismissed interstitial nodes~~ — not reachable with the current single-arrival-node tree; now an explicit testing note on Story 4.3, conditional on whether the real tree ever authors that shape.
- **[ACCEPTED — rare and non-destructive, 2026-08-06]** Dynamic Type crossing the accessibility-size boundary mid-interaction cancels an in-progress `ChoiceCardView` charge/undo `Task` — requires an in-app Dynamic Type change mid-interaction; state simply resets to idle, no crash/corruption.
- **[RESOLVED — tracked into Story 3.8, 2026-08-06]** ~~Echo-callback tag `Text` has no named DESIGN.md typography role, only ad-hoc `.fontWeight(.bold)`~~ — now an explicit AC on Story 3.8: add a named role or explicitly document the ad-hoc styling as intentional.

## Deferred from: code review of 2-7-run-options-action-sheet (2026-08-02)

- **[ACCEPTED — no action, 2026-08-06]** No automated UI-test coverage for `RunOptionsButton`'s chained dialogs, button ordering, or role-to-closure wiring — requires a UI-test target this project deliberately doesn't have (AD-7). User decision 2026-08-06: leave as accepted debt.
- **[RESOLVED — tracked as Story 3.7, 2026-08-06]** ~~`RootView`'s "Exit to Home" refresh relies on an implicit `.onChange(of: isPresentingStorySession)` refresh path with no test asserting the wiring~~ — re-inspected 2026-08-06: `RootView.swift`'s `.onChange` and `HomeView.swift`/`TutorialView.swift`'s `.onAppear` are each a deliberate fix for a different navigation trigger (session dismissal vs. Home↔Tutorial push/pop), not one fragile mechanism — but neither has automated test coverage, and no doc explains why both exist together. See `epics.md` Story 3.7 ("Run-Progress Refresh-on-Dismiss — Test Coverage & Consolidation Audit").

## Deferred from: Story 3.5 audit, user Simulator verification (2026-08-08)

- **[RESOLVED — Story 3.9, 2026-08-08]** ~~`runOptionsButtonClearance` overlap confirmed real at AX5: the run-options button's ellipsis glyph grows with Dynamic Type ... while the reserved clearance ... does not~~ — Story 3.9 (Run-Options Button Recede-on-Scroll) shipped the picked design direction: the button recedes to low opacity while the accessibility-size `ScrollView` is actively scrolling and returns to full opacity at rest, so it no longer visually collides with scrolled prose. Done, user-verified in Simulator 2026-08-08.

## Deferred from: code review of story-3-5-end-to-end-accessibility-validation (2026-08-08)

- **[TRACKED — Story 3.10, 2026-08-08]** ~~`HomeView`/`TutorialView` action buttons (`HomeView.swift:41-51`, `TutorialView.swift` equivalent) share the same unpadded `.frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)` pattern this review's fix addressed on the interstitial Continue button~~ — now an explicit AC on Story 3.10 (Action Button Padding — AX5 & Compact-Height Verification): verify at AX5, apply Story 3.5's own padding fix if actually broken.
- **[TRACKED — Story 3.10, 2026-08-08, same story as above]** ~~New `.padding(.vertical, Spacing.small)` on the interstitial Continue button (`BranchArrivalInterstitialView.swift:129-131`) adds to the required content height in the non-scrolling compact-height (landscape) layout path at ordinary Dynamic Type, which has no `ScrollView` escape route~~ — now Story 3.10's second AC: verify against `illustrationMaxHeightFractionCompact`'s headroom in that specific orientation/size combination, adjust if it doesn't fit.
- **[TRACKED — Story 3.11, 2026-08-08]** ~~Decided-but-not-selected `ChoiceCardView` cards keep the `.isButton` trait and a live (no-op) `.accessibilityAction(.default, …)` (`ChoiceCardView.swift:148-149`) with no disabled/`.notEnabled` trait to signal the card is inert~~ — now an explicit AC on Story 3.11 (ChoiceCardView Disabled Trait & VoiceOver Wording Contract). Kept as a story despite VoiceOver's 2026-08-07 v1 de-scoping — user decision 2026-08-08: an already-identified correctness gap is still worth closing, unlike the 2-2 review's `advancePage()` finding, which was accepted because no gap had been identified there.
- **[TRACKED — Story 3.11, 2026-08-08, same story as above]** ~~EXPERIENCE.md's exact VoiceOver wording contract is still not literally matched: no "Choice" role prefix in the accessibility label, and the pre-existing (Story 2.3) undo-window hint string doesn't mention "double-tap"/"1.5 seconds" (`ChoiceCardView.swift:148,154`; `Localizable.xcstrings:595-603`)~~ — now Story 3.11's second/third ACs: add the "Choice" role prefix and update both hint strings to literally reference "double-tap" and "1.5 seconds."

## Deferred from: code review of 3-6-reading-and-ending-surface-background-and-frame-inset-rule (2026-08-06)

- **[ACCEPTED — no action, 2026-08-08]** `isFrameEligibleNode == false` reading nodes render on `surfaceBase` directly with no `surfaceRaised` card fill (no `FrameView` attached there) — pre-existing gating logic unchanged by this story, not a regression; matches Memory's own no-raised-card precedent.
- **[RESOLVED — file header corrected directly, 2026-08-08]** ~~`LayoutMetrics.swift`'s file header ("Named layout/opacity constants... Pure refactor", Story 1.6) is stale relative to the file's actual contents~~ — header rewritten to describe the file's current scope (named constants plus shared `View`/`GeometryProxy` helpers accreted since Story 3.6/3.9), not just its Story 1.6 origin.
- **[ACCEPTED — no action, 2026-08-08]** `FrameView`'s `.background` attachment (this story's fix for the `.overlay` text-hiding bug) silently depends on `content` at every call site being sized to exactly the bounds `FrameView`'s own `GeometryReader` resolves to, with no compiler or test enforcement of that invariant — architectural risk inherent to the pattern, not solvable without UI/snapshot test infrastructure this project doesn't have (AD-7).
- **[ACCEPTED — no action, 2026-08-08]** No automated regression test (snapshot/reference-image) guards the accessibility-size scroll/safe-area geometry despite its five-round manual-debugging history during this story's Task 4 — consistent with this project's existing zero-view-test convention (AD-7), not a gap specific to this story.
