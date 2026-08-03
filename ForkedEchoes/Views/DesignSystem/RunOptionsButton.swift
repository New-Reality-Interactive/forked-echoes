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
        // DESIGN.md `components.run-options-button`: trace-brass idle, ink-primary pressed.
        .buttonStyle(RunOptionsButtonStyle())
        .padding(Spacing.small)
        .accessibilityLabel(Text("runOptions.accessibilityLabel"))
        // Code review, 2026-08-02 (UX-DR12): VoiceOver's default traversal order follows visual
        // layout, and this button sits top-trailing — first in reading order, not last. A negative
        // sort priority (default is 0 for every other element in this composition) pushes it to
        // the end of the traversal, after eyebrow -> prose -> choices -> pager, per UX-DR12.
        .accessibilitySortPriority(-1)
        .confirmationDialog("runOptions.accessibilityLabel", isPresented: $isPresentingOptions, titleVisibility: .hidden) {
            Button("runOptions.exitToHome") {
                onExitToHome()
            }
            Button("runOptions.restartRun", role: .destructive) {
                isPresentingRestartConfirmation = true
            }
            Button("runOptions.cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "runOptions.restartConfirmation.title",
            isPresented: $isPresentingRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("runOptions.restartRun", role: .destructive) {
                onRestartRun()
            }
            Button("runOptions.cancel", role: .cancel) {}
        }
    }
}

// DESIGN.md `components.run-options-button`: trace-brass idle, ink-primary pressed. A dedicated
// ButtonStyle (rather than @GestureState/@State press-tracking) mirrors ButtonStyles.swift's
// sibling styles for a single-glyph icon button — the least code for this one small control.
private struct RunOptionsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Color.inkPrimary : Color.traceBrass)
    }
}

#Preview {
    RunOptionsButton(onExitToHome: {}, onRestartRun: {})
}
