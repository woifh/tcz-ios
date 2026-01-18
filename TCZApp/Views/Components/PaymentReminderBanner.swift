import SwiftUI

enum PaymentBannerState {
    case deadlinePassed
    case deadlineUpcoming(daysUntil: Int, deadline: String)
    case confirmationPending
}

struct PaymentReminderBanner: View {
    let state: PaymentBannerState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }

    private var iconName: String {
        switch state {
        case .deadlinePassed:
            return "exclamationmark.triangle.fill"
        case .deadlineUpcoming:
            return "clock.fill"
        case .confirmationPending:
            return "clock.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .deadlinePassed:
            return .red
        case .deadlineUpcoming:
            return .orange
        case .confirmationPending:
            return .orange
        }
    }

    private var title: String {
        switch state {
        case .deadlinePassed:
            return "Mitgliedsbeitrag offen"
        case .deadlineUpcoming(let days, let deadline):
            if days == 0 {
                return "Zahlungsfrist: Heute (\(deadline))"
            } else if days == 1 {
                return "Noch 1 Tag bis zur Zahlungsfrist am \(deadline)"
            } else {
                return "Noch \(days) Tage bis zur Zahlungsfrist am \(deadline)"
            }
        case .confirmationPending:
            return "Zahlungsbestätigung angefragt"
        }
    }

    private var subtitle: String {
        switch state {
        case .deadlinePassed:
            return "Bitte zahl deinen Beitrag, um wieder buchen zu können."
        case .deadlineUpcoming:
            return "Wende dich an den Vorstand, um deinen Beitrag zu bezahlen."
        case .confirmationPending:
            return "Deine Zahlungsbestätigung wird geprüft."
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .deadlinePassed:
            return Color.red.opacity(0.1)
        case .deadlineUpcoming:
            return Color.yellow.opacity(0.15)
        case .confirmationPending:
            return Color.orange.opacity(0.1)
        }
    }
}

#Preview("Deadline Passed") {
    PaymentReminderBanner(state: .deadlinePassed)
        .padding()
}

#Preview("Deadline Upcoming - Today") {
    PaymentReminderBanner(state: .deadlineUpcoming(daysUntil: 0, deadline: "31.01.2026"))
        .padding()
}

#Preview("Deadline Upcoming - 1 Day") {
    PaymentReminderBanner(state: .deadlineUpcoming(daysUntil: 1, deadline: "31.01.2026"))
        .padding()
}

#Preview("Deadline Upcoming - Multiple Days") {
    PaymentReminderBanner(state: .deadlineUpcoming(daysUntil: 13, deadline: "31.01.2026"))
        .padding()
}

#Preview("Confirmation Pending") {
    PaymentReminderBanner(state: .confirmationPending)
        .padding()
}
