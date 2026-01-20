import SwiftUI

/// Data needed to show the booking sheet
struct BookingSheetData: Identifiable {
    let id = UUID()
    let courtId: Int
    let courtNumber: Int
    let time: String
    let userId: String
    let userName: String
}

/// Data for cancellation confirmation
struct CancelConfirmationData: Identifiable {
    let id = UUID()
    let reservationId: Int
    let courtNumber: Int
    let time: String
    let bookedFor: String
}

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var bookingSheetData: BookingSheetData?
    @State private var cancelConfirmation: CancelConfirmationData?
    @State private var isResendingVerification = false
    @State private var showingVerificationSentAlert = false
    @State private var showingProfile = false

    private var paymentBannerState: PaymentBannerState? {
        guard let user = authViewModel.currentUser else { return nil }

        // User has confirmed payment, waiting for approval
        if user.hasPendingPaymentConfirmation && !viewModel.isPaymentConfirmationDismissed {
            return .confirmationPending
        }

        // User has unpaid fee - check deadline from booking status
        if user.shouldShowPaymentReminder {
            if let deadline = viewModel.bookingStatus?.paymentDeadline {
                if deadline.isPast {
                    return .deadlinePassed
                } else if let days = deadline.daysUntil {
                    return .deadlineUpcoming(daysUntil: days, deadline: deadline.formattedDeadline)
                }
            }
            // No deadline set, but fee is unpaid - show generic warning
            return .deadlinePassed
        }

        return nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // App header with profile picture
                HStack {
                    HStack(spacing: 12) {
                        Image("tcz_icon")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                        Text("Platz-Reservierung")
                            .font(.title2.weight(.semibold))
                    }

                    Spacer()

                    if let user = authViewModel.currentUser {
                        Button {
                            showingProfile = true
                        } label: {
                            ProfilePictureView(member: user, size: 56)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                // Sticky header section
                VStack(spacing: 12) {
                    // Payment reminder banner (only for authenticated users with unpaid fee)
                    if let bannerState = paymentBannerState {
                        PaymentReminderBanner(
                            state: bannerState,
                            onDismiss: bannerState == .confirmationPending
                                ? { viewModel.isPaymentConfirmationDismissed = true }
                                : nil
                        )
                    }

                    // Email verification banner
                    if let user = authViewModel.currentUser,
                       user.shouldShowEmailVerificationReminder,
                       !viewModel.isEmailVerificationDismissed {
                        EmailVerificationBanner(
                            isResending: isResendingVerification,
                            onResend: { Task { await resendVerificationEmail() } },
                            onDismiss: { viewModel.isEmailVerificationDismissed = true }
                        )
                    }

                    // Date Navigation (header + scrollable date strip)
                    DateNavigationView(
                        selectedDate: $viewModel.selectedDate,
                        isToday: viewModel.isToday,
                        bookingStatus: viewModel.bookingStatus,
                        onToday: viewModel.goToToday,
                        onDateSelected: { Task { await viewModel.loadAvailability(forceRefresh: true) } }
                    )
                }
                .padding(.horizontal)
                .padding(.top)
                .background(Color(.systemBackground))

                // Scrollable court grid
                ScrollView {
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
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .sheet(item: $bookingSheetData) { data in
                BookingSheet(
                    courtId: data.courtId,
                    courtNumber: data.courtNumber,
                    time: data.time,
                    date: viewModel.selectedDate,
                    currentUserId: data.userId,
                    currentUserName: data.userName,
                    onComplete: {
                        bookingSheetData = nil
                        Task { await viewModel.loadData() }
                    }
                )
                .preferredColorScheme(appTheme.colorScheme)
            }
            .alert("Reservierung stornieren?", isPresented: Binding(
                get: { cancelConfirmation != nil },
                set: { if !$0 { cancelConfirmation = nil } }
            )) {
                Button("Abbrechen", role: .cancel) {
                    cancelConfirmation = nil
                }
                Button("Stornieren", role: .destructive) {
                    if let data = cancelConfirmation {
                        Task {
                            await viewModel.cancelReservation(data.reservationId)
                        }
                    }
                    cancelConfirmation = nil
                }
            } message: {
                if let data = cancelConfirmation {
                    Text("Platz \(data.courtNumber) um \(data.time) Uhr für \(data.bookedFor) stornieren?")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            if let userId = authViewModel.currentUser?.id {
                viewModel.setCurrentUserId(userId)
                await authViewModel.refreshCurrentUser()
            }
            await viewModel.loadData()
        }
        .onChange(of: authViewModel.currentUser?.id) { _ in
            viewModel.isPaymentConfirmationDismissed = false
            viewModel.isEmailVerificationDismissed = false
        }
        .alert("E-Mail gesendet", isPresented: $showingVerificationSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Eine Bestätigungs-E-Mail wurde gesendet. Bitte klicke auf den Link in der E-Mail.")
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authViewModel)
                .preferredColorScheme(appTheme.colorScheme)
        }
    }

    private func resendVerificationEmail() async {
        isResendingVerification = true
        do {
            let _: ResendVerificationResponse = try await APIClient.shared.request(
                .resendVerificationEmail, body: nil
            )
            showingVerificationSentAlert = true
            viewModel.isEmailVerificationDismissed = true
        } catch {
            // Silently fail - user can retry
        }
        isResendingVerification = false
    }

    private func handleSlotTap(courtId: Int, courtNumber: Int, time: String, slot: TimeSlot?) {
        guard let user = authViewModel.currentUser else {
            return
        }

        // Check if this is user's own cancellable booking - offer to cancel
        if viewModel.isUserBooking(slot),
           slot?.details?.canCancel == true,
           let details = slot?.details,
           let reservationId = details.reservationId {
            cancelConfirmation = CancelConfirmationData(
                reservationId: reservationId,
                courtNumber: courtNumber,
                time: time,
                bookedFor: details.bookedFor ?? "Unbekannt"
            )
            return
        }

        // Otherwise, try to book if possible
        guard viewModel.canBookSlot(slot, time: time) else {
            return
        }

        bookingSheetData = BookingSheetData(
            courtId: courtId,
            courtNumber: courtNumber,
            time: time,
            userId: user.id,
            userName: user.name
        )
    }
}

struct LegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let temporaryBlockColor = Color(red: 251/255, green: 191/255, blue: 36/255)

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                LegendRow(color: .white, title: "Frei", description: "Platz verfuegbar", showBorder: true)
                LegendRow(color: .red, title: "Belegt", description: "Bereits gebucht")
                LegendRow(color: .orange, title: "Kurzfristig", description: "ab 15 Minuten vor Beginn buchbar")
                LegendRow(color: Color(.systemGray3), title: "Gesperrt", description: "Nicht buchbar")
                LegendRow(color: temporaryBlockColor, title: "Vorübergehend gesperrt", description: "Kurzzeitig blockiert")
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
    var showBorder: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray3), lineWidth: showBorder ? 1 : 0)
                )
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
