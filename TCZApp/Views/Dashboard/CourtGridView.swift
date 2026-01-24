import SwiftUI

struct CourtGridView: View {
    @ObservedObject var viewModel: DashboardViewModel
    /// Callback when a slot is tapped: (courtId, courtNumber, time, slot)
    let onSlotTap: (Int, Int, String, TimeSlot?) -> Void

    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var showLegend = false
    @State private var selectedPage: Int = 0

    // Height constants
    private let rowHeight: CGFloat = LayoutConstants.courtGridRowHeight
    private let headerHeight: CGFloat = LayoutConstants.courtGridHeaderHeight

    // Calculate height for time slots only (no header)
    private var timeSlotsHeight: CGFloat {
        let slotCount = CGFloat(viewModel.timeSlots.count)
        let spacingCount = CGFloat(max(0, viewModel.timeSlots.count - 1))
        let cellSpacing = LayoutConstants.courtGridCellSpacing
        return (slotCount * rowHeight) + (spacingCount * cellSpacing)
    }

    var body: some View {
        VStack(spacing: 0) {
            // STICKY: Page indicator
            PageIndicatorView(
                currentPage: selectedPage,
                totalPages: viewModel.totalPages,
                onPageChange: { newPage in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedPage = newPage
                    }
                },
                onInfoTap: { showLegend = true }
            )

            // STICKY: Court header row
            CourtHeaderRow(
                viewModel: viewModel,
                selectedPage: selectedPage,
                headerHeight: headerHeight
            )
            .padding(.bottom, LayoutConstants.courtGridCellSpacing)

            // SCROLLABLE: Time slot rows only (each page has its own ScrollView)
            TabView(selection: $selectedPage) {
                ForEach(0..<viewModel.totalPages, id: \.self) { pageIndex in
                    ScrollViewReader { proxy in
                        ScrollView {
                            TimeSlotRowsView(
                                viewModel: viewModel,
                                pageIndex: pageIndex,
                                onSlotTap: onSlotTap,
                                rowHeight: rowHeight
                            )
                            .frame(height: timeSlotsHeight)
                        }
                        .onAppear {
                            scrollToCurrentHourIfNeeded(proxy: proxy, pageIndex: pageIndex)
                        }
                    }
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .sheet(isPresented: $showLegend) {
            LegendSheet()
                .presentationDetents([.height(260)])
                .preferredColorScheme(appTheme.colorScheme)
        }
    }

    private func scrollToCurrentHourIfNeeded(proxy: ScrollViewProxy, pageIndex: Int) {
        // Only auto-scroll for today
        guard viewModel.isToday else {
            return
        }

        // Calculate current hour from device time (Berlin timezone)
        guard let berlinTimeZone = TimeZone(identifier: "Europe/Berlin") else {
            return
        }
        var berlinCalendar = Calendar.current
        berlinCalendar.timeZone = berlinTimeZone
        let currentHour = berlinCalendar.component(.hour, from: Date())

        // If before or after operating hours (8-21), don't scroll
        guard currentHour >= 8 && currentHour < 22 else {
            return
        }

        // Scroll to current hour
        let targetTime = String(format: "%02d:00", currentHour)

        // Use unique ID for this page (IDs are "pageIndex-time")
        let targetId = "\(pageIndex)-\(targetTime)"

        // Delay to ensure layout is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo(targetId, anchor: .top)
        }
    }
}

/// Custom page indicator with arrows and dots
struct PageIndicatorView: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void
    let onInfoTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Left arrow
            Button(action: {
                if currentPage > 0 {
                    onPageChange(currentPage - 1)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentPage > 0 ? .green : .gray.opacity(0.3))
            }
            .disabled(currentPage == 0)

            // Page labels
            HStack(spacing: 16) {
                Text("Plätze 1-3")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentPage == 0 ? .green : .gray)
                    .onTapGesture {
                        onPageChange(0)
                    }

                Text("Plätze 4-6")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentPage == 0 ? .gray : .green)
                    .onTapGesture {
                        onPageChange(1)
                    }
            }

            // Right arrow
            Button(action: {
                if currentPage < totalPages - 1 {
                    onPageChange(currentPage + 1)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentPage < totalPages - 1 ? .green : .gray.opacity(0.3))
            }
            .disabled(currentPage == totalPages - 1)

            // Info button for legend
            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Sticky header row showing court names for the selected page
struct CourtHeaderRow: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPage: Int
    let headerHeight: CGFloat

    private var courtIndices: Range<Int> {
        viewModel.courtIndicesForPage(selectedPage)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.courtGridCellSpacing) {
            Text("Zeit")
                .font(.body)
                .fontWeight(.semibold)
                .frame(width: 60)
                .frame(height: headerHeight)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.courtGridCellCornerRadius))

            ForEach(courtIndices, id: \.self) { courtIndex in
                let courtNumber = viewModel.courtNumbers[courtIndex]
                Text("Platz \(courtNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: headerHeight)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.courtGridCellCornerRadius))
            }
        }
    }
}

