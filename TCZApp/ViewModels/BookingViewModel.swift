import Foundation

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var selectedMemberId: String?
    @Published var favorites: [MemberSummary] = []
    @Published var isLoading = false
    @Published var isLoadingFavorites = false
    @Published var error: String?
    @Published var isSuccess = false

    // Search-related properties
    @Published var searchQuery = ""
    @Published var searchResults: [MemberSummary] = []
    @Published var isSearching = false
    @Published var showSearch = false

    // Conflict resolution properties
    @Published var showConflictResolution = false
    @Published var activeSessions: [ActiveSession] = []
    @Published var cancellingSessionId: Int?
    @Published var conflictError: String?

    private let apiClient: APIClientProtocol

    var courtId: Int = 0
    var courtNumber: Int = 0
    var time: String = ""
    var date: Date = Date()
    var currentUserId: String?


    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func setup(courtId: Int, courtNumber: Int, time: String, date: Date, currentUserId: String) {
        self.courtId = courtId
        self.courtNumber = courtNumber
        self.time = time
        self.date = date
        self.currentUserId = currentUserId
        self.selectedMemberId = currentUserId

        Task {
            await loadFavorites()
        }
    }

    func loadFavorites() async {
        guard let userId = currentUserId ?? selectedMemberId else { return }

        isLoadingFavorites = true

        do {
            let response: FavoritesResponse = try await apiClient.request(
                .favorites(memberId: userId), body: nil
            )
            favorites = response.favourites
        } catch {
            print("Error loading favorites: \(error)")
        }

        isLoadingFavorites = false
    }

    func createBooking() async -> Bool {
        guard let bookedForId = selectedMemberId else {
            error = "Bitte wähle ein Mitglied aus"
            return false
        }

        isLoading = true
        error = nil
        isSuccess = false

        let request = CreateBookingRequest(
            courtId: courtId,
            date: DateFormatterService.apiDate.string(from: date),
            startTime: time,
            bookedForId: bookedForId
        )

        do {
            let _: BookingCreatedResponse = try await apiClient.request(
                .createReservation, body: request
            )
            isSuccess = true
            isLoading = false

            // Refresh favorites (server may have added new favorite)
            await loadFavorites()

            return true
        } catch let apiError as APIError {
            isLoading = false

            // Check for booking limit error with active sessions
            if case .bookingLimitExceeded(_, let sessions) = apiError {
                activeSessions = sessions
                showConflictResolution = true
                return false
            }

            error = apiError.localizedDescription
            return false
        } catch {
            self.error = "Fehler beim Erstellen der Buchung"
            isLoading = false
            return false
        }
    }

    var timeRange: String {
        guard let hour = Int(time.prefix(2)) else { return time }
        return "\(time) - \(String(format: "%02d:00", hour + 1))"
    }

    var formattedDate: String {
        DateFormatterService.displayDate.string(from: date)
    }

    // MARK: - Search functionality

    func searchMembers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let response: SearchResponse = try await apiClient.request(
                .searchMembers(query: query), body: nil
            )
            // Filter out already favorited members and self
            let favoriteIds = Set(favorites.map { $0.id })
            searchResults = response.results.filter { member in
                member.id != currentUserId && !favoriteIds.contains(member.id)
            }
        } catch {
            searchResults = []
        }

        isSearching = false
    }

    func selectSearchedMember(_ member: MemberSummary) {
        // Add to local favorites for immediate UI display
        // Server will persist the favourite when booking is created
        favorites.append(member)
        selectedMemberId = member.id
        resetSearch()
    }

    func resetSearch() {
        showSearch = false
        searchQuery = ""
        searchResults = []
    }

    func toggleSearch() {
        showSearch.toggle()
        if !showSearch {
            resetSearch()
        }
    }

    // MARK: - Conflict Resolution

    /// Cancel an active session to make room for new booking, then auto-retry
    func cancelSession(_ sessionId: Int) async -> Bool {
        cancellingSessionId = sessionId
        conflictError = nil

        do {
            let _: CancelResponse = try await apiClient.request(
                .cancelReservation(id: sessionId), body: nil
            )

            // Remove from local list
            activeSessions.removeAll { $0.reservationId == sessionId }
            cancellingSessionId = nil

            // Auto-retry the booking
            return await retryBooking()
        } catch let apiError as APIError {
            conflictError = apiError.localizedDescription
            cancellingSessionId = nil
            return false
        } catch {
            conflictError = "Fehler beim Stornieren"
            cancellingSessionId = nil
            return false
        }
    }

    /// Retry the original booking after cancellation
    private func retryBooking() async -> Bool {
        isLoading = true
        conflictError = nil

        guard let bookedForId = selectedMemberId else {
            conflictError = "Bitte wähle ein Mitglied aus"
            isLoading = false
            return false
        }

        let request = CreateBookingRequest(
            courtId: courtId,
            date: DateFormatterService.apiDate.string(from: date),
            startTime: time,
            bookedForId: bookedForId
        )

        do {
            let _: BookingCreatedResponse = try await apiClient.request(
                .createReservation, body: request
            )
            isSuccess = true
            showConflictResolution = false
            isLoading = false
            return true
        } catch let apiError as APIError {
            // Check if this is another booking limit error (edge case)
            if case .bookingLimitExceeded(_, let sessions) = apiError {
                activeSessions = sessions
                isLoading = false
                return false
            }
            conflictError = apiError.localizedDescription
            isLoading = false
            return false
        } catch {
            conflictError = "Fehler beim Erstellen der Buchung"
            isLoading = false
            return false
        }
    }

    /// Return to normal booking view without changes
    func dismissConflictResolution() {
        showConflictResolution = false
        activeSessions = []
        conflictError = nil
    }
}
