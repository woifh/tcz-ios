import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var availability: AvailabilityResponse?
    @Published var bookingStatus: BookingStatusResponse?
    @Published var isLoading = false
    @Published var isRefreshing = false  // Background refresh with cached data visible
    @Published var error: String?
    @Published var cancellationError: String?  // Error alert for failed cancellation
    @Published var connectionError: String?    // Error alert for API/network failures
    @Published var currentPage: Int = 0
    @Published var isPaymentConfirmationDismissed = false
    @Published var isEmailVerificationDismissed = false

    private let apiClient: APIClientProtocol
    private(set) var currentUserId: String?

    // MARK: - Cache Infrastructure

    /// Cache entry with timestamp for staleness/expiry checking
    private struct CacheEntry {
        let response: AvailabilityResponse
        let fetchedAt: Date

        /// Cache is expired after 5 minutes (hard limit)
        var isExpired: Bool {
            Date().timeIntervalSince(fetchedAt) > 300
        }
    }

    /// Cache for availability data: [dateString: CacheEntry]
    private var availabilityCache: [String: CacheEntry] = [:]

    /// Track in-flight range requests to prevent duplicates
    private var pendingRangeFetches: Set<String> = []

    // Range fetching constants
    private let initialFetchDays = 14      // Days to fetch on app launch
    private let prefetchDays = 7           // Days to fetch when prefetching
    private let prefetchBuffer = 3         // Prefetch when within N days of edge

    // Task management for cancellation
    private var currentAvailabilityTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    // Track if initial load has completed to avoid resetting to today on tab return
    private var hasPerformedInitialLoad = false

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

    func clearCurrentUserId() {
        self.currentUserId = nil
    }

    // MARK: - Cache Management

    /// Get cached availability if not expired (5 min hard limit)
    private func getCachedAvailability(for dateString: String) -> AvailabilityResponse? {
        guard let entry = availabilityCache[dateString], !entry.isExpired else {
            availabilityCache.removeValue(forKey: dateString)
            return nil
        }
        return entry.response
    }

    /// Check if date has any cached data (regardless of expiry)
    private func hasCachedData(for dateString: String) -> Bool {
        return availabilityCache[dateString] != nil
    }

    private func cacheAvailability(_ response: AvailabilityResponse, for dateString: String) {
        availabilityCache[dateString] = CacheEntry(response: response, fetchedAt: Date())
    }

    /// Cache multiple days from a range API response
    private func cacheRangeResponse(_ rangeResponse: AvailabilityRangeResponse) {
        for (dateString, dayData) in rangeResponse.days {
            let response = AvailabilityResponse(
                date: dateString,
                currentHour: dayData.currentHour,
                courts: dayData.courts,
                metadata: AvailabilityMetadata(
                    generatedAt: rangeResponse.metadata.generatedAt,
                    usesRealtimeLogic: nil,
                    timezone: rangeResponse.metadata.timezone
                )
            )
            cacheAvailability(response, for: dateString)
        }
    }

    func clearCache() {
        availabilityCache.removeAll()
    }

    func loadData() async {
        if hasPerformedInitialLoad {
            // Already loaded once - refresh for the selected date, not today
            await loadAvailability()
        } else {
            await initialLoad()
            hasPerformedInitialLoad = true
        }
    }

    /// Initial load - fetch 14 days starting from today using range endpoint
    private func initialLoad() async {
        let today = DateFormatterService.apiDate.string(from: Date())

        isLoading = availability == nil
        error = nil

        // Load availability (range) and booking status in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchInitialRange(today: today) }
            group.addTask { await self.loadBookingStatus() }
        }

        isLoading = false
    }

    /// Fetch initial 14-day range, with fallback to single-day
    private func fetchInitialRange(today: String) async {
        do {
            let response: AvailabilityRangeResponse = try await apiClient.request(
                .availabilityRange(start: today, days: initialFetchDays), body: nil
            )
            cacheRangeResponse(response)

            // Set current day's availability for display
            if let todayData = response.days[today] {
                availability = AvailabilityResponse(
                    date: today,
                    currentHour: todayData.currentHour,
                    courts: todayData.courts,
                    metadata: AvailabilityMetadata(
                        generatedAt: response.metadata.generatedAt,
                        usesRealtimeLogic: nil,
                        timezone: response.metadata.timezone
                    )
                )
            }
            error = nil
        } catch {
            // Fallback to single-day fetch
            await loadAvailabilitySingle(for: today)
        }
    }

    /// Reload after a booking or cancellation - invalidates current date cache
    /// Silently refreshes without showing loading indicator
    func reloadAfterBookingChange() async {
        let dateString = DateFormatterService.apiDate.string(from: selectedDate)
        availabilityCache.removeValue(forKey: dateString)

        // Fetch fresh data silently without loading indicators
        do {
            let response: AvailabilityResponse = try await apiClient.request(
                .availability(date: dateString), body: nil
            )
            cacheAvailability(response, for: dateString)
            availability = response
        } catch {
            // Silently fail - user can pull to refresh if needed
        }

        await loadBookingStatus()
    }

    func loadAvailability() async {
        // Cancel any in-flight request to prevent race conditions
        currentAvailabilityTask?.cancel()

        let dateString = DateFormatterService.apiDate.string(from: selectedDate)
        let cachedData = getCachedAvailability(for: dateString)

        // Show cached data immediately (instant UI response)
        if let cached = cachedData {
            availability = cached
            // Refresh silently in background - no loading indicator needed
        } else {
            isLoading = true
        }

        // Create cancellable task for the background refresh
        let task = Task { @MainActor [weak self] in
            guard let self = self else { return }

            defer {
                self.isLoading = false
            }

            // Fetch fresh data silently
            await self.loadAvailabilitySingle(for: dateString)

            // Trigger prefetch check
            self.checkAndPrefetch()
        }

        currentAvailabilityTask = task
        await task.value
    }

    /// Single-day fetch with caching and error handling
    private func loadAvailabilitySingle(for dateString: String) async {
        do {
            try Task.checkCancellation()

            let response: AvailabilityResponse = try await apiClient.request(
                .availability(date: dateString), body: nil
            )

            try Task.checkCancellation()

            cacheAvailability(response, for: dateString)
            availability = response
            error = nil
        } catch is CancellationError {
            // Request was cancelled - ignore silently
        } catch let apiError as APIError {
            if !Task.isCancelled {
                handleLoadError(apiError.localizedDescription)
            }
        } catch {
            if !Task.isCancelled {
                handleLoadError("Server nicht erreichbar")
            }
        }
    }

    /// Handle load errors - show popup if cached data visible, inline error otherwise
    private func handleLoadError(_ message: String) {
        if availability != nil {
            connectionError = message
        } else {
            error = message
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

    /// Check if prefetch is needed and trigger range fetch if near cache edge
    private func checkAndPrefetch() {
        Task.detached(priority: .low) { [weak self] in
            guard let self = self else { return }

            let calendar = Calendar.current
            let currentDate = await self.selectedDate

            // Check ahead: is there a date within prefetchBuffer days that's not cached?
            if let checkAheadDate = calendar.date(byAdding: .day, value: self.prefetchBuffer, to: currentDate) {
                let checkAheadStr = DateFormatterService.apiDate.string(from: checkAheadDate)
                if await !self.hasCachedData(for: checkAheadStr) {
                    // Need to fetch ahead - start from tomorrow
                    if let startAhead = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                        let startAheadStr = DateFormatterService.apiDate.string(from: startAhead)
                        await self.fetchRangeIfNeeded(start: startAheadStr, days: self.prefetchDays)
                    }
                }
            }

            // Check behind: is there a date within prefetchBuffer days that's not cached?
            if let checkBehindDate = calendar.date(byAdding: .day, value: -self.prefetchBuffer, to: currentDate) {
                let checkBehindStr = DateFormatterService.apiDate.string(from: checkBehindDate)
                if await !self.hasCachedData(for: checkBehindStr) {
                    // Need to fetch behind - start 7 days ago
                    if let startBehind = calendar.date(byAdding: .day, value: -self.prefetchDays, to: currentDate) {
                        let startBehindStr = DateFormatterService.apiDate.string(from: startBehind)
                        await self.fetchRangeIfNeeded(start: startBehindStr, days: self.prefetchDays)
                    }
                }
            }
        }
    }

    /// Fetch a range of dates in background, preventing duplicate requests
    private func fetchRangeIfNeeded(start: String, days: Int) async {
        let cacheKey = "\(start)-\(days)"

        // Prevent duplicate fetches for same range
        guard !pendingRangeFetches.contains(cacheKey) else { return }

        pendingRangeFetches.insert(cacheKey)
        defer { pendingRangeFetches.remove(cacheKey) }

        do {
            let response: AvailabilityRangeResponse = try await apiClient.request(
                .availabilityRange(start: start, days: days), body: nil
            )
            self.cacheRangeResponse(response)
        } catch {
            // Silently ignore prefetch failures
        }
    }

    /// Debounced loading for rapid navigation (arrows, "Heute" button)
    private func loadAvailabilityDebounced() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
                await loadAvailability()
            } catch {
                // Debounce was cancelled - ignore
            }
        }
    }

    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            loadAvailabilityDebounced()
        }
    }

    func goToToday() {
        selectedDate = Date()
        loadAvailabilityDebounced()
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
        guard let berlinTimeZone = TimeZone(identifier: "Europe/Berlin") else {
            return false  // Safe fallback - treat as not in past if timezone unavailable
        }

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
            return slotHour < currentHour
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
        return slot?.details?.canCancel ?? false
    }

    func isUserBooking(_ slot: TimeSlot?) -> Bool {
        guard let slot = slot,
              let details = slot.details,
              let userId = currentUserId else {
            return false
        }
        return details.bookedForId == userId || details.bookedById == userId
    }

    // Cancel a reservation with optimistic UI update
    func cancelReservation(_ reservationId: Int, courtId: Int) {
        // Store original state for rollback on error
        let originalAvailability = availability
        let dateString = DateFormatterService.apiDate.string(from: selectedDate)
        let originalCached = availabilityCache[dateString]

        // 1. Optimistic update - remove slot from local data immediately
        if let currentAvailability = availability,
           let courtIndex = currentAvailability.courts.firstIndex(where: { $0.courtId == courtId }) {

            let court = currentAvailability.courts[courtIndex]
            let filteredOccupied = court.occupied.filter { $0.details?.reservationId != reservationId }

            let updatedCourt = CourtAvailability(
                courtId: court.courtId,
                courtNumber: court.courtNumber,
                occupied: filteredOccupied
            )

            var updatedCourts = currentAvailability.courts
            updatedCourts[courtIndex] = updatedCourt

            let updatedAvailability = AvailabilityResponse(
                date: currentAvailability.date,
                currentHour: currentAvailability.currentHour,
                courts: updatedCourts,
                metadata: currentAvailability.metadata
            )

            availability = updatedAvailability
            cacheAvailability(updatedAvailability, for: dateString)
        }

        // 2. Call API in background
        Task {
            do {
                let _: CancelResponse = try await apiClient.request(
                    .cancelReservation(id: reservationId), body: nil
                )
                await loadBookingStatus()
            } catch {
                // 3. Error - rollback to original state and show alert
                availability = originalAvailability
                if let cached = originalCached {
                    availabilityCache[dateString] = cached
                } else {
                    availabilityCache.removeValue(forKey: dateString)
                }
                cancellationError = "Stornierung fehlgeschlagen"
            }
        }
    }

    var formattedSelectedDate: String {
        DateFormatterService.fullDate.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}
