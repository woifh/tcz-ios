import SwiftUI

/// Reusable profile picture view that shows a cached/fetched image or initials fallback.
struct ProfilePictureView: View {
    let memberId: String?
    let hasProfilePicture: Bool
    let profilePictureVersion: Int
    let name: String
    let size: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .task(id: cacheKey) {
            await loadImage()
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.green)
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let firstInitial = parts.first?.first.map(String.init) ?? ""
        let lastInitial = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (firstInitial + lastInitial).uppercased()
    }

    private var cacheKey: String {
        guard let memberId = memberId, hasProfilePicture else { return "" }
        return "\(memberId)_\(profilePictureVersion)"
    }

    private func loadImage() async {
        guard let memberId = memberId, hasProfilePicture else {
            image = nil
            return
        }

        // Check cache first
        if let cached = ProfilePictureCache.shared.getImage(memberId: memberId, version: profilePictureVersion) {
            image = cached
            return
        }

        // Fetch from API
        guard !isLoading else { return }
        isLoading = true

        do {
            let data = try await APIClient.shared.fetchProfilePicture(memberId: memberId)
            if let uiImage = UIImage(data: data) {
                ProfilePictureCache.shared.setImage(uiImage, memberId: memberId, version: profilePictureVersion)
                await MainActor.run {
                    self.image = uiImage
                }
            }
        } catch {
            // Silently fail - show initials
            #if DEBUG
            print("Failed to load profile picture for \(memberId): \(error)")
            #endif
        }

        isLoading = false
    }
}

// Convenience initializer for MemberSummary
extension ProfilePictureView {
    init(member: MemberSummary, size: CGFloat) {
        self.memberId = member.id
        self.hasProfilePicture = member.hasProfilePicture ?? false
        self.profilePictureVersion = member.profilePictureVersion ?? 0
        self.name = member.name
        self.size = size
    }

    init(member: Member, size: CGFloat) {
        self.memberId = member.id
        self.hasProfilePicture = member.hasProfilePicture ?? false
        self.profilePictureVersion = member.profilePictureVersion ?? 0
        self.name = member.name
        self.size = size
    }
}

#Preview {
    VStack(spacing: 20) {
        // With initials (no picture)
        ProfilePictureView(
            memberId: "123",
            hasProfilePicture: false,
            profilePictureVersion: 0,
            name: "Max Mustermann",
            size: 60
        )

        // Another initials example
        ProfilePictureView(
            memberId: "456",
            hasProfilePicture: false,
            profilePictureVersion: 0,
            name: "Anna",
            size: 40
        )
    }
    .padding()
}