/// Time slot rows for a single page of courts (no header)
struct TimeSlotRowsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let pageIndex: Int
    let onSlotTap: (Int, Int, String, TimeSlot?) -> Void
    let rowHeight: CGFloat

    private var courtIndices: Range<Int> {
        viewModel.courtIndicesForPage(pageIndex)
    }

    var body: some View {
        VStack(spacing: LayoutConstants.courtGridCellSpacing) {
            ForEach(viewModel.timeSlots, id: \.self) { time in
                HStack(spacing: LayoutConstants.courtGridCellSpacing) {
                    // Time label
                    Text(time)
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(width: 60)
                        .frame(height: rowHeight)

                    // Court cells (only for this page's courts)
                    ForEach(courtIndices, id: \.self) { courtIndex in
                        let slot = viewModel.getSlot(courtIndex: courtIndex, time: time)
                        let courtInfo = viewModel.getCourtInfo(courtIndex: courtIndex)

                        Button {
                            onSlotTap(courtInfo.id, courtInfo.number, time, slot)
                        } label: {
                            TimeSlotCell(
                                slot: slot,
                                isPast: viewModel.isSlotInPast(time: time),
                                canBook: viewModel.canBookSlot(slot, time: time),
                                isUserBooking: viewModel.isUserBooking(slot),
                                rowHeight: rowHeight
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .id("\(pageIndex)-\(time)")  // Unique ID per page for ScrollViewReader
            }
        }
        .contentShape(Rectangle())
    }
}

struct TimeSlotCell: View {
    let slot: TimeSlot?
    let isPast: Bool
    let canBook: Bool
    let isUserBooking: Bool
    let rowHeight: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            if let slot = slot {
                switch slot.status {
                case .available:
                    if isPast {
                        Text("-")
                            .font(.system(size: 14))
                    } else {
                        Text("Frei")
                            .font(.system(size: 13))
                            .fontWeight(.medium)
                    }

                case .reserved, .shortNotice:
                    if let details = slot.details {
                        VStack(spacing: 3) {
                            // Only show profile picture if member has one
                            if details.bookedForHasProfilePicture ?? false {
                                ProfilePictureView(
                                    memberId: details.bookedForId,
                                    hasProfilePicture: true,
                                    profilePictureVersion: details.bookedForProfilePictureVersion ?? 0,
                                    name: details.bookedFor ?? "?",
                                    size: LayoutConstants.courtGridProfilePictureSize
                                )
                            }

                            // Name below (or centered if no picture)
                            VStack(spacing: 0) {
                                Text(details.bookedFor ?? "Gebucht")
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                if let bookedBy = details.bookedBy,
                                   let bookedForId = details.bookedForId,
                                   let bookedById = details.bookedById,
                                   bookedForId != bookedById {
                                    Text("(\(bookedBy))")
                                        .font(.system(size: 8))
                                        .lineLimit(1)
                                        .opacity(0.9)
                                }
                            }
                            .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Gebucht")
                            .font(.system(size: 13))
                    }

                case .blocked:
                    VStack(spacing: 1) {
                        Text(slot.details?.reason ?? "Gesperrt")
                            .font(.system(size: 10))
                            .fontWeight(.medium)

                        if let details = slot.details?.details, !details.isEmpty {
                            Text(details)
                                .font(.system(size: 9))
                                .opacity(0.8)
                        }
                    }
                    .lineLimit(3)
                    .multilineTextAlignment(.center)

                case .blockedTemporary:
                    VStack(spacing: 1) {
                        Text(slot.details?.reason ?? "Vorübergehend gesperrt")
                            .font(.system(size: 10))
                            .fontWeight(.medium)

                        if let details = slot.details?.details, !details.isEmpty {
                            Text(details)
                                .font(.system(size: 9))
                                .opacity(0.8)
                        }

                        Text("(vorübergehend)")
                            .font(.system(size: 8))
                            .italic()
                            .opacity(0.9)

                        if let suspended = slot.details?.suspendedReservation {
                            HStack(spacing: 2) {
                                Text("\u{23F8}")
                                    .font(.system(size: 8))
                                Text(suspended.bookedFor)
                                    .font(.system(size: 8))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(2)
                        }
                    }
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                }
            } else {
                Text("Frei")
                    .font(.system(size: 13))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
        .padding(.horizontal, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.courtGridCellCornerRadius))
        .overlay(borderOverlay)
        .opacity(isPast ? 0.5 : 1.0)
    }

    private var backgroundColor: Color {
        guard let slot = slot else {
            return isPast ? Color(.systemGray5) : .white
        }

        switch slot.status {
        case .available:
            return isPast ? Color(.systemGray5) : .white
        case .reserved:
            return .green
        case .shortNotice:
            return .orange
        case .blocked:
            return Color(.systemGray3)
        case .blockedTemporary:
            return Color(red: 251/255, green: 191/255, blue: 36/255)
        }
    }

    private var foregroundColor: Color {
        guard let slot = slot else {
            return isPast ? .gray : Color(.darkGray)
        }

        switch slot.status {
        case .available:
            return isPast ? .gray : Color(.darkGray)
        case .blocked:
            return .primary
        case .blockedTemporary:
            return Color(red: 113/255, green: 63/255, blue: 18/255)
        default:
            return .black
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        // Subtle solid grey border for all slots
        RoundedRectangle(cornerRadius: LayoutConstants.courtGridCellCornerRadius)
            .stroke(Color(.systemGray4), lineWidth: 0.5)
    }
}
