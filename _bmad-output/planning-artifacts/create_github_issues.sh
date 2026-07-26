#!/usr/bin/env bash
#
# Creates GitHub milestones (Epics 1-4) and issues (Stories 1.1-4.6 + Pre-Submission
# Checklist) for the Many-Worlds CYOA app, from _bmad-output/planning-artifacts/epics.md.
#
# Usage:
#   ./create_github_issues.sh <owner/repo>
#
# Requires: gh CLI authenticated (gh auth status) with write access to the target repo.
# Safe to re-run for milestones/labels (idempotent). Re-running will create DUPLICATE
# issues — this script does not check for existing issues before creating them.

set -uo pipefail

REPO="${1:?Usage: $0 <owner/repo>}"

echo "Target repo: $REPO"
gh repo view "$REPO" >/dev/null 2>&1 || { echo "Cannot access repo '$REPO' — check the name and your gh auth." >&2; exit 1; }

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------
create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force
}

echo "== Creating labels =="
create_label "epic:1" "C5DEF5" "Epic 1: Home & Onboarding"
create_label "epic:2" "C5DEF5" "Epic 2: Story Reader, Choice Echo & Branch Realities"
create_label "epic:3" "C5DEF5" "Epic 3: Alignment Scoring, Ending & Memory Recap"
create_label "epic:4" "C5DEF5" "Epic 4: Story Content & Illustration Production"
create_label "type:engineering"   "1D76DB" "Engineering / implementation work"
create_label "type:content"       "0E8A16" "Story content / narrative authoring"
create_label "type:accessibility" "5319E7" "Accessibility-focused work"
create_label "type:submission"    "B60205" "App Store submission work"
create_label "type:tracking"      "FBCA04" "Non-epic tracking issue (not a story)"

# ---------------------------------------------------------------------------
# Milestones (idempotent: skip if a milestone with the same title exists)
# ---------------------------------------------------------------------------
echo "== Creating milestones =="
existing_milestones=$(gh api "repos/$REPO/milestones?state=all" --paginate -q '.[].title' 2>/dev/null || echo "")

create_milestone() {
  local title="$1" desc="$2"
  if grep -Fxq "$title" <<< "$existing_milestones"; then
    echo "Milestone already exists, skipping: $title"
  else
    gh api "repos/$REPO/milestones" -f title="$title" -f description="$desc" -f state="open" --silent \
      && echo "Created milestone: $title" \
      || echo "Failed to create milestone: $title" >&2
  fi
}

create_milestone "Epic 1: Home & Onboarding" \
"Player can open the app, optionally learn the mechanics via a tutorial, and enter a story - every entry action reachable by gesture or accessible tap, never gesture-only. FRs covered: FR1, FR2 (+FR11)."

create_milestone "Epic 2: Story Reader, Choice Echo & Branch Realities" \
"Player can read a branching story, make permanent choices (gesture or tap), watch the story explicitly call back to an earlier choice 2-3 times, and see a bundled illustration on arriving in a new branch reality. FRs covered: FR3, FR4, FR5, FR6, FR12 (+FR11)."

create_milestone "Epic 3: Alignment Scoring, Ending & Memory Recap" \
"When a run terminates (naturally or via hard-fail), it silently resolves to one of four endings through a shared template, followed by a memory screen recapping every choice, its consequence, and the alignment score/tier - for every run, no exceptions. FRs covered: FR7, FR8, FR9, FR10 (+FR11)."

create_milestone "Epic 4: Story Content & Illustration Production" \
"The player experiences the actual v1 story - real branches, real prose, real echoes, real illustrations - replacing every placeholder Epic 2/3 stood up to unblock engineering work. Depends on Epics 1-3 being complete."

# ---------------------------------------------------------------------------
# Issue helper
# ---------------------------------------------------------------------------
create_issue() {
  local title="$1" milestone="$2" labels="$3" body="$4"
  local args=(--repo "$REPO" --title "$title" --label "$labels" --body "$body")
  [[ -n "$milestone" ]] && args+=(--milestone "$milestone")
  gh issue create "${args[@]}" \
    && echo "Created issue: $title" \
    || echo "Failed to create issue: $title" >&2
}

M1="Epic 1: Home & Onboarding"
M2="Epic 2: Story Reader, Choice Echo & Branch Realities"
M3="Epic 3: Alignment Scoring, Ending & Memory Recap"
M4="Epic 4: Story Content & Illustration Production"

