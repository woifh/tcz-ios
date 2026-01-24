import Foundation
import Combine

@MainActor
final class ReservationsViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var cancellingId: Int?

    private let apiClient: APIClientProtocol
    private(set) var currentUserId: String?
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        observeRefreshEvents()
    }

    private func observeRefreshEvents() {
        RefreshCoordinator.shared.reservationsRefresh
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.silentRefresh()
                }
            }
            .store(in: &cancellables)
    }

    func silentRefresh() async {
        do {
            let response: ReservationsResponse = try await apiClient.request(.reservations, body: nil)
            if response.reservations != reservations {
                reservations = response.reservations
            }
        } catch {
            // Silently ignore
        }
    }

    func setCurrentUserId(_ id: String) {
        self.currentUserId = id
    }

    func loadReservations() async {
        isLoading = true
        error = nil

        do {
            let response: ReservationsResponse = try await apiClient.request(.reservations, body: nil)
            reservations = response.reservations
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Fehler beim Laden der Buchungen"
        }

        isLoading = false
    }

    func cancelReservation(_ id: Int) async -> Bool {
        cancellingId = id

        do {
            let _: CancelResponse = try await apiClient.request(
                .cancelReservation(id: id), body: nil
            )

            // Remove from local list
            reservations.removeAll { $0.id == id }

            cancellingId = nil

            // Notify Dashboard to refresh availability
            RefreshCoordinator.shared.availabilityRefresh.send()

            return true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            cancellingId = nil
            return false
        } catch {
            self.error = "Fehler beim Stornieren"
            cancellingId = nil
            return false
        }
    }

    func refresh() async {
        await loadReservations()
    }

    // Split reservations by type
    var myReservations: [Reservation] {
        guard let userId = currentUserId else { return reservations }
        return reservations.filter { $0.bookedForId == userId }
    }

    var bookingsForOthers: [Reservation] {
        guard let userId = currentUserId else { return [] }
        return reservations.filter { $0.bookedById == userId && $0.bookedForId != userId }
    }
}
