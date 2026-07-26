# Deferred Work

## Deferred from: code review of 1-1-project-scaffold (2026-07-26)

- No `DEVELOPMENT_TEAM` set in any build configuration (`CODE_SIGN_STYLE = Automatic`) — blocks device/Archive builds; Simulator builds are unaffected. Pre-existing: the story's own Dev Notes already defer the Apple Developer Program/team decision until the account type is chosen (epics.md Pre-Submission Checklist).
- `AppIcon.appiconset` declares a 1024x1024 slot with no image asset — will fail Release Archive/App Store validation once attempted. Pre-existing: real app icon art is Epic 4's job (Story 4.6, App Store listing/submission assets), not this scaffold story.
