import Foundation
import Observation

// AD-3: the sole owner and mutator of run state. Views never write currentNodeId/choiceHistory/
// alignmentScore directly — every mutation goes through one of the intent methods below.
//
// AD-4 (Story 2.4): every mutating intent persists (or clears) a RunSnapshot synchronously as a
// side effect of completing — see persistOrClearSnapshot(). Pager-gating (forward blocked on an
// *unresolved* choice, permeable once decided) is Story 2.2/2.3's job — see advancePage()'s own
// doc comment for the corrected AD-5 semantics. A committed choice is irrevocable (AD-3, FR-5) in
// both directions: `goBack()` only moves `currentNodeId` back along `visitedNodeIds` — it never
// removes a `choiceHistory` entry or reverses `alignmentScore` — and `selectChoice(_:)` refuses
// to fire again on a node that already has a `choiceHistory` entry, so navigating back to a
// decided choice and picking again is a no-op, not a second commit.
@Observable
final class StoryRunEngine {
    private(set) var currentNodeId: NodeID
    private(set) var choiceHistory: [ChoiceRecord] = []
    private(set) var alignmentScore: Int = 0

    /// Story 2.5: true only when `currentNodeId` is a `.reading` node with a non-nil echo
    /// callback key — purely derived, no stored flag (AD-5's "phase derived, not stored" ethos).
    /// Reverting to dormant on the next page turn is therefore a free consequence of
    /// `currentNodeId` changing via `advancePage()`/`goBack()`/`selectChoice(_:)`, not separate
    /// reset logic. Re-derives correctly immediately after `resumingFromSnapshot(defaults:)` too,
    /// since it never reads anything but `currentNodeId`.
    var isEchoActive: Bool {
        if case .reading(_, _, let echoBodyKey, _) = StoryTree.node(for: currentNodeId) {
            return echoBodyKey != nil
        }
        return false
    }

    /// Story 2.6: `Reading --> Interstitial --> Reading` per the run-phase state diagram
    /// (ARCHITECTURE-SPINE.md), purely derived from `currentNodeId` + `dismissedInterstitialNodeIds`
    /// below — `phase` itself is still never stored (AD-5's "phase derived, not stored" ethos,
    /// same as `isEchoActive`), even though `dismissedInterstitialNodeIds`'s *contents* are now
    /// persisted as of Story 2.9 (`RunSnapshot.visitedArrivalNodeIds`) so the derivation survives
    /// relaunch. `.memory` isn't reachable yet (Epic 3) — omitted for now.
    enum Phase: Equatable {
        case reading
        case interstitial
        case ending
        // Story 3.2: reachable once advancePage() has been called from .ending — Story 3.3
        // (Memory/Recap) doesn't exist yet, so this phase currently renders only a temporary
        // placeholder (StoryChoiceView.swift). See hasAdvancedPastEnding's doc comment below.
        case memory
    }

    /// Story 2.9: persisted via `RunSnapshot.visitedArrivalNodeIds` (AD-4/AD-5, amended
    /// 2026-08-02) — a node inserted here stays gate-free across an app relaunch, not just within
    /// the current process. Keyed by node, not reset on navigation — code-review finding,
    /// 2026-08-02 (Story 2.6): a single ephemeral flag reset on every `currentNodeId` change let
    /// the interstitial replay after backing up over a decided choice and paging forward again
    /// onto a node already dismissed this session. That per-node fix is preserved here; Story 2.9
    /// only changes how this set survives process restart, not how it's read within one process.
    private var dismissedInterstitialNodeIds: Set<NodeID> = []

    /// Story 3.2: true once `advancePage()` has been called from `.ending` — Story 3.3 doesn't
    /// exist yet, so this is a temporary stand-in for "advanced past Ending" (this story's Dev
    /// Notes: same shape as the Epic-2-era `.ending` placeholder this story itself replaces).
    /// Reset in `resetRunState()` alongside the other session-scoped flags, so a fresh run never
    /// starts in `.memory`.
    private var hasAdvancedPastEnding = false

    var phase: Phase {
        switch StoryTree.node(for: currentNodeId) {
        case .reading(_, _, _, let arrival):
            return (arrival != nil && !dismissedInterstitialNodeIds.contains(currentNodeId)) ? .interstitial : .reading
        case .choice:
            return .reading
        case .ending:
            return hasAdvancedPastEnding ? .memory : .ending
        }
    }

    /// The back-navigation stack `goBack()` pops. Story 2.10: persisted via
    /// `RunSnapshot.visitedNodeIds` (AD-4) — seeded from the snapshot in
    /// `resumingFromSnapshot(defaults:)` and written by every `persistOrClearSnapshot()` call, so
    /// this stays populated across a real app relaunch, not just within one process (previously
    /// an unpersisted, session-only stack — see the Story 2.4-through-2.9 history in
    /// `resumingFromSnapshot(defaults:)`'s doc comment above).
    private var visitedNodeIds: [NodeID] = []
    private let defaults: UserDefaults

