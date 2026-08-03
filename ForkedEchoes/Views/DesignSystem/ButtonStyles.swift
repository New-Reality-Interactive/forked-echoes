import SwiftUI

// Primary/secondary action button treatment for Home/Tutorial, per mockups/home.html's
// .btn-primary/.btn-secondary. Sharp corners only (DESIGN.md Shapes: `{rounded.DEFAULT}` = 0px
// everywhere in the reading UI) — deliberately not `.buttonStyle(.borderedProminent)`/`.bordered`,
// whose iOS 26 default shape is rounded.
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.heavy)
            .foregroundStyle(Color.inkPrimary)
            .background(Color.selectedFill)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? ButtonMetrics.pressedOpacity : 1) : ButtonMetrics.disabledOpacity)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.heavy)
            .foregroundStyle(Color.inkPrimary)
            .overlay(Rectangle().stroke(Color.inkPrimary, lineWidth: ButtonMetrics.borderWidth))
            // Background is otherwise fully transparent (border-only) — an explicit content
            // shape ensures the whole 44pt frame stays tappable, not just the stroke pixels.
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? ButtonMetrics.pressedOpacity : 1) : ButtonMetrics.disabledOpacity)
    }
}

// DESIGN.md `components.continue-button`: selected-fill background, surface-inverse text,
// uppercase — differs from PrimaryActionButtonStyle (selected-fill bg, ink-primary text, no
// uppercase), which Home/Tutorial's CTAs deliberately keep as-is. A dedicated style rather than
// parameterizing PrimaryActionButtonStyle, since only this one call site (the branch-arrival
// interstitial's Continue button) needs this color/case combination (Story 2.8).
struct ContinueActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.heavy)
            .textCase(.uppercase)
            .foregroundStyle(Color.surfaceInverse)
            .background(Color.selectedFill)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? ButtonMetrics.pressedOpacity : 1) : ButtonMetrics.disabledOpacity)
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle { PrimaryActionButtonStyle() }
}

extension ButtonStyle where Self == ContinueActionButtonStyle {
    static var continueAction: ContinueActionButtonStyle { ContinueActionButtonStyle() }
}

extension ButtonStyle where Self == SecondaryActionButtonStyle {
    static var secondaryAction: SecondaryActionButtonStyle { SecondaryActionButtonStyle() }
}
