import Foundation

// AD-1: story topology is authored as Swift `indirect enum` literals, never `Decodable`/
// runtime-loaded — an unterminated branch or dangling reference is a compile error. Every case
// here resolves to a choice or an ending; there is no representable dead end.
indirect enum StoryNode: Sendable {
    case reading(bodyKey: String, next: NodeID)
    case choice(promptKey: String, options: [ChoiceOption])
    case ending(EndingPayload)
}

// Struct-backed (not a bare associated NodeID) so Story 3.1 can add an `EndingKind` field here
// later without breaking existing `case .ending(let payload):` call sites — a positional second
// associated value would break their arity, a new struct field with a default does not. Keeps
// the extension additive per this story's own Dev Notes.
struct EndingPayload: Hashable, Sendable {
    let nodeId: NodeID
}

// AD-1: Content node/choice IDs are Swift enum cases — referencing a case that doesn't exist is a
// compile error, not a runtime lookup failure. Mirrors NodeID.swift's flat-enum pattern; a
// String-typed option id would silently no-op on a typo instead of failing to compile.
enum ChoiceOptionID: Hashable, Sendable, CaseIterable {
    case boat
    case shore
}

// Alignment deltas live on the choice edge (AD-1) — Memory-screen display data only (FR-7);
// they play no role in which terminal node a path reaches (AD-6).
struct ChoiceOption: Hashable, Sendable {
    let id: ChoiceOptionID
    let labelKey: String
    let alignmentDelta: Int
    let target: NodeID
}
