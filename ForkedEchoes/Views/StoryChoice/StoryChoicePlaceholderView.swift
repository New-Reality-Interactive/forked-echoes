import SwiftUI

// Stand-in for Home's "Start Story"/"Resume Story" destination until Story 2.1 replaces it
// with the real, content-minimal Story/Choice view backed by StoryRunEngine.
struct StoryChoicePlaceholderView: View {
    var body: some View {
        Text(verbatim: "Story (placeholder)")
    }
}

#Preview {
    StoryChoicePlaceholderView()
}
