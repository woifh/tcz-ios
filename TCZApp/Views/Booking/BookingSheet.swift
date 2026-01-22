import SwiftUI

struct BookingSheet: View {
    @StateObject private var viewModel = BookingViewModel()
    @Environment(\.dismiss) private var dismiss

    // Store booking details directly in the view
    let courtId: Int
    let courtNumber: Int
    let time: String
    let date: Date
    let currentUserId: String
    let currentUserName: String
    let onComplete: () -> Void
    @State private var isInitialized = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    // 1. Booking details section
                    Section(header: Text("Buchungsdetails")) {
                        HStack {
                            Text("Platz")
                            Spacer()
                            Text("Platz \(courtNumber)")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Datum")
                            Spacer()
                            Text(formattedDate)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Uhrzeit")
                            Spacer()
                            Text(timeRange)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 2. Member picker section
                    Section(header: Text("Buchung für")) {
                        if viewModel.isLoadingFavorites {
                            HStack {
                                ProgressView()
                                Text("Lade Favoriten...")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Picker("Mitglied", selection: $viewModel.selectedMemberId) {
                                Text(currentUserName)
                                    .tag(currentUserId as String?)

                                ForEach(viewModel.favorites) { favorite in
                                    Text(favorite.name)
                                        .tag(favorite.id as String?)
                                }
                            }
                        }
                    }

                    // 3. Search section
                    Section(header: Text("Anderes Mitglied suchen")) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Nach Name oder E-Mail suchen...", text: $viewModel.searchQuery)
                                .textContentType(.name)
                                .disableAutocorrection(true)
                                .onChange(of: viewModel.searchQuery) { newValue in
                                    Task {
                                        try? await Task.sleep(nanoseconds: 300_000_000)
                                        if viewModel.searchQuery == newValue {
                                            await viewModel.searchMembers(query: newValue)
                                        }
                                    }
                                }

                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.searchQuery = ""
                                    viewModel.searchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Search results with limited height
                        if viewModel.isSearching {
                            HStack {
                                ProgressView()
                                Text("Suche...")
                                    .foregroundColor(.secondary)
                            }
                        } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                            HStack {
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(.secondary)
                                Text("Keine Mitglieder gefunden")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(viewModel.searchResults.prefix(5)) { member in
                                Button {
                                    Task {
                                        await viewModel.selectSearchedMember(member)
                                    }
                                } label: {
                                    HStack {
                                        ProfilePictureView(member: member, size: 36)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text(member.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if viewModel.isAddingToFavorites {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(viewModel.isAddingToFavorites)
                            }
                        }
                    }

                    // Error section
                    if let error = viewModel.error {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }

                // 4. Fixed bottom button
                Button {
                    Task {
                        if await viewModel.createBooking() {
                            onComplete()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Buchung bestätigen")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.selectedMemberId == nil || viewModel.isLoading ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isLoading || viewModel.selectedMemberId == nil)
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Platz buchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: viewModel.selectedMemberId) { _ in
                viewModel.error = nil
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            #if DEBUG
            print("📋 BookingSheet appeared - courtId: \(courtId), courtNumber: \(courtNumber), time: \(time), userId: \(currentUserId)")
            #endif
            if !isInitialized {
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

    private var formattedDate: String {
        DateFormatterService.displayDate.string(from: date)
    }

    private var timeRange: String {
        guard let hour = Int(time.prefix(2)) else { return time }
        return "\(time) - \(String(format: "%02d:00", hour + 1))"
    }
}
