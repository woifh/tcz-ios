# CLAUDE.md — TCZ iOS (SwiftUI)

This file contains iOS-specific guidance.
Shared rules (git, releases, vibe coding) are in `/Users/woifh/tcz/CLAUDE.md`.

---

## 🔗 Cross-Project Context

This app **consumes the API** defined by the web backend.

### Related Codebases

| Project | Path | Relationship |
|---------|------|--------------|
| Web Backend | `/Users/woifh/tcz/tcz-web` | Defines API we consume |
| Android App | `/Users/woifh/tcz/tcz-android` | Sibling app, same API |

### Cross-Project Search

See "Cross-Project Search" in the parent CLAUDE.md (`/Users/woifh/tcz/CLAUDE.md`) for grep commands.

### API Debugging Tips

- **Getting unexpected data?** → Check endpoint in `tcz-web/app/routes/api/`
- **401 errors?** → Check auth flow in `tcz-web/app/routes/api/auth.py`
- **Different behavior than Android?** → Compare implementations
- **New endpoint needed?** → Ask to create it in tcz-web first

---

## 🔧 Build Commands

```bash
# Build (Debug)
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp -configuration Debug build

# Build for Simulator
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp -sdk iphonesimulator build

# Clean
xcodebuild -project TCZApp/TCZApp.xcodeproj -scheme TCZApp clean
```

⚠️ **Note:** On this machine, xcodebuild commands may not work reliably. Always ask the user to build manually in Xcode to verify changes compile correctly.

---

## 🏗️ Architecture

**MVVM with SwiftUI** — Clean separation between Views, ViewModels, and Models.

### Source Structure (TCZApp/)

```
TCZApp/
├── Core/           # Networking, services, utilities
├── Models/         # Codable data structures
├── ViewModels/     # State management (@MainActor)
├── Views/          # SwiftUI views organized by feature
│   ├── Authentication/
│   ├── Booking/
│   ├── Components/
│   ├── Dashboard/
│   ├── Favorites/
│   ├── Main/
│   ├── Profile/
│   └── Reservations/
├── Resources/      # Assets.xcassets
└── TCZAppTests/    # Unit tests with mocks
```

### Where to Put Things

| Type | Location |
|------|----------|
| API client code | `Core/` |
| Data models | `Models/` |
| Business logic | `ViewModels/` |
| UI components | `Views/` |

### Key Patterns

- All ViewModels use `@MainActor` for thread-safe UI updates
- `APIClientProtocol` enables dependency injection
- Bearer tokens stored in Keychain
- Sparse data format for availability (only occupied slots)

### Authentication Flow

1. Login via `APIClient.login()` → stores token in Keychain
2. Bearer token added to all authenticated requests
3. Session restore on launch via `AuthViewModel.checkStoredSession()`

### Navigation

- `MainTabView` with conditional tabs based on auth state
- Anonymous: Dashboard + Login placeholder
- Authenticated: Dashboard + Reservations + Favorites + Profile

---

## 🧪 Testing

### Test Commands

```bash
# Run all tests
xcodebuild test -project TCZApp/TCZApp.xcodeproj -scheme TCZApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project TCZApp/TCZApp.xcodeproj -scheme TCZApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:TCZAppTests/AuthViewModelTests
```

⚠️ **Note:** If xcodebuild fails, ask user to run tests manually in Xcode (⌘U).

### When to Test

- After modifying ViewModels
- After changing API integration
- After modifying model decoding
- Before declaring a feature complete

### Manual Testing

Always ask user to verify changes in Xcode:
1. Build succeeds (⌘B)
2. App runs in simulator
3. Affected feature works correctly

### Test Infrastructure

The project has comprehensive test coverage with mocks for dependency injection:

- `TCZAppTests/Mocks/MockAPIClient.swift` — Mock API client for unit tests
- `TCZAppTests/Mocks/MockKeychainService.swift` — Mock keychain for auth tests
- `TCZAppTests/Helpers/TestData.swift` — Shared test fixtures

Test files exist for all ViewModels (AuthViewModelTests, DashboardViewModelTests, etc.)

---

## 🌐 Server Configuration

Server URL is set at **compile-time** via `#if DEBUG` in `Core/APIClient.swift`:

| Build | URL |
|-------|-----|
| Debug (Simulator) | `http://localhost:5001` |
| Debug (Device) | `http://10.0.0.147:5001` |
| Release | `https://woifh.pythonanywhere.com` |

### Changing Local Dev IP

If your Mac's IP changes from `10.0.0.147`:

1. Find new IP: `ipconfig getifaddr en0`
2. Edit `TCZApp/Core/APIClient.swift`
3. Update the IP in the `#else` branch under `#if DEBUG`
4. Rebuild the app

### Network Security

- `NSAllowsLocalNetworking` enabled in `Info.plist` for local dev
- Release builds enforce HTTPS (will fail on HTTP URLs)

---

## 📦 Versioning

- `TCZApp/CHANGELOG.md` is the **single source of truth**
- App version parsed dynamically from CHANGELOG.md
- Format: `## [major.minor] - YYYY-MM-DD` → displays as `major.minor.0`
- Git tag format: `vX.Y.0` (e.g., changelog 3.10 → tag v3.10.0)

### Xcode Version Sync

- `MARKETING_VERSION` in `project.pbxproj` must match CHANGELOG.md
- Update both Debug and Release configurations when bumping versions

### Release Configuration (for woifh workflows)

| Setting | Value |
|---------|-------|
| CHANGELOG | `TCZApp/CHANGELOG.md` |
| Version file | `TCZApp/TCZApp.xcodeproj/project.pbxproj` |
| Version keys | `MARKETING_VERSION` (both Debug and Release) |
| Test command | Manual in Xcode (⌘U) or `xcodebuild test ...` |

---

## 📝 Adding New Swift Files

New `.swift` files must be manually added to `TCZApp/TCZApp.xcodeproj/project.pbxproj`.

Required entries in 4 sections:
1. `PBXBuildFile`
2. `PBXFileReference`
3. `PBXGroup` (appropriate folder)
4. `PBXSourcesBuildPhase`

Use existing file entries as templates. Without these entries, Xcode reports "Cannot find X in scope".

**Tip:** After adding a file, always ask user to verify it compiles in Xcode.

---

## ⚠️ Common Mistakes to Avoid

- New files must be added to `project.pbxproj` manually
- `@MainActor` required on all ViewModels
- Keychain access can fail silently in simulator — test on device for auth issues
- Don't assume API response format — check tcz-web implementation
- Don't forget to handle token expiration (401 responses)

---

## 📚 Key Files

| File | Purpose |
|------|---------|
| `TCZApp.swift` | App entry point |
| `Core/APIClient.swift` | Network layer, server URL config |
| `Core/APIEndpoints.swift` | Endpoint URL construction |
| `Core/APIError.swift` | API error type definitions |
| `Core/AppDelegate.swift` | App lifecycle, push notifications |
| `Core/AppTheme.swift` | App-wide theme/styling constants |
| `Core/DateFormatterService.swift` | Date formatting utilities |
| `Core/KeychainService.swift` | Secure token storage |
| `Core/LayoutConstants.swift` | UI layout constants |
| `Core/ProfilePictureCache.swift` | Profile image caching |
| `Core/PushNotificationService.swift` | Push notification handling |
| `Models/Reservation.swift` | Core data model |
| `ViewModels/AuthViewModel.swift` | Authentication state |
| `CHANGELOG.md` | Version source of truth |
