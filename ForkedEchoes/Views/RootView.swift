import SwiftUI

// AD-5 (amended 2026-07-31, Story 2.2): NavigationStack is reserved for Home <-> Tutorial's
// back-and-forth wayfinding only — it never wraps individual story pages. The Story session used
// to be one more NavigationStack destination here too, but a NavigationStack push always carries
// a system back button and an interactivePopGestureRecognizer swipe gesture, and Simulator testing
// showed the latter wins unconditionally over the Story session's own swipe-left/right page-turn
// gesture (Story 2.2) -- not just at the screen edge. See ARCHITECTURE-SPINE.md#AD-5 for the full
// rationale.
enum HomeDestination: Hashable {
    case tutorial
}

struct RootView: View {
    // AD-3: single StoryRunEngine instance, owned here and injected via @Environment for every
    // screen below Home in the navigation stack. Story 2.4: cold launch attempts to resume a
    // persisted RunSnapshot, falling back to a fresh run at StoryTree.root on any decode failure.
    @State private var engine = StoryRunEngine.resumingFromSnapshot()

    // Code review, 2026-08-01: a single shared instance injected via `@Environment`, same pattern
    // as `engine` above (AD-3) — Home and Tutorial previously each held their own independent
    // `RunProgressObserver`, which worked but was an inconsistent DRY violation against the one
    // other piece of shared observable state this app has.
    @State private var runProgress = RunProgressObserver()

    // AD-5: the Story session is a full-screen modal presentation, not a NavigationStack push --
    // see the enum comment above. Its only sanctioned dismissal is a deliberate action (Memory's
    // "Return Home", or a mid-run "Exit to Home" via Story 2.7's run-options sheet) -- for now,
    // code review's temporary "Exit to Home" button (StoryChoiceView.swift).
    @State private var isPresentingStorySession = false

    // Code review, 2026-08-01: the Story session can be launched from Home *or* Tutorial (both
    // sit under this one NavigationStack), so its temporary exit button needs to be able to pop
    // back to Home regardless of which one it was launched from -- not just dismiss the
    // fullScreenCover and reveal whatever the stack happened to be showing underneath. Owning
    // the path here, rather than each screen managing its own dismissal, is what lets one
    // closure (below) reset both the modal and the stack together.
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(isPresentingStorySession: $isPresentingStorySession)
                .navigationDestination(for: HomeDestination.self) { destination in
                    switch destination {
                    case .tutorial:
                        TutorialView(isPresentingStorySession: $isPresentingStorySession)
                    }
                }
        }
        .environment(runProgress)
        // Story 2.7: also applied to the whole NavigationStack now (previously only inside the
        // fullScreenCover below), so TutorialView (which now needs StoryRunEngine for its own
        // run-options control) can see it too.
        //
        // User-confirmed bug, 2026-08-02: this NavigationStack-level application does NOT, in
        // practice, propagate into the fullScreenCover's content closure below — contrary to this
        // story's original assumption ("SwiftUI environment values propagate from a presenting
        // view into its modally-presented content by default"). Real Xcode/Simulator testing
        // showed the opposite: StoryChoiceView crashed with "No Observable object of type
        // StoryRunEngine found" the moment "Start Story" presented it, because the explicit
        // `.environment(engine)` that used to sit directly inside the fullScreenCover closure had
        // been removed on the assumption it was now redundant. It wasn't. Both applications are
        // needed: this one for Home/Tutorial, and the one inside the closure below for the Story
        // session — a fullScreenCover's content, at least as this app's SwiftUI version resolves
        // it, only inherits environment values from its presenting view's environment at the
        // *call site* the modifier is attached to, not modifiers applied earlier in the same
        // chain to the view the modifier decorates.
        .environment(engine)
        .fullScreenCover(isPresented: $isPresentingStorySession) {
            StoryChoiceView(onExitToHome: {
                navigationPath = NavigationPath()
                isPresentingStorySession = false
            })
            .environment(engine)
        }
        // User-confirmed bug, 2026-08-01: HomeView/TutorialView's own `.onAppear` refresh does
        // NOT reliably fire when this fullScreenCover dismisses back to them (confirmed: it does
        // fire on NavigationStack push/pop between Home and Tutorial, but not on cover dismissal)
        // — contradicting the assumption the earlier RunProgressObserver fix relied on. RootView
        // owns `isPresentingStorySession` directly and knows the exact moment the session ends,
        // so this is the deterministic fix: refresh whenever it flips to false, regardless of
        // which button/path caused the dismissal.
        //
        // User-confirmed bug, 2026-08-01 (same session): tapping "Start Story" after a run ended
        // re-presented the same finished run — `engine.startFreshRunIfCurrentRunHasEnded()` is a
        // no-op mid-run, so this only resets when the label actually read "Start Story."
        .onChange(of: isPresentingStorySession) { _, isPresenting in
            if isPresenting {
                engine.startFreshRunIfCurrentRunHasEnded()
            } else {
                runProgress.refresh()
            }
        }
    }
}

#Preview {
    RootView()
}
