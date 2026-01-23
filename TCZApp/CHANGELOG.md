# Changelog

All notable changes to the TCZ Tennis App will be documented in this file.

## [Unreleased]
### Added
- About screen: tap TCZ logo on dashboard to view app info, licenses, and impressum
- Profile picture cropping: zoom and move to select the perfect area for your photo

### Changed
- Redesigned booking modal with compact chip layout for better keyboard handling
- Member search results now stay visible when typing with phone keyboard
- Moved App Info section from Profile to new About screen

## [8.2] - 2026-01-22
### Changed
- Redesigned court grid with rounded tile styling and spacing between cells
- Booked slots now use green background for a calmer look
- Profile pictures centered in booked slots (name only when no picture)
- Court header and page navigation now stay visible when scrolling
- Booking modal now has fixed confirm button at bottom for better usability

### Fixed
- Profile picture now loads correctly when opening profile settings
- Dashboard properly refreshes when logging out

## [8.1] - 2026-01-21
### Added
- Take profile selfies directly with front camera

## [8.0] - 2026-01-21
### Added
- Push notifications: receive instant alerts when someone books a court for you
- Separate notification settings for email and push notifications
- Configure which notification types you want to receive for each channel

### Fixed
- Push notifications now register correctly after login

## [7.1] - 2026-01-21
### Fixed
- Selected date now preserved when switching between tabs

## [7.0] - 2026-01-21
### Changed
- Improved app stability and code quality
- Better accessibility support with VoiceOver labels
- Thread-safe operations for smoother performance

## [6.1] - 2026-01-20
### Added
- Profile pictures now shown in booking grid for reserved slots

### Changed
- Faster calendar navigation with 14-day data preloading on app launch
- Intelligent prefetching loads additional days as you navigate

## [6.0] - 2026-01-20
### Added
- Profile pictures: upload and display your photo across the app
- Profile pictures shown in favorites list, member search, and bookings
- Theme settings: choose between dark mode, light mode, or follow system settings

### Changed
- Profile access moved to header: tap your profile picture to open settings
- Simplified tab bar with 3 tabs (Dashboard, Bookings, Favorites)
- Profile picture buttons now use icons instead of text
- Logout is now instant with immediate navigation to the overview
- Faster date navigation with instant feedback when switching days
- Cancellations now update instantly with background server sync
- Connection errors now show alert popups when server is unreachable

## [5.2] - 2026-01-20
### Added
- Unit test infrastructure covering ViewModels and Models

### Changed
- Favorites now show remove button directly instead of requiring swipe gesture

### Fixed
- Error messages in booking modal now clear when selecting a different member
- "No member found" message now scrolls into view when keyboard is open

## [5.1] - 2026-01-20
### Changed
- Cancellation rules now determined by server for consistent behavior across all devices
- Date navigation now stays visible when scrolling through court times

### Fixed
- Court availability now always refreshes when switching dates
- TestFlight release notes now populate automatically
- Court grid page switching now animates smoothly

## [5.0] - 2026-01-19
### Added
- Temporary court blocks now shown in yellow with "(vorübergehend)" label
- Suspended reservations display "Pausiert" badge with suspension reason
- Suspended reservations can now be cancelled from "Meine Buchungen"
- Legend updated with temporary block indicator

## [4.1] - 2026-01-19
### Added
- Automatic TestFlight release notes from changelog

## [4.0] - 2026-01-19
### Changed
- New swipeable date strip for faster day-by-day navigation
- Today indicator now shows in light orange when viewing other dates
- "Heute" button scrolls calendar strip back to current day

## [3.11] - 2026-01-19
### Changed
- Email verification badge now displays inline next to email address in profile

### Fixed
- Short-term bookings now available for ongoing time slots (current hour)

## [3.10] - 2026-01-19
### Added
- Reservations made on behalf of others now show the booker's name in the court grid
- "Buchungen für andere" section now displays who each booking is for
- Email verification status badge in profile edit screen
- Banner and section for unverified emails with option to resend verification

## [3.9] - 2026-01-18
### Added
- Payment reminder banner on dashboard shows days until payment deadline
- Confirmation dialog before sending payment confirmation request
- Payment confirmation info banner can now be dismissed with (X) button

### Changed
- User data now refreshes automatically when opening the app

## [3.8] - 2026-01-18
### Fixed
- App now automatically retries on temporary server errors during startup
- Member search results now scroll into view automatically when keyboard is open

### Changed
- Version number now read directly from changelog (no more separate VERSION file)
- Build warns if Xcode project version differs from changelog
- App now uses informal "du" instead of formal "Sie" throughout

## [3.7] - 2026-01-18
### Added
- Book on behalf of another member: search for any club member when creating a booking

## [3.6] - 2026-01-18
### Added
- Changelog viewer: tap on app or server version to see release history

## [3.5] - 2026-01-18
### Changed
- Cleaner visual design for court availability grid (available slots now white instead of green)
- Past time slots now appear more muted for better focus on current availability

## [3.4] - 2026-01-17
### Added
- Profile editing: users can now update their personal data, contact info, address, password, and notification preferences

## [3.3] - 2026-01-16
### Changed
- Faster date switching with cached availability data
- Adjacent dates are now preloaded in the background
- App and server version now displayed in profile
- App icon shown on login screen

## [3.2] - 2026-01-15
### Changed
- Improved court page indicator with text labels instead of dots
- Court grid now shows all time slots instead of limiting to 8
- Redesigned date selector with larger touch targets
- Legend is now accessible via info icon instead of inline display
- Added calendar picker for quick date selection
- Today button now always visible with visual state indication
- Added app icon to navigation bar
- Booking limits now always visible in date selector
- Moved legend info icon to court page indicator row

### Fixed
- App now correctly logs out when session expires

## [3.1] - 2026-01-15
### Changed
- Improved code quality with centralized date formatting
- Better testability through protocol-based services

## [3.0.0] - 2026-01-15
### Changed
- Updated to work with server version 3.7.0
- Improved booking dialog reliability
- Optimized data loading for better performance

### Fixed
- Court availability display now loads correctly
- Booking a court now works properly
- "My Bookings" list displays correctly

## [2.0.0] - 2025-01-14
### Changed
- Compact header layout for more screen space
- Secure token-based authentication

## [1.0.1] - 2025-01-11
### Fixed
- Profile view now dynamically reads version from app bundle and server URL from APIClient

## [1.0.0] - 2025-01-11
### Added
- Initial release
- Court availability grid with 6 courts (Plätze 1-6)
- Swipeable court pages (1-3 and 4-6)
- Improved grid readability with 8 visible time slots and vertical scrolling
- Booking management (create, view, cancel)
- User authentication with session management
- Favorite members management for quick booking
- Booking quota tracking (regular + short-notice reservations)
- Date navigation with "Today" quick access
- Legend for slot status (Frei, Gebucht, Kurzfristig, Gesperrt)
- User's own bookings highlighted with blue border
