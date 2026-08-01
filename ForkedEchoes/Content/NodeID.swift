import Foundation

// AD-1: Content node/choice IDs are Swift enum cases (ARCHITECTURE-SPINE.md Consistency
// Conventions) — referencing a case that doesn't exist is a compile error, not a runtime lookup
// failure. Never a raw String; that would trade this guarantee away.
enum NodeID: Hashable, CaseIterable, Sendable, Codable {
    case intro
    case firstChoice
    case boatEcho
    case endingHomeward
    case endingElsewhere
}
