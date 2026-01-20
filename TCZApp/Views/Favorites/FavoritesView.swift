import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddSheet = false
    @State private var favoriteToRemove: MemberSummary?
    @State private var showingRemoveAlert = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.favorites.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.favorites.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadFavorites() }
                    }
                } else if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        icon: "star",
                        title: "Keine Favoriten",
                        message: "Füge Mitglieder als Favoriten hinzu, um schneller Buchungen für sie zu erstellen."
                    )
                } else {
                    List {
                        ForEach(viewModel.favorites) { favorite in
                            FavoriteRow(
                                favorite: favorite,
                                isRemoving: viewModel.removingId == favorite.id,
                                onRemove: {
                                    favoriteToRemove = favorite
                                    showingRemoveAlert = true
                                }
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Meine Favoriten")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFavoriteSheet(viewModel: viewModel)
            }
            .alert(isPresented: $showingRemoveAlert) {
                Alert(
                    title: Text("Favorit entfernen?"),
                    message: Text(removeAlertMessage),
                    primaryButton: .destructive(Text("Entfernen")) {
                        if let favorite = favoriteToRemove {
                            Task {
                                await viewModel.removeFavorite(favorite.id)
                            }
                        }
                        favoriteToRemove = nil
                    },
                    secondaryButton: .cancel(Text("Abbrechen")) {
                        favoriteToRemove = nil
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            if let userId = authViewModel.currentUser?.id {
                viewModel.setCurrentUserId(userId)
            }
            await viewModel.loadFavorites()
        }
    }

    private var removeAlertMessage: String {
        if let favorite = favoriteToRemove {
            return "Möchtest du \(favorite.name) wirklich aus deinen Favoriten entfernen?"
        }
        return ""
    }
}

struct FavoriteRow: View {
    let favorite: MemberSummary
    let isRemoving: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack {
            ProfilePictureView(member: favorite, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.name)
                    .font(.headline)
                Text(favorite.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isRemoving {
                ProgressView()
            } else {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFavoriteSheet: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Nach Name oder E-Mail suchen...", text: $searchText)
                        .textContentType(.name)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { newValue in
                            Task {
                                try? await Task.sleep(nanoseconds: 300_000_000) // Debounce
                                if searchText == newValue {
                                    await viewModel.searchMembers(query: newValue)
                                }
                            }
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Results
                if viewModel.isSearching {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Keine Mitglieder gefunden")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else if searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Such nach einem Mitglied")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(viewModel.searchResults) { member in
                        HStack {
                            ProfilePictureView(member: member, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.headline)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                Task {
                                    if await viewModel.addFavorite(member.id) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            } label: {
                                if viewModel.isAdding {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(viewModel.isAdding)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favorit hinzufuegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    FavoritesView(viewModel: FavoritesViewModel())
        .environmentObject(AuthViewModel())
}
