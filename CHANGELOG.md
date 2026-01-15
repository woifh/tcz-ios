# Changelog

All notable changes to the TCZ Tennis App will be documented in this file.

## [Unreleased]

## [3.2] - 2026-01-15
### Changed
- Improved court page indicator with text labels instead of dots
- Court grid now shows all time slots instead of limiting to 8
- Redesigned date selector with larger touch targets
- Legend is now accessible via info icon instead of inline display
- Added calendar picker for quick date selection
- Today button now always visible with visual state indication

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
- Court availability grid with 6 courts (Plaetze 1-6)
- Swipeable court pages (1-3 and 4-6)
- Improved grid readability with 8 visible time slots and vertical scrolling
- Booking management (create, view, cancel)
- User authentication with session management
- Favorite members management for quick booking
- Booking quota tracking (regular + short-notice reservations)
- Date navigation with "Today" quick access
- Legend for slot status (Frei, Gebucht, Kurzfristig, Gesperrt)
- User's own bookings highlighted with blue border
