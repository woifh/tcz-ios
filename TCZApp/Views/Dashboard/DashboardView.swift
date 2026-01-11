import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingBookingSheet = false
    @State private var selectedSlotInfo: (courtId: Int, courtNumber: Int, time: String)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Date Selector
                    DateSelectorView(
                        selectedDate: viewModel.selectedDate,
                        formattedDate: viewModel.formattedSelectedDate,
                        isToday: viewModel.isToday,
                        onPrevious: { viewModel.changeDate(by: -1) },
                        onNext: { viewModel.changeDate(by: 1) },
                        onToday: viewModel.goToToday
                    )

                    // Booking Status
                    if let status = viewModel.bookingStatus {
                        BookingStatusView(status: status)
                    }

                    // Legend
                    LegendView()

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
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingBookingSheet) {
                if let info = selectedSlotInfo,
                   let userId = authViewModel.currentUser?.id {
                    BookingSheet(
                        courtId: info.courtId,
                        courtNumber: info.courtNumber,
                        time: info.time,
                        date: viewModel.selectedDate,
                        currentUserId: userId,
                        onComplete: {
                            showingBookingSheet = false
                            Task { await viewModel.loadData() }
                        }
                    )
                }
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
        if viewModel.canBookSlot(slot, time: time) {
            selectedSlotInfo = (courtId, courtNumber, time)
            showingBookingSheet = true
        }
    }
}

struct DateSelectorView: View {
    let selectedDate: Date
    let formattedDate: String
    let isToday: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                Spacer()

                Text(formattedDate)
                    .font(.headline)

                Spacer()

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)

            if !isToday {
                Button("Heute", action: onToday)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct BookingStatusView: View {
    let status: BookingStatusResponse

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buchungen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(status.limits.regularReservations.current)/\(status.limits.regularReservations.limit)")
                    .font(.headline)
                    .foregroundColor(status.limits.regularReservations.canBook ? .primary : .red)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Kurzfristig")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(status.limits.shortNoticeBookings.current)/\(status.limits.shortNoticeBookings.limit)")
                    .font(.headline)
                    .foregroundColor(status.limits.shortNoticeBookings.canBook ? .primary : .orange)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct LegendView: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: .green, text: "Frei")
            LegendItem(color: .red, text: "Gebucht")
            LegendItem(color: .orange, text: "Kurzfristig")
            LegendItem(color: .gray, text: "Gesperrt")
        }
        .font(.caption2)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel())
        .environmentObject(AuthViewModel())
}
