import SwiftUI
import UIKit

// AD-8 cold-launch fix: if the device was already rotated before the app launched,
// SwiftUI's first layout pass can settle on the wrong orientation before UIKit's window
// bounds catch up. This does a single, one-shot read of the authoritative window scene
// orientation at appear and forces exactly one corrective re-layout if it disagrees with
// what the environment's `verticalSizeClass` produced — never `UIDevice.orientation`/
// `NotificationCenter` (AD-8 bans those as persistent structural signals).
//
// Epic 2's reading surface (Story 2.1/2.2) must NOT reuse `.id(layoutGeneration)` as-is:
// bumping it forces a full subtree teardown/rebuild, discarding all nested `@State`. Home/
// Tutorial have no meaningful child state today so this is harmless here, but the reading
// surface will have real state to lose (pager position, in-flight choice-hold gesture).
// Before reuse, either scope the `.id()` to a state-free wrapper layer, or replace this
// mechanism with something that corrects layout without discarding descendant state.
private struct ColdLaunchOrientationFix: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var hasAttemptedCorrection = false
    @State private var layoutGeneration = 0

    func body(content: Content) -> some View {
        content
            .id(layoutGeneration)
            .onAppear(perform: correctIfNeeded)
    }

    private func correctIfNeeded() {
        guard !hasAttemptedCorrection else { return }

        guard
            let trueOrientation = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?
                .interfaceOrientation,
            trueOrientation != .unknown
        else { return }

        hasAttemptedCorrection = true

        let layoutThinksLandscape = verticalSizeClass == .compact
        guard trueOrientation.isLandscape != layoutThinksLandscape else { return }

        layoutGeneration += 1
    }
}

extension View {
    /// Corrects a stale cold-launch layout pass (see `ColdLaunchOrientationFix`) by forcing
    /// exactly one re-layout if the true launch orientation disagrees with the first pass.
    func correctColdLaunchOrientation() -> some View {
        modifier(ColdLaunchOrientationFix())
    }
}
