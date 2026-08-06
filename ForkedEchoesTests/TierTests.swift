import Testing
@testable import ForkedEchoes

// Story 3.3 (AD-9, AC #9): Tier.scoreToTier(score:) boundary cases. Pure function, no
// UserDefaults/engine-instance dependency at all — no freshDefaults() isolation needed, unlike
// every StoryRunEngineTests case.
@Suite
struct TierTests {

    @Test func aLargeNegativeScoreResolvesToTheLowestTier() {
        #expect(Tier.scoreToTier(score: Int.min) == .wandering)
    }

    @Test func anOrdinaryNegativeScoreResolvesToTheLowestTier() {
        #expect(Tier.scoreToTier(score: -1) == .wandering)
    }

    @Test func theWanderingAdriftBoundaryResolvesCorrectlyOnBothSides() {
        #expect(Tier.scoreToTier(score: -1) == .wandering)
        #expect(Tier.scoreToTier(score: 0) == .adrift)
    }

    @Test func zeroScoreResolvesToAdrift() {
        #expect(Tier.scoreToTier(score: 0) == .adrift)
    }

    @Test func theAdriftSteadyBoundaryResolvesCorrectlyOnBothSides() {
        #expect(Tier.scoreToTier(score: 2) == .adrift)
        #expect(Tier.scoreToTier(score: 3) == .steady)
    }

    @Test func theSteadyHomeBoundBoundaryResolvesCorrectlyOnBothSides() {
        #expect(Tier.scoreToTier(score: 5) == .steady)
        #expect(Tier.scoreToTier(score: 6) == .homeBound)
    }

    @Test func aVeryLargePositiveScoreResolvesToTheHighestTierWithNoCeiling() {
        #expect(Tier.scoreToTier(score: Int.max) == .homeBound)
    }

    @Test func mockupSampleScoreResolvesToHomeBound() {
        // mockups/memory.html's sample row: +7 -> "Home-Bound".
        #expect(Tier.scoreToTier(score: 7) == .homeBound)
    }

    @Test func everyTierHasANonEmptyLabelKey() {
        for tier in Tier.allCases {
            #expect(!tier.labelKey.isEmpty)
        }
    }
}