echo "== Creating Epic 1 stories =="

BODY=$(cat <<'EOF'
**As a** developer,
**I want** a working Xcode project matching the Architecture's Structural Seed layout,
**So that** every later story has a consistent place to add code.

### Acceptance Criteria
- [ ] Given no existing Xcode project, when the project is created, then it targets iOS 18.0 minimum (iOS 26 SDK), Swift 6.3, SwiftUI app lifecycle
- [ ] And the project contains `App/`, `Content/`, `Engine/`, `Views/`, `Resources/` groups matching the Structural Seed, plus a `ForkedEchoesTests/` target using Swift Testing
- [ ] And `Resources/Localizable.xcstrings` and `Resources/Assets.xcassets` exist (empty, ready for content) per AD-2
- [ ] Given the project is opened in Xcode 26.6, when built and run on the iOS Simulator, then it builds with no warnings/errors and launches to an empty placeholder root view
EOF
)
create_issue "Story 1.1: Project Scaffold" "$M1" "epic:1,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to see the app and story title and choose to start (or resume) the story or view the tutorial when I open the app,
**So that** I can begin or continue playing.

### Acceptance Criteria
- [ ] Given a fresh install with no saved run, when Home renders, then it shows the app title, story title, and "Start Story" / "Start Tutorial" actions, tap only (no gesture-only affordances - EXPERIENCE.md resolves FR-1's home entry to tap, not gesture)
- [ ] Given a minimal `RunSnapshot` presence check exists (per AD-4 - full snapshot read/write is Epic 2's job; this story only needs to detect presence), when a snapshot is present in `UserDefaults`, then the primary action relabels from "Start Story" to "Resume Story"
- [ ] Given "Start Story" or "Resume Story" is activated, when activated, then the app navigates away from Home (destination is a placeholder Story/Choice stand-in until Epic 2 implements the real reader)
- [ ] Given "Start Tutorial" is activated, when activated, then the app navigates to the Tutorial screen (Story 1.3)
- [ ] Given all Home screen text (app title, story title, action labels), when rendered, then every string is sourced from `Localizable.xcstrings` via generated symbols, never a hardcoded Swift string literal (AD-2) - so adding another LTR language later requires no code changes
EOF
)
create_issue "Story 1.2: Home Screen - Start/Resume Story & Start Tutorial" "$M1" "epic:1,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** first-time player,
**I want** to view a tutorial that explains the game's mechanics in words,
**So that** I understand how to read and choose before I reach a real decision.

### Acceptance Criteria
- [ ] Given the player navigates to Tutorial from Home, when it renders, then it explains page-turning (swipe or tap-zone) and choice-making (hold or tap) mechanics in words, per EXPERIENCE.md Voice and Tone
- [ ] Given Tutorial is shown, when inspected, then it offers "Back Home" and "Start Story" actions, tap only
- [ ] Given any other screen in the app, when checked for a path to Tutorial, then Tutorial is reachable only from Home (FR2)
- [ ] Given all Tutorial screen text (mechanic explanations, action labels), when rendered, then every string is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)
EOF
)
create_issue "Story 1.3: Tutorial Screen" "$M1" "epic:1,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player, including one using assistive technology,
**I want** Home and Tutorial to follow the app's visual identity and be fully usable with VoiceOver and Dynamic Type,
**So that** the app is usable and on-brand regardless of ability.

### Acceptance Criteria
- [ ] Given DESIGN.md tokens needed by Home/Tutorial (headline, body, eyebrow typography; surface/ink colors; spacing scale), when applied, then Home/Tutorial render per DESIGN.md, with no circuit frame on either screen (UX-DR9, UX-DR10 - the frame is reserved for reading surfaces)
- [ ] Given VoiceOver is active, when navigating Home/Tutorial, then every action exposes an accessible label and is operable via standard VoiceOver activation, meeting the 44pt minimum tap target (FR11, NFR6)
- [ ] Given Dynamic Type is set to an accessibility size, when Home/Tutorial render, then text scales without truncation or clipping (FR11, NFR8)
EOF
)
create_issue "Story 1.4: Home & Tutorial Visual Identity + Accessibility Pass" "$M1" "epic:1,type:accessibility" "$BODY"

echo "== Creating Epic 2 stories =="

