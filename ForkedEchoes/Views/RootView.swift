import SwiftUI

// AD-5: NavigationStack is reserved for this coarse top-level flow
// (Home <-> Tutorial <-> Story session) and never wraps individual story pages.
enum HomeDestination: Hashable {
    case storyChoice
    case tutorial
}

struct RootView: View {
    // AD-3: single StoryRunEngine instance, owned here and injected via @Environment for every
    // screen below Home in the navigation stack.
    @State private var engine = StoryRunEngine()

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: HomeDestination.self) { destination in
                    switch destination {
                    case .storyChoice:
                        StoryChoiceView()
                            .environment(engine)
                    case .tutorial:
                        TutorialView()
                    }
                }
        }
    }
}

#Preview {
    RootView()
}
