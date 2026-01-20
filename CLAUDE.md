# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TCZ Tennis Club Booking iOS App - a SwiftUI app for managing tennis court reservations. Current version: 3.0.0 (compatible with server v3.7.0).

## Build Commands

Build the app:
```bash
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp -configuration Debug build
```

Build for simulator:
```bash
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp -sdk iphonesimulator -configuration Debug build
```

Clean build:
```bash
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp clean
```

**Note:** These commands require full Xcode installation. If only Command Line Tools are installed, build from Xcode IDE instead.

## Architecture

**MVVM with SwiftUI** - Clean separation between Views, ViewModels, and Models.

### Source Structure (TCZApp/TCZApp/)
- **Core/** - Networking layer: `APIClient.swift` (HTTP client with Bearer auth), `APIEndpoints.swift` (route definitions), `KeychainService.swift` (secure storage)
- **Models/** - Codable data structures: `Member`, `Reservation`, `AvailabilityGrid`, `BookingStatus`
- **ViewModels/** - State management with `@MainActor`: `AuthViewModel`, `DashboardViewModel`, `BookingViewModel`, `ReservationsViewModel`, `FavoritesViewModel`
- **Views/** - SwiftUI components organized by feature: Main, Authentication, Dashboard, Booking, Reservations, Favorites, Components

### Key Patterns
- All ViewModels use `@MainActor` for thread-safe UI updates
- `APIClientProtocol` enables dependency injection for testability
- Authentication uses Bearer tokens stored in Keychain
- Sparse data format for court availability (only occupied slots returned from API)

### Authentication Flow
1. Login via `APIClient.login()` → stores access token in Keychain
2. Bearer token added to all authenticated requests via `APIClient`
3. Session restoration on app launch via `AuthViewModel.checkStoredSession()`

### Navigation
- `MainTabView` with conditional tabs based on auth state
- Anonymous: Dashboard + Login placeholder
- Authenticated: Dashboard + Reservations + Favorites + Profile

## Server Configuration

- **Debug builds:** `http://10.0.0.147:5001` (local development)
- **Production:** `https://woifh.pythonanywhere.com`

Change in `APIClient.swift` → `baseURL` property.

## Related Codebases

The server backend and web app code is available locally for reference:
- **Location:** `/Users/woifh/tcz/web`
- **Use cases:** Search through these files to understand API behavior, endpoint implementations, and how the web app UI works

## Important Conventions

- **Language:** All UI text is in German
- **Timezone:** Uses `Europe/Berlin` for all date operations
- **Error messages:** German localized via `APIError` enum
- **Date formats:** Custom JSON decoder handles multiple API date formats

## Versioning

- `TCZApp/CHANGELOG.md` is the **single source of truth** for version numbers
- App version is parsed dynamically from CHANGELOG.md (first `## [X.Y]` entry after `[Unreleased]`)
- Do NOT create separate VERSION files - the changelog IS the version file
- Format: `## [major.minor] - YYYY-MM-DD` → displays as `major.minor.0` in app
- **Xcode archive version**: `MARKETING_VERSION` in project.pbxproj must match CHANGELOG.md
  - A build script warns if they differ, but you must update `MARKETING_VERSION` manually when bumping versions
  - Update both Debug and Release configurations in project.pbxproj

## Important Rules

- **CRITICAL: NEVER push to GitHub without explicit user request** - NEVER run `git push` unless the user explicitly asks you to push. This is the most important rule. Always wait for explicit permission before pushing any commits or tags.
- **CRITICAL: Always show changelog and wait for explicit approval before pushing** - Before any push, show the user the changelog entry that will be added. Then use AskUserQuestion to get explicit user confirmation before running git commit or git push. Do not proceed until the user explicitly approves the changelog.
- **When pushing to GitHub (only after user requests it)**:
  - Ask the user whether to increase major or minor version
  - Add a short, non-technical changelog entry to CHANGELOG.md (version format: major.minor)
  - **Update MARKETING_VERSION in project.pbxproj** to match the new version (both Debug and Release)
  - **Every code change must have a corresponding changelog entry** - don't push without updating the changelog first
  - Create a meaningful commit message
  - Push to GitHub
  - Create and push a git tag matching the changelog version (format: vX.Y.0, e.g., v3.9.0 for changelog version 3.9)
    - **Version sync rule**: CHANGELOG.md version and git tag MUST always match (e.g., changelog 3.10 → tag v3.10.0)


- **Git commit rules**:
  - NEVER use `git commit --amend` on commits that have been pushed to remote
  - NEVER use `--force` or `--force-with-lease` push unless explicitly requested
  - Always create new commits for fixes rather than amending

- **Adding new Swift files**:
  - New `.swift` files must be manually added to `TCZApp/TCZApp.xcodeproj/project.pbxproj`
  - Required entries in 4 sections: `PBXBuildFile`, `PBXFileReference`, `PBXGroup` (appropriate folder), and `PBXSourcesBuildPhase`
  - Use existing file entries as templates for the format and ID generation
  - Without these entries, Xcode will report "Cannot find X in scope" errors

## Vibe Coding Principles

This codebase prioritizes flow, clarity, and fast iteration.

### General Guidelines
- Prefer simple, readable code over clever abstractions
- Optimize for local reasoning: a reader should understand code in under a minute
- Keep changes small, reversible, and easy to delete
- Avoid premature abstraction; duplicate a little before extracting
- Make failures loud and obvious—no silent magic

### Naming & Structure
- Use clear, descriptive names; naming is more important than comments
- Keep related logic close together
- Avoid deep inheritance or excessive indirection

### Comments & Intent
- Comment *why* something exists, not *what the code does*
- Explain tradeoffs, constraints, or non-obvious decisions

### Testing Philosophy
- Write tests that increase confidence without slowing momentum
- Focus on behavior, not implementation details
- Prefer a few high-signal tests over exhaustive coverage

### Refactoring
- Refactor opportunistically when it improves clarity
- Do not refactor solely for architectural purity
- It should feel safe to rewrite or delete code

## Mandatory Rules

- **NEVER break existing functionality** - preserve working behavior at all costs
- **When in doubt, ask the user** - don't guess or assume; clarify before proceeding
- **Respect software development principles** - follow SOLID, DRY, KISS
- **Never mention Claude Code** - no references to Claude, AI, or this tool in changelogs, commits, or any project files