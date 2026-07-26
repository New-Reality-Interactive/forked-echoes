# Version/Reality-Check Review — ARCHITECTURE-SPINE.md (Many-Worlds CYOA iOS App v1)

**Reviewed:** 2026-07-25
**Reviewer:** Claude (web-search verification pass)
**Scope:** Every version/tooling claim in the "Stack" table and the tooling-dependent invariants (AD-2, AD-7) — checked against independent web search, not the spine's own assertions.

## Overall Verdict

The stack choices are **factually accurate for July 25, 2026** and each is a real, current, non-hallucinated Apple capability — but the spine states them with more permanence than the evidence supports. As of the spine's own authorship date, Apple had already shipped iOS 27 / Xcode 27 beta 4 (Swift 6.4) and put iOS 27 into **public beta on ~July 14, 2026** — 11 days before this spine was written — with GA expected ~September 14, 2026. The spine's stack table reads as a settled, durable fact rather than "the current stable toolchain, already 11 days into being one cycle behind a beta that will go GA partway through this project's likely build window." That's the one real calibration gap; everything else checks out.

---

## Item-by-item

### 1. Swift 6.3 / Xcode 26.6 / iOS 26 SDK / iOS 18 minimum — VERIFIED, but see confidence caveat

- Xcode 26.6 (build 17F113) is a real, current stable release; it bundles **Swift 6.3** and the **iOS 26.5 / iPadOS 26.5 / tvOS 26.5 / macOS 26.5 / visionOS 26.5** SDKs, and requires macOS Tahoe 26.2+ to run. This matches the spine's "Swift 6.3 / Xcode 26.6 / iOS 26 SDK" line exactly.
  Sources: [Apple Developer Releases — Xcode 26.6](https://developer.apple.com/news/releases/?id=06252026a), [Releasebot Xcode updates](https://releasebot.io/updates/apple/xcode)
- Apple's 2025 rebrand (WWDC 2025) renumbered all OS versions to a year-based scheme, jumping iOS from 18 straight to 26 (skipping 19–25) so that "26" denotes the Sept-2025–Sept-2026 release season. This makes the spine's "iOS 18.0 minimum (N-1) / iOS 26 SDK (N)" framing internally consistent and historically accurate — iOS 18 (2024) genuinely is the prior year's major release relative to iOS 26 (2025).
  Sources: [Engadget — iOS 26 naming change](https://www.engadget.com/apps/ios-26-is-official-apple-changes-from-version-numbers-to-years-for-its-os-names-172129166.html)
- **Caveat (the actual finding):** WWDC 2026 already happened (June 8, 2026). Xcode 27 beta and iOS 27 have been in developer beta since June 8, with **iOS 27 public beta live since ~July 14, 2026** (11 days before this spine's 2026-07-25 date) and bundling **Swift 6.4**. iOS 27 GA is projected for ~September 14, 2026. So "current" here means "current *stable/shippable* toolchain," which is the right choice for a production target — you should not build a shipping app against a beta SDK — but the spine doesn't say that explicitly, and doesn't flag that N will very plausibly become 27 partway through this project's build cycle, which would push the "N-1 minimum / N SDK" policy from iOS 18/26 to iOS 19(26)/27 before submission. Nothing to fix now, but this is a decision with a short shelf life that the spine presents as settled.
  Sources: [MacRumors — iOS 27 release date/beta timeline](https://www.macrumors.com/2026/06/05/ios-27-release-date-how-to-install-beta/), [Michael Tsai — Xcode 27 Announced](https://mjtsai.com/blog/2026/06/09/xcode-27-announced/), [Michael Tsai — Swift 6.4](https://mjtsai.com/blog/2026/06/24/swift-6-4/)
- **Minor source-reliability note:** two of my own search hits disagreed on Xcode 27's bundled Swift version (one said 6.2, most others said 6.4) — a reminder that even fresh web results about bleeding-edge tooling are inconsistent, and a single search pass shouldn't be over-trusted. This doesn't affect the spine (which correctly targets the stable 26.6/6.3 line, not 27), but is worth naming for calibration.

**Severity: Low.** Factually correct for today; the only gap is that it's presented as durable rather than as a fast-decaying "current stable" snapshot.

### 2. Swift Testing as default for new unit tests, compatible with Swift 6.3/Xcode 26.6 — VERIFIED

- Swift Testing has been the default choice for the Unit Testing Bundle template since Xcode 16, ships with Xcode 16+ / Swift 6 toolchains, and is Apple's stated forward direction (WWDC26 even has a dedicated "Migrate to Swift Testing" session, confirming it's still the current guidance in 2026).
- XCTest is *not* deprecated — it remains required for UI tests (XCUITest) and performance tests (XCTMetric), which the spine correctly doesn't ask Swift Testing to cover (AD-7 only invokes Swift Testing for engine/logic testing, and explicitly excludes UI-test requirements).
- Compatibility: Swift Testing bundled with Xcode 26.6 obviously continues to work fine (it's been iterated on every release since Xcode 16, including test cancellation/warning-issue improvements added in Swift 6.3 itself).
  Sources: [Apple — Migrate to Swift Testing, WWDC26](https://developer.apple.com/videos/play/wwdc2026/267/), [Swift.org — Swift 6.3 Released](https://www.swift.org/blog/swift-6.3-released/), [blakecrosley.com — Swift Testing vs XCTest](https://blakecrosley.com/blog/swift-testing-vs-xctest)

**Severity: None.** Claim and scoping are both accurate.

### 3. Xcode String Catalogs (.xcstrings) as current default; LocalizedStringResource iOS 16+ vs iOS 18 min target — VERIFIED

- .xcstrings has been the default String Catalog format since Xcode 15 and remains current; nothing has superseded it as of Xcode 26.6/27 beta.
- `LocalizedStringResource` was introduced in iOS 16 — the spine's iOS 18.0 minimum deployment target is strictly newer, so there's no compatibility gap. This is a correctly-verified constraint, not just an assumption.
  Sources: [SimpleLocalize — xcstrings guide](https://simplelocalize.io/blog/posts/xcstrings-string-catalog-guide/), [AppleInsider — Xcode String Catalogs](https://appleinsider.com/inside/xcode/tips/how-to-use-xcode-string-catalogs-to-localize-your-app)

**Severity: None.**

### 4. @Observable / Observation framework as current recommended default over ObservableObject — VERIFIED

- Observation (`@Observable`) shipped in iOS 17 and has been Apple's consistently recommended default for new SwiftUI state management since; nothing in 2026 sources suggests this has been superseded (no successor framework announced at WWDC26 per the search results).
- Minimum OS for `@Observable` is iOS 17 — again strictly older than the spine's iOS 18 deployment floor, so AD-3's design (single `@Observable` `StoryRunEngine`) is compatible.
  Sources: [tanaschita.com — Migrating to Observation](https://tanaschita.com/swiftui-observation-migrating-to-observation/), [sharpskill.dev — @Observable vs @State 2026](https://sharpskill.dev/en/blog/ios/swiftui-observable-vs-state)

**Severity: None.**

### 5. Type-safe generated symbols for String Catalog keys (LocalizedStringResource) and Asset Catalog image sets (ImageResource) — VERIFIED, real and current

- **Asset Catalog → `ImageResource`/`ColorResource`:** real Apple feature since Xcode 15, controlled by `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`, on by default for app targets, produces `Image(.assetName)`-style typed accessors. Not stale — still current in Xcode 26.6/27.
  Sources: [nilcoalescing.com — Xcode 15 Assets](https://nilcoalescing.com/blog/Xcode15Assets/), [useyourloaf.com — Disabling Asset Symbol Generation](https://useyourloaf.com/blog/disabling-xcode-asset-symbol-generation/)
- **String Catalog → generated `LocalizedStringResource` symbols:** this is a real, but *newer and less universally known*, capability ("Generate String Catalog Symbols"), introduced around Xcode 26, generating static members/functions on `LocalizedStringResource` from manually-added catalog keys (`extractionState: "manual"`). The spine's AD-2 workflow (stable, hand-authored keys referenced by `LocalizedStringResource`) matches exactly the manual-key workflow this feature targets, so the claim isn't just current, it's the *right-shaped* current feature for how the spine intends to author strings.
  Sources: [Sahil Garg — Type-Safe Localization in Xcode 26](https://sgarg28.medium.com/%EF%B8%8F-type-safe-localization-in-xcode-26-your-strings-now-compiler-proof-63c12ea1a49d), [Apple Developer Forums — generated symbols from string catalogs in SPM packages](https://developer.apple.com/forums/thread/789813)
- Minimum-OS check: `Image(ImageResource)` requires iOS 17+; the spine's iOS 18 floor clears this with room to spare.
  Sources: [Swift Forums — Xcode15 generated ImageResource](https://forums.swift.org/t/xcode15-generated-imageresource-with-public-access/67293)

**Severity: None.** This was the claim most worth independently checking (it's the newest/least-famous of the five), and it holds up — not a stale or incorrect assertion.

---

## Summary Table

| Claim | Status | Severity |
| --- | --- | --- |
| Swift 6.3 / Xcode 26.6 / iOS 26 SDK / iOS 18 min | Accurate for 2026-07-25, but presented as more durable than warranted — iOS 27 already in public beta 11 days prior, GA ~7 weeks out | Low |
| Swift Testing as default, compatible with stated versions | Accurate | None |
| .xcstrings default; LocalizedStringResource iOS 16+ vs iOS 18 min | Accurate, compatibility margin confirmed | None |
| @Observable as current recommended default | Accurate, no successor framework found | None |
| Type-safe symbol generation for String Catalog + Asset Catalog | Accurate and current; String Catalog symbol gen is genuinely new (~Xcode 26) and matches the spine's manual-key workflow | None |

## Recommendation

No changes required to the technical decisions themselves. If the spine is revisited before App Store submission (plausible given iOS 27 GA lands ~September 14, 2026), it would be worth a one-line addendum noting the stack table is a dated snapshot of the *stable* toolchain and should be re-verified against whatever is GA at submission time — particularly the deployment-target policy's N/N-1 values, which will shift by one when iOS 27 ships.
