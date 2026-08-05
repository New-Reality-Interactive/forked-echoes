import Testing
@testable import ForkedEchoes

// Story 2.13 (AC #5): closes the gap Story 2.7's code review flagged — no automated coverage
// existed for RunOptionsButton's row ordering. RunOptionsRow.allCases is the plain, testable
// value RunOptionsButton's confirmationDialog iterates over to render its rows, so asserting the
// case order here is a compiler-checked proxy for the sheet's actual row order without any
// SwiftUI rendering involved.
struct RunOptionsButtonTests {

    @Test func runOptionsRowOrderIsFixed() {
        #expect(RunOptionsRow.allCases == [
            .exitToHome,
            .restartRun,
            .exitAndClearProgress,
            .cancel,
        ])
    }
}
