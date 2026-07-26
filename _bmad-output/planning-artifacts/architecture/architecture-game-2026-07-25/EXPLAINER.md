# Why the Architecture Looks Like This

A companion to `ARCHITECTURE-SPINE.md` — that file is the terse build contract; this one is the reasoning behind it, for when you come back in three months and wonder "wait, why did I do it this way?" Each section names the AD it explains.

## The story tree is Swift code, not a JSON file (AD-1)

The first instinct was JSON: write the story as data, load it at runtime. That's a completely reasonable way to build a CYOA app in general. But two things about *this* app pushed away from it:

1. **Nothing here is dynamic.** No network, no backend, no runtime content updates — the story ships frozen inside the app binary either way. JSON's usual advantage (change content without recompiling the *shipped* app) doesn't apply; you'd only be trading it for editing convenience during development, and Xcode rebuilds this size of project in seconds anyway.
2. **The tree shape and Swift's type system fit together almost too well to pass up.** Because a choice can't be undone or revisited differently (FR-5), the whole story is a tree, never a graph with cycles or merges. Swift's `indirect enum` is built exactly for recursive, tree-shaped data — and if you define every case to resolve into either "more choices" or "an ending," **the compiler physically cannot let you build a branch that doesn't terminate.** That's not a test you have to remember to run — FR-8's most important rule (every branch ends in exactly one of four ending types) becomes something the app can't compile if it's wrong.

The cost: content edits mean editing Swift files, not a text file. For ~10-15 branches on a solo project, that's a fair trade for never shipping a dangling story branch.

## Prose lives separately, in a String Catalog (AD-2)

Putting the actual sentences of prose *inside* the enum (as string literals) would have undercut the whole idea the moment you wanted a second language — you'd be duplicating the entire tree just to translate it. Xcode's String Catalog (`.xcstrings`) is the standard tool for exactly this: the tree holds stable *keys* ("story.boat_scene.body"), the catalog holds the actual text per language. Translating later is purely additive — you never touch the tree. It also gives you a clean, single home for VoiceOver accessibility labels (FR-11), which localize the same way.

## One shared "engine" object, not five ViewModels (AD-3)

The generic 2026 SwiftUI recipe is MVVM with one `@Observable` ViewModel per screen. But this app isn't five independent screens — it's **one run**, moving through five views. The current node, the locked choice history, and the alignment score all have to mean the same thing on every screen. Giving each screen its own ViewModel would just mean passing that same state between them anyway, so instead there's a single `StoryRunEngine` that owns it all, injected into every view. Screens only ever *ask* it to do something (`selectChoice`, `advancePage`, ...) — they never touch the state directly. This is the answer to "who's allowed to mutate the run" — it's always exactly one thing.

One nuance worth remembering: a choice card's press-and-hold animation and its tap-then-undo-window are **not** run state — they're just the view's own local, temporary "is this mid-interaction" flag. The engine only finds out about a choice once it's truly final. That's deliberate: if you force-quit the app mid-undo-window, nothing was ever committed, so relaunching just shows you the same undecided choice page again — no weird half-committed state to reconcile.

## Resuming a run: UserDefaults, not a database (AD-4)

The whole run's state — current position, choice history, score, a couple of flags — is maybe a kilobyte. That's precisely the case `UserDefaults` exists for; reaching for Core Data or SwiftData here would be solving a problem you don't have. It's one `Codable` struct, one key, written every time something changes (immediately, not batched — so nothing is ever lost to the OS killing the app in the background).

One thing worth remembering here: the snapshot only means "a run in progress." Once a run reaches its Ending, the snapshot gets cleared — otherwise Home would keep offering "Resume Story" pointing at a run that already finished.

## The story reader isn't a `NavigationStack` or a paging `TabView` (AD-5)

This was the least obvious call. iOS gives you two natural "swipe through screens" tools, and neither fits: `NavigationStack` assumes you're pushing/popping named screens (and fighting its default back-gesture chrome, which this app's design explicitly doesn't want). `TabView(.page)` assumes you already know the full list of pages up front — but your pages are **discovered as the player makes choices**; a run down one branch never even generates the other branch's pages, and there's no clean way to tell either container "block swiping forward until an external condition clears."

So instead: one reading view, and the engine owns "what node is showing right now" directly. A swipe or an invisible tap-zone is just a request to the engine ("try to advance") — the engine is the one that knows whether that's currently allowed. This also happens to be why hard-fail endings feel seamless: the engine doesn't have a special case for them, it just recognizes "the node I landed on is an Ending" and the screen shows Ending, immediately, the same way it would for any other node transition.

## Ending kind lives on the node, not in a score function (AD-6)

An earlier draft of this document (and the architecture it explains) had this section built around a `scoreToEnding` pure function — the idea being that a run's ending was *computed* by summing alignment deltas and checking the total against bands (Home 1-2, Stay 3-4, else Limbo). That turned out to be a misreading of the original design: those figures were never score thresholds. They were always meant as a content-authoring ratio — roughly 1-2 terminal nodes in the tree authored as "home" endings, 3-4 authored as "stay," and the rest (aside from hard-fail) as "limbo." The misunderstanding was self-consistent enough that a boundary-overlap "bug" (Home 1-2 and Stay 2-4 overlapping at score 2) got caught and fixed by hand during PRD writing — a bug that only existed because of the wrong mental model in the first place.

Once caught, the fix collapses the whole problem: since AD-1 already has every terminal node carry its `EndingKind` directly (home/stay/limbo/hard-fail), there's nothing left to compute. The engine doesn't sum anything to decide an ending — it just reads the `EndingKind` off whichever terminal node the player's path landed on. Alignment score still exists and still accumulates exactly as before (per choice, silently) — it just turned out to have a much smaller job than originally thought: it's a number for the Memory screen, full stop, with zero say in how the run actually resolves.

## Everything else

Illustrations use Xcode's asset-catalog code generation for the same reason the tree uses Swift instead of JSON — a typo'd illustration name becomes a compile error instead of a blank image at runtime. Testing leans on Swift Testing (the current default, not the older XCTest) for the engine's logic specifically — the UI itself is validated by hand and via VoiceOver, since that's what FR-11 actually asks for. And the whole thing ships as a single iPhone app target with no backend of any kind — the only real external dependency left is enrolling in the Apple Developer Program, which nothing here can do for you.
