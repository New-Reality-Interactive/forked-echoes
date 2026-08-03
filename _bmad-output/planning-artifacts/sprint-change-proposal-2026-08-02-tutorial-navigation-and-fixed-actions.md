---
name: 'Sprint Change Proposal — Tutorial Navigation & Fixed-Actions Layout'
type: sprint-change-proposal
status: approved
created: '2026-08-02'
triggering_story: '1-3-tutorial-screen'
follow_up_story: '2-11-tutorial-navigation-and-fixed-actions-layout'
---

# Sprint Change Proposal — Tutorial Navigation & Fixed-Actions Layout

## 1. Issue Summary

Story 1.3 (Tutorial Screen) shipped and merged with two actions per UX-DR10: an in-content "Back Home" button (`@Environment(\.dismiss)`) and "Start Story"/"Resume Story" (`NavigationLink`), both scrolling with the mechanics copy inside the shared `GeometryReader`/`ScrollView` centering pattern.

Two issues surfaced from live use of the shipped screen, raised by the user on this branch (2026-08-02) and discussed with Sally (UX Designer):

1. **Redundant back navigation.** Tutorial is pushed onto `RootView`'s `NavigationStack` (the one place in the app that still uses stock push/pop — see `ARCHITECTURE-SPINE.md` AD-5 and `project-context.md`'s Navigation section), which gives it a standard nav-bar back chevron and edge-swipe-back for free. Story 1.3's "Back Home" button duplicates that. Nobody had explicitly decided to keep both — the button predates the app-wide reasoning against relying on incidental system gestures (later formalized in AD-5's Story 2.2 amendment for the Story session) being reconsidered for Home↔Tutorial specifically.
2. **Landscape scroll to reach actions.** Both actions scroll with the mechanics copy inside the shared centering pattern; in landscape's reduced vertical space, the user has to scroll past the text to reach either button.

## 2. Impact Analysis

**Epic Impact:** None at the epic level. Epic 2 remains fully achievable as planned; this is a UI-only follow-up, no engine/content impact.

**Story Impact:**
- **Story 1.3** — already `done`/merged. Left historically intact (its AC accurately describes what was actually shipped and reviewed); a pointer note added to its Change Log referencing this proposal.
- **New Story 2.11** — added to `epics.md` (appended after 2.10, following the same "append rather than renumber" convention Story 2.9 established) and to `sprint-status.yaml` as `backlog`. Owns implementing the revised Tutorial layout/navigation.

