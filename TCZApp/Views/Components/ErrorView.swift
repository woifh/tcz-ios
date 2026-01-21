import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Fehler")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Erneut versuchen", action: retryAction)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityHint("Doppeltippen, um die Anfrage erneut zu senden")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ErrorView(message: "Netzwerkfehler. Bitte überprüfe deine Verbindung.") {
        print("Retry")
    }
}
