import SwiftUI

// Story 2.3: a single choice card, supporting press-and-hold (charge over
// LayoutMetrics.choiceChargeDuration) and quick-tap-then-undo-window (LayoutMetrics.choiceUndoWindow)
// commit paths. Presentation-only — never calls engine.selectChoice(_:) directly; StoryChoiceView
// owns that call via onFinalize (AD-3).
//
// RESOLVED CONFLICT (2026-08-01, see the story file's Acceptance Criteria section for full context):
// onFinalize fires only at true finalization — hold-complete, or tap-undo-window-elapsed-without-
// cancel — never eagerly at touch-down/tap. This means engine.choiceHistory never contains an entry
// for the current node while a charge or undo window is still in flight, so StoryChoiceView's
// decided-page check (engine.choiceHistory-driven) never needs to special-case "reconsiderable."
struct ChoiceCardView: View {
    let option: ChoiceOption
    let isDecided: Bool
    let isSelected: Bool
    @Binding var activeOptionID: ChoiceOptionID?
    let onFinalize: (ChoiceOptionID) -> Void

    private enum LocalState: Equatable {
        case idle
        case charging
        case tapAwaitingUndo
        case finalized
    }

    @State private var localState: LocalState = .idle
    @State private var chargeProgress: CGFloat = 0
    @State private var pendingTask: Task<Void, Never>?
    @State private var touchDownDate: Date?

    // Not decided elsewhere, not finalized locally. Deliberately does NOT check whether a
    // sibling is currently active — AC #1 ("holding a second cancels the first") requires a
    // touch on this card to reach touchDown() even while a sibling is charging/awaiting-undo,
    // so it can reassign activeOptionID and trigger the sibling's own onChange(of:)-driven
    // cancel below. Pre-blocking hit-testing here would make that reassignment unreachable
    // (code-review finding, 2026-08-01: the original gate made AC #1 structurally impossible).
    private var isInteractive: Bool {
        !isDecided && localState != .finalized
    }

    private var showsCheckmark: Bool {
        isSelected || localState == .tapAwaitingUndo
    }

    private var accessibilityHint: LocalizedStringKey? {
        if localState == .tapAwaitingUndo {
            return "storyChoice.choiceCard.hint.undoWindow"
        } else if isInteractive {
            return "storyChoice.choiceCard.hint.tapOrHold"
        } else {
            return nil
        }
    }

