import SwiftUI

struct TutorialView: View {
    // AD-5: the Story session is a full-screen modal presented from RootView, not a
    // NavigationStack push -- this button just flips the shared binding, RootView owns the
    // .fullScreenCover(isPresented:) itself.
    @Binding var isPresentingStorySession: Bool

    // Code review, 2026-08-01: shared with HomeView via RootView's `.environment(_:)` (AD-3
    // pattern) rather than each view owning its own instance. Refreshed via `.onAppear` below
    // rather than read as a plain `let` in `body` — see RunProgressObserver's doc comment for why
    // (UserDefaults isn't SwiftUI-observed, so a `let` here could go stale after returning from
    // the Story session).
    @Environment(RunProgressObserver.self) private var runProgress

    var body: some View {
        let primaryActionLabel: LocalizedStringKey = runProgress.hasInProgressRun ? "home.action.resumeStory" : "tutorial.action.startStory"

        VStack(spacing: Spacing.large) {
            GeometryReader { proxy in
                ScrollView {
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
                    // AD-8 / Story 5.3 pattern: `minHeight: proxy.size.height` (rather than
                    // `maxHeight: .infinity`) centers the text block alone when it's short enough
                    // to fit, but scrolls instead of clipping when Dynamic Type + landscape's
                    // reduced height push it past the frame. No `Spacer` anywhere in this pattern
                    // — a `Spacer` here would measure as zero/minLength during layout and can
                    // push content out of the reachable area (Story 1.3's shipped landscape bug).
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }

            // Story 2.11: the action button is a sibling of the ScrollView, not inside it — this
            // is what keeps it fixed and always reachable without scrolling, regardless of how
            // much mechanics copy is above it or how large Dynamic Type has grown. A ScrollView
            // given flexible sizing as a sibling of a fixed-size button in this outer VStack
            // doesn't have the same "Spacer measures as zero" failure mode as a Spacer placed
            // inside the ScrollView's own content.
            Button {
                isPresentingStorySession = true
            } label: {
                Text(primaryActionLabel)
                    .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget)
            }
            .buttonStyle(.primaryAction)
            // AD-8: geometry-only landscape constraint, matches HomeView's action-cap pattern
            // so the action button doesn't stretch edge-to-edge in a wide landscape frame.
            .frame(maxWidth: LayoutMetrics.actionStackMaxWidth)
        }
        .padding()
        .background(Color.surfaceBase.ignoresSafeArea())
        .correctColdLaunchOrientation()
        .onAppear { runProgress.refresh() }
    }
}

#Preview {
    NavigationStack {
        TutorialView(isPresentingStorySession: .constant(false))
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .tutorial:
                    TutorialView(isPresentingStorySession: .constant(false))
                }
            }
    }
    .environment(RunProgressObserver())
}