    /// Never reads `UserDefaults` at construction time — pre-dates this story unchanged (Task 3).
    /// `StoryRunEngine()`/`StoryRunEngine(startingAt:)` must keep meaning exactly this, since
    /// existing tests rely on it to pin an exact starting node without any snapshot interference.
    init(startingAt nodeId: NodeID = StoryTree.root, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentNodeId = nodeId
    }

    /// Cold-launch construction (RootView's call site): attempts to resume from a validated
    /// `RunSnapshot`; falls back to a fresh run at `StoryTree.root` on any decode/validation
    /// failure (AC #2, #3) — identical fallback logic to `RunSnapshotPresence.hasInProgressRun`.
    /// Story 2.10: `visitedNodeIds` (the back-navigation stack, distinct from
    /// `RunSnapshot.visitedArrivalNodeIds` added Story 2.9 — see that field's doc comment) is now
    /// seeded from the persisted `RunSnapshot.visitedNodeIds`, so a resumed run's `goBack()` can
    /// navigate backward through the same history it had before the relaunch, instead of starting
    /// with an empty stack (Story 2.4 through 2.9's prior, deliberate-but-since-superseded
    /// behavior).
    ///
    /// Deliberately a distinctly-named factory rather than a third `init` overload: an earlier
    /// version of this made a bare `StoryRunEngine()` call resolve here instead of the plain init
    /// above, which silently broke `StoryRunEngineTests.freshEngineStartsAtRootWithEmptyHistoryAndZeroScore()`
    /// the moment a real (persistent, cross-run) `UserDefaults.standard` was involved — the test
    /// only proved it started fresh on Linux SwiftPM, where `.standard` is effectively ephemeral
    /// per process; a real Xcode/Simulator run surfaced the collision immediately.
    static func resumingFromSnapshot(defaults: UserDefaults = .standard) -> StoryRunEngine {
        guard let snapshot = RunSnapshot.loadValid(from: defaults) else {
            return StoryRunEngine(defaults: defaults)
        }

        let engine = StoryRunEngine(startingAt: snapshot.currentNodeId, defaults: defaults)
        engine.choiceHistory = snapshot.choiceHistory
        engine.alignmentScore = snapshot.alignmentScore
        // Story 2.9, AD-5 (amended 2026-08-02): seed from the persisted set of arrival nodes
        // actually dismissed, not an unconditional insert of currentNodeId. A truly-first-ever
        // visit that's still mid-interstitial when the app is killed correctly re-gates on
        // relaunch (it was never dismissed, so it isn't in visitedArrivalNodeIds) — only a node
        // whose Continue was actually tapped skips the gate on resume. This intentionally departs
        // from Story 2.6's original "any resume onto the node skips the gate" behavior, which
        // would otherwise let a player who always force-quits mid-interstitial never see the
        // illustration at all — that was a latent bug relative to AD-5's "first-visit-ever" intent,
        // not a case worth preserving.
        engine.dismissedInterstitialNodeIds = snapshot.visitedArrivalNodeIds
        engine.visitedNodeIds = snapshot.visitedNodeIds
        return engine
    }

    /// Commits the option with the given id on the current choice node. No-op if the current node
    /// isn't a choice node, if `optionId` doesn't match one of its options, or if this node
    /// already has a committed choice (a choice is irrevocable once made — AD-3, FR-5; code-review
    /// finding 2026-07-31: `goBack()` returning to a decided node used to leave it re-selectable).
    func selectChoice(_ optionId: ChoiceOptionID) {
        guard case .choice(_, let options) = StoryTree.node(for: currentNodeId),
              !choiceHistory.contains(where: { $0.nodeId == currentNodeId }),
              let option = Self.option(withId: optionId, in: options) else {
            return
        }

        choiceHistory.append(ChoiceRecord(nodeId: currentNodeId, chosenOptionId: optionId))
        alignmentScore += option.alignmentDelta
        visitedNodeIds.append(currentNodeId)
        currentNodeId = option.target
        persistOrClearSnapshot()
    }

