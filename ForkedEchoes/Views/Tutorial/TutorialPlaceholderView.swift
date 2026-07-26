import SwiftUI

// Stand-in for Home's "Start Tutorial" destination until Story 1.3 replaces it
// with the real Tutorial screen.
struct TutorialPlaceholderView: View {
    var body: some View {
        Text(verbatim: "Tutorial (placeholder)")
    }
}

#Preview {
    TutorialPlaceholderView()
}