**Artifact Conflicts:**
- `epics.md` UX-DR10 — updated in place with a dated amendment note (same pattern as AD-5's Story 2.2 amendment).
- `EXPERIENCE.md`'s "Tutorial actions" Component Patterns row — updated to describe the fixed "Start Story" action and standard-iOS-back exit, with a pointer to this proposal.
- `project-context.md` — no change needed. Its Navigation section's existing rule ("`NavigationStack` ... reserved for Home ↔ Tutorial's back-and-forth wayfinding only") already correctly describes the mechanism Tutorial will now rely on for exit; nothing about that rule was wrong, Story 1.3 just hadn't yet leaned on it for the exit action.
- PRD — no conflict. The PRD's "options to go back home or start the story" (Section: user journey) and "Both exit actions ... are gesture-selectable with accessible tap equivalents" language are satisfied by standard iOS back navigation (nav-bar button is an accessible tap equivalent to the edge-swipe gesture) — no FR change.
- No other artifacts (deployment, CI, infra) affected.

**Technical Impact (for Story 2.11's dev pass, not decided here):**
- Remove the in-content "Back Home" button and its `dismiss()` wiring from `TutorialView.swift`; remove the now-unused `tutorial.action.backHome` localization key (grep repo-wide first per project-context.md's Pre-Completion Self-Check).
- Restructure `TutorialView.swift`'s layout so "Start Story"/"Resume Story" sits outside the scrollable region (fixed), with only the mechanics copy inside the `GeometryReader`/`ScrollView`. This diverges from the shared Home/Tutorial single-scroll-column pattern documented in `project-context.md` — that pattern's `Spacer()`-avoidance rule still applies to whatever flat, spacing-driven structure replaces it.
- Home (`HomeView.swift`) is explicitly out of scope — it keeps today's single-scroll-column pattern unchanged.

## 3. Recommended Approach

**Selected: Option 1 — Direct Adjustment**, via a new follow-up story (2.11) rather than reopening Story 1.3.

Rationale:
- Effort: **Low**. Risk: **Low**. Removes one button and its localization key, restructures one screen's internal layout; no engine/content/persistence changes.
- Rollback isn't applicable — nothing is broken, this refines intended behavior based on live-use feedback.
- MVP scope review isn't applicable — no PRD/FR impact.
- A new story (rather than editing Story 1.3 in place) was chosen for the same reason Story 2.6→2.9 set the precedent: Story 1.3 is `done` and merged. Rewriting its AC would misrepresent what was actually built, reviewed, and shipped under that story number. A dated, cross-referenced amendment keeps history accurate while making the current rule easy to find.

## 4. Detailed Change Proposals

### UX — `epics.md`, UX-DR10

**OLD:**
> UX-DR10: Tutorial screen — explains page-turn (swipe/tap-zone) and choice (hold/tap) mechanics in words before the player reaches a real choice; Back Home / Start Story actions, tap only.

**NEW:**
> UX-DR10: Tutorial screen — explains page-turn (swipe/tap-zone) and choice (hold/tap) mechanics in words before the player reaches a real choice; "Start Story" is a fixed, always-visible primary action (pinned outside scrolling content, both orientations); leaving Tutorial uses standard iOS back navigation (nav-bar button/edge-swipe), no separate "Back Home" button.

**Status: applied.**

### UX — `EXPERIENCE.md`, Component Patterns — "Tutorial actions" row

**OLD:**
> "Back home" / "Start Story", tap only — tutorial is not itself gestural, it *describes* the gesture (including the page-turn tap zones and choice-card tap/hold, so the player knows both exist before reaching a real choice).

**NEW:**
> "Start Story" (relabels to "Resume Story" when a run is in progress) is a fixed, always-visible primary action — pinned outside the scrolling content area in both portrait and landscape, so it never requires scrolling to reach. Leaving Tutorial uses the screen's standard iOS navigation-bar back button/edge-swipe — no separate in-content "Back Home" button.

**Status: applied.**

### Decision record (from the UX conversation with the user, 2026-08-02)

- **Back Home button:** removed. Standard iOS back chevron + edge-swipe is sufficient; Tutorial's "non-gestural" intent (UX-DR10) applies to the *mechanics being taught* (page-turn, choice hold/tap), not to the act of leaving the screen.
- **An alternative considered and rejected:** folding both "Start Story" and "Back Home" into a single run-options-style icon menu (mirroring Story 2.7's pattern). Rejected because "Start Story" is the screen's primary forward-progress CTA, not a secondary/escape action — burying it behind an icon tap would be a net UX regression for the screen's actual job (getting the player into the story). A hybrid (Start Story prominent + fixed, Back Home behind an icon) was also considered but superseded once the user confirmed standard iOS back nav alone was sufficient — no icon-menu needed for either action.
- **Start Story fixed-position scope:** applies in **both** portrait and landscape (not landscape-only), for one consistent layout regardless of rotation.
- **Screen scope:** Tutorial only. Home is not affected — no reported problem there, and its content is short enough that it isn't hitting the same landscape squeeze.

## 5. Addendum (2026-08-02) — Remove the Run-Options Control from Tutorial

After the decisions above were recorded and Story 2.11 was drafted, the user asked to also remove Tutorial's run-options icon/menu (the ellipsis-circle button opening "Exit to Home"/"Restart This Run"/"Cancel"). **Correction for the record:** that control was added to Tutorial by **Story 2.7** (`RunOptionsButton` retrofit, per UX-DR11's original "present on every Story/Choice and Tutorial page"), not Story 2.8 as initially suspected — Story 2.8 (reading surface visual identity) never touched `TutorialView.swift`'s run-options wiring. Confirmed via `git log -- ForkedEchoes/Views/Tutorial/TutorialView.swift` and the `// Story 2.7:` comment already in that file.

**Rationale for removal, independent of the misattribution:** Tutorial is a pre-run explainer screen, not a page within an active run. Its two run-options actions don't fit that context:
- **"Exit to Home"** duplicates the exit Tutorial already has (now: standard iOS back navigation, per this proposal's main decision) — there's no meaningful difference between "leave Tutorial" and "exit to Home from Tutorial."
- **"Restart This Run"** presumes a run exists to restart. Tutorial is reachable with no run in progress at all (fresh install), which is exactly why Story 2.7 had to add a guard (`guard runProgress.hasInProgressRun else { return }`) around it — a control needing a no-op guard for its most common entry context is a sign it was retrofitted onto a screen it doesn't really belong on, not a sign the guard fixed the fit.

**Scope:** Removes `TutorialView.swift`'s `.overlay(alignment: .topTrailing) { RunOptionsButton(...) }` entirely, including its `onExitToHome`/`onRestartRun` closures. Story/Choice pages are unaffected — the run-options control remains exactly as Story 2.7 shipped it there; UX-DR11 is narrowed to Story/Choice only, not repealed.

**Artifacts updated:**
- `epics.md` UX-DR11 — narrowed to "Story/Choice" only, dated amendment note added.
- `epics.md` Story 2.11 — AC added for removing the `RunOptionsButton` overlay; story statement and title context updated; manual-verification AC extended to confirm no run-options icon renders on Tutorial.
- `EXPERIENCE.md`'s "Run options button" row — narrowed to "Story/Choice," Tutorial added to the explicit absence list, pointer note added.
- `2-7-run-options-action-sheet.md` — pointer note added to Change Log (story itself left historically intact — it correctly implemented UX-DR11 as specified at the time).
