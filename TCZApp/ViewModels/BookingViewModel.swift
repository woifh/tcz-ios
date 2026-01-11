import Foundation

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var selectedMemberId: Int?
    @Published var favorites: [MemberSummary] = []
    @Published var isLoading = false
    @Published var isLoadingFavorites = false
    @Published var error: String?
    @Published var isSuccess = false

    private let apiClient: APIClientProtocol

    var courtId: Int = 0
    var courtNumber: Int = 0
    var time: String = ""
    var date: Date = Date()
    var currentUserId: Int?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        return formatter
    }()

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func setup(courtId: Int, courtNumber: Int, time: String, date: Date, currentUserId: Int) {
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
            error = "Bitte waehlen Sie ein Mitglied aus"
            return false
        }

        isLoading = true
        error = nil
        isSuccess = false

        let request = CreateBookingRequest(
            courtId: courtId,
            date: dateFormatter.string(from: date),
            startTime: time,
            bookedForId: bookedForId
        )

        do {
            let _: BookingCreatedResponse = try await apiClient.request(
                .createReservation, body: request
            )
            isSuccess = true
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isLoading = false
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
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
