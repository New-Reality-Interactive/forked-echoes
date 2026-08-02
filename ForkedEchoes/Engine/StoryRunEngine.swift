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
    /// (ARCHITECTURE-SPINE.md), purely derived from `currentNodeId` + the ephemeral
    /// `interstitialDismissed` flag below — same "phase derived, not stored" ethos as
    /// `isEchoActive` (AD-5). `.memory` isn't reachable yet (Epic 3) — omitted for now.
    enum Phase: Equatable {
        case reading
        case interstitial
        case ending
    }

    /// Never persisted (AD-5): a relaunch mid-interstitial resumes straight into the node's
    /// reading content without re-showing the arrival announcement. Reset unconditionally
    /// whenever `currentNodeId` is about to change, so a newly arrived node's own arrival (if
    /// any) always starts undismissed.
    private var interstitialDismissed = false

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
    /// `visitedNodeIds` is not part of `RunSnapshot` (AD-4's four fields are exhaustive), so a
    /// resumed run starts with an empty back-navigation stack — `goBack()` is a no-op until the
    /// player advances forward again this session. This is an accepted, deliberate consequence of
    /// AD-4's fixed shape, not a bug.
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
        // Story 2.6, AD-5: phase is never persisted, so a resumed run never re-shows the
        // branch-arrival interstitial even if it resumes onto an arrival node — relaunch goes
        // straight to that node's ordinary reading content.
        engine.interstitialDismissed = true
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
        interstitialDismissed = false
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
        // Story 2.6: "Continue" past the branch-arrival interstitial (AD-3) — dismisses the
        // interstitial without following the node's `next` link, without touching
        // `visitedNodeIds`, and without persisting anything (AD-5: phase is non-persisted).
        if phase == .interstitial {
            interstitialDismissed = true
            return
        }

        switch StoryTree.node(for: currentNodeId) {
        case .reading(_, let next, _, _):
            visitedNodeIds.append(currentNodeId)
            currentNodeId = next
            interstitialDismissed = false
            persistOrClearSnapshot()

        case .choice(_, let options):
            guard let decision = choiceHistory.first(where: { $0.nodeId == currentNodeId }),
                  let target = Self.option(withId: decision.chosenOptionId, in: options)?.target else {
                return
            }
            visitedNodeIds.append(currentNodeId)
            currentNodeId = target
            interstitialDismissed = false
            persistOrClearSnapshot()

        case .ending:
            return
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
        interstitialDismissed = false
        persistOrClearSnapshot()
    }

    /// Resets to a fresh run at `StoryTree.root` if the current run has ended; a no-op otherwise
    /// (mid-run, "Start Story"/"Resume Story" tapped again should do nothing to the live run).
    ///
    /// User-confirmed bug, 2026-08-01: this app reuses one `StoryRunEngine` instance for its
    /// entire lifetime (`RootView`'s `@State`), so nothing previously reset `currentNodeId` once
    /// a run reached `.ending` — tapping "Start Story" from Home re-presented the same finished
    /// run instead of a fresh one. AD-3 keeps the engine the sole mutator of its own state, so
    /// this is a real engine method, not `RootView` reaching into `currentNodeId` directly (which
    /// has no public setter). This is a narrowly-scoped fix for that one break, not the general
    /// `startNewRun()`/`exitToHome()`/`restartRun()` intent surface AD-3 anticipates — restarting
    /// or exiting *mid-run* remains Story 2.7/Epic 3's job.
    ///
    /// No `persistOrClearSnapshot()` call here: reaching `.ending` already cleared any snapshot
    /// (AC #5), so there's nothing to clear, and a freshly reset run shouldn't persist until its
    /// first mutating intent completes — same as any other fresh run (AC #1's own scope).
    func startFreshRunIfCurrentRunHasEnded() {
        guard case .ending = StoryTree.node(for: currentNodeId) else {
            return
        }

        currentNodeId = StoryTree.root
        choiceHistory = []
        alignmentScore = 0
        visitedNodeIds = []
        interstitialDismissed = false
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
            tutorialSeen: false
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
