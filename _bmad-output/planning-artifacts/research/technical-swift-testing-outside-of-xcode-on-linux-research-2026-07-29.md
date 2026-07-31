---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments: []
workflowType: 'research'
lastStep: 6
research_type: 'technical'
research_topic: 'Running Swift Testing (import Testing) outside of Xcode, specifically on Linux'
research_goals: 'Determine whether/how the StoryRunEngine Swift Testing suite (engine-logic only, no UIKit/SwiftUI) can actually execute in this Linux devcontainer (swiftc 6.3.3, no Xcode/Apple SDKs) rather than only being parsed/type-checked with `swiftc -parse`'
user_name: 'Brian'
date: '2026-07-29'
web_research_enabled: true
source_verification: true
---

# Research Report: technical

**Date:** 2026-07-29
**Author:** Brian
**Research Type:** technical

---

## Research Overview

This research investigates whether the project's Swift Testing suite (`import Testing`, scoped to `StoryRunEngine`/engine logic per `AD-7`) can actually **execute** in this Linux devcontainer — not just be parsed with `swiftc -parse` — given the environment has a Linux Swift 6.3.3 toolchain but no Xcode or Apple SDKs. The finding: Swift Testing is fully cross-platform and Linux-supported out of the box; the real obstacle is that this project is structured as an Xcode app target rather than a SwiftPM package, and `swift test` (the Linux test driver) only operates on SwiftPM packages. The fix is a well-established pattern — extract the engine logic into a local SwiftPM package consumed by the Xcode project — not a framework limitation. Full findings, a resolved source conflict on a "no such module 'Testing'" error, and a concrete 6-step implementation roadmap are below; see the Executive Summary and Recommendations in the Research Synthesis section for the complete picture.

---

<!-- Content will be appended sequentially through research workflow steps -->

## Technical Research Scope Confirmation

**Research Topic:** Running Swift Testing (import Testing) outside of Xcode, specifically on Linux
**Research Goals:** Determine whether/how the StoryRunEngine Swift Testing suite (engine-logic only, no UIKit/SwiftUI) can actually execute in this Linux devcontainer (swiftc 6.3.3, no Xcode/Apple SDKs) rather than only being parsed/type-checked with `swiftc -parse`

**Technical Research Scope:**

- Architecture Analysis - Swift Testing framework structure, SPM vs Xcode test integration
- Implementation Approaches - `swift test` CLI workflow, package manifest setup for Linux
- Technology Stack - Swift 6.3 Linux toolchain compatibility with Swift Testing
- Integration Patterns - CI/CD (GitHub Actions Linux runners), devcontainer usage
- Performance Considerations - what's actually runnable vs. blocked by Foundation/Apple-only dependencies

**Research Methodology:**

- Current web data with rigorous source verification
- Multi-source validation for critical technical claims
- Confidence level framework for uncertain information
- Comprehensive technical coverage with architecture-specific insights

**Scope Confirmed:** 2026-07-29

## Technology Stack Analysis

### Programming Languages

Swift is the only language in scope here, and the relevant version is the Swift 6.x language mode. Swift Testing (the modern `import Testing` framework) shipped as part of the Swift 6 toolchain and Xcode 16, and is included in officially-supported Swift toolchains for **all** platforms Swift targets, including Linux and Windows — not just Apple platforms.