BODY=$(cat <<'EOF'
**As a** developer,
**I want** a minimal placeholder Content tree and a StoryRunEngine skeleton,
**So that** later stories have real data and engine plumbing to build against.

### Acceptance Criteria
- [ ] Given `Content/` needs data, when a minimal `indirect enum` tree is authored, then it contains at least one reading node, one choice node with 2 options, and terminal placeholder ending nodes, per AD-1 (every case resolves to a choice or an ending; tree never reconverges)
- [ ] Given the engine needs to exist, when `StoryRunEngine` (`@Observable`) is created, then it exposes `selectChoice(_:)`, `advancePage()`, `goBack()`, and tracks `currentNodeId`, `choiceHistory`, `alignmentScore` in memory (persistence lands in Story 2.4)
- [ ] Given Home's placeholder destination (Story 1.2), when "Start Story"/"Resume Story" is activated, then it now navigates to a real, content-minimal Story/Choice view backed by `StoryRunEngine`, replacing the Story 1.2 placeholder
- [ ] Given the minimal placeholder tree includes terminal ending nodes, but Epic 3 (which implements phase-derivation for `.ending`) doesn't exist yet at this point in the build, when the engine's current node is a terminal node, then the view renders a simple placeholder screen ("Run complete - Ending screen coming in Epic 3") instead of crashing or showing undefined content - a temporary stand-in Epic 3 Story 3.2 replaces, not a permanent behavior
EOF
)
create_issue "Story 2.1: Minimal Story Content & Engine Foundation" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to advance and return through story pages via swipe, tap zones, or VoiceOver actions,
**So that** I can read at my own pace regardless of input method.

### Acceptance Criteria
- [ ] Given a reading page, when the player swipes left or taps the right third of the reading card (UX-DR4), then `advancePage()` is called and the next page renders
- [ ] Given at least one page has been read, when the player swipes right or taps the left third, then `goBack()` is called and the previous page renders
- [ ] Given VoiceOver is active, when the player uses the "Next Page"/"Previous Page" custom rotor actions, then the same advance/back behavior occurs (UX-DR12 - swipe is otherwise consumed by VoiceOver navigation)
- [ ] Given a page contains an unresolved choice, when the player attempts to advance, then forward navigation is blocked (FR3)
- [ ] A Swift Testing case verifies pager-gating - forward blocked on unresolved choice, locked display on revisit (AD-7, NFR3)
EOF
)
create_issue "Story 2.2: Page Navigation" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to make a permanent choice via press-and-hold or a quick tap,
**So** my decision sticks and the story moves forward.

### Acceptance Criteria
- [ ] Given a choice page with >=2 options, when rendered, then each is an independently selectable Choice card (UX-DR3); only one card can charge at a time (holding a second cancels the first)
- [ ] Given a press-and-hold on a choice card, when the hold reaches ~3s, then the choice commits via `selectChoice(_:)`; releasing early cancels to idle with no partial memory
- [ ] Given a quick tap (or VoiceOver double-tap), when activated, then it commits instantly and opens a 1.5s undo window (tap again to revert) - never less forgiving than the hold path
- [ ] Given a choice finalizes, when `selectChoice(_:)` fires, then forward navigation unblocks, the card locks to selected styling with a checkmark, and the choice's alignment delta accumulates into the engine's running score (FR7's accumulation mechanism - never exposed in any Epic 2 UI)
- [ ] Given a decided choice page revisited via back-navigation, when rendered, then it shows the made choice locked, with no alternate-choice control at all (FR5)
- [ ] Given the app terminates mid-charge or mid-undo-window, when relaunched, then the choice page shows undecided - nothing was committed (AD-3)
- [ ] Given a quick tap has committed a choice and its 1.5s undo window is still open, when the player pages forward before the window elapses, then forward navigation is already unblocked (commit unblocks navigation immediately, independent of the undo window) and the choice remains locked; the undo affordance has nothing left to act on once the page has changed
- [ ] Given DESIGN.md's specified timings (3000ms charge, 1500ms undo window) are unvalidated placeholder-quality values, when implemented and tried by hand on a real device, then these durations may be tuned by feel - they are a reasonable starting point, not a locked spec; if adjusted, update DESIGN.md's token values to match what actually shipped
- [ ] A Swift Testing case verifies the choice-commit state machine: charge-then-release-early cancels to idle with no partial memory, a tap-commit reverts if tapped again within the undo window, holding a second card while one is charging cancels the first, and no engine mutation occurs unless a commit path (hold-complete or tap-commit) actually fires (AD-3, AD-7, NFR3)
EOF
)
create_issue "Story 2.3: Choice Presentation, Selection & Permanence" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** my in-progress run saved automatically,
**So** a relaunch or backgrounding doesn't lose my place.

