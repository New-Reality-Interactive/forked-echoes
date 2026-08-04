import SwiftUI

// Story 2.7 (UX-DR11, DESIGN.md components.run-options-button): shared by StoryChoiceView and
// TutorialView (the two surfaces that carry this control) rather than living under Views/
// StoryChoice/ — same DesignSystem/ home as ButtonStyles.swift/LayoutMetrics.swift, since both
// call sites need genuinely different "go home"/refresh behavior and shouldn't hardcode
// navigation here.
//
// Uses .confirmationDialog (not the deprecated ActionSheet type) — role: .destructive gives
// native destructive styling, VoiceOver announcement, and Dynamic Type support for free
// (EXPERIENCE.md Accessibility Floor: "no custom-built confirmation dialog").
//
// Story 2.12 (amends UX-DR11): starting in iOS 26, confirmationDialog/actionSheet presentations
// triggered from an ordinary button (not a UIBarButtonItem in a navigation bar) anchor to that
// button by default on iPhone — the same button-anchored popover-with-arrow style iPadOS has
// always used, not the pre-iOS-26 bottom-sliding sheet (confirmed via WWDC 2025 Session 284,
// "Build a UIKit app with the new design": "Starting in iOS 26, [action sheets] behave the same
// on iPhone [as iPad], appearing directly over the originating view"). This is intentional
// platform behavior, not a bug, and UX-DR11's "platform-native action sheet" now means this
// anchored-popover style for this app's non-nav-bar-anchored control.
//
// That popover-style presentation has always auto-suppressed any button with `role: .cancel`
// (documented UIAlertController behavior since iOS 8: tap-outside-to-dismiss already covers that
// case in a popover, so the system drops a redundant Cancel action) — which is why the sheet's
// intended "Cancel" row went missing. Fix: `cancelButtonRole` below is `nil` on iOS 26+ so the
// row survives, but `.cancel` on iOS 18-25 (this app's real deployment target, project-context.md)
// where confirmationDialog still renders as the bottom sheet and role: .cancel's native
// bold/separated styling and VoiceOver cancel trait are never suppressed — unconditionally
// dropping the role would needlessly regress that still-supported presentation.
struct RunOptionsButton: View {
    let onExitToHome: () -> Void
    let onRestartRun: () -> Void

    @State private var isPresentingOptions = false
    @State private var isPresentingRestartConfirmation = false

    private var cancelButtonRole: ButtonRole? {
        if #available(iOS 26, *) {
            return nil
        }
        return .cancel
    }

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
            Button("runOptions.cancel", role: cancelButtonRole) {}
        }
        .confirmationDialog(
            "runOptions.restartConfirmation.title",
            isPresented: $isPresentingRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("runOptions.restartRun", role: .destructive) {
                onRestartRun()
            }
            Button("runOptions.cancel", role: cancelButtonRole) {}
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
