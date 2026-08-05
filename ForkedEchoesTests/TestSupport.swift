import Foundation
import Testing

/// Creates an isolated `UserDefaults` suite so a test never writes to the real `.standard`
/// domain (which pollutes real app state and races other tests — code review, 2026-08-01,
/// Story 2.4). Callers must clean up when done, typically via `defer { defaults.removePersistentDomain(forName: suiteName) }`.
func freshDefaults() -> (defaults: UserDefaults, suiteName: String) {
    let suiteName = "ForkedEchoesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, suiteName)
}

/// Serializes every test carrying this trait against every other test carrying it, across
/// suites — not just within one suite.
///
/// Root cause (Story 2.14): on Linux, `UserDefaults(suiteName:)` is backed by
/// swift-corelibs-foundation's CFPreferences, which keeps its domain cache
/// (`CFPreferences.c`'s static `domainCache`, guarded by `domainCacheLock`) and its
/// per-application-name preferences cache (`CFApplicationPreferences.c`'s static
/// `__CFStandardUserPreferences`, guarded by `__CFApplicationPreferencesLock`) as *process-global*
/// mutable state shared across every suite name, not per-suite state the way Darwin's
/// `cfprefsd`-brokered preferences are. Confirmed empirically with a minimal reproduction outside
/// this codebase (no engine or test-support code involved): dozens of concurrent threads each
/// constructing a distinct, UUID-suffixed `UserDefaults(suiteName:)`, writing one key, and
/// immediately reading it back on that same instance, intermittently got `nil` back — the exact
/// write-then-immediate-read-not-visible shape observed in this suite. `TestSupport.swift`'s
/// UUID-suffixed suite names already rule out two tests colliding on the same *domain*; the
/// failure is concurrent *unrelated* domains contending on that shared global machinery during
/// domain creation/lookup/synchronize, not a collision between this suite's own reads and writes.
/// That means no change to `freshDefaults()`'s own logic can fix this — the race isn't in how it
/// picks a suite name, and reads of the resulting `UserDefaults` also happen deep inside
/// `StoryRunEngine`/`RunSnapshot`/`RunSnapshotPresence` (out of scope for this test-infrastructure
/// story to change).
///
/// Swift Testing's built-in `.serialized` trait (confirmed against this project's Swift 6.3
/// `Testing.swiftinterface`) only orders test cases *within* the `@Suite` it's applied to — two
/// different `@Suite` types with `.serialized` still run concurrently with each other, which
/// would leave the actual, process-global race intact. A custom `TestScoping` trait backed by a
/// single shared actor is the only way to get real cross-suite mutual exclusion without
/// restructuring the three affected files into one suite. This is applied only to the three
/// suites that actually construct `UserDefaults(suiteName:)`
/// (`StoryRunEngineTests`/`RunSnapshotTests`/`RunSnapshotPresenceTests`) — `ForkedEchoesTests` and
/// `RunOptionsButtonTests` touch no shared state and keep running fully in parallel.
struct SerializesUserDefaultsAccess: TestTrait, SuiteTrait, TestScoping {
    // Traits are not recursively applied to child test functions by default (Swift Testing's own
    // documented default) — without this, the trait only scopes the *suite* as a whole once, not
    // each individual `@Test` inside it, so tests within one suite would still race each other.
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await UserDefaultsTestMutex.shared.lock()
        do {
            try await function()
        } catch {
            await UserDefaultsTestMutex.shared.unlock()
            throw error
        }
        await UserDefaultsTestMutex.shared.unlock()
    }
}

extension Trait where Self == SerializesUserDefaultsAccess {
    static var serializesUserDefaultsAccess: Self { SerializesUserDefaultsAccess() }
}

/// An async-safe FIFO mutex all `SerializesUserDefaultsAccess`-tagged tests funnel through.
///
/// A first attempt used a plain `actor` whose `run(_:)` method awaited `function()` directly,
/// assuming that would serialize callers since none of this suite's test bodies contain their own
/// `await`. That assumption was wrong and confirmed wrong empirically (an instrumented counter
/// showed concurrent entries even with the trait applied): Swift Testing's own scope/expectation
/// machinery suspends internally even around a synchronous `@Test func`, and Swift actors are
/// reentrant at any suspension point — so a second call could enter `run` while the first was still
/// mid-`function()`, defeating the lock. A continuation-based mutex avoids this: `lock()`/`unlock()`
/// only ever touch actor-isolated state synchronously (no `await` inside their own bodies other than
/// the controlled continuation suspension while genuinely waiting), so there is no reentrancy window
/// for a second caller to slip through while a first caller's `function()` is running.
///
/// This does not block an OS thread (unlike `DispatchSemaphore.wait()`, which would risk starving
/// Swift's cooperative thread pool if many of this suite's ~60 gated tests tried to block
/// simultaneously) — a waiting task suspends and yields its thread back to the pool until resumed.
///
/// `lock()` is cancellation-aware (code review, 2026-08-04): a plain `withCheckedContinuation`
/// ignores task cancellation entirely, so a waiter whose task is cancelled while queued would sit
/// in `waiters` forever, resumable only by an unrelated `unlock()` reaching it — the same class of
/// silent hang this mutex exists to prevent. `withTaskCancellationHandler` lets a cancelled waiter
/// remove itself and rethrow instead. `waiters.append` happens synchronously inside `lock()` (an
/// actor-isolated method) before the awaited continuation suspends, and `onCancel` can only reach
/// `cancelWaiter` by hopping back onto the actor via `Task { await ... }` — so a waiter is always
/// enqueued before any cancellation targeting it can be processed, even for an already-cancelled
/// task, ruling out the append-vs-cancel ordering race this pattern would otherwise risk.
private actor UserDefaultsTestMutex {
    static let shared = UserDefaultsTestMutex()

    private var isLocked = false
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Void, Error>)] = []

    func lock() async throws {
        if !isLocked {
            isLocked = true
            return
        }
        try Task.checkCancellation()
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                waiters.append((id, continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    func unlock() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            waiters.removeFirst().continuation.resume()
        }
    }

    private func cancelWaiter(_ id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }
}
