import SwiftUI

struct BookingSheet: View {
    @StateObject private var viewModel = BookingViewModel()
    @Environment(\.presentationMode) private var presentationMode

    // Store booking details directly in the view
    let courtId: Int
    let courtNumber: Int
    let time: String
    let date: Date
    let currentUserId: Int
    let onComplete: () -> Void

    @State private var currentUserName: String = "Ich"
    @State private var isInitialized = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Buchungsdetails")) {
                    HStack {
                        Text("Datum")
                        Spacer()
                        Text(formattedDate)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Platz")
                        Spacer()
                        Text("Platz \(courtNumber)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Uhrzeit")
                        Spacer()
                        Text(timeRange)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Gebucht fuer")) {
                    if viewModel.isLoadingFavorites {
                        HStack {
                            ProgressView()
                            Text("Lade Favoriten...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Mitglied", selection: $viewModel.selectedMemberId) {
                            Text("\(currentUserName) (Ich)")
                                .tag(currentUserId as Int?)

                            ForEach(viewModel.favorites) { favorite in
                                Text(favorite.name)
                                    .tag(favorite.id as Int?)
                            }
                        }
                    }
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Buchung erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Buchen") {
                        Task {
                            if await viewModel.createBooking() {
                                onComplete()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.selectedMemberId == nil)
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !isInitialized {
                // Setup viewModel with booking data
                viewModel.courtId = courtId
                viewModel.courtNumber = courtNumber
                viewModel.time = time
                viewModel.date = date
                viewModel.currentUserId = currentUserId
                viewModel.selectedMemberId = currentUserId
                isInitialized = true

                Task {
                    await viewModel.loadFavorites()
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }

    // Compute display values directly from view properties
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private var timeRange: String {
        guard let hour = Int(time.prefix(2)) else { return time }
        return "\(time) - \(String(format: "%02d:00", hour + 1))"
    }
}
