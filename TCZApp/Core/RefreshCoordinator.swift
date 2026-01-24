import Foundation
import Combine

/// Coordinates refresh events between Dashboard and Reservations screens.
/// Uses Combine PassthroughSubject to publish events for silent data refresh.
final class RefreshCoordinator {
    static let shared = RefreshCoordinator()

    /// Published when availability data needs refresh (e.g., after cancellation on Reservations screen)
    let availabilityRefresh = PassthroughSubject<Void, Never>()

    /// Published when reservations list needs refresh (e.g., after booking or cancellation on Dashboard)
    let reservationsRefresh = PassthroughSubject<Void, Never>()

    private init() {}
}
