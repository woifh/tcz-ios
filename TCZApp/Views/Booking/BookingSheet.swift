import SwiftUI

struct BookingSheet: View {
    @StateObject private var viewModel = BookingViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

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
            Group {
                if viewModel.showConflictResolution {
                    BookingConflictView(
                        viewModel: viewModel,
                        onDismiss: {
                            viewModel.dismissConflictResolution()
                        },
                        onComplete: {
                            onComplete()
                        }
                    )
                } else {
                    bookingContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.showConflictResolution ? "Platz buchen" : "Platz buchen")
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

    // MARK: - Booking Content

    private var bookingContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Booking details as horizontal chips
                    bookingDetailsChips

                    // 2. Member picker section
                    memberPickerSection

                    // 3. Search section
                    searchSection

                    // 4. Error display
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                confirmButton
            }
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
        }
    }

    // MARK: - Booking Details Chips

    private var bookingDetailsChips: some View {
        HStack(spacing: 8) {
            ChipView(text: "Platz \(courtNumber)")
            Text("•")
                .foregroundColor(.secondary)
            ChipView(text: formattedDate)
            Text("•")
                .foregroundColor(.secondary)
            ChipView(text: timeRange)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Member Picker Section

    private var memberPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buchung für")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if viewModel.isLoadingFavorites {
                HStack {
                    ProgressView()
                    Text("Lade Favoriten...")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            } else {
                Menu {
                    Button {
                        viewModel.selectedMemberId = currentUserId
                    } label: {
                        Label(currentUserName, systemImage: viewModel.selectedMemberId == currentUserId ? "checkmark" : "")
                    }

                    ForEach(viewModel.favorites) { favorite in
                        Button {
                            viewModel.selectedMemberId = favorite.id
                        } label: {
                            Label(favorite.name, systemImage: viewModel.selectedMemberId == favorite.id ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack {
                        if let selectedMember = selectedMember {
                            ProfilePictureView(member: selectedMember, size: 36)
                        } else {
                            // Fallback for current user (no Member object)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(initials(for: currentUserName))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }

                        Text(selectedMemberName)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anderes Mitglied suchen")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Nach Name oder E-Mail suchen...", text: $viewModel.searchQuery)
                    .textContentType(.name)
                    .disableAutocorrection(true)
                    .focused($isSearchFocused)
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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)

            // Search results
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                    Text("Suche...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.secondary)
                    Text("Keine Mitglieder gefunden")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .id("noResults")
            } else if !viewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.searchResults.prefix(5).enumerated()), id: \.element.id) { index, member in
                        Button {
                            isSearchFocused = false
                            viewModel.selectSearchedMember(member)
                        } label: {
                            HStack {
                                ProfilePictureView(member: member, size: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20))
                            }
                            .padding()
                            .background(Color(.systemBackground))
                        }
                        .buttonStyle(PlainButtonStyle())

                        if index < min(viewModel.searchResults.count, 5) - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .cornerRadius(10)
                .id("searchResults")
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
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

    // MARK: - Helpers

    private var formattedDate: String {
        DateFormatterService.displayDate.string(from: date)
    }

    private var timeRange: String {
        guard let hour = Int(time.prefix(2)) else { return time }
        return "\(time) - \(String(format: "%02d:00", hour + 1))"
    }

    private var selectedMemberName: String {
        if viewModel.selectedMemberId == currentUserId {
            return currentUserName
        }
        return viewModel.favorites.first { $0.id == viewModel.selectedMemberId }?.name ?? currentUserName
    }

    private var selectedMember: MemberSummary? {
        if viewModel.selectedMemberId == currentUserId {
            return nil // Current user doesn't have a MemberSummary object
        }
        return viewModel.favorites.first { $0.id == viewModel.selectedMemberId }
    }

    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - ChipView

private struct ChipView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(16)
    }
}
