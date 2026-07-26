import SwiftUI

// Stand-in for Home's "Start Tutorial" destination until Story 1.3 replaces it
// with the real Tutorial screen.
struct TutorialPlaceholderView: View {
    var body: some View {
        // AD-8: explicit centering in both orientations, matching the "every screen reflows,
        // nothing stretches/clips" invariant Home already follows. The real Tutorial screen's
        // landscape treatment (circuit frame, reading column, actions) is Story 1.3/1.4's job.
        // `ScrollView` + `minHeight: proxy.size.height` (rather than `maxHeight: .infinity`) keeps
        // this scrollable instead of clipping at large Dynamic Type sizes in landscape, where this
        // pushed destination has less available height than Home due to the NavigationStack back bar.
        GeometryReader { proxy in
            ScrollView {
                Text(verbatim: "Tutorial (placeholder)")
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
    }
}

#Preview {
    TutorialPlaceholderView()
}
