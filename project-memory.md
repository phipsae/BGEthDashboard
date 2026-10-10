# Project memory

Last updated 2026-10-10.

## Verified facts

- ETH Tracker is the app in this repository, `phipsae/BGEthDashboard`. PRs #1, #2 and #3 merged into `main` on 2026-10-10. The application baseline after those merges is `e2f432da845ae93d4e36d1f049a9f7baa66e8c89`.
- PR #1 keeps dashboard values visible during pull-to-refresh by owning an observable `DashboardStore` in `ContentView` and awaiting `store.load()`. Its final reviewed head was `5fd716b1f793665d5c6d647d1b90a97fb25ebc19`, merged as `80905952f3650ef76518afc41e3b98ade5345f74`.
- PR #1's follow-up fix assigns each load a request number and ignores superseded successes and failures before updating displayed data, the update time, error state, widget cache or widget reloads.
- PR #2 removes the unreferenced `1024_backup.png`. All 37 referenced icon files remain present. A pre-existing macOS warning about `1024.png` remains. The reviewed head was `bacdddd3c23e6979a4822f4d80e6744fb930b806`, merged as `348f3c4a35802ff1d99cc2ccb425d4ad7bc6b93c`.
- PR #3 sets `ITSAppUsesNonExemptEncryption = NO` in both app build configurations. Independent checks confirmed the setting for iOS Debug and Release and Boolean `false` in the built macOS Release plist. The reviewed head was `96ea3eacd8db815fc2de2693d26e36aa23f6fdf0`, merged as `e2f432da845ae93d4e36d1f049a9f7baa66e8c89`.
- Each reviewed PR passed an unsigned arm64 macOS Release build. The sandbox prevented compiler macro subprocesses from running normally, so verification used `OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox` within the existing execution sandbox.
- An isolated Swift harness compiled the exact final `DashboardStore` with mocked networking, an in-memory cache and a widget reload stub. Checks passed for retained values during loading, successful updates, failed refreshes, overlapping completions in both orders, ignored stale failures, superseded cancellation and recovery.
- Version 1.1.1 (build 5) has been live on the App Store for iOS and Mac since 2026-07-09, according to the iTunes lookup API on 2026-10-10. Apple's TestFlight overview says a build can be tested for up to 90 days. The TestFlight 1.1.1 copy installed on the Mac on 2026-07-08 stopped opening in October with "The provisioning profile is invalid", and the timing matched that limit. Installing from the Mac App Store replaces it.
- Builds from Xcode 27.0 with the iOS 27.0 and macOS 27.0 SDKs produce no Swift warnings. On an iOS 27.0 simulator (iPhone 18 Pro) on 2026-10-10, the PR #1 build loaded live data, the widget was listed in the gallery, small, medium and large widgets showed live data, and the widget refresh button updated the small widget without opening the app. The App Store build was not tested on a physical iOS 27 device.
- A screen recording of a real pull gesture on the iOS 27 simulator showed every value replaced by a dash after the pull on the unfixed `main` build, and no dashes on the PR #1 build.
- Widgets can be added on the simulator without manual steps. A throwaway XCUITest project generated with `xcodegen` (a host app plus a `bundle.ui-testing` target with ad hoc signing) drives `com.apple.springboard`. On iOS 27.0 the path is a long press on an empty home screen area, or a long press on a widget followed by "Edit Home Screen", then "Edit", "Add Widget", the "ETH Tracker" cell, a swipe to the wanted size, and the button whose label ends with "Add Widget". That label starts with an extra glyph, so an exact match fails. Widget contents are not exposed to springboard queries, so widget buttons are tapped by screen coordinate.
- XCUITest waits for the app to become idle after a gesture, so it cannot observe short-lived states such as the old pull-to-refresh blanking. `xcrun simctl io <device> recordVideo` during the test, followed by an ffmpeg frame montage, does capture them.
- `xcodebuild -exportArchive` with `method` set to `app-store-connect` and `destination` set to `upload` reached App Store Connect on 2026-10-10 using the Xcode account, without an API key. It failed with "PLA Update available" and "No signing certificate \"iOS Distribution\" found". A successful upload by this route has not been observed.
- Apple's Materials guidelines say "Don't use Liquid Glass in the content layer" and recommend standard materials for content. The dashboard cards are content, so `.ultraThinMaterial` remains appropriate. `glassEffect(_:in:)` and the `.glass` button style are available from iOS 26.0 and macOS 26.0, so they fit the 26.1 deployment target.

## Decisions and preferences

- Keep durable ETH Tracker context in this repository and update it only on explicit request.
- Recheck dated PR and branch information before treating it as current.

## Analysis

- The final review found no remaining merge blockers at the reviewed heads. PR #1's initial version allowed an older request to overwrite newer pull-to-refresh data and the widget cache, or show an error after a successful refresh. The request-number guard resolved both reproduced cases.
- The app uses HTTPS through Apple's `URLSession`, with no bundled third-party cryptography found in the reviewed project. The export-compliance flag matches Apple's guidance for this use of system encryption.
- The isolated checks establish store behavior under controlled responses. They do not establish live widget recovery or the iOS pull gesture. The iOS gesture remained untested by this review, and no App Store upload or production verification was performed. The gesture was later confirmed on the iOS 27 simulator through the screen recording described above.
- Build logs and the harness were temporary review artifacts outside the repository. Their availability is not guaranteed.

## Sources

- [PR #1, pull-to-refresh](https://github.com/phipsae/BGEthDashboard/pull/1).
- [PR #2, unused app icon](https://github.com/phipsae/BGEthDashboard/pull/2).
- [PR #3, export-compliance flag](https://github.com/phipsae/BGEthDashboard/pull/3).
- [Merged application baseline](https://github.com/phipsae/BGEthDashboard/tree/e2f432da845ae93d4e36d1f049a9f7baa66e8c89).
- [Apple's encryption export guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).
- Independent source inspection, isolated regression checks and local build validation in this review on 2026-10-10.
- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview).
- [Materials in the Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/materials).
- [`glassEffect(_:in:)`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)).
- Simulator runs, screen recordings and the export attempt on 2026-10-10.
