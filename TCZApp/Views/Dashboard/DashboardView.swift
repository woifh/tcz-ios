import SwiftUI

/// Data needed to show the booking sheet
struct BookingSheetData: Identifiable {
    let id = UUID()
    let courtId: Int
    let courtNumber: Int
    let time: String
    let userId: String
}

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var bookingSheetData: BookingSheetData?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Compact Header (date selector + legend + booking badge)
                    CompactHeaderView(
                        selectedDate: viewModel.selectedDate,
                        isToday: viewModel.isToday,
                        bookingStatus: viewModel.bookingStatus,
                        onPrevious: { viewModel.changeDate(by: -1) },
                        onNext: { viewModel.changeDate(by: 1) },
                        onToday: viewModel.goToToday
                    )

                    // Court Grid
                    if viewModel.isLoading && viewModel.availability == nil {
                        LoadingView()
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            Task { await viewModel.loadData() }
                        }
                    } else {
                        CourtGridView(
                            viewModel: viewModel,
                            onSlotTap: { courtId, courtNumber, time, slot in
                                handleSlotTap(courtId: courtId, courtNumber: courtNumber, time: time, slot: slot)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Platzuebersicht")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $bookingSheetData) { data in
                BookingSheet(
                    courtId: data.courtId,
                    courtNumber: data.courtNumber,
                    time: data.time,
                    date: viewModel.selectedDate,
                    currentUserId: data.userId,
                    onComplete: {
                        bookingSheetData = nil
                        Task { await viewModel.loadData() }
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            if let userId = authViewModel.currentUser?.id {
                viewModel.setCurrentUserId(userId)
            }
            await viewModel.loadData()
        }
    }

    private func handleSlotTap(courtId: Int, courtNumber: Int, time: String, slot: TimeSlot?) {
        guard viewModel.canBookSlot(slot, time: time),
              let userId = authViewModel.currentUser?.id else {
            return
        }
        bookingSheetData = BookingSheetData(
            courtId: courtId,
            courtNumber: courtNumber,
            time: time,
            userId: userId
        )
    }
}

struct CompactHeaderView: View {
    let selectedDate: Date
    let isToday: Bool
    let bookingStatus: BookingStatusResponse?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    private var compactDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E, d. MMM"
        return formatter.string(from: selectedDate)
    }

    private var showRegularBadge: Bool {
        guard let status = bookingStatus else { return false }
        let limits = status.limits.regularReservations
        return limits.current >= limits.limit - 1
    }

    private var showShortNoticeBadge: Bool {
        guard let status = bookingStatus else { return false }
        let limits = status.limits.shortNoticeBookings
        return limits.current >= limits.limit - 1
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Date navigation
                HStack(spacing: 8) {
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.green)
                    }

                    Text(compactDateString)
                        .font(.subheadline.weight(.medium))
                        .frame(minWidth: 100)

                    Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                // Legend
                HStack(spacing: 8) {
                    CompactLegendDot(color: .green, label: "F")
                    CompactLegendDot(color: .red, label: "B")
                    CompactLegendDot(color: .orange, label: "K")
                    CompactLegendDot(color: .gray, label: "G")
                }

                // Booking badges (only show when near limit)
                if let status = bookingStatus {
                    if showRegularBadge || showShortNoticeBadge {
                        HStack(spacing: 4) {
                            if showRegularBadge {
                                BookingBadge(
                                    current: status.limits.regularReservations.current,
                                    limit: status.limits.regularReservations.limit,
                                    color: status.limits.regularReservations.canBook ? .secondary : .red
                                )
                            }
                            if showShortNoticeBadge {
                                BookingBadge(
                                    current: status.limits.shortNoticeBookings.current,
                                    limit: status.limits.shortNoticeBookings.limit,
                                    color: status.limits.shortNoticeBookings.canBook ? .orange : .red
                                )
                            }
                        }
                    }
                }
            }

            // Today button (only when not on today)
            if !isToday {
                Button("Heute", action: onToday)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct CompactLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct BookingBadge: View {
    let current: Int
    let limit: Int
    let color: Color

    var body: some View {
        Text("\(current)/\(limit)")
            .font(.caption2.weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel())
        .environmentObject(AuthViewModel())
}
