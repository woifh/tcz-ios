# Changelog

All notable changes to the TCZ Tennis App will be documented in this file.

## [Unreleased]

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
