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

    // Story 2.8, AC #3: Reduce Motion routes a touch-down through the same tap-undo path
    // handleAccessibilityActivate() already uses for VoiceOver, instead of starting the animated
    // 3s charge — this keeps holding functionally equivalent to tapping under Reduce Motion (both
    // lock into the undo window immediately) rather than requiring a hold to complete a charge
    // that no longer visibly exists. Read per-view (AD-3: StoryRunEngine never touches
    // rendering/animation), not stored in or gated by the engine.
    //
    // Code review, 2026-08-02/03 — two rounds: (1) an early version called
    // lockAndStartUndoWindow() from touchDown()'s .idle case with no re-entrancy guard — broke on
    // the very next onChanged of the SAME continuous touch (chargeGesture's
    // DragGesture(minimumDistance: 0) fires onChanged repeatedly, not once), which landed on the
    // .tapAwaitingUndo case below (written for a genuinely new second touch) and canceled the
    // choice via resetToIdle() before the finger ever lifted. (2) The first fix routed through the
    // normal `.charging` state instead and let touchUp() classify tap-vs-hold on release — that
    // broke long-press commit entirely under Reduce Motion (user-confirmed via Simulator, 2026-08-03:
    // holding did nothing), since there is no timer to auto-finalize a sustained hold once the 3s
    // charge Task is skipped. Restored the immediate touch-down lock, guarded by
    // `hasLockedReduceMotionTouch` below so the SAME touch's repeated `onChanged` calls are a safe
    // no-op while a genuinely new touch (after this one's `onEnded`/touchUp() resets the flag)
    // still cancels via `.tapAwaitingUndo` as intended.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Story 2.8, AC #3 (see `reduceMotion`'s comment above): guards `.tapAwaitingUndo` in
    // `touchDown()` against the SAME continuous touch's own repeated `onChanged` callbacks under
    // Reduce Motion. Reset in `touchUp()`/`resetToIdle()`, never read outside this Reduce Motion
    // touch-down path.
    @State private var hasLockedReduceMotionTouch = false

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

    // Accessibility audit fix (Story 3.5, 2026-08-08): explicit LocalizedStringKey type
    // annotation on the property itself, per project-context.md's ternary/LocalizedStringKey
    // overload-resolution rule.
    private var accessibilityStateValue: LocalizedStringKey {
        showsCheckmark ? "storyChoice.choiceCard.state.selected" : "storyChoice.choiceCard.state.notSelected"
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
            .choiceLabelStyle()
            .frame(maxWidth: .infinity, minHeight: LayoutMetrics.minTapTarget, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .overlay(alignment: .trailing) {
                if showsCheckmark {
                    Image(systemName: "checkmark")
                        .padding(.trailing, Spacing.medium)
                } else if isInteractive {
                    // Code review, 2026-08-02: DESIGN.md `components.choice-card` — "...
                    // {typography.choice-label}, an arrow glyph trailing"; EXPERIENCE.md's Choice
                    // idle row: "Card shows text + arrow". No SF Symbol is named by either doc —
                    // chevron.right is a reasonable idle-state default, shown only while
                    // interactive (idle/charging), never alongside the checkmark or once decided.
                    Image(systemName: "chevron.right")
                        .padding(.trailing, Spacing.medium)
                }
            }
            // DESIGN.md `components.choice-card.charge-fill-color` = trace-brass, mid-charge; the
            // selected/checkmark state keeps Color.selectedFill (already correct — leave as-is).
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    (showsCheckmark ? Color.selectedFill : Color.traceBrass)
                        .opacity(showsCheckmark ? 1 : 0.6)
                        .frame(width: proxy.size.width * (showsCheckmark ? 1 : chargeProgress))
                }
            }
            // DESIGN.md `components.choice-card`: surface-raised base background, behind the
            // charge-fill/selected-fill layer above.
            .background(Color.surfaceRaised)
            // DESIGN.md `components.choice-card.border-width` = 3pt, ink-primary.
            .overlay(Rectangle().stroke(Color.inkPrimary, lineWidth: LayoutMetrics.choiceCardBorderWidth))
            .contentShape(Rectangle())
            .opacity(isDecided && !isSelected ? ButtonMetrics.disabledOpacity : 1)
            .allowsHitTesting(isInteractive)
            .highPriorityGesture(chargeGesture)
            // Accessibility audit fix (Story 3.5, 2026-08-08): without this, the checkmark/chevron
            // `Image` overlays above surface as their OWN separate accessibility elements (each
            // sized to its own tiny glyph bounds, e.g. 7x12) instead of being absorbed into this
            // card's single element — confirmed via a live Xcode Accessibility Inspector Audit
            // pass, which flagged both the label Text (143x17, NOT the full 44pt-tall `.frame()`
            // above) and the chevron glyph as independent "hit area too small" violations (NFR6).
            // Applying `.accessibilityAddTraits`/`.accessibilityHint`/`.accessibilityAction` alone
            // does NOT implicitly collapse sibling `.overlay` content into one element — only
            // `.accessibilityElement(children:)` does that. `.ignore` makes this fully-composed
            // view (already `.frame(minHeight: 44)` above) the sole accessibility element, so its
            // reported hit area matches the real 44pt+ visual card, and the icons stop appearing
            // as separate audit-flagged elements entirely.
            .accessibilityElement(children: .ignore)
            // `.ignore` above means the label is no longer inherited from the inner `Text` —
            // set explicitly, same key the visible `Text` at the top of this view uses.
            .accessibilityLabel(Text(LocalizedStringKey(option.labelKey)))
            // Restores EXPERIENCE.md's Accessibility Floor example ("...not yet selected" /
            // "...selected, double-tap again...") — previously never implemented as an explicit
            // value, only implied by the now-ignored checkmark icon's default SF Symbol label.
            .accessibilityValue(Text(accessibilityStateValue))
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
            // Story 2.8, AC #3: under Reduce Motion, lock straight into the tap-undo path —
            // matching handleAccessibilityActivate()'s VoiceOver shape — instead of starting the
            // animated 3s charge. hasLockedReduceMotionTouch (reset in touchUp()) makes this
            // idempotent for the SAME continuous touch's own repeated onChanged callbacks, which
            // would otherwise fall through to the .tapAwaitingUndo case below and be misread as a
            // second, distinct touch canceling the choice before the finger ever lifts.
            guard !reduceMotion else {
                hasLockedReduceMotionTouch = true
                lockAndStartUndoWindow()
                return
            }

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
            // is purely local state reverting. hasLockedReduceMotionTouch distinguishes that from
            // this SAME touch's own repeated onChanged calls immediately after the Reduce Motion
            // lock above (see that case's comment) — ignore those instead of canceling.
            guard !hasLockedReduceMotionTouch else { return }
            resetToIdle()

        case .charging, .finalized:
            break
        }
    }

    private func touchUp(translation: CGSize) {
        // Story 2.8, AC #3: clears the Reduce Motion re-entrancy guard as soon as this touch ends
        // — unconditionally, since under Reduce Motion localState is already .tapAwaitingUndo (not
        // .charging) by the time onEnded fires, so the guard below returns early without reaching
        // any of the logic that would otherwise reset it.
        hasLockedReduceMotionTouch = false

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
        // Story 2.8, AC #3: any reset to idle (VoiceOver's second-activation cancel above, a
        // sibling card stealing activeOptionID via onChange below) should also clear this so a
        // future Reduce Motion touch on this card starts from a clean slate.
        hasLockedReduceMotionTouch = false
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
        option: ChoiceOption(id: .boat, labelKey: "story.firstChoice.choice.1", consequenceKey: "story.firstChoice.choice.1.consequence", alignmentDelta: 1, target: .endingHomeward),
        isDecided: false,
        isSelected: false,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}

#Preview("Selected/locked") {
    ChoiceCardView(
        option: ChoiceOption(id: .boat, labelKey: "story.firstChoice.choice.1", consequenceKey: "story.firstChoice.choice.1.consequence", alignmentDelta: 1, target: .endingHomeward),
        isDecided: true,
        isSelected: true,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}

#Preview("Decided, not selected") {
    ChoiceCardView(
        option: ChoiceOption(id: .shore, labelKey: "story.firstChoice.choice.2", consequenceKey: "story.firstChoice.choice.2.consequence", alignmentDelta: -1, target: .endingElsewhere),
        isDecided: true,
        isSelected: false,
        activeOptionID: .constant(nil),
        onFinalize: { _ in }
    )
    .padding()
}
