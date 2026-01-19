import SwiftUI

struct EmailVerificationBanner: View {
    let isResending: Bool
    let onResend: () -> Void
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("E-Mail nicht bestätigt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Bestätige deine E-Mail, um Benachrichtigungen zu erhalten.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onResend) {
                if isResending {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Senden")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(isResending)

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 16) {
        EmailVerificationBanner(isResending: false, onResend: {})
        EmailVerificationBanner(isResending: true, onResend: {})
        EmailVerificationBanner(isResending: false, onResend: {}, onDismiss: {})
    }
    .padding()
}