### Acceptance Criteria
- [ ] Given any completed mutating intent (`selectChoice`, `advancePage`, `goBack`), when it completes, then `RunSnapshot` (`currentNodeId`, `choiceHistory` as ID pairs, `alignmentScore`, `tutorialSeen`) is encoded and written synchronously to its single `UserDefaults` key (AD-4)
- [ ] Given a cold launch with a valid snapshot, when the app starts, then the engine decodes it and resumes at the saved node with full history and score restored
- [ ] Given a decode failure of any kind (missing key, malformed JSON, unresolved `currentNodeId`), when encountered, then the engine falls back to a fresh run at Home exactly as if no snapshot existed - no crash (NFR4)
- [ ] Given Home's Story 1.2 presence-only check, when this story's decode-failure handling lands, then Home's Resume/Start label is driven by decode *success*, not mere key presence - a corrupted snapshot falls back to fresh Home and shows "Start Story," never "Resume Story" followed by a silent fresh-start
- [ ] A Swift Testing case verifies `RunSnapshot` encode/decode round-trip, including the decode-failure fallback (AD-7, NFR3)
EOF
)
create_issue "Story 2.4: Run Persistence (RunSnapshot)" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** an earlier choice's consequence to resurface explicitly in the prose,
**So** I feel like my choices mattered.

### Acceptance Criteria
- [ ] Given the content tree extended with at least one echo-wired node (referencing an earlier choice by construction, per AD-1), when that node renders, then an Echo callback block appears inline, tagged "The story remembers" in `accent-ember-text` (UX-DR5, UX-DR15)
- [ ] Given an echo block is on-screen, when rendered, then the circuit Frame powers up brass -> ember with the via-grow/pad-fill shape cue (UX-DR1), for exactly that page's duration, returning to dormant on the next page turn
- [ ] Given each echoed choice, when authored, then its callback text is distinguishable in-prose as a reference to the earlier decision, not merely implied by branching (FR6)
- [ ] A Swift Testing case verifies echo-callback reachability as authored in the tree (AD-7, NFR3)
EOF
)
create_issue "Story 2.5: Narrative Callback (Choice Echo)" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** a full-bleed illustration and caption when I arrive in a new branch reality,
**So** the shift feels distinct and grounded.

### Acceptance Criteria
- [ ] Given the content tree extended with a branch-reality transition, when the player's choice leads into a new branch reality, then the engine's phase derives to `.interstitial` and a full-bleed illustration + caption renders (UX-DR6), using placeholder/SF Symbol art for now (final generated art is separate tracked work per the Epic 2 Art note)
- [ ] Given the interstitial is showing, when the player swipes or taps a page zone, then nothing happens - the interstitial blocks both forward and back until its own Continue affordance is tapped (closes the architecture review's Finding 1 - must block both directions, not just forward)
- [ ] Given the interstitial's Continue affordance is tapped, when activated, then phase returns to `.reading` at the new node
- [ ] Given the illustration is referenced, when wired, then it uses a generated `ImageResource` symbol from `Assets.xcassets` - never a raw string name (AD-2) - and is never fetched over the network (FR12)
- [ ] Given the branch-arrival interstitial is showing, when inspected, then the run-options button is absent - present only on Story/Choice and Tutorial pages, never during the interstitial (UX-DR11)
- [ ] Given the interstitial's flavor caption, when rendered, then its text is sourced from `Localizable.xcstrings` by stable key, matching the same convention as story body prose (AD-2)
EOF
)
create_issue "Story 2.6: Branch-Arrival Interstitial & Illustrations" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player mid-run,
**I want** to exit to Home or restart my run from a run-options control,
**So** I have an escape hatch without losing progress unintentionally.

