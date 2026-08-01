import Foundation
import Testing
@testable import ForkedEchoes

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

        #expect(engine.currentNodeId == .endingHomeward)
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
        #expect(engine.currentNodeId == .endingHomeward)

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

        #expect(engine.currentNodeId == .endingHomeward)
    }

    @Test func navigationFromTheResultingNodeAfterAChoiceIsResolved() {
        // Code review, 2026-08-01: AC #5 asks for a test proving forward navigation "proceeds
        // normally from the next reading node" once a choice resolves. Story 2.1's placeholder
        // tree (StoryTree.swift) resolves every firstChoice option directly to an .ending node,
        // never to a .reading node — Epic 4 authors a real tree with reading nodes past the
        // first choice. Until then, there is no "next reading node" to advance into, so this
        // pins down the closest honest equivalent against today's tree: from the actual
        // resulting node, goBack() correctly returns to the decided choice node, and
        // advancePage() correctly no-ops there too (Ending isn't .reading — same guard as
        // everywhere else, nothing choice-resolution-specific about it).
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .endingHomeward)

        engine.advancePage()
        #expect(engine.currentNodeId == .endingHomeward)

        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)
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
        #expect(snapshot.currentNodeId == .firstChoice)
    }

    @Test func goBackWritesASnapshotMatchingEngineState() throws {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .intro, defaults: defaults)
        engine.advancePage()

        engine.goBack()

        let data = try #require(defaults.data(forKey: RunSnapshotPresence.runSnapshotKey))
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        #expect(snapshot.currentNodeId == .intro)
    }

    @Test func reachingAnEndingNodeClearsTheStoredSnapshot() {
        let (defaults, suiteName) = freshDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let engine = StoryRunEngine(startingAt: .firstChoice, defaults: defaults)

        engine.selectChoice(.boat)

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
}