_Popular Frameworks in Scope: Swift Testing (`import Testing`), the successor to XCTest for new code._
_Language Evolution: As of 2026, Swift Testing is the default starting point for new Swift projects; XCTest remains supported for legacy suites and UI-test hosts._
_Performance Characteristics: Not relevant here — the constraint is toolchain/module availability, not raw language performance._
_Source: [GitHub - swiftlang/swift-testing](https://github.com/swiftlang/swift-testing), [Swift.org Server Testing Guide](https://www.swift.org/documentation/server/guides/testing.html)_

### Development Frameworks and Libraries

**Swift Testing itself is cross-platform and open source** — its own `Package.swift` declares `swift-tools-version: 6.3` and explicitly supports non-Apple platforms including Linux. It does not depend on the Objective-C runtime (unlike classic XCTest, which historically relied on Objective-C runtime introspection for test discovery on Apple platforms — a mechanism that never existed on Linux to begin with).

The one important nuance found (via [swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763)): **on some Linux toolchain/SwiftPM combinations, `import Testing` requires an explicit `swift-testing` package dependency declared in `Package.swift`, whereas on macOS with Xcode/Swift 6 it's bundled implicitly and "just works" via `import Testing` with no manifest entry.** This is filed as an open inconsistency, not a permanent architectural limit — but it means "no such module 'Testing'" on Linux is a known, documented failure mode with a known fix (add the dependency), not a sign Swift Testing is unsupported on Linux.

_Major Frameworks: Swift Testing (primary), XCTest (legacy/UI-test fallback, macOS/Xcode only for UI hosts)._
_Ecosystem Maturity: Swift Testing is production-stable and is the officially recommended default; Linux support is a first-class, documented target, not a community port._
_Source: [swift-testing Package.swift](https://github.com/swiftlang/swift-testing/blob/main/Package.swift), [swift-package-manager issue #7763](https://github.com/swiftlang/swift-package-manager/issues/7763)_

### Database and Storage Technologies

_Not applicable to this research topic — no persistence layer is in scope for running Swift Testing on Linux._

### Development Tools and Platforms

The actual test **driver** on Linux is the `swift` CLI via Swift Package Manager — specifically `swift test` (optionally `swift build --enable-testing` first). This is a from-scratch SwiftPM invocation, entirely independent of Xcode's test-runner UI/`xcodebuild`.

**Critical constraint for this project specifically:** `swift test` operates on a **SwiftPM package** (a directory with `Package.swift` and target sources) — it does not operate directly on an `.xcodeproj`/`.xcworkspace`. This project's structure (per its `project-context.md`) is an Xcode app project using `PBXFileSystemSynchronizedRootGroup`s under `Views/`, with `StoryRunEngine` as shared app-target source — **not** an SPM package today. To get `swift test` running in this devcontainer, the engine-logic code that Swift Testing already covers (`StoryRunEngine`, ending resolution, echo reachability, pager-gating, `RunSnapshot` round-trip) would need to be reachable from a `Package.swift` target that imports only Foundation/Swift-standard-library-safe code — no `SwiftUI`/`UIKit` imports, which is already true of engine-logic-only code per this project's stated test scope.
Two established patterns for this, found in research:
1. **Local SwiftPM package** added as a local dependency of the Xcode project (a `Sources/<EngineTarget>` package folder referenced by the `.xcodeproj`), so the exact same source is compiled both by Xcode (for the app) and by `swift test` on Linux (for the test suite) — no code duplication.
2. **Standalone test harness package** that vendors/symlinks the engine source files into its own `Sources/`, used purely for CI/Linux verification, kept in sync manually — lower setup cost but a duplication risk if not automated.

_IDE and Editors: N/A on Linux (no Xcode) — CLI-only via `swift build`/`swift test`._
_Build Systems: Swift Package Manager (`swift test`) is the correct and only viable driver for this environment; `xcodebuild test` is unavailable (confirmed: no Apple SDKs in this devcontainer)._
_Testing Frameworks: Swift Testing (`import Testing`), invoked automatically by `swift test` when the package's test target declares it as a dependency (or implicitly on toolchains where it's bundled)._
_Source: [GitHub Docs: Building and testing Swift](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift), [Unit Testing Swift Code on Linux — Pelmorex](https://tech.pelmorex.com/2020/05/unit-testing-swift-code-on-linux/)_

### Cloud Infrastructure and Deployment

_Not directly applicable, but relevant for the CI angle of the stated research goal:_ GitHub Actions supports Swift on Linux runners two ways — the `swift-actions/setup-swift` action on standard `ubuntu-latest` runners (pinning a `swift-version`, e.g. `6.3`), or a Docker-container job using the official `swift:<version>` image. Either path runs `swift build --enable-testing && swift test` on Linux, which is the same command surface available in this devcontainer today.

_Container Technologies: Official `swift` Docker images (e.g. `swift:6.3`) are the standard way to reproduce a Linux Swift toolchain in CI, matching what a devcontainer already provides locally._
_Source: [swift-actions/setup-swift](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift), [Building Swift packages with Docker, no Xcode](https://shashikantjagtap.net/building-packages-with-swift-package-manager-and-docker-without-xcode/)_

### Technology Adoption Trends

The broader industry pattern this project's constraint fits: teams extract pure-Swift business/engine logic into a separate SwiftPM target/package specifically so it can be tested on Linux (fast, cheap CI) while UI code (SwiftUI/UIKit) stays macOS/Xcode-only and is verified manually or via a separate macOS CI job. This is described as a "hybrid pipeline" — Swift Testing suite on Linux for speed/cost, macOS job reserved only for UI/XCUITest verification. This maps directly onto this project's existing test scope (`AD-7`: Swift Testing covers `StoryRunEngine` only, no UI test target) — the architecture is already shaped in a way that's Linux-testable in principle; what's missing is the SwiftPM manifest/target wiring to let `swift test` see that code.

_Migration Patterns: Apps moving from "logic embedded in the Xcode app target" to "logic in a local SwiftPM package consumed by the app target" specifically to unlock Linux/CI testing and faster iteration._
_Source: [Unit testing with Swift PM — Rob Allen](https://akrabat.com/unit-testing-with-swift-pm/), [Ensuring Swift Compatibility on Linux — Daniel Lyons](https://dandylyons.net/posts/ensuring-swift-compatibility-on-linux/)_

## Integration Patterns Analysis

_Note: this topic has no REST/GraphQL/microservices/messaging surface — "integration" here is reframed to what actually applies: how `Package.swift` wires the Testing framework in, how the devcontainer toolchain is configured, and how a local SwiftPM package integrates with an existing Xcode `.xcodeproj`. The template's network-protocol subsections are marked not applicable rather than stretched to fit._

### Package Manifest Integration (the load-bearing pattern)

The concrete SPM wiring, confirmed from the swift-testing project's own manifest and standard SPM usage: a package declares a library target (the engine code) and a separate test target that depends on it, e.g. `.target(name: "StoryEngine")` and `.testTarget(name: "StoryEngineTests", dependencies: ["StoryEngine"])`. Where the Linux-specific gap from swift-package-manager#7763 applies, the test target's dependencies would also need an explicit `.product(name: "Testing", package: "swift-testing")` entry (with a matching `.package(url: "https://github.com/swiftlang/swift-testing", ...)` or a toolchain-local reference), even though the same manifest works without it on macOS/Xcode. **This should be verified directly against this devcontainer's actual `swift --version` / `swift package` behavior rather than assumed** — the GitHub issue describes an inconsistency that may or may not affect Swift 6.3.3 specifically depending on how recently it was patched.
_Source: [swift-testing Package.swift](https://github.com/swiftlang/swift-testing/blob/main/Package.swift), [swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763)_

### Xcode-Project ↔ SwiftPM-Package Integration

Since Xcode 11+, Xcode natively integrates local SwiftPM packages as dependencies of an app target (added under the target's "Frameworks, Libraries, and Embedded Content", or via "Add Local Package…" pointing at a package directory with a path-based reference instead of a remote URL). This is the standard mechanism for the "shared engine source" pattern identified above: the same `Sources/StoryEngine/*.swift` files are compiled once by Xcode (as part of the app, importing SwiftUI for the UI layer elsewhere) and separately by `swift test` on Linux (test target only, no SwiftUI/UIKit in the dependency graph). No file duplication is required — only a `Package.swift` addition and an Xcode "Add Local Package" step done once from a macOS machine.
_Source: [Local SPM in Xcode — Medium/Guy Cohen](https://medium.com/@guycohendev/local-spm-part-2-mastering-modularization-with-swift-package-manager-xcode-15-16-d5a11ddd166c/), [Step-by-Step Local SPM Package Guide](https://medium.com/mobillium/step-by-step-guide-to-creating-a-local-spm-package-in-xcode-15-7582d178ccab)_

### Devcontainer / Toolchain Integration

Official Swift devcontainer tooling (`swift-server/swift-devcontainer-template`, VS Code's Swift extension) confirms this devcontainer's shape is a known, supported pattern: a `devcontainer.json` built on an official `swift` base image, with the VS Code Swift extension (`sswg.swift-lang`) auto-detecting the installed toolchain via `swift: Select Toolchain…`. Devcontainer features exist specifically for `swiftpm`, `jemalloc`, and `foundationnetworking` — meaning this devcontainer's `swiftc 6.3.3` is very likely SwiftPM-capable already (`swift build`/`swift test` should exist as commands), even though `xcodebuild` and Apple SDKs are absent. **This should be spot-checked directly** (`swift package --version`, `swift test --help`) rather than assumed from research alone.
_Source: [swift-server/swift-devcontainer-template](https://github.com/swift-server/swift-devcontainer-template), [Configuring VS Code for Swift — Swift.org](https://www.swift.org/documentation/articles/getting-started-with-vscode-swift.html)_

### API Design Patterns, Communication Protocols, Data Formats, Microservices/Event-Driven Patterns

_Not applicable — this research topic has no network API, wire protocol, or distributed-systems surface. Skipped rather than forced to fit._

### Integration Security Patterns

_Not applicable — no auth/transport-security surface in scope for local/CI test execution._

## Architectural Patterns and Design

_Reframed for this topic: the relevant "architecture" question isn't microservices/enterprise patterns, it's what app-level architecture makes engine logic Linux-testable in the first place, and what pipeline architecture runs it. Sections without a meaningful analogue here (data architecture, security architecture) are marked not applicable._

### Testable-Core Architecture Pattern (why this matters here)

Across current SwiftUI architecture guidance (MVVM, Clean Architecture, Composable Architecture / TCA), the consistent principle is: isolate business/domain logic from the View layer so it can be unit-tested independently of any UI framework, with dependency injection reducing coupling. This project's own documented pattern — `StoryRunEngine` as the single shared source of state, no per-screen ViewModel, Swift Testing scoped to engine logic only (`AD-7`) — is already this exact pattern in practice, just not yet split into a separate SwiftPM module. The architecture is the right shape; only the module boundary (Xcode target vs. SwiftPM package) is missing for Linux testability, as identified in the Technology Stack and Integration sections above.
_Source: [Clean Architecture for SwiftUI — Alexey Naumov](https://nalexn.github.io/clean-architecture-swiftui/), [Architectural Patterns for SwiftUI Apps — Medium](https://medium.com/@deepak.srivastava.india/architectural-patterns-and-design-strategies-for-swiftui-apps-671099c5e34d)_

### Deployment and Operations Architecture (CI pipeline shape)

The established pattern for exactly this Swift-on-Linux-plus-Apple-UI split is a **hybrid pipeline**: Swift Testing suites run on Linux runners (cheap, fast, parallelizable) while `XCUITest`/Simulator-dependent verification stays on a macOS job, since UI automation depends on Apple's Simulator and accessibility layer and doesn't port to Linux. One documented real-world example runs the same Swift package's tests across four separate CI jobs (macOS, iOS Simulator, Linux, Windows) via GitHub Actions, confirming this is a proven, not theoretical, pattern at the same granularity this project would need (engine-only tests on Linux, UI/manual verification on macOS/Simulator — which is already this project's stated split per `AD-7`).
_Source: [Four Green Checkmarks: GitHub CI for macOS, iOS, Linux, and Windows — Cocoanetics](https://www.cocoanetics.com/2026/04/four-green-checkmarks-github-ci-for-macos-ios-linux-and-windows/), [Swift Continuous Integration — Swift.org](https://www.swift.org/documentation/continuous-integration/)_

### System Architecture Patterns, Scalability/Performance Patterns, Security Architecture, Data Architecture

_Not applicable — no distributed-systems, scaling, or data-persistence surface in scope for this topic._

## Implementation Approaches and Technology Adoption

### Resolving the "no such module 'Testing'" Conflict (source disagreement, resolved)

The two earlier sources on this ([swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763) vs. general Swift 6 guidance) initially looked contradictory. Cross-checking against [Swift Forums: "Error: no such module 'Testing'"](https://forums.swift.org/t/error-no-such-module-testing/74784) and [swiftlang/swift#79113](https://github.com/swiftlang/swift/issues/79113) resolves it: **Swift 6 toolchains bundle Swift Testing and it should not need a manifest dependency at all**, on Linux or macOS — the cases where "no such module 'Testing'" appears are almost always an older/mismatched toolchain, an explicitly-added (and now redundant/conflicting) `swift-testing` package dependency, or an unusual OSS toolchain build. **Confidence: Medium-High.** Given Swift 6.3.3 in this devcontainer post-dates this fix, `import Testing` should work with zero `Package.swift` dependency entries — but this is a "verify first" item, not an assumption to build a plan on blindly.

### Concrete Implementation Roadmap for This Devcontainer

1. **Spot-check the toolchain right now** (no risk, read-only): `swift --version`, `swift package --version`, `swift test --help` — confirms SwiftPM/test-runner presence independent of Xcode.
2. **Create a minimal SwiftPM package** (`swift package init --type library` in a new directory, e.g. `Sources/StoryEngine`) and confirm `import Testing` compiles/runs via `swift test` with **no** explicit `swift-testing` dependency in `Package.swift`, per the resolved finding above.
3. **Migrate `StoryRunEngine` and its Swift Testing suite** into that package's `Sources`/`Tests` folders (or symlink from the existing Xcode-project location, per the two patterns identified in Technology Stack Analysis).
4. **Watch for the Linux case-sensitive filesystem gotcha**: Linux treats `Foo.swift`/`foo.swift` as distinct files, unlike macOS's typically case-insensitive filesystem — a real risk if any existing file/import casing was only "working by accident" on macOS.
5. **Wire the package into the Xcode project** (from a macOS machine, when convenient) via "Add Local Package…" so the same source compiles for both the app (Xcode) and the Linux test run — no duplication.
6. **Add CI** once local `swift test` is confirmed working: a GitHub Actions Linux job (`swift-actions/setup-swift@v2` pinned to `6.3`, or the official `swift:6.3` Docker image) running `swift build --enable-testing && swift test`, alongside the existing manual-Simulator verification process for UI (per this project's `AD-7` scope — no change needed there).

### Testing and Quality Assurance

No change to test *scope* is implied — this is purely about **where** the already-existing Swift Testing suite executes. The project's current rule (Swift Testing for `StoryRunEngine`/engine logic only, manual Simulator verification for UI, no UI test target) stays exactly as documented; Linux execution is an additional, faster feedback loop for the same tests, not a new testing strategy.
_Source: [Swift.org Server Testing Guide](https://www.swift.org/documentation/server/guides/testing.html)_

### Deployment and Operations Practices

Once the package split lands, `swift test` in this devcontainer becomes a legitimate pre-commit/pre-push fast-feedback step — genuinely running the engine-logic suite (not just `swiftc -parse` syntax-checking, which is this devcontainer's current documented limit per `project-context.md`). Full build/run/Simulator verification remains explicitly out of reach here and still needs to be flagged to the user, per this project's existing environment rule.

### Team Organization and Skills, Cost Optimization, Risk Assessment

_Lightweight for this topic — no team/cost dimension beyond: this is a one-time ~30–60 minute migration (create package, move/symlink files, verify) with low risk (pure refactor of module boundaries, no logic changes) and a clear rollback (the Xcode-target-only setup keeps working unchanged if the package split is reverted)._

## Technical Research Recommendations

### Implementation Roadmap

Follow the 6-step roadmap above. Steps 1–2 (toolchain spot-check, minimal package scaffold) are safe, reversible, and answer the open "verify, don't assume" questions with near-zero cost before committing to the full `StoryRunEngine` migration.

### Technology Stack Recommendations

- Use Swift Testing (`import Testing`) exactly as already adopted — no framework change needed.
- Use Swift Package Manager (`swift test`) as the Linux/devcontainer test driver — no third-party test runner needed.
- Do **not** add an explicit `swift-testing` package dependency preemptively; add it only if step 2 above actually reproduces the "no such module" error on this specific toolchain.

### Skill Development Requirements

None beyond standard SwiftPM familiarity (`Package.swift` authoring, `swift build`/`swift test` CLI) — no new language, framework, or paradigm is introduced.

### Success Metrics and KPIs

- `swift test` runs the full existing Swift Testing suite in this devcontainer with a real pass/fail result (not a parse-only check).
- Xcode build of the app target is unaffected (same behavior pre/post package split).
- (Optional, stretch) A GitHub Actions Linux job runs the same suite on every push/PR.

**Technical research phases completed:**

- Step 1: Research scope confirmation
- Step 2: Technology stack analysis
- Step 3: Integration patterns analysis
- Step 4: Architectural patterns analysis
- Step 5: Implementation research (current step)

---

# Running Swift Testing Outside Xcode: A Linux Devcontainer's Untapped Test Runner

## Executive Summary

Swift Testing — the `import Testing` framework that replaced XCTest as Swift's recommended default in 2026 — is not an Apple-platform exclusive. It ships in every officially-supported Swift 6 toolchain, Linux included, with no Objective-C runtime dependency and no macOS-only magic. That means the question "can this devcontainer actually run tests?" has a real answer, and it's more encouraging than the current `swiftc -parse`-only workflow suggests. The suite this project already writes — `StoryRunEngine`, ending resolution, echo reachability, pager-gating, `RunSnapshot` round-trip — is precisely the kind of Foundation-only, UIKit/SwiftUI-free code Swift Testing was built to run anywhere.

The obstacle isn't the test framework — it's the project's shape. `swift test`, the CLI that actually executes Swift Testing suites on Linux, operates on a Swift Package Manager package (a `Package.swift` plus target sources), not on an `.xcodeproj`. This project is currently the latter. Closing that gap is a well-trodden, low-risk pattern: extract the engine-logic code into a local SwiftPM package, consumed by the Xcode app target via "Add Local Package…" so the exact same source compiles for both the iOS app (in Xcode, on a Mac) and the Linux test run (`swift test`, in this devcontainer) — no duplication, no logic changes, no new testing strategy. It is, in effect, finishing an architectural separation this codebase has already half-completed: `StoryRunEngine` is already the single source of engine state with no per-screen ViewModel; it just isn't yet its own module.

**Key Technical Findings:**

- Swift Testing is a first-class Linux citizen, not a community port — confirmed via its own `Package.swift` and Swift.org's server-testing documentation.
- The one Linux-specific gap in the research ("no such module 'Testing'" requiring an explicit manifest dependency) turned out, on cross-checking multiple sources, to be a stale-toolchain/redundant-dependency symptom rather than a standing Swift 6 limitation — Swift 6.3.3 should need zero extra `Package.swift` entries for `import Testing` to resolve.
- The blocker is structural (Xcode target vs. SwiftPM package), not framework-level, and this project's existing architecture (isolated engine, no ViewModel sprawl) already fits the "testable core" pattern the industry converges on for exactly this reason.
- A proven hybrid-CI pattern exists at the same granularity this project needs: Swift Testing on Linux runners for engine logic, macOS/Simulator only for UI — which already matches this project's stated `AD-7` test scope.

**Technical Recommendations:**

1. Spot-check `swift --version` / `swift test --help` in this devcontainer before assuming anything — the SwiftPM toolchain is very likely already present.
2. Scaffold a minimal SwiftPM library package and confirm `import Testing` resolves without a manifest dependency, isolating whether the Linux gap applies to this specific toolchain.
3. Migrate `StoryRunEngine` + its Swift Testing suite into that package; wire it into the Xcode project as a local package dependency (from macOS) so both build targets share one source of truth.
4. Watch for Linux's case-sensitive filesystem during the move — a latent risk independent of Swift Testing itself.
5. Leave UI/manual Simulator verification exactly as documented (`AD-7`) — this changes *where* engine tests run, not what gets tested.
6. Treat GitHub Actions Linux CI as an optional follow-on once local `swift test` is confirmed working, not a prerequisite.

## Table of Contents

1. Introduction and Methodology
2. Technical Landscape: Swift Testing on Linux
3. The Real Constraint: Xcode Project vs. SwiftPM Package
4. Architecture: This Project Already Fits the Pattern
5. CI/CD: The Hybrid Pipeline Precedent
6. Resolved Conflict: The "No Such Module 'Testing'" Question
7. Implementation Roadmap and Risk Assessment
8. Research Methodology and Source Verification
9. Conclusion and Next Steps

## 1. Introduction and Methodology

### Why This Matters Now

This devcontainer has always had a documented ceiling: `swiftc -parse` gives genuine syntax verification, but nothing closer to "did the tests pass" has been available, and the project's own `project-context.md` explicitly calls out that full compilation, build/run, and Simulator verification "cannot happen here." That ceiling was assumed to include the Swift Testing suite itself. This research set out to check whether that assumption still holds, given Swift Testing's stated cross-platform design — and found that it doesn't have to.

### Research Methodology

- **Scope**: Swift Testing framework architecture and Linux support; SwiftPM as the Linux test driver; the specific structural gap between this Xcode-project-shaped codebase and SwiftPM's package-shaped expectations; CI patterns for the same split.
- **Sources**: Official Swift.org documentation, the swift-testing and swift-package-manager GitHub repositories (including open issues), Swift Forums discussions, GitHub Docs for Actions, and independent practitioner write-ups on Linux/Xcode SwiftPM patterns.
- **Verification approach**: Multi-source cross-checking, with one identified source conflict (Section 6) explicitly resolved rather than left ambiguous.
- **Depth**: Practical/implementation-focused rather than theoretical — the deliverable is a roadmap this devcontainer can act on directly, not a general industry survey.

### Research Goals and Objectives

**Original Goal:** Determine whether/how the `StoryRunEngine` Swift Testing suite can actually execute in this Linux devcontainer, rather than only being parsed/type-checked.

**Achieved:**

- Confirmed Swift Testing's Linux support is real and first-class, not aspirational (Section 2).
- Identified and explained the actual blocker — package structure, not framework support (Section 3).
- Discovered this project's architecture already anticipates the fix (Section 4).
- Resolved a genuine source disagreement about a specific error message rather than reporting it unresolved (Section 6).
- Produced a concrete, low-risk, reversible roadmap (Section 7).

## 2. Technical Landscape: Swift Testing on Linux

Swift Testing shipped with the Swift 6 toolchain and Xcode 16, and — critically for this research — is included in **every** officially-supported Swift toolchain, Apple platforms, Linux, and Windows alike. Unlike classic XCTest, which historically leaned on Objective-C runtime introspection for automatic test discovery on Apple platforms (a mechanism Linux never had), Swift Testing doesn't depend on the Objective-C runtime at all. Its own `Package.swift` targets `swift-tools-version: 6.3` and explicitly supports non-Apple platforms. By 2026, Swift Testing is described as the default starting point for new Swift projects industry-wide, with XCTest relegated to legacy suites and UI-test hosts (`XCUITest` still requires Apple's Simulator/accessibility layer and doesn't port to Linux — this project's `AD-7` scoping, which excludes UI tests from Swift Testing entirely, sidesteps that limitation by design).
_Source: [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing), [swift-testing Package.swift](https://github.com/swiftlang/swift-testing/blob/main/Package.swift), [Swift.org Server Testing Guide](https://www.swift.org/documentation/server/guides/testing.html)_

## 3. The Real Constraint: Xcode Project vs. SwiftPM Package

`swift test` — the command that actually runs a Swift Testing suite on Linux — is a Swift Package Manager operation. It expects a `Package.swift` manifest and target sources; it has no concept of an `.xcodeproj`/`.xcworkspace`. This project, per its own `project-context.md`, is structured as an Xcode app project (`PBXFileSystemSynchronizedRootGroup`s under `Views/`, `StoryRunEngine` as shared app-target source) — not a SwiftPM package. That mismatch, not any Linux limitation in Swift Testing itself, is why `swift test` has nothing to run today.

Two established fixes exist:

1. **Local SwiftPM package** (recommended) — engine sources live in `Sources/<EngineTarget>`, referenced by the Xcode project as a local package dependency (Xcode 11+ feature: "Add Local Package…", using a path reference instead of a remote URL). The same files compile for both Xcode (app) and `swift test` (Linux) — zero duplication.
2. **Standalone test-harness package** — a separate package that vendors/symlinks the engine sources purely for Linux/CI verification. Lower setup cost, but a manual-sync duplication risk if not automated.

The manifest shape itself is unremarkable SwiftPM: a `.target(name: "StoryEngine")` library target plus a `.testTarget(name: "StoryEngineTests", dependencies: ["StoryEngine"])`, matching the pattern in swift-testing's own manifest.
_Source: [swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763), [Local SPM in Xcode — Guy Cohen](https://medium.com/@guycohendev/local-spm-part-2-mastering-modularization-with-swift-package-manager-xcode-15-16-d5a11ddd166c/)_

## 4. Architecture: This Project Already Fits the Pattern

Current SwiftUI architecture guidance — MVVM, Clean Architecture, the Composable Architecture — converges on one principle: isolate business/domain logic from the View layer so it's unit-testable independent of any UI framework. This project already lives by that principle: `StoryRunEngine` is the single shared source of engine state, there's deliberately no per-screen ViewModel, and Swift Testing is already scoped to engine logic only. The only piece missing for Linux testability is the module *boundary* — Xcode target vs. SwiftPM package — not a redesign of the logic itself. This is a favorable starting position: the fix is mechanical (move files, add a manifest), not architectural.
_Source: [Clean Architecture for SwiftUI — Alexey Naumov](https://nalexn.github.io/clean-architecture-swiftui/)_

## 5. CI/CD: The Hybrid Pipeline Precedent

Once the package split exists, the same command surface (`swift build --enable-testing && swift test`) runs identically in this devcontainer and in CI. GitHub Actions supports this on standard Linux runners via `swift-actions/setup-swift@v2` (pinned to a `swift-version`, e.g. `6.3`) or a Docker job on the official `swift:6.3` image. The broader pattern — Swift Testing on cheap Linux runners, `XCUITest`/Simulator work reserved for a separate macOS job — is documented and proven (one real-world example runs the same package across macOS, iOS Simulator, Linux, and Windows jobs). This is exactly this project's existing split (`AD-7`: Swift Testing for engine logic, manual Simulator verification for UI) — CI would just be automating the Linux half of a division that already exists.
_Source: [Four Green Checkmarks — Cocoanetics](https://www.cocoanetics.com/2026/04/four-green-checkmarks-github-ci-for-macos-ios-linux-and-windows/), [GitHub Docs: Building and testing Swift](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)_

## 6. Resolved Conflict: The "No Such Module 'Testing'" Question

Research surfaced an apparent contradiction: [swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763) describes Linux CLI builds needing an explicit `swift-testing` package dependency that macOS doesn't need, while general Swift 6 guidance says the framework is bundled and needs no manifest entry at all. Cross-checking against [Swift Forums](https://forums.swift.org/t/error-no-such-module-testing/74784) and [swiftlang/swift#79113](https://github.com/swiftlang/swift/issues/79113) resolves this: the bundled-by-default behavior is correct for current Swift 6 toolchains, and "no such module 'Testing'" reports trace to older/mismatched toolchains, unusual OSS toolchain builds, or an explicitly-added dependency that's now redundant (and can conflict). **Confidence: Medium-High.** Since this devcontainer's Swift 6.3.3 postdates the relevant fix, `import Testing` should resolve with zero `Package.swift` dependency entries — but this is flagged as a "verify against the actual toolchain" item (Step 1 of the roadmap below), not a certainty to build a plan around blindly.

## 7. Implementation Roadmap and Risk Assessment

1. **Spot-check the toolchain** — `swift --version`, `swift package --version`, `swift test --help`. Read-only, zero risk, answers whether SwiftPM/test-runner tooling is already present.
2. **Scaffold a minimal SwiftPM library package** (`swift package init --type library`) and confirm `import Testing` compiles/runs via `swift test` with no manifest dependency — isolates whether Section 6's resolved finding actually holds for this exact toolchain build.
3. **Migrate `StoryRunEngine` and its test suite** into the new package's `Sources`/`Tests`, per the local-package pattern in Section 3.
4. **Check for Linux's case-sensitive filesystem** during the move (`Foo.swift` vs `foo.swift` are distinct files on Linux, unlike macOS) — a real but easily-checked risk.
5. **Wire the package into the Xcode project** via "Add Local Package…" from a macOS machine, so app and test-suite share one source tree.
6. **(Optional) Add a GitHub Actions Linux job** once local `swift test` passes, per Section 5.

**Risk profile**: low. This is a one-time, ~30–60 minute module-boundary refactor with no logic changes and a trivial rollback (revert to Xcode-target-only if the split doesn't pan out). **Success metrics**: `swift test` produces a real pass/fail result for the existing suite (not a parse-only check); the Xcode app build is unaffected; UI/manual verification continues exactly as documented.

## 8. Research Methodology and Source Verification

**Primary sources**: [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing) (repo + `Package.swift`), [swift-package-manager#7763](https://github.com/swiftlang/swift-package-manager/issues/7763), [swiftlang/swift#79113](https://github.com/swiftlang/swift/issues/79113), [Swift.org Server Testing Guide](https://www.swift.org/documentation/server/guides/testing.html), [Swift.org Continuous Integration](https://www.swift.org/documentation/continuous-integration/), GitHub Docs on building/testing Swift.

**Secondary sources**: Practitioner write-ups on local SwiftPM packages in Xcode, Linux/macOS Foundation gotchas, SwiftUI testable-architecture patterns, and a documented four-platform CI case study.

**Confidence levels**: High for Swift Testing's Linux support and the SwiftPM-package-vs-Xcode-project constraint (multiple independent, authoritative sources agree). Medium-High for the resolved "no such module 'Testing'" question — resolved via cross-referencing but not verified against this exact devcontainer, hence Step 1/2 of the roadmap being explicitly a verification gate rather than an assumption.

**Limitations**: This research could not execute commands inside the devcontainer to directly confirm toolchain behavior — the roadmap's first two steps exist specifically to close that gap cheaply before any real migration work begins.

## Technical Research Conclusion

### Summary of Key Findings

Swift Testing is genuinely Linux-native, and this devcontainer's `swiftc 6.3.3` toolchain is very likely already capable of running it via `swift test` — the missing piece is a SwiftPM package boundary around `StoryRunEngine`, not a framework or platform limitation. This project's existing architecture already anticipates that boundary; closing it is a small, mechanical, reversible step.

### Strategic Impact

Once closed, this devcontainer moves from "syntax-check only" to "genuine automated test execution" for the engine-logic suite — a materially better feedback loop for engine-focused stories, without touching the UI-testing approach this project has already deliberately scoped out of Swift Testing.

### Next Steps

Run Steps 1–2 of the roadmap (Section 7) first — they're read-only/low-cost and will confirm or correct this research's Medium-High-confidence assumption about the toolchain before any file migration happens.

---

**Technical Research Completion Date:** 2026-07-31
**Source Verification:** All technical claims cited with current sources; one source conflict identified and explicitly resolved
**Technical Confidence Level:** High for core findings (Linux support, structural constraint); Medium-High for the toolchain-specific manifest-dependency question, pending direct verification in this devcontainer

_This document serves as the technical reference for unblocking Swift Testing execution in this project's Linux devcontainer._
