import SwiftUI

struct BookingSheet: View {
    @StateObject private var viewModel = BookingViewModel()
    @Environment(\.presentationMode) private var presentationMode

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
            ScrollViewReader { scrollProxy in
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

                Section(header: Text("Gebucht für")) {
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

                        Button {
                            viewModel.toggleSearch()
                        } label: {
                            HStack {
                                Image(systemName: viewModel.showSearch ? "xmark.circle" : "magnifyingglass")
                                Text(viewModel.showSearch ? "Suche schliessen" : "Anderes Mitglied suchen")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }

                if viewModel.showSearch {
                    Section(header: Text("Mitglied suchen")) {
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
                            .id("noResults")
                        } else {
                            ForEach(viewModel.searchResults) { member in
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
                            .id("searchResults")
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
            .onChange(of: viewModel.searchResults) { results in
                if !results.isEmpty {
                    withAnimation {
                        scrollProxy.scrollTo("searchResults", anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.isSearching) { isSearching in
                if !isSearching && viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    withAnimation {
                        scrollProxy.scrollTo("noResults", anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.selectedMemberId) { _ in
                viewModel.error = nil
            }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            #if DEBUG
            print("📋 BookingSheet appeared - courtId: \(courtId), courtNumber: \(courtNumber), time: \(time), userId: \(currentUserId)")
            #endif
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

    private var formattedDate: String {
        DateFormatterService.displayDate.string(from: date)
    }

    private var timeRange: String {
        guard let hour = Int(time.prefix(2)) else { return time }
        return "\(time) - \(String(format: "%02d:00", hour + 1))"
    }
}
