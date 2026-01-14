# Changelog

All notable changes to the TCZ Tennis App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
