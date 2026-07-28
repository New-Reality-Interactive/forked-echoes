import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let hasInProgressRun = RunSnapshotPresence.hasInProgressRun()
        let primaryActionLabel: LocalizedStringKey = hasInProgressRun ? "home.action.resumeStory" : "tutorial.action.startStory"

        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("tutorial.eyebrow")
                            .eyebrowStyle()

                        Text("tutorial.mechanic.pageTurn")
                            .bodyStyle()

                        Text("tutorial.mechanic.choice")
                            .bodyStyle()

                        Text("tutorial.mechanic.echo")
                            .bodyStyle()
                    }
                    // AD-8: reading surfaces (Tutorial included, per DESIGN.md) cap their column
                    // width in landscape rather than stretching edge-to-edge; 680pt matches the
                    // reading-surface column-max-width-landscape value in ARCHITECTURE-SPINE.md.
                    // Text stays left-aligned within the capped column, but the column itself
                    // centers in extra-wide landscape frames (DESIGN.md: "extra width becomes
                    // side margin"), so this inner frame keeps `.leading` and the outer one does
                    // not.
                    .frame(maxWidth: LayoutMetrics.readingColumnMaxWidthLandscape, alignment: .leading)
                    .frame(maxWidth: .infinity)

                    VStack(spacing: Spacing.medium) {
                        Button {
                            dismiss()
                        } label: {
                            Text("tutorial.action.backHome")
                                .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
                        }
                        .buttonStyle(.secondaryAction)

                        NavigationLink(value: HomeDestination.storyChoice) {
                            Text(primaryActionLabel)
                                .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
                        }
                        .buttonStyle(.primaryAction)
                    }
                    // AD-8: geometry-only landscape constraint, matches HomeView's action-cap pattern
                    // so the action stack doesn't stretch edge-to-edge in a wide landscape frame.
                    .frame(maxWidth: LayoutMetrics.actionStackMaxWidth)
                }
                .padding()
                // AD-8 / Story 5.3 pattern: `minHeight: proxy.size.height` (rather than
                // `maxHeight: .infinity`) centers the whole content block (text + actions) as a
                // single group when it fits, but scrolls instead of clipping when Dynamic Type +
                // landscape's reduced height (this pushed destination has less available height
                // than Home due to the NavigationStack back bar) push it past the frame. No
                // `Spacer` between text and actions — a `Spacer` here would measure as zero/
                // minLength during layout and can push "Start Story" out of the reachable area.
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .background(Color.surfaceBase.ignoresSafeArea())
        }
        .correctColdLaunchOrientation()
    }
}

#Preview {
    NavigationStack {
        TutorialView()
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
