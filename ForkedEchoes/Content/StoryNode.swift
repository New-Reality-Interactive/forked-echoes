import Foundation

// AD-1: story topology is authored as Swift `indirect enum` literals, never `Decodable`/
// runtime-loaded — an unterminated branch or dangling reference is a compile error. Every case
// here resolves to a choice or an ending; there is no representable dead end.
indirect enum StoryNode: Sendable {
    // Story 2.5: `echoBodyKey` is a defaulted third associated value (Swift supports default
    // associated-value parameters), so `.intro`'s existing 2-argument construction keeps
    // compiling unchanged — only an echo-wired node passes a non-nil third value. Non-nil marks
    // this node as an authored callback to an earlier choice (AD-1: tree-shape-fixed, not a
    // runtime `choiceHistory` lookup) — see StoryRunEngine.isEchoActive.
    // Story 2.6: `arrival` is a defaulted fourth associated value, same pattern — non-nil marks
    // this node as a branch-reality arrival (AD-1: tree-shape-fixed) — see StoryRunEngine.phase.
    case reading(bodyKey: String, next: NodeID, echoBodyKey: String? = nil, arrival: BranchArrival? = nil)
    case choice(promptKey: String, options: [ChoiceOption])
    case ending(EndingPayload)
}

// Struct-backed (not a bare associated NodeID) so Story 3.1 could add an `EndingKind` field here
// without breaking existing `case .ending(let payload):` call sites — a positional second
// associated value would have broken their arity. Story 3.1: `kind` is deliberately non-optional
// and non-defaulted (unlike `.reading`'s `echoBodyKey`/`arrival` additive extensions above) — every
// existing `EndingPayload(nodeId:)` call site was expected to become a compile error until it
// supplied a kind. That's what makes AD-1/AD-6's "every terminal node resolves to exactly one
// EndingKind" a compiler guarantee rather than a runtime check: StoryTree.swift's
// `resolvedNode(for:)` cannot construct an `.ending` case for any NodeID without naming its kind.
// Story 3.2: `titleKey`/`bodyKey` follow `kind`'s non-defaulted precedent (see the doc comment
// above), not `.reading`'s `echoBodyKey`/`arrival` defaulted-parameter one — ending text isn't an
// optional, additive node feature, so every terminal node's authoring site becomes a compile error
// until it supplies real values, same as `kind` did in Story 3.1.
struct EndingPayload: Hashable, Sendable {
    let nodeId: NodeID
    let kind: EndingKind
    let titleKey: String
    let bodyKey: String
}

// AD-6: fixed at write-time on each terminal node — the run's ending is read directly from this,
// never computed from alignmentScore. hardFail nodes are reached only via a designated gotcha
// choice (StoryTree.swift); every other case is reached through ordinary branch traversal.
// Equatable (code review, 2026-08-05): so tests can assert a terminal node's resolved kind matches
// expectation directly, rather than only checking NodeID reachability — the compiler only
// guarantees a kind is *present* on every terminal node (AD-1), never that it's the *correct* one.
enum EndingKind: Sendable, Equatable {
    case home
    case stay
    case limbo
    case hardFail
}

// AD-1: Content node/choice IDs are Swift enum cases — referencing a case that doesn't exist is a
// compile error, not a runtime lookup failure. Mirrors NodeID.swift's flat-enum pattern; a
// String-typed option id would silently no-op on a typo instead of failing to compile.
enum ChoiceOptionID: Hashable, Sendable, CaseIterable, Codable {
    case boat
    case shore
    // Story 3.1: the designated gotcha (hard-fail) choice — targets .endingHardFail directly, one
    // hop from firstChoice, so the immediate selectChoice(_:)-to-Ending transition (AD-5, AC #3)
    // is directly exercisable and testable.
    case gotcha
    // Story 3.1: reaches the fourth EndingKind case (.limbo) not otherwise exercised by the
    // existing .boat/.shore paths.
    case driftLimbo
}

// Alignment deltas live on the choice edge (AD-1) — Memory-screen display data only (FR-7);
// they play no role in which terminal node a path reaches (AD-6).
// Story 3.3: `consequenceKey` follows `EndingPayload.titleKey`/`bodyKey`'s non-defaulted precedent
// (Story 3.2) — consequence text isn't an optional, additive feature, so every existing
// `ChoiceOption(...)` construction site is a compile error until it supplies a real value. Memory
// re-resolves this key from the current String Catalog at render time (AD-4), never a target
// node's own bodyKey — see this story's Dev Notes "Consequence text lives on ChoiceOption, not on
// the target node."
struct ChoiceOption: Hashable, Sendable {
    let id: ChoiceOptionID
    let labelKey: String
    let consequenceKey: String
    let alignmentDelta: Int
    let target: NodeID
}

struct BranchArrival: Hashable, Sendable {
    let illustration: BranchIllustration
    let captionKey: String
}

// AD-1: one case per authored branch-reality flavor, a compile-time-checked identifier —
// never a raw asset-name string. The Views layer (not Content) maps each case to its
// generated ImageResource, keeping Content SwiftUI-free (see StoryChoiceView.swift's
// existing bodyKey/LocalizedStringKey boxing precedent for the same layering rule).
enum BranchIllustration: Sendable {
    case shoreArrival
}
