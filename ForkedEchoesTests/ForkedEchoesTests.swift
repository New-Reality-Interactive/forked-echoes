import Testing

struct ForkedEchoesTests {

    @Test func testTargetCompilesAndRuns() {
        #expect(1 + 1 == 2)
    }
}
