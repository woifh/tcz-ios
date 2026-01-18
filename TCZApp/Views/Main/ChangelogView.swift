import SwiftUI

struct ChangelogView: View {
    let title: String
    let content: String?
    let isLoading: Bool
    let error: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Laden...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let content = content {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(parseChangelog(content), id: \.id) { entry in
                                ChangelogEntryView(entry: entry)
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("Kein Changelog verfuegbar")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func parseChangelog(_ content: String) -> [ChangelogEntry] {
        var entries: [ChangelogEntry] = []
        var currentVersion: String?
        var currentDate: String?
        var currentSection: String?
        var currentItems: [ChangelogItem] = []

        let lines = content.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip main title and empty lines
            if trimmed.isEmpty || trimmed == "# Changelog" || trimmed.hasPrefix("All notable changes") {
                continue
            }

            // Version header: ## [3.5] - 2026-01-18 or ## [Unreleased]
            if trimmed.hasPrefix("## ") {
                // Save previous entry if exists
                if let version = currentVersion {
                    entries.append(ChangelogEntry(
                        version: version,
                        date: currentDate,
                        items: currentItems
                    ))
                }

                // Parse new version
                let versionLine = String(trimmed.dropFirst(3))
                if versionLine == "[Unreleased]" {
                    currentVersion = "Unreleased"
                    currentDate = nil
                } else if let match = versionLine.range(of: #"\[([^\]]+)\](?:\s*-\s*(.+))?"#, options: .regularExpression) {
                    let matched = String(versionLine[match])
                    let parts = matched.components(separatedBy: " - ")
                    currentVersion = parts[0].replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    currentDate = parts.count > 1 ? parts[1] : nil
                } else {
                    currentVersion = versionLine
                    currentDate = nil
                }
                currentItems = []
                currentSection = nil
                continue
            }

            // Section header: ### Added, ### Changed, ### Fixed
            if trimmed.hasPrefix("### ") {
                currentSection = String(trimmed.dropFirst(4))
                continue
            }

            // List item: - Some change
            if trimmed.hasPrefix("- ") {
                let itemText = String(trimmed.dropFirst(2))
                currentItems.append(ChangelogItem(
                    section: currentSection ?? "Changes",
                    text: itemText
                ))
            }
        }

        // Don't forget the last entry
        if let version = currentVersion {
            entries.append(ChangelogEntry(
                version: version,
                date: currentDate,
                items: currentItems
            ))
        }

        return entries
    }
}

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String?
    let items: [ChangelogItem]
}

struct ChangelogItem: Identifiable {
    let id = UUID()
    let section: String
    let text: String
}

struct ChangelogEntryView: View {
    let entry: ChangelogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Version header
            HStack(alignment: .firstTextBaseline) {
                Text("Version \(entry.version)")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if let date = entry.date {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)

            // Group items by section
            let groupedItems = Dictionary(grouping: entry.items) { $0.section }
            let sortedSections = ["Added", "Changed", "Fixed", "Improved", "Removed", "Security", "Performance", "Technical"]
                .filter { groupedItems.keys.contains($0) }
            + groupedItems.keys.filter { !["Added", "Changed", "Fixed", "Improved", "Removed", "Security", "Performance", "Technical"].contains($0) }.sorted()

            ForEach(sortedSections, id: \.self) { section in
                if let items = groupedItems[section] {
                    HStack(spacing: 6) {
                        Image(systemName: iconForSection(section))
                            .font(.caption)
                            .foregroundColor(colorForSection(section))
                        Text(section)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorForSection(section))
                    }
                    .padding(.top, 4)

                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(item.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .padding(.bottom, 12)
    }

    private func formatDate(_ dateString: String) -> String {
        // Convert 2026-01-18 to 18.01.2026
        let parts = dateString.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[2]).\(parts[1]).\(parts[0])"
        }
        return dateString
    }

    private func iconForSection(_ section: String) -> String {
        switch section {
        case "Added": return "plus.circle.fill"
        case "Changed": return "arrow.triangle.2.circlepath"
        case "Fixed": return "wrench.and.screwdriver.fill"
        case "Improved": return "arrow.up.circle.fill"
        case "Removed": return "minus.circle.fill"
        case "Security": return "lock.shield.fill"
        case "Performance": return "gauge.with.dots.needle.67percent"
        case "Technical": return "gearshape.fill"
        default: return "circle.fill"
        }
    }

    private func colorForSection(_ section: String) -> Color {
        switch section {
        case "Added": return .green
        case "Changed": return .blue
        case "Fixed": return .orange
        case "Improved": return .purple
        case "Removed": return .red
        case "Security": return .red
        case "Performance": return .cyan
        case "Technical": return .gray
        default: return .secondary
        }
    }
}

#Preview {
    ChangelogView(
        title: "App Changelog",
        content: """
        # Changelog

        All notable changes to the TCZ Tennis App will be documented in this file.

        ## [3.5] - 2026-01-18
        ### Changed
        - Cleaner visual design for court availability grid
        - Past time slots now appear more muted

        ## [3.4] - 2026-01-17
        ### Added
        - Profile editing: users can now update their personal data

        ## [3.3] - 2026-01-16
        ### Changed
        - Faster date switching with cached availability data
        ### Fixed
        - App now correctly logs out when session expires
        """,
        isLoading: false,
        error: nil
    )
}
