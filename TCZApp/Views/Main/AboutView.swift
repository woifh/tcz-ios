import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    // App Info state
    @State private var appVersion: String = "?"
    @State private var serverVersion: String?
    @State private var showAppChangelog = false
    @State private var showServerChangelog = false
    @State private var appChangelogContent: String?
    @State private var serverChangelogContent: String?
    @State private var serverChangelogLoading = false
    @State private var serverChangelogError: String?

    // Licenses state
    @State private var showLicenseDetail = false

    var body: some View {
        NavigationView {
            List {
                // App Info section
                Section(header: Text("App Info")) {
                    Button {
                        showAppChangelog = true
                    } label: {
                        HStack {
                            Text("App-Version")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button {
                        showServerChangelog = true
                        Task {
                            await loadServerChangelog()
                        }
                    } label: {
                        HStack {
                            Text("Server-Version")
                                .foregroundColor(.primary)
                            Spacer()
                            if let version = serverVersion {
                                Text(version)
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(APIClient.shared.serverHost)
                            .foregroundColor(.secondary)
                    }
                }

                // Licenses section
                Section(header: Text("Lizenzen")) {
                    DisclosureGroup("TOCropViewController") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tim Oliver")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("MIT License")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Divider()
                            Text(mitLicenseText)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Impressum section
                Section(header: Text("Impressum")) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tennisclub Zellerndorf")
                                .font(.headline)
                            Text("Zellerndorf 354")
                            Text("2051 Zellerndorf")
                            Text("Österreich")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Link(destination: URL(string: "https://www.tczellerndorf.at")!) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("www.tczellerndorf.at")
                                }
                            }
                            Link(destination: URL(string: "mailto:info@tczellerndorf.at")!) {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("info@tczellerndorf.at")
                                }
                            }
                        }

                        Divider()

                        HStack {
                            Text("Made by Wolfgang Hacker")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Über")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAppChangelog) {
                ChangelogView(
                    title: "App Changelog",
                    content: appChangelogContent,
                    isLoading: false,
                    error: appChangelogContent == nil ? "Changelog nicht gefunden" : nil
                )
                .preferredColorScheme(appTheme.colorScheme)
            }
            .sheet(isPresented: $showServerChangelog) {
                ChangelogView(
                    title: "Server Changelog",
                    content: serverChangelogContent,
                    isLoading: serverChangelogLoading,
                    error: serverChangelogError
                )
                .preferredColorScheme(appTheme.colorScheme)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await loadServerVersion()
        }
        .onAppear {
            loadAppVersion()
            loadAppChangelog()
        }
    }

    // MARK: - Data Loading

    private func loadAppVersion() {
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        if let path = Bundle.main.path(forResource: "CHANGELOG", ofType: "md"),
           let content = try? String(contentsOfFile: path, encoding: .utf8),
           let unreleasedRange = content.range(of: "## [Unreleased]") {
            let searchStart = unreleasedRange.upperBound
            if let startRange = content.range(of: "## [", range: searchStart..<content.endIndex),
               let endRange = content.range(of: "]", range: startRange.upperBound..<content.endIndex) {
                let version = String(content[startRange.upperBound..<endRange.lowerBound])
                if version.contains(".") {
                    appVersion = "\(version).0 (\(buildNumber))"
                    return
                }
            }
        }
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        appVersion = "\(shortVersion) (\(buildNumber))"
    }

    private func loadServerVersion() async {
        do {
            let response: ServerVersionResponse = try await APIClient.shared.request(.serverVersion, body: nil)
            serverVersion = response.version
        } catch {
            serverVersion = "?"
        }
    }

    private func loadAppChangelog() {
        if let path = Bundle.main.path(forResource: "CHANGELOG", ofType: "md"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            appChangelogContent = content
        }
    }

    private func loadServerChangelog() async {
        serverChangelogLoading = true
        serverChangelogError = nil
        serverChangelogContent = nil

        do {
            let response: ServerChangelogResponse = try await APIClient.shared.request(.serverChangelog, body: nil)
            serverChangelogContent = response.changelog
        } catch {
            serverChangelogError = "Changelog konnte nicht geladen werden"
        }

        serverChangelogLoading = false
    }

    // MARK: - License Text

    private var mitLicenseText: String {
        """
        Copyright (c) Tim Oliver

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """
    }
}

#Preview {
    AboutView()
}
