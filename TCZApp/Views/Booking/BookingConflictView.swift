import SwiftUI

struct BookingConflictView: View {
    @ObservedObject var viewModel: BookingViewModel
    let onDismiss: () -> Void
    let onComplete: () -> Void

    @State private var sessionToCancel: ActiveSession?
    @State private var showingCancelAlert = false

    /// Detect if this is a short-notice booking conflict (any session is short-notice)
    private var isShortNoticeConflict: Bool {
        viewModel.activeSessions.contains { $0.isShortNotice == true }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with warning icon
            headerSection

            // Active bookings list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isShortNoticeConflict
                        ? "Deine aktive kurzfristige Buchung:"
                        : "Deine aktiven Buchungen:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.activeSessions) { session in
                        ActiveSessionCard(
                            session: session,
                            isCancelling: viewModel.cancellingSessionId == session.reservationId,
                            canCancel: session.isShortNotice != true,
                            onCancel: {
                                sessionToCancel = session
                                showingCancelAlert = true
                            }
                        )
                    }
                }
                .padding()
            }

            // Error display
            if let error = viewModel.conflictError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // Back button
            backButton
        }
        .background(Color(.systemGroupedBackground))
        .alert(isPresented: $showingCancelAlert) {
            Alert(
                title: Text("Buchung stornieren?"),
                message: Text(cancelAlertMessage),
                primaryButton: .destructive(Text("Stornieren")) {
                    if let session = sessionToCancel {
                        Task {
                            if await viewModel.cancelSession(session.reservationId) {
                                onComplete()
                            }
                        }
                    }
                    sessionToCancel = nil
                },
                secondaryButton: .cancel(Text("Abbrechen")) {
                    sessionToCancel = nil
                }
            )
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                onComplete()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Warning icon
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            // Title
            Text(isShortNoticeConflict
                ? "Kurzfristige Buchung aktiv"
                : "Buchungslimit erreicht")
                .font(.title2)
                .fontWeight(.semibold)

            // Explanation
            Text(isShortNoticeConflict
                ? "Du hast bereits eine aktive kurzfristige Buchung. Kurzfristige Buchungen können nicht storniert werden."
                : "Du hast bereits 2 aktive Buchungen. Bitte storniere eine bestehende Buchung, um fortzufahren.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Zurück")
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color(.systemGray5))
        .foregroundColor(.primary)
        .cornerRadius(10)
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers

    private var cancelAlertMessage: String {
        if let session = sessionToCancel {
            return "Möchtest du die Buchung für \(session.courtName) am \(session.formattedDate) um \(session.startTime) wirklich stornieren?\n\nDie neue Buchung wird danach automatisch erstellt."
        }
        return ""
    }
}

// MARK: - Active Session Card

private struct ActiveSessionCard: View {
    let session: ActiveSession
    let isCancelling: Bool
    let canCancel: Bool
    let onCancel: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Date card (calendar style)
            SessionDateCard(dateString: session.date)

            // Time, court and optional booked_by info
            VStack(alignment: .leading, spacing: 4) {
                // Time and court on first line
                HStack(spacing: 8) {
                    Text(session.timeRange)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(session.courtName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Show booker's name if booked by someone else
                if let bookedByName = session.bookedByName {
                    Text("Gebucht von \(bookedByName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Cancel button (only shown if cancellation is allowed)
            if canCancel {
                if isCancelling {
                    ProgressView()
                        .frame(width: 44, height: 44)
                } else {
                    Button(action: onCancel) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Session Date Card

private struct SessionDateCard: View {
    let dateString: String  // Format: "YYYY-MM-DD"

    // German month abbreviations (uppercase)
    private static let germanMonths = [
        "JAN", "FEB", "MÄR", "APR", "MAI", "JUN",
        "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ"
    ]

    // German weekday abbreviations (uppercase)
    private static let germanWeekdays = [
        "SO", "MO", "DI", "MI", "DO", "FR", "SA"
    ]

    private var monthText: String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3, let month = Int(parts[1]), month >= 1, month <= 12 else {
            return ""
        }
        return Self.germanMonths[month - 1]
    }

    private var dayText: String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3, let day = Int(parts[2]) else {
            return ""
        }
        return String(day)
    }

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        let weekday = Calendar.current.component(.weekday, from: date)
        return Self.germanWeekdays[weekday - 1]
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(monthText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            Text(dayText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(weekdayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 50, height: 60)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

