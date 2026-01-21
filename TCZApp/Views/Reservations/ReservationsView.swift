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
                        message: "Du hast keine aktiven Buchungen."
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
                                        },
                                        showBookedBy: true
                                    )
                                }
                            }
                        }

                        if !viewModel.bookingsForOthers.isEmpty {
                            Section(header: Text("Buchungen für andere")) {
                                ForEach(viewModel.bookingsForOthers) { reservation in
                                    ReservationRow(
                                        reservation: reservation,
                                        isCancelling: viewModel.cancellingId == reservation.id,
                                        onCancel: {
                                            reservationToCancel = reservation
                                            showingCancelAlert = true
                                        },
                                        showBookedBy: false
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
            let courtText = reservation.courtNumber.map { "Platz \($0)" } ?? "den Platz"
            return "Möchtest du die Buchung für \(courtText) am \(reservation.formattedDate) um \(reservation.startTime) wirklich stornieren?"
        }
        return ""
    }
}

struct ReservationRow: View {
    let reservation: Reservation
    let isCancelling: Bool
    let onCancel: () -> Void
    let showBookedBy: Bool  // true for "Meine Buchungen", false for "Buchungen für andere"

    var body: some View {
        HStack {
            ProfilePictureView(
                memberId: reservation.bookedForId,
                hasProfilePicture: reservation.bookedForHasProfilePicture ?? false,
                profilePictureVersion: reservation.bookedForProfilePictureVersion ?? 0,
                name: reservation.bookedFor ?? "",
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Platz \(reservation.courtNumber ?? 0)")
                        .font(.headline)

                    if reservation.isSuspended {
                        Text("Pausiert")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 251/255, green: 191/255, blue: 36/255))
                            .foregroundColor(Color(red: 113/255, green: 63/255, blue: 18/255))
                            .cornerRadius(4)
                    }

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

                if reservation.isSuspended, let reason = reservation.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(Color(red: 113/255, green: 63/255, blue: 18/255))
                }

                // Show who booked/who it's for when booker differs from recipient
                if reservation.bookedForId != reservation.bookedById {
                    if showBookedBy, let bookedBy = reservation.bookedBy {
                        // In "Meine Buchungen": show who booked it for me
                        Text("Von: \(bookedBy)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !showBookedBy, let bookedFor = reservation.bookedFor {
                        // In "Buchungen für andere": show who it's for
                        Text("Für: \(bookedFor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
