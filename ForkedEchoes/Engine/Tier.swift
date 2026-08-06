import Foundation

// AD-9: a single pure function is the one place score→tier-label boundaries live (mirrors AD-6's
// EndingKind pattern in spirit, not in shape — see this story's Dev Notes "Tier lives in Engine/,
// not Content/" for why: EndingKind is authored per terminal node at content-authoring time,
// while Tier is derived at run time from alignmentScore, an Engine-owned Int with no relationship
// to any specific StoryNode). Lives in Engine/, not Content/, so it stays covered by this
// devcontainer's real `swift test` execution (project-context.md Environment section).
enum Tier: CaseIterable, Equatable {
    case wandering
    case adrift
    case steady
    case homeBound

    // Placeholder boundaries (Epic 4 finalizes real numbers per AD-9's own note), tunable by feel
    // like every other untokened constant in this codebase. The lowest tier's range is
    // deliberately open-ended toward negative infinity (never a fixed floor like 0) — implemented
    // as a descending if/else-if chain that always terminates in .wandering as its unconditional
    // else, so no Int value (including Int.min) falls through unmapped (AC #9).
    static func scoreToTier(score: Int) -> Tier {
        if score >= 6 {
            .homeBound
        } else if score >= 3 {
            .steady
        } else if score >= 0 {
            .adrift
        } else {
            .wandering
        }
    }

    // AC #8/AD-2: never a hardcoded label string. Engine-layer (unlike EndingKind's eyebrow
    // mapping, which stays Views-layer-only because it derives from Content) since this mapping
    // derives from a runtime Int, not authored node data.
    var labelKey: String {
        switch self {
        case .wandering: "memory.tier.wandering"
        case .adrift: "memory.tier.adrift"
        case .steady: "memory.tier.steady"
        case .homeBound: "memory.tier.homeBound"
        }
    }
}
