import Foundation
import CoreGraphics

/// Centralized layout constants to avoid magic numbers throughout the codebase.
/// Use these constants instead of hardcoded values for consistent styling.
enum LayoutConstants {
    // MARK: - Profile Pictures
    /// Large profile picture (profile page header)
    static let profilePictureLarge: CGFloat = 100
    /// Medium profile picture (profile view, list headers)
    static let profilePictureMedium: CGFloat = 60
    /// Standard profile picture (list rows)
    static let profilePictureStandard: CGFloat = 44
    /// Small profile picture (compact lists, search results)
    static let profilePictureSmall: CGFloat = 40
    /// Tiny profile picture (inline, booking sheet)
    static let profilePictureTiny: CGFloat = 36

    // MARK: - Court Grid
    /// Height of each time slot row in the court grid
    static let courtGridRowHeight: CGFloat = 65
    /// Height of the court header row
    static let courtGridHeaderHeight: CGFloat = 36
    /// Width of the time column in the grid
    static let courtGridTimeColumnWidth: CGFloat = 60
    /// Corner radius for court grid cells
    static let courtGridCellCornerRadius: CGFloat = 8
    /// Spacing between court grid cells
    static let courtGridCellSpacing: CGFloat = 8
    /// Profile picture size for booked slot cells
    static let courtGridProfilePictureSize: CGFloat = 28
    /// Dash pattern for available slot border [dash length, gap length]
    static let courtGridAvailableBorderDash: [CGFloat] = [4, 3]
    /// Border width for available slot dashed border
    static let courtGridAvailableBorderWidth: CGFloat = 1.5

    // MARK: - Date Navigation
    /// Height of the date strip view
    static let dateStripHeight: CGFloat = 70
    /// Width of each day cell in the date strip
    static let dayCellWidth: CGFloat = 50
    /// Height of each day cell in the date strip
    static let dayCellHeight: CGFloat = 60

    // MARK: - Login
    /// Size of the app logo on login screen
    static let loginLogoSize: CGFloat = 80

    // MARK: - Icons
    /// Size for large decorative icons (empty states, errors)
    static let iconSizeLarge: CGFloat = 50
    /// Size for medium icons
    static let iconSizeMedium: CGFloat = 36

    // MARK: - Spacing
    /// Standard horizontal padding
    static let horizontalPadding: CGFloat = 24
    /// Standard vertical padding
    static let verticalPadding: CGFloat = 16
    /// Compact vertical padding for list rows
    static let listRowVerticalPadding: CGFloat = 4
    /// Badge padding (horizontal)
    static let badgePaddingHorizontal: CGFloat = 6
    /// Badge padding (vertical)
    static let badgePaddingVertical: CGFloat = 2
}

/// Date range constants for availability views.
enum DateRangeConstants {
    /// Number of days in the past to show
    static let pastDays = 30
    /// Number of days in the future to show
    static let futureDays = 365
    /// Total days in the date range
    static var totalDays: Int { pastDays + futureDays + 1 }
}