### Acceptance Criteria
- [ ] Given a Story/Choice or Tutorial page, when rendered, then a run-options ellipsis icon appears top-right of the reading card (absent from the interstitial and Home) (UX-DR11) - this retrofits Tutorial (Story 1.3) with the control it was missing
- [ ] Given the run-options icon is activated, when tapped, then a native action sheet presents: "Exit to Home", "Restart This Run", "Cancel"
- [ ] Given "Exit to Home" is selected, when activated, then the app returns to Home and the in-progress `RunSnapshot` is preserved (non-destructive) via `exitToHome()`
- [ ] Given "Restart This Run" is selected, when activated, then a second explicit confirmation is required before anything clears; only on confirming does `restartRun()` reset to the initial node and alignment score (AD-3, destructive)
- [ ] Given the run-options button, when inspected with VoiceOver, then it carries an explicit `accessibilityLabel` of "Run options" (UX-DR12), not the SF Symbol's default name
- [ ] Given the run-options action sheet's labels ("Exit to Home", "Restart This Run", "Cancel"), when rendered, then every label is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)
EOF
)
create_issue "Story 2.7: Run Options Action Sheet" "$M2" "epic:2,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player, including one using accessibility features,
**I want** the reading surface to follow the app's visual identity and remain fully usable under Dynamic Type and Reduce Motion,
**So** the core experience is accessible end-to-end.

### Acceptance Criteria
- [ ] Given the remaining DESIGN.md tokens for reading surfaces (frame, choice-card, echo-callback, interstitial, continue-button), when applied, then all Epic 2 screens render per DESIGN.md with verified WCAG AA contrast (NFR7, UX-DR15)
- [ ] Given Dynamic Type set to an accessibility size, when reading content or a 3-choice decision point renders, then content scrolls inside the fixed frame (frame itself never resizes), headroom sized for the largest accessibility category, no text clamped (FR11, NFR8, UX-DR13)
- [ ] Given Reduce Motion is enabled, when a choice charges or an echo/interstitial transition occurs, then the charge-fill animation is skipped (instant commit) and frame/interstitial/page-turn transitions collapse to instant cuts - nothing produces continuous or looping motion (NFR5, UX-DR14)
- [ ] Given VoiceOver is active on a Story/Choice page, when focus traversal occurs, then order follows eyebrow -> prose -> choices -> pager, with run-options last (UX-DR12)
EOF
)
create_issue "Story 2.8: Reading Surface Visual Identity, Dynamic Type & Reduce Motion" "$M2" "epic:2,type:accessibility" "$BODY"

echo "== Creating Epic 3 stories =="

BODY=$(cat <<'EOF'
**As a** developer,
**I want** each terminal node in the content tree to carry its `EndingKind` directly, and the engine to resolve a run's ending from whichever terminal node is reached,
**So** ending resolution requires no runtime computation.

### Acceptance Criteria
- [ ] Given `Content/`'s minimal tree (from Epic 2, Story 2.1) extended with terminal nodes, when each terminal node is authored, then it carries an `EndingKind` case (home/stay/limbo/hardFail) fixed at write-time (AD-1, AD-6)
- [ ] Given the engine's current node is a terminal node, when the phase derives to `.ending` (per AD-5), then the run's ending is read directly as that node's `EndingKind` - no computation, no score check
- [ ] Given a designated gotcha (hard-fail) choice is selected, when `selectChoice(_:)` targets a hard-fail terminal node, then the engine transitions to Ending the instant the choice fires (AD-5), not on a later `advancePage()` discovery
- [ ] Given the content tree, when traced across all branches, then every branch terminates in exactly one of the four ending types (FR8), enforced by AD-1's tree shape
- [ ] A Swift Testing case verifies hard-fail nodes are reachable only via their designated gotcha choice, and that the Ending transition fires immediately at `selectChoice(_:)` time rather than being deferred to a subsequent `advancePage()` (AD-7, NFR3)
- [ ] Content-authoring guidance is documented for later story-tree writing: roughly 1-2 terminal nodes as home endings and 3-4 as stay endings across the full v1 tree (addendum.md); this story's placeholder tree only needs enough terminal nodes to exercise all four `EndingKind` cases at least once each
- [ ] Given the engine's phase derives to `.ending`, when the transition completes, then `RunSnapshot` is cleared from `UserDefaults` as part of that same transition (AD-4) - Memory (Story 3.3) can rely on this having already happened by the time it reads snapshot state
EOF
)
create_issue "Story 3.1: Ending Kind Resolution" "$M3" "epic:3,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to see an ending screen that matches how my run concluded,
**So** I understand how my choices resolved.