    var body: some View {
        Text(LocalizedStringKey(option.labelKey))
            .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .overlay(alignment: .trailing) {
                if showsCheckmark {
                    Image(systemName: "checkmark")
                        .padding(.trailing, Spacing.medium)
                }
            }
            // Minimum-viable committed/charging feedback reusing Color.selectedFill
            // (already used by PrimaryActionButtonStyle for its own, unrelated filled-button
            // look — intentional asset reuse, not a collision; DESIGN.md's full choice-card
            // token set — surface-raised/ink-primary border/trace-brass charge fill — needs new
            // Color Set assets that don't exist yet and is Story 2.8's scope).
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    Color.selectedFill
                        .opacity(showsCheckmark ? 1 : 0.6)
                        .frame(width: proxy.size.width * (showsCheckmark ? 1 : chargeProgress))
                }
            }
            .contentShape(Rectangle())
            .opacity(isDecided && !isSelected ? ButtonMetrics.disabledOpacity : 1)
            .allowsHitTesting(isInteractive)
            .highPriorityGesture(chargeGesture)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, handleAccessibilityActivate)
            // .map(Text.init), not a closure, resolves Text's generic StringProtocol overload
            // instead of the LocalizedStringKey one for a bare function reference — the same
            // overload-resolution pitfall project-context.md's Localization section documents
            // for ternary-selected keys elsewhere in this file's sibling view.
            .accessibilityHint(accessibilityHint.map { Text($0) } ?? Text(""))
            .onChange(of: activeOptionID) { _, newValue in
                // localState != .finalized guard: finalize() below clears activeOptionID as
                // part of committing, which would otherwise trigger this same onChange and
                // stomp the just-set .finalized state back to .idle.
                if newValue != option.id && localState != .finalized {
                    resetToIdle()
                }
            }
            .onDisappear {
                // Code-review finding, 2026-08-01: an in-flight charge/undo-window Task is not
                // structured concurrency tied to this view's lifetime — without an explicit
                // cancel here it survives navigating away mid-interaction and can later call
                // onFinalize() against whatever choice node happens to be current by then.
                pendingTask?.cancel()
            }
    }

    // Both press-and-hold and quick-tap are handled by this single DragGesture(minimumDistance: 0)
    // — not LongPressGesture(minimumDuration:), which fires only once at completion and can't drive
    // a continuously animating charge-fill, and not a separate .onTapGesture, which was tried first
    // and found (via Simulator testing, 2026-08-01) to never fire at all: a high-priority
    // zero-distance DragGesture matches every touch, including a quick tap, so it always wins and
    // consumes the touch before a co-attached .onTapGesture ever sees it. Instead, a single touch's
    // total contact duration (measured, not animation-linked) classifies it as a tap or a released
    // hold in touchUp(). Attached via .highPriorityGesture so it wins over StoryChoiceView's
    // page-turn DragGesture (Story 2.2) whenever a touch starts on this card.
    private var chargeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in touchDown() }
            .onEnded { value in touchUp(translation: value.translation) }
    }

    private func touchDown() {
        guard isInteractive else { return }

        switch localState {
        case .idle:
            activeOptionID = option.id
            localState = .charging
            touchDownDate = Date()
            withAnimation(.linear(duration: LayoutMetrics.choiceChargeDuration.timeInterval)) {
                chargeProgress = 1
            }
            pendingTask?.cancel()
            pendingTask = Task { @MainActor in
                try? await Task.sleep(for: LayoutMetrics.choiceChargeDuration)
                guard !Task.isCancelled, localState == .charging else { return }
                finalize()
            }

        case .tapAwaitingUndo:
            // A second touch while the undo window is open: full cancel. selectChoice(_:) never
            // fired (RESOLVED CONFLICT), so there is nothing to undo at the engine layer — this
            // is purely local state reverting.
            resetToIdle()

        case .charging, .finalized:
            break
        }
    }

    private func touchUp(translation: CGSize) {
        // Fires on every touch-up. A completed charge has already moved localState to .finalized
        // by the time this runs (the Task-based timer, not this gesture callback, drives that) —
        // only a still-.charging state here means the touch is actually ending mid-interaction.
        guard localState == .charging else { return }

        let heldDuration = Date().timeIntervalSince(touchDownDate ?? .now)
        // Code-review finding, 2026-08-01: classifying purely by duration let a fast swipe
        // starting on this card (this view's .highPriorityGesture wins any touch that starts
        // here, so StoryChoiceView's own page-turn gesture never sees it) get misread as a
        // "quick tap" and lock/commit a choice the player meant as a page turn. Reuses
        // LayoutMetrics.pageSwipeThreshold, the same distance StoryChoiceView's pageTurnGesture
        // treats as "this was a swipe, not a tap."
        let travelDistance = max(abs(translation.width), abs(translation.height))
        pendingTask?.cancel()
        pendingTask = nil
        withAnimation { chargeProgress = 0 }

        if heldDuration < LayoutMetrics.choiceTapMaxHoldDuration.timeInterval
            && travelDistance < LayoutMetrics.pageSwipeThreshold {
            lockAndStartUndoWindow()
        } else {
            // Held past the tap threshold, or moved too far to be a tap: cancel.
            localState = .idle
            if activeOptionID == option.id {
                activeOptionID = nil
            }
        }
    }

    // VoiceOver's double-tap-to-activate bypasses this view's raw DragGesture entirely (it drives
    // .accessibilityAction, not the touch pipeline) — map it to the same quick-tap-then-undo-window
    // semantics as a fast touchUp(), and to the same second-activation-cancels semantics as
    // touchDown()'s .tapAwaitingUndo case, rather than the 3s hold path (VoiceOver users can't
    // reliably sustain a hold via double-tap).
    private func handleAccessibilityActivate() {
        guard isInteractive else { return }

        switch localState {
        case .idle:
            lockAndStartUndoWindow()
        case .tapAwaitingUndo:
            resetToIdle()
        case .charging, .finalized:
            break
        }
    }

    private func lockAndStartUndoWindow() {
        activeOptionID = option.id
        localState = .tapAwaitingUndo
        pendingTask?.cancel()
        pendingTask = Task { @MainActor in
            try? await Task.sleep(for: LayoutMetrics.choiceUndoWindow)
            guard !Task.isCancelled, localState == .tapAwaitingUndo else { return }
            finalize()
        }
    }

    private func resetToIdle() {
        pendingTask?.cancel()
        pendingTask = nil
        localState = .idle
        chargeProgress = 0
        if activeOptionID == option.id {
            activeOptionID = nil
        }
    }

    private func finalize() {
        pendingTask = nil
        localState = .finalized
        // Code-review finding, 2026-08-01: leaving activeOptionID pointing at this option after
        // finalization let a *future* choice node reusing the same ChoiceOptionID inherit this
        // stale claim, since ChoiceOptionID is shared across all choice nodes (StoryNode.swift),
        // not scoped per-node.
        if activeOptionID == option.id {
            activeOptionID = nil
        }
        onFinalize(option.id)
    }
}

#Preview("Idle") {
    ChoiceCardView(
        option: ChoiceOption(id: .boat, labelKey: "story.firstChoice.choice.1", alignmentDelta: 1, target: .endingHomeward),
        isDecided: false,
        isSelected: false,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}

#Preview("Selected/locked") {
    ChoiceCardView(
        option: ChoiceOption(id: .boat, labelKey: "story.firstChoice.choice.1", alignmentDelta: 1, target: .endingHomeward),
        isDecided: true,
        isSelected: true,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}

#Preview("Decided, not selected") {
    ChoiceCardView(
        option: ChoiceOption(id: .shore, labelKey: "story.firstChoice.choice.2", alignmentDelta: -1, target: .endingElsewhere),
        isDecided: true,
        isSelected: false,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}
