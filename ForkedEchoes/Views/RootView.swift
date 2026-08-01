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
    // screen below Home in the navigation stack.
    @State private var engine = StoryRunEngine()

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
        .fullScreenCover(isPresented: $isPresentingStorySession) {
            StoryChoiceView(onExitToHome: {
                navigationPath = NavigationPath()
                isPresentingStorySession = false
            })
            .environment(engine)
        }
    }
}

#Preview {
    RootView()
}