### Acceptance Criteria
- [ ] Given a run reaches a terminal node (whether through ordinary branch traversal or a hard-fail gotcha choice), when the Ending phase is entered, then a single shared Ending template renders, differing only in outcome-specific text/illustration across home/stay/limbo/hard-fail (FR9), driven by that node's `EndingKind` (Story 3.1)
- [ ] Given the Ending screen, when rendered, then the circuit Frame rests permanently in its powered-up ember state - a resting condition, not a transition (UX-DR7)
- [ ] Given the Ending screen, when the player taps anywhere, then the app advances to Memory (Story 3.3) - no auto-advance
- [ ] Given a hard-fail ending, when it renders, then it uses the same shared template with tone-appropriate dark-comedy copy, arriving directly from the gotcha choice rather than through normal page-turn flow (FR8, FR9)
- [ ] Given the Ending screen's "tap to continue" affordance text, when rendered, then it is sourced from `Localizable.xcstrings`, consistent with the ending body copy's own per-node localization (AD-2)
EOF
)
create_issue "Story 3.2: Ending Screen" "$M3" "epic:3,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** a recap of every choice I made, what it caused, and my alignment score/tier after every run,
**So** the run becomes a story about me.

### Acceptance Criteria
- [ ] Given the Ending screen is tapped, when advancing, then Memory renders a read-only list of choice -> consequence rows sourced from `RunSnapshot.choiceHistory`, re-resolving display text from the current String Catalog by ID at render time - never stale frozen prose (AD-4, UX-DR8)
- [ ] Given any run, including hard-fail, when it completes, then Memory is shown for 100% of completed runs with no ending-type exception (FR10)
- [ ] Given the Memory screen, when rendered, then it shows the alignment score at the top in `{typography.stat}` styling (UX-DR8) - a purely reflective stat with no bearing on the ending already shown on the previous screen (closing FR7's display-only exposure rule from Epic 2's silent accumulation)
- [ ] Given a descriptive tier label is derived from the score for display, when shown alongside the score, then it is cosmetic only - the tier label never changes or predicts which ending (Story 3.2) was already reached; the two are fully independent
- [ ] Given "Return Home" is selected, when activated, then the app navigates to Home; `RunSnapshot` was already cleared on entering Ending (AD-4), so no destructive confirmation is needed
- [ ] Given "Start New Run" is selected, when activated, then `startNewRun()` resets the engine to the initial node with cleared history/score and the app enters a fresh run - no confirmation required (AD-3)
- [ ] Given a run that hard-failed on its very first choice (a `choiceHistory` of exactly one entry), when Memory renders, then it still shows a valid recap with that single choice-and-consequence row and the correspondingly small alignment score - no empty-state or crash at the minimum possible history length
- [ ] Given the Memory screen's "Return Home"/"Start New Run" action labels and any tier-label copy, when rendered, then every string is sourced from `Localizable.xcstrings` via generated symbols, never hardcoded (AD-2)
EOF
)
create_issue "Story 3.3: Memory / Recap Screen" "$M3" "epic:3,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** Ending and Memory to follow the app's visual identity with correct contrast and typography,
**So** run resolution feels consistent with the rest of the app.

### Acceptance Criteria
- [ ] Given the remaining DESIGN.md tokens (`ending-frame`, `memory-row`, `memory-score`), when applied, then both screens render per DESIGN.md with verified WCAG AA contrast (NFR7)
- [ ] Given Dynamic Type at an accessibility size, when Ending/Memory render, then text scales without truncation (FR11, NFR8)
- [ ] Given VoiceOver is active, when navigating Ending/Memory, then all actions (tap-to-continue, Return Home, Start New Run) expose accessible labels and meet the 44pt tap target (FR11, NFR6)
EOF
)
create_issue "Story 3.4: Ending & Memory Visual Identity" "$M3" "epic:3,type:accessibility" "$BODY"

