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
                        selectedDate: $viewModel.selectedDate,
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("tcz_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("TCZ Platz Reservierung")
                            .font(.headline)
                    }
                }
            }
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
    @Binding var selectedDate: Date
    let isToday: Bool
    let bookingStatus: BookingStatusResponse?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    @State private var showDatePicker = false

    private var compactDateString: String {
        DateFormatterService.compactDate.string(from: selectedDate)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Date navigation
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.green)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            Button(action: { showDatePicker = true }) {
                Text(compactDateString)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)
            }

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.green)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Today button (calendar icon)
            Button(action: onToday) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(isToday ? Color(.systemGray4) : Color.green)
                    .cornerRadius(8)
            }
            .disabled(isToday)

            Spacer()

            // Booking badges (always show)
            if let status = bookingStatus {
                HStack(spacing: 4) {
                    BookingBadge(
                        current: status.limits.regularReservations.current,
                        limit: status.limits.regularReservations.limit,
                        color: status.limits.regularReservations.canBook ? .secondary : .red
                    )
                    BookingBadge(
                        current: status.limits.shortNoticeBookings.current,
                        limit: status.limits.shortNoticeBookings.limit,
                        color: status.limits.shortNoticeBookings.canBook ? .orange : .red
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.medium])
        }
    }
}

struct LegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                LegendRow(color: .green, title: "Frei", description: "Platz verfuegbar")
                LegendRow(color: .red, title: "Belegt", description: "Bereits gebucht")
                LegendRow(color: .orange, title: "Kurzfristig", description: "Buchbar innerhalb 24h")
                LegendRow(color: Color(.systemGray3), title: "Gesperrt", description: "Nicht buchbar")
                Spacer()
            }
            .padding()
            .navigationTitle("Legende")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    var body: some View {
        NavigationView {
            DatePicker(
                "Datum",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Datum wählen")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedDate) { _ in
                dismiss()
            }
        }
    }
}

struct LegendRow: View {
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            Text(title)
                .font(.subheadline.weight(.medium))
            Text("– \(description)")
                .font(.subheadline)
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
