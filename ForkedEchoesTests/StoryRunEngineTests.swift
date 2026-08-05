import Foundation
import Testing
@testable import ForkedEchoes

@Suite(.serializesUserDefaultsAccess)
struct StoryRunEngineTests {

    @Test func freshEngineStartsAtRootWithEmptyHistoryAndZeroScore() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(defaults: defaults)

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    @Test func advancePageMovesFromReadingNodeToItsNext() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
    }

    @Test func advancePageIsNoOpOnANonReadingNode() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    @Test func selectChoiceRecordsHistoryAccumulatesScoreAndMovesToTarget() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.boat)

        // Story 2.5: .boat's target is now the echo-wired .boatEcho reading node, not
        // .endingHomeward directly (that node moved one hop further out).
        #expect(engine.currentNodeId == .boatEcho)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    // selectChoiceWithUnknownOptionIdIsNoOp was removed (code review, 2026-07-31): it tested a
    // typo'd/stale option id, a bug class ChoiceOptionID being an enum now makes structurally
    // impossible to construct — there is no "unknown" ChoiceOptionID to pass. Compile-time
    // prevention is a strictly stronger guarantee than the runtime test it replaces.

    @Test func selectChoiceOnANonChoiceNodeIsNoOp() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)

        engine.selectChoice(.boat)

        #expect(engine.currentNodeId == .intro)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    @Test func selectChoiceDoesNotFireTwiceOnAnAlreadyDecidedNode() {
        // Code-review finding (2026-07-31): goBack() returning to a decided choice node used to
        // leave it re-selectable, double-recording choiceHistory and double-counting
        // alignmentScore — contradicting FR-5/AD-3's "irrevocable once committed" guarantee.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)

        engine.selectChoice(.shore)

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    @Test func goBackMovesToThePreviouslyVisitedNode() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)
        engine.advancePage()
        #expect(engine.currentNodeId == .firstChoice)

        engine.goBack()

        #expect(engine.currentNodeId == .intro)
    }

    @Test func goBackAfterACommittedChoiceDoesNotUndoTheChoice() {
        // AD-3/FR-5: a committed choice is irrevocable — goBack() only moves the position
        // pointer, it never pops choiceHistory or reverses alignmentScore.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        engine.goBack()

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    @Test func goBackWithNoHistoryIsNoOp() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)

        engine.goBack()

        #expect(engine.currentNodeId == .intro)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    // Story 2.2 (pager-gating, FR-3/AD-5/AD-7): the tests below give this story's own AC #4/#5
    // dedicated traceability. The underlying guard already existed from Story 2.1's skeleton
    // (advancePage() no-ops on any non-.reading node) — these don't change engine behavior, they
    // pin down the pager-gating contract explicitly rather than leaving it implied by a
    // more generic node-kind test.

    @Test func advancePageIsBlockedOnAnUnresolvedChoiceNode() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory.isEmpty)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    @Test func advancePageProceedsFromADecidedChoiceNodeToItsRecordedTarget() {
        // Story 2.3, correcting a Story 2.2 defect: AD-5 blocks forward only on an *unresolved*
        // choice ("blocks forward on an unresolved choice" — the "locked display" clause is a
        // separate, display-only concern, Story 2.3's job). The original Story 2.2 test here
        // asserted the opposite — a permanent block regardless of resolution — which contradicted
        // AD-5's own wording and only surfaced once real choice-selection UI (this story) made
        // revisiting a decided page (via goBack()) an actual player action: swiping forward again
        // from that revisit had nowhere to go, confirmed via user Simulator testing, 2026-08-01.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])

        engine.advancePage()

        // Story 2.5: .boat's decided target is now .boatEcho (a reading node), one hop before
        // .endingHomeward — this test's job is only to prove advancePage() honors the decided
        // choice's recorded target, whatever that target is.
        #expect(engine.currentNodeId == .boatEcho)
    }

    @Test func navigationFromTheResultingNodeAfterAChoiceIsResolved() {
        // Code review, 2026-08-01: AC #5 asks for a test proving forward navigation "proceeds
        // normally from the next reading node" once a choice resolves. Story 2.1's placeholder
        // tree (StoryTree.swift) originally resolved every firstChoice option directly to an
        // .ending node; Story 2.5 gave .boat a real "next reading node" (.boatEcho) to advance
        // into, which this test now exercises directly — from the resulting node, advancePage()
        // proceeds to .endingHomeward, and goBack() steps back one node at a time.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        engine.advancePage()
        #expect(engine.currentNodeId == .endingHomeward)

        engine.goBack()
        #expect(engine.currentNodeId == .boatEcho)
    }

    // Story 2.4 (AD-4): persistence is a side effect of a completed mutating intent. Each test
    // below injects its own isolated UserDefaults suite (freshDefaults() pattern) rather than
    // writing to .standard — a rule that applies to every test in this file, not only the ones
    // below (code review, 2026-08-01: pre-existing tests above were silently writing to the real
    // `.standard` domain once persistence was wired into every mutating intent).

    // Note: the placeholder StoryTree (StoryTree.swift, Story 2.1) has every selectChoice(_:) path
    // land directly on an .ending node, so selectChoice's "writes a snapshot" side effect (AC #1)
    // can't be observed in isolation from its "clears the snapshot" side effect (AC #5) with
    // today's content — reachingAnEndingNodeClearsTheStoredSnapshot below covers that combined
    // path. advancePage()/goBack() below exercise the plain-write path since .intro is a reading
    // node.

    @Test func advancePageWritesASnapshotMatchingEngineState() throws {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)

        engine.advancePage()

        let data = try #require(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey))
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        #expect(snapshot.currentNodeId == engine.currentNodeId)
        #expect(snapshot.choiceHistory == engine.choiceHistory)
        #expect(snapshot.alignmentScore == engine.alignmentScore)
        // AD-4/Completion Notes: tutorialSeen has no producer yet — always written false.
        #expect(snapshot.tutorialSeen == false)
    }

    @Test func goBackWritesASnapshotMatchingEngineState() throws {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)
        engine.advancePage()

        engine.goBack()

        let data = try #require(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey))
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        #expect(snapshot.currentNodeId == engine.currentNodeId)
        #expect(snapshot.choiceHistory == engine.choiceHistory)
        #expect(snapshot.alignmentScore == engine.alignmentScore)
    }

    @Test func resumedEngineWithADecidedChoiceAdvancesUsingTheRestoredHistory() {
        // Code review, 2026-08-01: Task 3 (resume) and advancePage()'s pre-existing .choice
        // branch had no test proving they compose — a resumed engine's restored choiceHistory,
        // not a freshly-computed one, is what advancePage() must consult to resolve where a
        // decided choice node goes next.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)
        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        engine.advancePage()

        // Story 2.5: .boat's decided target is now .boatEcho, not .endingHomeward directly.
        #expect(engine.currentNodeId == .boatEcho)
    }

    @Test func startFreshRunIfCurrentRunHasEndedResetsAFinishedRunToRoot() {
        // User-confirmed bug, 2026-08-01: tapping "Start Story" after a run ended re-presented
        // the same finished run — this engine method is RootView's fix, called when the Story
        // session is about to be presented.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        // .boat reaches an ending directly via .boatEcho, one advancePage() past the echo node
        // (unlike .shore, which now passes through the interstitial-wired .shoreArrival reading
        // node first, Story 2.6) — this test only needs a run that has already ended, not either
        // specific path.
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        engine.advancePage()
        #expect(engine.currentNodeId == .endingHomeward)

        engine.startFreshRunIfCurrentRunHasEnded()

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    @Test func startFreshRunIfCurrentRunHasEndedIsNoOpMidRun() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.startFreshRunIfCurrentRunHasEnded()

        #expect(engine.currentNodeId == .firstChoice)
    }

    @Test func reachingAnEndingNodeClearsTheStoredSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        // .boat reaches an ending directly via .boatEcho, one advancePage() past the echo node
        // (unlike .shore, which now passes through the interstitial-wired .shoreArrival reading
        // node first, Story 2.6).
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)

        engine.advancePage()

        #expect(engine.currentNodeId == .endingHomeward)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    @Test func engineConstructedWithAValidSnapshotResumesAtTheSavedState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 4,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 4)
    }

    @Test func engineConstructedWithCorruptDataStartsFreshAtRoot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data([0xFF, 0x00]), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    @Test func engineConstructedWithASnapshotPointingAtAnEndingNodeStartsFreshAtRoot() {
        // Code review, 2026-08-01: a content-tree edit could reclassify a previously-in-progress
        // node as .ending after a snapshot was written for it — loadValid must reject that stale
        // snapshot rather than resuming onto a finished run (AC #5's intent).
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .endingHomeward,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    // Story 2.5 (AC #5, AD-7): echo-callback reachability as authored in the tree —
    // isEchoActive derives purely from currentNodeId (AD-1/AD-5), never from a runtime
    // choiceHistory scan.

    @Test func reachingTheEchoNodeViaTheBoatChoiceSetsIsEchoActive() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        #expect(engine.isEchoActive == true)
    }

    @Test func advancingPastTheEchoNodeClearsIsEchoActive() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)
        #expect(engine.isEchoActive == true)

        engine.advancePage()

        #expect(engine.currentNodeId == .endingHomeward)
        #expect(engine.isEchoActive == false)
    }

    @Test func theShorePathNeverReportsIsEchoActiveTrueAnywhereAlongIt() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        #expect(engine.isEchoActive == false)

        engine.selectChoice(.shore)

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.isEchoActive == false)

        // Story 2.9: Continue past the interstitial advances just like an ordinary page turn —
        // one advancePage() call reaches .endingElsewhere directly (see
        // advancePageWhileInterstitialDismissesAndAdvancesToTheNextNode for the dedicated test).
        engine.advancePage()

        #expect(engine.currentNodeId == .endingElsewhere)
        #expect(engine.isEchoActive == false)
    }

    @Test func anEngineResumedOntoTheEchoNodeReportsIsEchoActiveImmediately() {
        // Closes the same "restored vs. freshly-computed state" gap Story 2.4's 2nd review pass
        // closed for choiceHistory — isEchoActive must be correct right after
        // resumingFromSnapshot(defaults:), without any intervening mutating intent.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .boatEcho,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)],
            alignmentScore: 1,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .boatEcho)
        #expect(engine.isEchoActive == true)
    }

    @Test func anEngineResumedOntoANonEchoNodeReportsIsEchoActiveFalseImmediately() {
        // Code review, 2026-08-01: the companion negative case to the test above — proves the
        // resumed-state re-derivation isn't accidentally always true.
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .firstChoice,
            choiceHistory: [],
            alignmentScore: 0,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.isEchoActive == false)
    }

    // Story 2.6 (AC #7, AD-7): branch-arrival interstitial phase derivation and dismissal.

    @Test func selectingShoreArrivesAtShoreArrivalWithInterstitialPhase() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.shore)

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .interstitial)
    }

    // Story 2.9 (user-clarified 2026-08-02, after Simulator testing surfaced the original
    // reading of this behavior as a real usability bug): Continue performs the SAME forward move
    // an ordinary reading page's advancePage() does — it leaves the arrival node entirely,
    // following its `next` link, rather than merely unlocking the same node in place. The
    // illustration+caption stays this node's permanent content for any LATER visit (revisit via
    // goBack() or relaunch), but the first-ever Continue tap advances past it.
    @Test func advancePageWhileInterstitialDismissesAndAdvancesToTheNextNode() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        #expect(engine.phase == .interstitial)

        engine.advancePage()

        #expect(engine.currentNodeId == .endingElsewhere)
    }

    // Story 2.9: once dismissed, revisiting the arrival node (backing up to it) and advancing
    // again behaves exactly like an ordinary reading page — swipe forward reaches the same real
    // target, no gate involved the second time.
    @Test func advancingFromARevisitedDismissedArrivalNodeReachesTheSameNextTargetAgain() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        engine.advancePage() // Continue: dismiss + advance to .endingElsewhere
        engine.goBack() // back to .shoreArrival, now ungated
        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .reading)

        engine.advancePage() // ordinary forward swipe, no gate this time

        #expect(engine.currentNodeId == .endingElsewhere)
    }

    @Test func goBackWhileInterstitialIsANoOp() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        #expect(engine.phase == .interstitial)

        engine.goBack()

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .interstitial)
    }

    @Test func theBoatPathNeverReportsInterstitialPhaseAnywhereAlongIt() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        #expect(engine.phase != .interstitial)

        engine.selectChoice(.boat)

        #expect(engine.currentNodeId == .boatEcho)
        #expect(engine.phase != .interstitial)

        engine.advancePage()

        #expect(engine.currentNodeId == .endingHomeward)
        #expect(engine.phase != .interstitial)
    }

    // Code-review finding, 2026-08-02: interstitialDismissed used to be a single flag reset on
    // every currentNodeId change, so backing up over a decided choice and paging forward again
    // re-showed an already-dismissed interstitial. Regression test for the fix (dismissal now
    // tracked per-node) — updated for Story 2.9's corrected semantics (Continue actually advances
    // past the node now, so reaching it a second time requires backing up twice: once off the
    // node Continue advanced to, once more off the arrival node itself, back to the choice page).
    @Test func dismissedInterstitialDoesNotReplayAfterBackingUpAndPagingForwardAgain() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        engine.advancePage() // Continue: dismiss + advance to .endingElsewhere
        #expect(engine.currentNodeId == .endingElsewhere)

        engine.goBack() // -> .shoreArrival (dismissed, ungated)
        engine.goBack() // -> .firstChoice (the decided choice node)
        #expect(engine.currentNodeId == .firstChoice)

        engine.advancePage() // forward again via the already-decided choice

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .reading)
    }

    // Story 2.9 (AD-5, amended 2026-08-02): a snapshot resuming directly onto .shoreArrival with
    // no record of the interstitial having been dismissed represents a truly-first-ever visit
    // that was still mid-gate when the app was killed — it must re-gate on relaunch, not skip
    // straight to reading. This replaces Story 2.6's original expectation (any resume onto the
    // arrival node skipped the gate unconditionally), which would have let a player who always
    // force-quits mid-interstitial never see the illustration at all.
    @Test func anEngineResumedOntoShoreArrivalWithoutDismissalStillReportsInterstitialPhase() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .shoreArrival,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .shore)],
            alignmentScore: -1,
            tutorialSeen: false
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .interstitial)
    }

    // Story 2.9 (AC #4): the actual regression test for the bug this story fixes. In the real
    // app, dismissing the interstitial (Continue) DOES move currentNodeId onward (it behaves
    // like an ordinary forward advance) — but a player can then back up to the dismissed arrival
    // node again, at which point currentNodeId == .shoreArrival while .shoreArrival is already
    // present in visitedArrivalNodeIds. If the app is killed right there and relaunched, a
    // *freshly constructed* engine (not the same instance that dismissed it) must read that
    // persisted signal and report .reading, not .interstitial — this is the case Story 2.6's
    // in-memory-only dismissedInterstitialNodeIds could never satisfy across a real process
    // restart.
    @Test func aFreshlyConstructedEngineResumedOntoADismissedArrivalNodeReportsReadingPhase() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .shoreArrival,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .shore)],
            alignmentScore: -1,
            tutorialSeen: false,
            visitedArrivalNodeIds: [.shoreArrival]
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .reading)
    }

    // Story 2.9 (Task 4): startFreshRunIfCurrentRunHasEnded() must clear the persisted-visited
    // signal too, not just the in-memory set — otherwise a brand new run's own first visit to
    // .shoreArrival would incorrectly skip the gate, inheriting the previous run's dismissal.
    @Test func startingAFreshRunAfterEndingClearsPersistedArrivalVisitationOnNextSnapshotWrite() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        engine.advancePage() // Continue: dismiss + advance to .endingElsewhere, clears the snapshot (AC #5)
        #expect(engine.currentNodeId == .endingElsewhere)

        engine.startFreshRunIfCurrentRunHasEnded()
        engine.advancePage() // .intro (StoryTree.root) -> .firstChoice, the fresh run's own start
        engine.selectChoice(.shore) // re-arrive at .shoreArrival on the new run, writes a snapshot

        let reloaded = RunSnapshot.loadValid(from: defaults)
        #expect(reloaded?.visitedArrivalNodeIds.isEmpty == true)
        #expect(engine.phase == .interstitial)
    }

    // Story 2.7: exitToHome()/restartRun() are part of AD-3's intent surface (Story 2.13 adds
    // exitAndClearProgress() below the restartRun() trio; only startNewRun(), Epic 3's job,
    // remains). exitToHome() is intentionally a no-op — these tests prove that directly, including
    // against the persisted snapshot, not just in-memory state.
    @Test func exitToHomeDoesNotMutateEngineState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)

        engine.exitToHome()

        #expect(engine.currentNodeId == .boatEcho)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    @Test func exitToHomeLeavesAnExistingPersistedSnapshotUntouched() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        let beforeSnapshot = RunSnapshot.loadValid(from: defaults)

        engine.exitToHome()

        let afterSnapshot = RunSnapshot.loadValid(from: defaults)
        #expect(afterSnapshot == beforeSnapshot)
    }

    @Test func restartRunResetsAllRunStateMidRun() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        engine.restartRun()

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)

        // Back-navigation stack cleared as part of the reset (Task 1's resetRunState()).
        engine.goBack()
        #expect(engine.currentNodeId == StoryTree.root)
    }

    // Story 2.9 precedent: restartRun() must clear dismissed-arrival-node state too, or a fresh
    // run's own first-ever visit to .shoreArrival would incorrectly skip the gate.
    @Test func restartRunClearsDismissedArrivalNodeState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        engine.advancePage() // dismiss the interstitial, advances to .endingElsewhere
        #expect(engine.currentNodeId == .endingElsewhere)

        engine.restartRun()
        engine.advancePage() // .intro -> .firstChoice
        engine.selectChoice(.shore) // re-arrive at .shoreArrival on the restarted run

        #expect(engine.phase == .interstitial)
    }

    // The regression this story exists to prevent: restartRun() must persist immediately, unlike
    // startFreshRunIfCurrentRunHasEnded(), because a real snapshot of the pre-restart run is
    // already on disk. Without an immediate persist, a force-quit right after confirming "Restart
    // This Run" (simulated here by constructing a second, independent engine on the same
    // UserDefaults suite) would resurrect the pre-restart run instead of the fresh one confirmed.
    @Test func restartRunImmediatelyOverwritesTheStaleMidRunSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        engine.restartRun()

        let relaunchedEngine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(relaunchedEngine.currentNodeId == StoryTree.root)
        #expect(relaunchedEngine.choiceHistory.isEmpty)
        #expect(relaunchedEngine.alignmentScore == 0)
    }

    // Story 2.13: exitAndClearProgress() completes AD-3's intent surface. Modeled directly on the
    // restartRun() trio above — the field reset is identical (shared resetRunState()) — except the
    // last test, which pins down the one behavior that actually differs: no persisted snapshot.
    @Test func exitAndClearProgressResetsAllRunStateMidRun() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .boatEcho)

        engine.exitAndClearProgress()

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)

        // Back-navigation stack cleared as part of the reset (shared resetRunState()).
        engine.goBack()
        #expect(engine.currentNodeId == StoryTree.root)
    }

    @Test func exitAndClearProgressClearsDismissedArrivalNodeState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.shore)
        engine.advancePage() // dismiss the interstitial, advances to .endingElsewhere
        #expect(engine.currentNodeId == .endingElsewhere)

        engine.exitAndClearProgress()
        engine.advancePage() // .intro -> .firstChoice
        engine.selectChoice(.shore) // re-arrive at .shoreArrival on the new run

        #expect(engine.phase == .interstitial)
    }

    // The regression this story exists to prevent (see StoryRunEngine.exitAndClearProgress()'s
    // doc comment): unlike restartRun(), which leaves a fresh, resumable snapshot on disk,
    // exitAndClearProgress() must leave Home in its fresh-install state — no persisted snapshot.
    @Test func exitAndClearProgressLeavesNoPersistedSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(RunSnapshot.loadValid(from: defaults) != nil)

        engine.exitAndClearProgress()

        #expect(RunSnapshot.loadValid(from: defaults) == nil)
        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == false)
    }

    // Review finding, 2026-08-04: exitAndClearProgress()'s defaults.removeObject(forKey:) call was
    // only ever exercised with a snapshot present. Asserts the no-prior-snapshot path is a harmless
    // no-op, not just an assumption.
    @Test func exitAndClearProgressIsHarmlessWithNoPriorSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)
        #expect(RunSnapshot.loadValid(from: defaults) == nil)

        engine.exitAndClearProgress()

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(RunSnapshot.loadValid(from: defaults) == nil)
        #expect(RunSnapshotPresence.hasInProgressRun(in: defaults) == false)
    }

    // Story 2.10 (AC #1, #4): the actual regression test for the bug this story fixes. Before
    // this story, StoryRunEngine.visitedNodeIds (the back-navigation stack) was never part of
    // RunSnapshot, so a freshly-constructed engine resuming onto a mid-run snapshot always
    // started with an empty stack — goBack() was a silent no-op until the player advanced forward
    // again in the new session. Builds a snapshot at a node reached via two forward moves from
    // root (.intro -> .firstChoice -> .shoreArrival), with visitedNodeIds recording that history,
    // resumes on a fresh engine instance, and proves goBack() can walk all the way back through
    // it, exactly as it could pre-relaunch.
    @Test func resumedEngineCanNavigateBackwardThroughPersistedHistory() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .shoreArrival,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .shore)],
            alignmentScore: -1,
            tutorialSeen: false,
            visitedArrivalNodeIds: [],
            visitedNodeIds: [.intro, .firstChoice]
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)
        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .interstitial)

        // Interstitial blocks backward navigation until dismissed (Story 2.6/2.9) — advance past
        // it first via Continue, matching how a player would actually reach a backward-navigable
        // state from a never-dismissed arrival node.
        engine.advancePage()
        #expect(engine.currentNodeId == .endingElsewhere)

        engine.goBack()
        #expect(engine.currentNodeId == .shoreArrival)

        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)

        // Code review, 2026-08-03 (Story 2.10 patch): this story is specifically about
        // persistence, but nothing above confirmed the shrinking stack actually round-trips
        // through persistOrClearSnapshot() on disk, not just in memory — reload here and assert
        // the on-disk visitedNodeIds matches what's left after two pops.
        #expect(RunSnapshot.loadValid(from: defaults)?.visitedNodeIds == [.intro])

        engine.goBack()
        #expect(engine.currentNodeId == .intro)

        engine.goBack()
        #expect(engine.currentNodeId == .intro) // stack exhausted, no-op (pre-existing behavior)
    }

    // Code review, 2026-08-03 (Story 2.10 patch): AC #3 guards against this story's persisted
    // back-stack interacting badly with Story 2.9's interstitial gate. The composition test above
    // only covers a *dismissed* arrival node; this covers the un-dismissed case — a resumed engine
    // with a non-empty persisted visitedNodeIds stack sitting on a never-dismissed arrival node
    // must still have goBack() blocked entirely by phase == .interstitial (Story 2.6/2.9), not
    // silently pop the stack because history happens to exist.
    @Test func goBackStaysBlockedByInterstitialGateOnAResumedEngineWithNonEmptyHistory() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshot = RunSnapshot(
            currentNodeId: .shoreArrival,
            choiceHistory: [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .shore)],
            alignmentScore: -1,
            tutorialSeen: false,
            visitedArrivalNodeIds: [],
            visitedNodeIds: [.intro, .firstChoice]
        )
        defaults.set(try! JSONEncoder().encode(snapshot), forKey: RunSnapshotPresence.runSnapshotKey)

        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)
        #expect(engine.phase == .interstitial)

        engine.goBack()

        #expect(engine.currentNodeId == .shoreArrival) // gate held; stack untouched despite non-empty history
    }

    // Story 2.10 (AC #3): proves this story's persisted back-stack composes correctly with Story
    // 2.9's persisted arrival-dismissal tracking rather than one silently overriding the other.
    // Drives a real engine through dismissing .shoreArrival, advancing past it, then backing up
    // to it once (leaving a genuinely resumable, non-ending on-disk snapshot — reaching the
    // ending itself would clear the snapshot entirely, AC #5), then resumes a FRESH engine
    // instance from that exact on-disk state and confirms: (a) it lands on the dismissed arrival
    // node ungated, matching Story 2.9's own behavior, and (b) goBack() from there still walks
    // further back through this story's persisted history to the choice node.
    @Test func resumedEngineComposesPersistedBackStackWithDismissedArrivalState() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let priorSessionEngine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        priorSessionEngine.selectChoice(.shore)
        priorSessionEngine.advancePage() // Continue: dismiss + advance to .endingElsewhere
        priorSessionEngine.goBack() // back to .shoreArrival, now ungated; writes a resumable snapshot
        #expect(priorSessionEngine.currentNodeId == .shoreArrival)

        // Simulate force-quit + relaunch: a brand new engine instance, not the same one above.
        let engine = StoryRunEngine.resumingFromSnapshot(defaults: defaults)

        #expect(engine.currentNodeId == .shoreArrival)
        #expect(engine.phase == .reading)

        engine.goBack()

        #expect(engine.currentNodeId == .firstChoice)
    }

    // Story 2.10 (Task 2): resetRunState() already cleared the in-memory visitedNodeIds stack
    // (pre-dates this story) — this proves the clear now also propagates to disk via the next
    // persistOrClearSnapshot() call, mirroring Story 2.9's equivalent regression test for
    // visitedArrivalNodeIds.
    @Test func startingAFreshRunAfterEndingClearsPersistedBackNavigationHistoryOnNextSnapshotWrite() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        engine.advancePage() // .boatEcho -> .endingHomeward, clears the snapshot (AC #5)
        #expect(engine.currentNodeId == .endingHomeward)

        engine.startFreshRunIfCurrentRunHasEnded()
        engine.advancePage() // .intro (StoryTree.root) -> .firstChoice, the fresh run's own start

        let reloaded = RunSnapshot.loadValid(from: defaults)
        #expect(reloaded?.visitedNodeIds == [.intro])
    }

    // Story 3.1 (AC #1/#2, code review 2026-08-05): the compiler only guarantees every terminal
    // node has *some* EndingKind (AD-1's non-optional `kind` field) — it can't catch a *wrong*
    // one being assigned (e.g. a copy-paste swap of .home for .hardFail). This test asserts each
    // terminal node's resolved EndingKind matches what StoryTree.swift actually authors, closing
    // that gap directly rather than relying on NodeID reachability alone.

    @Test func eachTerminalNodeResolvesToItsAuthoredEndingKind() {
        func kind(of nodeId: NodeID) -> EndingKind? {
            guard case .ending(let payload) = StoryTree.node(for: nodeId) else { return nil }
            return payload.kind
        }

        #expect(kind(of: .endingHomeward) == .home)
        #expect(kind(of: .endingElsewhere) == .stay)
        #expect(kind(of: .endingLimbo) == .limbo)
        #expect(kind(of: .endingHardFail) == .hardFail)
    }

    // Story 3.2 (AC #1/#7): extends the same "content routes correctly per node" traceability
    // check to titleKey/bodyKey — the compiler only guarantees these fields are *present* on every
    // terminal node (EndingPayload's non-defaulted shape), never that they're the *intended*
    // values authored for that specific node.

    @Test func eachTerminalNodeResolvesToItsAuthoredTitleAndBodyKeys() {
        func keys(of nodeId: NodeID) -> (titleKey: String, bodyKey: String)? {
            guard case .ending(let payload) = StoryTree.node(for: nodeId) else { return nil }
            return (payload.titleKey, payload.bodyKey)
        }

        #expect(keys(of: .endingHomeward)?.titleKey == "story.endingHomeward.title")
        #expect(keys(of: .endingHomeward)?.bodyKey == "story.endingHomeward.body")
        #expect(keys(of: .endingElsewhere)?.titleKey == "story.endingElsewhere.title")
        #expect(keys(of: .endingElsewhere)?.bodyKey == "story.endingElsewhere.body")
        #expect(keys(of: .endingLimbo)?.titleKey == "story.endingLimbo.title")
        #expect(keys(of: .endingLimbo)?.bodyKey == "story.endingLimbo.body")
        #expect(keys(of: .endingHardFail)?.titleKey == "story.endingHardFail.title")
        #expect(keys(of: .endingHardFail)?.bodyKey == "story.endingHardFail.body")
    }

    // Story 3.2 (AC #3): advancePage() from .ending transitions phase to .memory (not a no-op);
    // a second call while already .memory stays a no-op and doesn't crash or re-transition.

    @Test func advancePageFromEndingTransitionsPhaseToMemory() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .endingHomeward, defaults: defaults)
        #expect(engine.phase == .ending)

        engine.advancePage()

        #expect(engine.phase == .memory)
        #expect(engine.currentNodeId == .endingHomeward)
    }

    @Test func advancePageFromMemoryIsANoOp() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .endingHomeward, defaults: defaults)
        engine.advancePage()
        #expect(engine.phase == .memory)

        engine.advancePage()

        #expect(engine.phase == .memory)
        #expect(engine.currentNodeId == .endingHomeward)
    }

    // Story 3.2 (AC #6): reaching .ending/.memory never re-persists a RunSnapshot — the snapshot
    // was already cleared on arrival at .ending (AD-4/Story 3.1 AC #7), and advancePage()'s
    // .ending branch deliberately never calls persistOrClearSnapshot().

    @Test func advancePageFromEndingToMemoryNeverWritesASnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .endingHomeward, defaults: defaults)
        #expect(defaults.object(forKey: RunSnapshotPresence.runSnapshotKey) == nil)

        engine.advancePage()

        #expect(engine.phase == .memory)
        #expect(defaults.object(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    // Story 3.1 (AC #3, AD-5, AD-7/NFR3): selectChoice(_:) targeting a hard-fail terminal node
    // transitions the engine to Ending the instant the choice fires, with no intervening
    // advancePage() call. phase's derivation is already generic (see StoryRunEngine.phase) — this
    // is a content-wiring regression test, not a test of new engine logic.

    @Test func selectingTheGotchaChoiceTransitionsToEndingImmediately() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.gotcha)

        #expect(engine.currentNodeId == .endingHardFail)
        #expect(engine.phase == .ending)
    }

    // Story 3.1 (AC #3): the hard-fail terminal node is reachable only via its designated gotcha
    // choice — selecting any other firstChoice option never lands on .endingHardFail. Three
    // independent tests (code review, 2026-08-05: originally one bundled @Test with three
    // scenarios inline, which masked which sub-case failed) rather than one @Test asserting all
    // three, so a Swift Testing failure report identifies exactly which option's targeting broke.

    @Test func selectingBoatNeverReachesTheHardFailEnding() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.boat)

        #expect(engine.currentNodeId != .endingHardFail)
    }

    @Test func selectingShoreNeverReachesTheHardFailEnding() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.shore)

        #expect(engine.currentNodeId != .endingHardFail)
    }

    @Test func selectingDriftLimboNeverReachesTheHardFailEnding() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.driftLimbo)

        #expect(engine.currentNodeId != .endingHardFail)
    }

    // Story 3.1 (AC #7): reaching either of this story's two new terminal nodes clears the
    // persisted RunSnapshot, exactly like the pre-existing endings — persistOrClearSnapshot()'s
    // `.ending` branch already matches generically (see reachingAnEndingNodeClearsTheStoredSnapshot
    // above for the pre-existing equivalent), so these are new traceability, not new behavior.

    @Test func reachingTheHardFailEndingClearsTheStoredSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.gotcha)

        #expect(engine.currentNodeId == .endingHardFail)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }

    @Test func reachingTheLimboEndingClearsTheStoredSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.driftLimbo)

        #expect(engine.currentNodeId == .endingLimbo)
        #expect(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey) == nil)
    }
}