BODY=$(cat <<'EOF'
**As a** player using any assistive technology,
**I want** the complete app - Home through Memory - verified end-to-end for VoiceOver, Dynamic Type, Reduce Motion, and contrast,
**So** nothing scattered across individual stories was missed.

### Acceptance Criteria
- [ ] Given the full app (Epics 1-3) is complete, when walked end-to-end using VoiceOver only, no sighted/gesture interaction, then every screen and action is reachable, correctly labeled, and announces state changes (choice selected, undo window, echo firing, ending reached) (FR11)
- [ ] Given Dynamic Type at the largest accessibility category, when every screen is inspected, then no text is clipped or truncated anywhere (FR11, NFR8)
- [ ] Given Reduce Motion enabled, when a full run is played, then no continuous or looping motion occurs anywhere in the app (NFR5)
- [ ] Given every text/color pairing across DESIGN.md, when measured, then all meet WCAG AA thresholds in both light and dark themes (NFR7)
- [ ] Given any interaction in the app, when audited, then none is reachable only via a custom gesture - every one has a standard tap/VoiceOver equivalent (FR11's hard constraint)
- [ ] Given every illustration in the app, when audited with VoiceOver, then each announces its authored descriptive label - none is silent (hidden) and none announces a meaningless default label
EOF
)
create_issue "Story 3.5: End-to-End Accessibility Validation" "$M3" "epic:3,type:accessibility" "$BODY"

echo "== Creating Epic 4 stories =="

BODY=$(cat <<'EOF'
**As a** solo developer/writer,
**I want** to plan the full v1 branch structure before writing final prose,
**So** the tree satisfies FR-8's ending taxonomy and the addendum's content ratio from the start.

### Acceptance Criteria
- [ ] Given PRD Open Question 1 (story scale undetermined), when the outline is created, then it specifies a concrete target branch count and total choice-point count for v1
- [ ] Given the addendum's content ratio, when ending nodes are planned, then the outline allocates 1-2 terminal nodes as home, 3-4 as stay, remaining non-hard-fail terminals as limbo, plus at least one hard-fail gotcha choice
- [ ] Given the addendum's "always an ideal path home" principle, when the outline is reviewed, then at least one traceable path from the root to a home ending is identified and marked
- [ ] Given FR-6 (echo), when the outline is built, then each planned echo callback identifies which earlier choice it references and where (2-3 per run)
EOF
)
create_issue "Story 4.1: Story Tree Outline & Structure" "$M4" "epic:4,type:content" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to read the actual v1 story, not placeholder text,
**So** the app delivers the real experience.

### Acceptance Criteria
- [ ] Given the outline (Story 4.1), when prose is written, then every planned node's body, choice labels, echo callbacks, and ending/tutorial copy are added to `Localizable.xcstrings` with stable keys following the node-id + role convention (AD-2)
- [ ] Given the "safe choice unreliable" mechanic (addendum.md), when choices are authored, then at least one choice reads as safe but doesn't guarantee the safe outcome
- [ ] Given hard-fail choices, when authored, then they read as obviously absurd dark-comedy gotchas, not fair telegraphed warnings (FR-8 notes)
- [ ] Given v1 scope, when all user-facing text is authored - story prose plus every UI chrome label from Epics 1-3, then it exists in `Localizable.xcstrings` in English only for v1, but because every screen sources 100% of its text from the catalog with zero hardcoded strings, adding another LTR language later is purely additive: translate the catalog, ship no code changes (Architecture's Deferred section, AD-2)
- [ ] Given each of the ~10-15 branch-reality illustrations, when authored, then a distinct, descriptive VoiceOver description of what the illustration depicts is written and added to `Localizable.xcstrings` alongside the caption - not restating the caption, but conveying the illustration's specific visual content so VoiceOver users get equivalent access to the branch reality's atmosphere
EOF
)
create_issue "Story 4.2: Full Prose Authoring" "$M4" "epic:4,type:content" "$BODY"

BODY=$(cat <<'EOF'
**As a** developer,
**I want** the full outline and prose wired into `Content/`'s Swift tree, replacing the Epic 2 placeholder,
**So** the real story is playable.

### Acceptance Criteria
- [ ] Given the outline and prose, when the tree is authored, then it replaces the placeholder 2-3 node tree from Epic 2 Story 2.1 with the full v1 branch structure
- [ ] Given AD-1, when compiled, then every node resolves to a choice or an ending - no dead ends possible
- [ ] Given the ratio guidance, when the final tree is inspected, then it matches Story 4.1's planned home/stay/limbo distribution
- [ ] Given echo wiring, when the tree is complete, then each planned echo correctly references its earlier choice by tree position (AD-1)
EOF
)
create_issue "Story 4.3: Story Tree Wiring" "$M4" "epic:4,type:engineering" "$BODY"

BODY=$(cat <<'EOF'
**As a** player,
**I want** to see a distinct illustration for each branch reality I visit,
**So** each reality feels visually grounded.

### Acceptance Criteria
- [ ] Given the ~10-15 distinct branch-reality flavors identified in the outline, when illustrations are produced, then each is generated via a generative AI image tool at development time, per the addendum's art pipeline note
- [ ] Given each illustration, when added, then it's bundled into `Assets.xcassets` as its own image set, replacing Epic 2 Story 2.6's placeholder art, referenced only via generated `ImageResource` symbols (AD-2)
- [ ] Given FR-12, when illustrations are wired, then none are fetched over the network at runtime - bundled in the app binary
- [ ] Given each illustration's authored VoiceOver description (Story 4.2), when the interstitial renders, then the illustration exposes that description as its `accessibilityLabel` - VoiceOver users hear a real description of the branch reality's visual flavor, not a meaningless default label and not silence
EOF
)
create_issue "Story 4.4: Branch-Reality Illustration Production" "$M4" "epic:4,type:content" "$BODY"

BODY=$(cat <<'EOF'
**As a** developer,
**I want** to playtest the complete v1 story and self-assess its App Store content rating before final polish,
**So** compellingness and rating risk are addressed while there's still room to adjust content.

### Acceptance Criteria
- [ ] Given the full tree (Story 4.3) and illustrations (Story 4.4), when played end-to-end by the developer and friends (PRD's informal validation plan, Open Question 4), then at least one full playthrough of each ending type (home/stay/limbo/hard-fail) is exercised
- [ ] Given the dark-comedy hard-fail content, when Apple's App Store Connect content-rating self-assessment is completed, then a target age rating is determined with enough runway left to adjust content if the rating comes back stricter than expected - not deferred to the Pre-Submission Checklist
- [ ] Given the "ideal path home" design principle, when playtested, then at least one tester finds a path to a home ending following only the story's own cues (informal validation)
EOF
)
create_issue "Story 4.5: Content Playtesting & App Store Rating Self-Assessment" "$M4" "epic:4,type:content" "$BODY"

BODY=$(cat <<'EOF'
**As a** developer,
**I want** the mandatory App Store Connect listing assets completed,
**So** the app can actually be submitted (SM-1).

### Acceptance Criteria
- [ ] Given DESIGN.md's warm-ink/circuit-frame visual identity, with no app icon spec anywhere in it, when an app icon is designed, then it translates the in-app aesthetic into Apple's required icon sizes - closing this gap, not cropping an existing screenshot
- [ ] Given the app's on-device-only architecture (no network calls, no data collection), when App Store Connect's privacy nutrition label questionnaire is completed, then it accurately declares zero data collection
- [ ] Given screenshots are required for submission, when captured, then they're taken from the actual running app across required device sizes, showing representative moments (a choice page, an echo firing, an ending)
- [ ] Given a title, subtitle, description, and keywords field are required, when written, then they describe the app honestly - category, mechanic, and feeling - without overclaiming features that don't exist
- [ ] Given this is explicitly "not a business" (PRD Non-Goals), when this story is scoped, then it covers only mandatory listing requirements for submission - no ASO strategy, no keyword-ranking optimization, no iterative marketing copy testing
EOF
)
create_issue "Story 4.6: App Store Listing & Submission Assets" "$M4" "epic:4,type:submission" "$BODY"

echo "== Creating Pre-Submission Checklist tracking issue =="

BODY=$(cat <<'EOF'
Non-epic checklist, tracked for visibility - not a story with user-facing value.
Completing Epics 1-4 means the app is fully built, content-complete, and playable
end-to-end. These items remain before App Store submission.

- [ ] Apple Developer Program enrollment (blocking prerequisite for TestFlight/App Store distribution - not yet in place)
- [ ] Decide developer account type - individual (personal legal name as Seller, faster ~24-48hr approval, no D-U-N-S needed) vs. organization under the LLC (LLC's legal name as Seller, requires a D-U-N-S number + entity email + active website, slower approval) - a legal/tax call outside this document's scope
- [ ] App Store content rating self-assessment: front-loaded to Epic 4 Story 4.5, run against the full v1 content - not deferred to submission time
- [ ] Complete Agreements, Tax, and Banking in App Store Connect (required before the paid app can go live)
- [ ] Export compliance declaration at submission (expected: no custom encryption, given zero networking)
EOF
)
create_issue "Pre-Submission Checklist" "" "type:tracking" "$BODY"

echo "== Done =="
