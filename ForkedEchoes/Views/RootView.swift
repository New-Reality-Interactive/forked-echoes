import SwiftUI

// AD-5: NavigationStack is reserved for this coarse top-level flow
// (Home <-> Tutorial <-> Story session) and never wraps individual story pages.
enum HomeDestination: Hashable {
    case storyChoice
    case tutorial
}

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: HomeDestination.self) { destination in
                    switch destination {
                    case .storyChoice:
                        StoryChoicePlaceholderView()
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
