# TCZ iOS App

iOS app for the TCZ tennis court reservation system, built with SwiftUI.

## Requirements

- Xcode 15+
- iOS 16.0+
- Swift 5.0

## Dependencies

Managed via Swift Package Manager:

- [TOCropViewController](https://github.com/TimOliver/TOCropViewController) — Profile picture cropping

## Setup

1. Clone the repository
2. Open `TCZApp/TCZApp.xcodeproj` in Xcode
3. Build and run (⌘R)

### Server Configuration

The app connects to different servers based on build configuration:

| Build | URL |
|-------|-----|
| Debug (Simulator) | `http://localhost:5001` |
| Debug (Device) | `http://10.0.0.147:5001` |
| Release | `https://woifh.pythonanywhere.com` |

To change the local dev IP, edit `TCZApp/Core/APIClient.swift`.

### Running Local Backend

To test with the local backend:

```bash
cd /Users/woifh/tcz/tcz-web
source .venv/bin/activate && flask run --host=0.0.0.0 --port=5001
```

## Project Structure

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
└── TCZAppTests/    # Unit tests
```

## Architecture

**MVVM with SwiftUI**

- **Models** — Codable structs for API data
- **ViewModels** — `@MainActor` classes managing state and business logic
- **Views** — SwiftUI views organized by feature

Key patterns:
- `APIClientProtocol` for dependency injection
- Bearer token authentication stored in Keychain
- Sparse availability data format (only occupied slots sent)

## Features

- Court availability grid (6 courts, swipeable pages)
- Book courts for yourself or other members
- Push notifications for bookings
- Favorites for quick member selection
- Profile management with photo upload
- Dark/light mode theming
- Offline-friendly with data caching

## Testing

Run tests in Xcode with ⌘U, or via command line:

```bash
xcodebuild test -project TCZApp/TCZApp.xcodeproj -scheme TCZApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Test infrastructure includes:
- `MockAPIClient` and `MockKeychainService` for dependency injection
- ViewModel tests for all major features
- Model decoding tests

## Versioning

- Version is read from `TCZApp/CHANGELOG.md`
- Format: `major.minor` (e.g., 8.1)
- `MARKETING_VERSION` in Xcode must match CHANGELOG.md
- Git tags use format `vX.Y.0`

## Related Projects

| Project | Path | Description |
|---------|------|-------------|
| Web Backend | `tcz-web/` | Flask API + Web UI |
| Android App | `tcz-android/` | Kotlin/Compose app |
