import SwiftUI

// Story 2.7 (UX-DR11, DESIGN.md components.run-options-button): shared by StoryChoiceView and
// TutorialView (the two surfaces that carry this control) rather than living under Views/
// StoryChoice/ — same DesignSystem/ home as ButtonStyles.swift/LayoutMetrics.swift, since both
// call sites need genuinely different "go home"/refresh behavior and shouldn't hardcode
// navigation here.
//
// Uses .confirmationDialog (not the deprecated ActionSheet type) — still renders as a native
// action sheet on iPhone, matching UX-DR11's "platform-native action sheet" wording. role:
// .destructive/.cancel give native destructive styling, VoiceOver announcement, and Dynamic Type
// support for free (EXPERIENCE.md Accessibility Floor: "no custom-built confirmation dialog").
struct RunOptionsButton: View {
    let onExitToHome: () -> Void
    let onRestartRun: () -> Void

    @State private var isPresentingOptions = false
    @State private var isPresentingRestartConfirmation = false

    var body: some View {
        Button {
            isPresentingOptions = true
        } label: {
            Image(systemName: "ellipsis.circle")
                .frame(minWidth: LayoutMetrics.minTapTarget, minHeight: LayoutMetrics.minTapTarget)
                .contentShape(Rectangle())
        }
        // DESIGN.md's run-options-button token specifies {colors.trace-brass} idle / {colors.ink-
        // primary} pressed — no TraceBrass color set exists yet (confirmed contents: AccentColor,
        // InkPrimary, InkSecondary, SelectedFill, SurfaceBase). Placeholder-color-reuse precedent
        // (Stories 2.3/2.5/2.6/2.9): Color.inkPrimary stands in for now; Story 2.8 owns the real
        // DESIGN.md palette pass for every Epic 2 reading-surface component at once.
        .foregroundStyle(Color.inkPrimary)
        .padding(Spacing.small)
        .accessibilityLabel(Text("storyChoice.runOptions.accessibilityLabel"))
        .confirmationDialog("storyChoice.runOptions.accessibilityLabel", isPresented: $isPresentingOptions, titleVisibility: .hidden) {
            Button("storyChoice.runOptions.exitToHome") {
                onExitToHome()
            }
            Button("storyChoice.runOptions.restartRun", role: .destructive) {
                isPresentingRestartConfirmation = true
            }
            Button("storyChoice.runOptions.cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "storyChoice.runOptions.restartConfirmation.title",
            isPresented: $isPresentingRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("storyChoice.runOptions.restartRun", role: .destructive) {
                onRestartRun()
            }
            Button("storyChoice.runOptions.cancel", role: .cancel) {}
        }
    }
}

#Preview {
    RunOptionsButton(onExitToHome: {}, onRestartRun: {})
}
