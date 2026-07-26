import SwiftUI

struct HomeView: View {
    var body: some View {
        let hasInProgressRun = RunSnapshotPresence.hasInProgressRun()
        let primaryActionLabel: LocalizedStringKey = hasInProgressRun ? "home.action.resumeStory" : "home.action.startStory"

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
        }
        .padding()
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