    /// Moves forward. From a reading node, follows its `next` link. From a *decided* choice node
    /// (one with a `choiceHistory` entry), follows the recorded option's `target` — AD-5 blocks
    /// forward only on an *unresolved* choice; once resolved, a choice node behaves like a reading
    /// node for navigation purposes (the "locked, no alternate-choice control" contract, FR-5, is a
    /// display concern, Story 2.3's job, independent of whether forward navigation is gated). No-op
    /// on an unresolved choice node or an ending node.
    ///
    /// Story 2.2 originally shipped this as a no-op on *any* non-reading node, including a decided
    /// choice — its own test asserted the block was permanent. That contradicted AD-5's documented
    /// "blocks forward on an unresolved choice" wording and only surfaced once Story 2.3's real
    /// choice-selection UI made revisiting a decided page (via goBack()) an actual player action:
    /// swiping forward again from that revisit had nowhere to go. Corrected here.
    func advancePage() {
        // Story 2.9 (AD-3, AD-5 — user-clarified 2026-08-02): "Continue" past the branch-arrival
        // interstitial performs the SAME forward move an ordinary reading page's advancePage()
        // does (follows the node's `next` link) — it does not just unlock the current page in
        // place. AD-3 already documented advancePage() as serving "Continue past the branch-
        // arrival interstitial" with "the same 'move forward past the current blocking beat'
        // intent as ordinary paging" — an earlier pass at this story read that as "unlock without
        // moving," which the user corrected after Simulator testing: the illustration+caption is
        // this node's permanent content for any LATER visit (revisiting via goBack() or a
        // relaunch shows it exactly this way, ungated), but the first-ever visit's Continue tap
        // leaves the node entirely, continuing into whatever comes next — the same one-tap
        // "acknowledge and proceed" a player expects from a full-bleed interstitial.
        //
        // Marking the node dismissed here, before the shared `.reading` branch below runs, is
        // what makes a later revisit ungated (AD-5's persisted `visitedArrivalNodeIds` — see
        // `dismissedInterstitialNodeIds`'s doc comment above `phase`).
        if phase == .interstitial {
            dismissedInterstitialNodeIds.insert(currentNodeId)
        }

        switch StoryTree.node(for: currentNodeId) {
        case .reading(_, let next, _, _):
            visitedNodeIds.append(currentNodeId)
            currentNodeId = next
            persistOrClearSnapshot()

        case .choice(_, let options):
            guard let decision = choiceHistory.first(where: { $0.nodeId == currentNodeId }),
                  let target = Self.option(withId: decision.chosenOptionId, in: options)?.target else {
                return
            }
            visitedNodeIds.append(currentNodeId)
            currentNodeId = target
            persistOrClearSnapshot()

        // Story 3.2 (AC #3): "tap to continue" past Ending — the same "move forward past the
        // current blocking beat" intent AD-3 already documents for this method's other phases.
        // Deliberately does NOT call persistOrClearSnapshot() (AC #6): AD-4/Story 3.1 AC #7
        // already cleared the snapshot on arrival at .ending, and there is nothing to write for
        // a phase with no corresponding NodeID/currentNodeId change — persisting here would
        // silently resurrect a "resumable" snapshot for a run that has already ended.
        case .ending:
            hasAdvancedPastEnding = true
        }
    }

    /// Moves back to the previously visited node, if any. Never mutates `choiceHistory` or
    /// `alignmentScore` — a committed choice stays committed (AD-3, FR-5).
    func goBack() {
        // Story 2.6 (AD-5 amendment): blocks backward navigation unconditionally while the
        // interstitial shows — releases only via its own Continue affordance.
        if phase == .interstitial {
            return
        }

        guard let previous = visitedNodeIds.popLast() else {
            return
        }

        currentNodeId = previous
        persistOrClearSnapshot()
    }

    /// Story 2.7 (AD-3): leaves the Story session for Home mid-run, preserving the in-progress
    /// `RunSnapshot` untouched (non-destructive, per the run-options action sheet's "Exit to
    /// Home"). Intentionally does nothing: `persistOrClearSnapshot()` already wrote the current
    /// state synchronously as a side effect of whatever mutating intent last ran (AD-4), so there
    /// is nothing left to change here. This method exists anyway, as a real named intent rather
    /// than being skipped in favor of a bare View-layer action, purely so "Exit to Home" routes
    /// through the engine's fixed intent surface (AD-3's explicit list names it) like every other
    /// player action — don't "simplify" this away. The actual Home navigation is a View-layer
    /// concern this engine has no state for (AD-5): `StoryChoiceView`'s `onExitToHome` closure and
    /// `TutorialView`'s `@Environment(\.dismiss)` are what actually get the player back to Home.
    func exitToHome() {}

    /// Story 2.7 (AD-3): the run-options action sheet's destructive "Restart This Run," fired
    /// mid-run after its own second confirmation. Resets to a fresh run at `StoryTree.root` and,
    /// unlike `startFreshRunIfCurrentRunHasEnded()` below, immediately persists that reset state
    /// (AD-4) — this fires while a real `RunSnapshot` of the *old* run is still on disk, so
    /// skipping the persist here would let a force-quit immediately after confirming Restart
    /// resurrect the pre-restart run on relaunch instead of the fresh one just confirmed.
    func restartRun() {
        resetRunState()
        persistOrClearSnapshot()
    }

