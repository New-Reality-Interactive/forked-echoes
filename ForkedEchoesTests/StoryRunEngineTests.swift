import Foundation
import Testing
@testable import ForkedEchoes

struct StoryRunEngineTests {

    @Test func freshEngineStartsAtRootWithEmptyHistoryAndZeroScore() {
        let engine = StoryRunEngine()

        #expect(engine.currentNodeId == StoryTree.root)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    @Test func advancePageMovesFromReadingNodeToItsNext() {
        let engine = StoryRunEngine(startingAt: .intro)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
    }

    @Test func advancePageIsNoOpOnANonReadingNode() {
        let engine = StoryRunEngine(startingAt: .firstChoice)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
    }

    @Test func selectChoiceRecordsHistoryAccumulatesScoreAndMovesToTarget() {
        let engine = StoryRunEngine(startingAt: .firstChoice)

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
        let engine = StoryRunEngine(startingAt: .intro)

        engine.selectChoice(.boat)

        #expect(engine.currentNodeId == .intro)
        #expect(engine.choiceHistory.isEmpty)
        #expect(engine.alignmentScore == 0)
    }

    @Test func selectChoiceDoesNotFireTwiceOnAnAlreadyDecidedNode() {
        // Code-review finding (2026-07-31): goBack() returning to a decided choice node used to
        // leave it re-selectable, double-recording choiceHistory and double-counting
        // alignmentScore — contradicting FR-5/AD-3's "irrevocable once committed" guarantee.
        let engine = StoryRunEngine(startingAt: .firstChoice)
        engine.selectChoice(.boat)
        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)

        engine.selectChoice(.shore)

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    @Test func goBackMovesToThePreviouslyVisitedNode() {
        let engine = StoryRunEngine(startingAt: .intro)
        engine.advancePage()
        #expect(engine.currentNodeId == .firstChoice)

        engine.goBack()

        #expect(engine.currentNodeId == .intro)
    }

    @Test func goBackAfterACommittedChoiceDoesNotUndoTheChoice() {
        // AD-3/FR-5: a committed choice is irrevocable — goBack() only moves the position
        // pointer, it never pops choiceHistory or reverses alignmentScore.
        let engine = StoryRunEngine(startingAt: .firstChoice)
        engine.selectChoice(.boat)
        #expect(engine.currentNodeId == .endingHomeward)

        engine.goBack()

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])
        #expect(engine.alignmentScore == 1)
    }

    @Test func goBackWithNoHistoryIsNoOp() {
        let engine = StoryRunEngine(startingAt: .intro)

        engine.goBack()

        #expect(engine.currentNodeId == .intro)
    }

    // Story 2.2 (pager-gating, FR-3/AD-5/AD-7): the tests below give this story's own AC #4/#5
    // dedicated traceability. The underlying guard already existed from Story 2.1's skeleton
    // (advancePage() no-ops on any non-.reading node) — these don't change engine behavior, they
    // pin down the pager-gating contract explicitly rather than leaving it implied by a
    // more generic node-kind test.

    @Test func advancePageIsBlockedOnAnUnresolvedChoiceNode() {
        let engine = StoryRunEngine(startingAt: .firstChoice)

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory.isEmpty)
    }

    @Test func advancePageRemainsBlockedOnAChoiceNodeEvenAfterItHasBeenResolved() {
        // Forward-blocking is keyed on the current node's *type* (any non-.reading node),
        // not on whether a choice there has been resolved (AD-5). Resolving a choice moves
        // currentNodeId away via selectChoice(_:) itself — there is no scenario where
        // advancePage() is the thing that unblocks at the *same* choice node. Revisiting a
        // decided choice via goBack() must still block advancePage() there, matching AD-5's
        // "back-navigation shows a decided choice locked" contract from the navigation side
        // (the locked *display* itself is Story 2.3's job).
        let engine = StoryRunEngine(startingAt: .firstChoice)
        engine.selectChoice(.boat)
        engine.goBack()
        #expect(engine.currentNodeId == .firstChoice)
        #expect(engine.choiceHistory == [ChoiceRecord(nodeId: .firstChoice, chosenOptionId: .boat)])

        engine.advancePage()

        #expect(engine.currentNodeId == .firstChoice)
    }
}
