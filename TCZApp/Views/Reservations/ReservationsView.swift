import SwiftUI

struct ReservationsView: View {
    @ObservedObject var viewModel: ReservationsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCancelAlert = false
    @State private var reservationToCancel: Reservation?

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.reservations.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.reservations.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadReservations() }
                    }
                } else if viewModel.reservations.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "Keine Buchungen",
                        message: "Sie haben keine aktiven Buchungen."
                    )
                } else {
                    List {
                        if !viewModel.myReservations.isEmpty {
                            Section(header: Text("Meine Buchungen")) {
                                ForEach(viewModel.myReservations) { reservation in
                                    ReservationRow(
                                        reservation: reservation,
                                        isCancelling: viewModel.cancellingId == reservation.id,
                                        onCancel: {
                                            reservationToCancel = reservation
                                            showingCancelAlert = true
                                        }
                                    )
                                }
                            }
                        }

                        if !viewModel.bookingsForOthers.isEmpty {
                            Section(header: Text("Buchungen fuer andere")) {
                                ForEach(viewModel.bookingsForOthers) { reservation in
                                    ReservationRow(
                                        reservation: reservation,
                                        isCancelling: viewModel.cancellingId == reservation.id,
                                        onCancel: {
                                            reservationToCancel = reservation
                                            showingCancelAlert = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Meine Buchungen")
            .refreshable {
                await viewModel.refresh()
            }
            .alert(isPresented: $showingCancelAlert) {
                Alert(
                    title: Text("Buchung stornieren?"),
                    message: Text(cancelAlertMessage),
                    primaryButton: .destructive(Text("Stornieren")) {
                        if let reservation = reservationToCancel {
                            Task {
                                await viewModel.cancelReservation(reservation.id)
                            }
                        }
                        reservationToCancel = nil
                    },
                    secondaryButton: .cancel(Text("Abbrechen")) {
                        reservationToCancel = nil
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            if let userId = authViewModel.currentUser?.id {
                viewModel.setCurrentUserId(userId)
            }
            await viewModel.loadReservations()
        }
    }

    private var cancelAlertMessage: String {
        if let reservation = reservationToCancel {
            return "Moechten Sie die Buchung fuer Platz \(reservation.courtNumber) am \(reservation.formattedDate) um \(reservation.startTime) wirklich stornieren?"
        }
        return ""
    }
}

struct ReservationRow: View {
    let reservation: Reservation
    let isCancelling: Bool
    let onCancel: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Platz \(reservation.courtNumber)")
                        .font(.headline)

                    if reservation.isShortNotice {
                        Text("Kurzfristig")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text("\(reservation.formattedDate), \(reservation.timeRange)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if reservation.bookedFor != reservation.bookedBy {
                    Text("Fuer: \(reservation.bookedFor)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if reservation.canCancel {
                if isCancelling {
                    ProgressView()
                } else {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReservationsView(viewModel: ReservationsViewModel())
        .environmentObject(AuthViewModel())
}
