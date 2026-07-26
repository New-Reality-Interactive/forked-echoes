import SwiftUI

struct HomeView: View {
    var body: some View {
        let hasInProgressRun = RunSnapshotPresence.hasInProgressRun()
        let primaryActionLabel: LocalizedStringKey = hasInProgressRun ? "home.action.resumeStory" : "home.action.startStory"

        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("home.appTitle")
                            .font(.subheadline)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)

                        Text("home.storyTitle")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 14) {
                        NavigationLink(value: HomeDestination.storyChoice) {
                            Text(primaryActionLabel)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink(value: HomeDestination.tutorial) {
                            Text("home.action.startTutorial")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                    // AD-8: geometry-only landscape constraint, no verticalSizeClass branch needed.
                    // Caps action-button width so they don't stretch edge-to-edge in a wide landscape
                    // frame. Also applies in portrait on the largest phones, narrowing the buttons
                    // somewhat there too — an accepted trade-off per AD-8, not a true no-op.
                    .frame(maxWidth: 320)
                }
                .padding()
                // AD-8: explicit centering in both orientations, matching mockups/home-landscape.html's
                // centered-content treatment. `minHeight: proxy.size.height` (rather than
                // `maxHeight: .infinity`) ties centering to the ScrollView so content still centers
                // when it fits, but scrolls instead of clipping when Dynamic Type + reduced landscape
                // height push it past the available frame (AC #2).
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
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
                    TutorialPlaceholderView()
                }
            }
    }
}