    /// Story 2.13 (AD-3): the run-options action sheet's destructive "Exit and Clear Progress,"
    /// fired mid-run after its own second confirmation. Resets fields exactly like `restartRun()`
    /// above (same `resetRunState()`), but deliberately does **not** call `persistOrClearSnapshot()`
    /// afterward. That helper writes a fresh `RunSnapshot` whenever `currentNodeId` isn't
    /// `.ending` — which a reset-to-root always is — so calling it here would leave a resumable
    /// snapshot on disk even though this action's whole point is to leave the run. Home's
    /// Resume/Start label (`RunSnapshotPresence.hasInProgressRun`) reads snapshot *presence*, not
    /// engine field state, so removing the persisted key directly is what actually lands Home on
    /// its fresh-install "Start Story" state rather than "Resume Story."
    func exitAndClearProgress() {
        resetRunState()
        defaults.removeObject(forKey: RunSnapshotPresence.runSnapshotKey)
    }

    /// Resets to a fresh run at `StoryTree.root` if the current run has ended; a no-op otherwise
    /// (mid-run, "Start Story"/"Resume Story" tapped again should do nothing to the live run).
    ///
    /// User-confirmed bug, 2026-08-01: this app reuses one `StoryRunEngine` instance for its
    /// entire lifetime (`RootView`'s `@State`), so nothing previously reset `currentNodeId` once
    /// a run reached `.ending` — tapping "Start Story" from Home re-presented the same finished
    /// run instead of a fresh one. AD-3 keeps the engine the sole mutator of its own state, so
    /// this is a real engine method, not `RootView` reaching into `currentNodeId` directly (which
    /// has no public setter).
    ///
    /// No `persistOrClearSnapshot()` call here: reaching `.ending` already cleared any snapshot
    /// (AC #5), so there's nothing to clear, and a freshly reset run shouldn't persist until its
    /// first mutating intent completes — same as any other fresh run (AC #1's own scope). Contrast
    /// with `restartRun()` above, which fires mid-run against a still-valid on-disk snapshot and
    /// therefore must persist immediately.
    func startFreshRunIfCurrentRunHasEnded() {
        guard case .ending = StoryTree.node(for: currentNodeId) else {
            return
        }

        resetRunState()
    }

    /// Shared reset shape for `startFreshRunIfCurrentRunHasEnded()` and `restartRun()` — the only
    /// difference between the two callers is the guard condition and whether a snapshot write
    /// follows, not which fields get reset.
    private func resetRunState() {
        currentNodeId = StoryTree.root
        choiceHistory = []
        alignmentScore = 0
        visitedNodeIds = []
        dismissedInterstitialNodeIds = []
        hasAdvancedPastEnding = false
    }

    // Code-review finding, 2026-08-01: selectChoice(_:) and advancePage()'s .choice branch both
    // independently resolved "what does this option id target" — a single shared lookup avoids
    // the two drifting apart if either is ever changed on its own.
    private static func option(withId id: ChoiceOptionID, in options: [ChoiceOption]) -> ChoiceOption? {
        options.first(where: { $0.id == id })
    }

    // AD-4: called at the end of every mutating intent's state-changing path (never on a no-op
    // guard-return path, since nothing changed). Writes synchronously and immediately — no Task,
    // no debounce — because iOS can jetsam a backgrounded app before a debounced write fires
    // (architecture adversarial review, Finding 3). Reaching an .ending node clears the snapshot
    // instead of writing one (AC #5) — a finished run has nothing to resume (Finding 6).
    private func persistOrClearSnapshot() {
        if case .ending = StoryTree.node(for: currentNodeId) {
            defaults.removeObject(forKey: RunSnapshotPresence.runSnapshotKey)
            return
        }

        let snapshot = RunSnapshot(
            currentNodeId: currentNodeId,
            choiceHistory: choiceHistory,
            alignmentScore: alignmentScore,
            tutorialSeen: false,
            visitedArrivalNodeIds: dismissedInterstitialNodeIds,
            visitedNodeIds: visitedNodeIds
        )

        guard let data = try? JSONEncoder().encode(snapshot) else {
            defaults.removeObject(forKey: RunSnapshotPresence.runSnapshotKey)
            return
        }

        defaults.set(data, forKey: RunSnapshotPresence.runSnapshotKey)
    }
}

// AD-4: choiceHistory as ID pairs, never frozen prose — Memory re-resolves display text from the
// current String Catalog by id at render time. Codable added Story 2.4 for RunSnapshot encoding.
struct ChoiceRecord: Hashable, Codable {
    let nodeId: NodeID
    let chosenOptionId: ChoiceOptionID
}
