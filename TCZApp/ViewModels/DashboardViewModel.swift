import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var availability: AvailabilityResponse?
    @Published var bookingStatus: BookingStatusResponse?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage: Int = 0
    @Published var isPaymentConfirmationDismissed = false

    private let apiClient: APIClientProtocol
    private(set) var currentUserId: String?

    // Cache for availability data: [dateString: (response, timestamp)]
    private var availabilityCache: [String: (AvailabilityResponse, Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    // Time slots: 08:00 to 21:00 (14 slots)
    let timeSlots = (8..<22).map { String(format: "%02d:00", $0) }
    let courtNumbers = [1, 2, 3, 4, 5, 6]

    // Pagination: 3 courts per page
    let courtsPerPage = 3
    var totalPages: Int { 2 }

    func courtIndicesForPage(_ page: Int) -> Range<Int> {
        let start = page * courtsPerPage
        let end = min(start + courtsPerPage, courtNumbers.count)
        return start..<end
    }

    func pageLabelForPage(_ page: Int) -> String {
        let start = page * courtsPerPage + 1
        let end = min(start + courtsPerPage - 1, courtNumbers.count)
        return "Plätze \(start)-\(end)"
    }


    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func setCurrentUserId(_ id: String) {
        self.currentUserId = id
    }

    // MARK: - Cache Management

    private func getCachedAvailability(for dateString: String) -> AvailabilityResponse? {
        guard let (response, timestamp) = availabilityCache[dateString] else { return nil }
        if Date().timeIntervalSince(timestamp) < cacheTTL {
            return response
        }
        availabilityCache.removeValue(forKey: dateString)
        return nil
    }

    private func cacheAvailability(_ response: AvailabilityResponse, for dateString: String) {
        availabilityCache[dateString] = (response, Date())
    }

    func clearCache() {
        availabilityCache.removeAll()
    }

    func loadData() async {
        clearCache()
        isLoading = true
        error = nil

        // Load availability and booking status in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailability() }
            group.addTask { await self.loadBookingStatus() }
        }

        isLoading = false
    }

    func loadAvailability() async {
        let dateString = DateFormatterService.apiDate.string(from: selectedDate)

        // Return cached data immediately if available
        if let cached = getCachedAvailability(for: dateString) {
            availability = cached
            prefetchAdjacentDates()
            return
        }

        do {
            let response: AvailabilityResponse = try await apiClient.request(.availability(date: dateString), body: nil)
            cacheAvailability(response, for: dateString)
            availability = response
            prefetchAdjacentDates()
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Fehler beim Laden der Verfuegbarkeit"
        }
    }

    func loadBookingStatus() async {
        // Only load booking status for authenticated users
        guard currentUserId != nil else {
            bookingStatus = nil
            return
        }

        do {
            bookingStatus = try await apiClient.request(.reservationStatus, body: nil)
        } catch {
            // Silently ignore for anonymous users or auth errors
            bookingStatus = nil
        }
    }

    private func prefetchAdjacentDates() {
        Task.detached(priority: .low) { [weak self] in
            guard let self = self else { return }
            let calendar = Calendar.current
            let currentDate = await self.selectedDate

            for offset in [-1, 1] {
                if let adjacentDate = calendar.date(byAdding: .day, value: offset, to: currentDate) {
                    let dateString = DateFormatterService.apiDate.string(from: adjacentDate)
                    if await self.getCachedAvailability(for: dateString) == nil {
                        do {
                            let response: AvailabilityResponse = try await self.apiClient.request(.availability(date: dateString), body: nil)
                            await self.cacheAvailability(response, for: dateString)
                        } catch {
                            // Silently ignore prefetch failures
                        }
                    }
                }
            }
        }
    }

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            Task {
                await loadAvailability()
            }
        }
    }

    func goToToday() {
        selectedDate = Date()
        Task {
            await loadAvailability()
        }
    }

    func getSlot(courtIndex: Int, time: String) -> TimeSlot? {
        guard let courts = availability?.courts,
              courtIndex < courts.count else {
            return nil
        }

        // Check if this time slot is in the occupied array (sparse format)
        if let occupied = courts[courtIndex].occupied.first(where: { $0.time == time }) {
            return TimeSlot(time: occupied.time, status: occupied.status, details: occupied.details)
        }

        // Slot not in occupied array = available
        return TimeSlot(time: time, status: .available, details: nil)
    }

    /// Returns the court ID and number for a given index
    func getCourtInfo(courtIndex: Int) -> (id: Int, number: Int) {
        guard let courts = availability?.courts,
              courtIndex < courts.count else {
            // Fallback: assume court ID equals court number (1-6)
            return (id: courtIndex + 1, number: courtIndex + 1)
        }
        let court = courts[courtIndex]
        return (id: court.courtId, number: court.courtNumber)
    }

    func isSlotInPast(time: String) -> Bool {
        let now = Date()
        let berlinTimeZone = TimeZone(identifier: "Europe/Berlin")!

        var berlinCalendar = Calendar.current
        berlinCalendar.timeZone = berlinTimeZone

        // If selected date is before today, all slots are in the past
        if berlinCalendar.compare(selectedDate, to: now, toGranularity: .day) == .orderedAscending {
            return true
        }

        // If selected date is after today, no slots are in the past
        if berlinCalendar.compare(selectedDate, to: now, toGranularity: .day) == .orderedDescending {
            return false
        }

        // For today, check the hour
        let currentHour = berlinCalendar.component(.hour, from: now)
        if let slotHour = Int(time.prefix(2)) {
            return slotHour <= currentHour
        }
        return false
    }

    func canBookSlot(_ slot: TimeSlot?, time: String) -> Bool {
        guard let slot = slot,
              slot.status == .available,
              !isSlotInPast(time: time) else {
            return false
        }
        return true
    }

    func canCancelSlot(_ slot: TimeSlot?) -> Bool {
        guard let slot = slot,
              let details = slot.details,
              let userId = currentUserId else {
            return false
        }

        // Short notice bookings cannot be cancelled
        if slot.status == .shortNotice || details.isShortNotice == true {
            return false
        }

        // User can cancel if they booked it or if it's for them
        return details.bookedForId == userId || details.bookedById == userId
    }

    func isUserBooking(_ slot: TimeSlot?) -> Bool {
        guard let slot = slot,
              let details = slot.details,
              let userId = currentUserId else {
            return false
        }
        return details.bookedForId == userId || details.bookedById == userId
    }

    // Cancel a reservation
    func cancelReservation(_ reservationId: Int) async {
        isLoading = true
        do {
            let _: CancelResponse = try await apiClient.request(
                .cancelReservation(id: reservationId), body: nil
            )
            // Reload data to reflect the cancellation
            await loadData()
        } catch {
            self.error = "Stornierung fehlgeschlagen"
        }
        isLoading = false
    }

    var formattedSelectedDate: String {
        DateFormatterService.fullDate.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}
