import SwiftUI

struct HomeView: View {
    var body: some View {
        let hasInProgressRun = RunSnapshotPresence.hasInProgressRun()
        let primaryActionLabel: LocalizedStringKey = hasInProgressRun ? "home.action.resumeStory" : "home.action.startStory"

        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Spacing.large) {
                    VStack(spacing: Spacing.small) {
                        Text("home.appTitle")
                            .eyebrowStyle()

                        Text("home.storyTitle")
                            .headlineStyle()
                            .multilineTextAlignment(.center)

                        Text("home.storySubtitle")
                            .subtitleStyle()
                            .multilineTextAlignment(.center)
                            // Matches mockups/home.html's `.story-sub { max-width:280px }` — keeps
                            // the one-line blurb compact instead of stretching edge-to-edge on wide
                            // layouts (landscape, larger phones), unlike the full-bleed title above it.
                            .frame(maxWidth: LayoutMetrics.subtitleMaxWidth)
                    }

                    VStack(spacing: Spacing.medium) {
                        NavigationLink(value: HomeDestination.storyChoice) {
                            Text(primaryActionLabel)
                                .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
                        }
                        .buttonStyle(.primaryAction)

                        NavigationLink(value: HomeDestination.tutorial) {
                            Text("home.action.startTutorial")
                                .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
                        }
                        .buttonStyle(.secondaryAction)
                    }
                    // AD-8: geometry-only landscape constraint, no verticalSizeClass branch needed.
                    // Caps action-button width so they don't stretch edge-to-edge in a wide landscape
                    // frame. Also applies in portrait on the largest phones, narrowing the buttons
                    // somewhat there too — an accepted trade-off per AD-8, not a true no-op.
                    .frame(maxWidth: LayoutMetrics.actionStackMaxWidth)
                }
                .padding()
                // AD-8: explicit centering in both orientations, matching mockups/home-landscape.html's
                // centered-content treatment. `minHeight: proxy.size.height` (rather than
                // `maxHeight: .infinity`) ties centering to the ScrollView so content still centers
                // when it fits, but scrolls instead of clipping when Dynamic Type + reduced landscape
                // height push it past the available frame (AC #2).
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .background(Color.surfaceBase.ignoresSafeArea())
        }
    }
}

#Preview {
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
