import SwiftUI

struct CourtGridView: View {
    @ObservedObject var viewModel: DashboardViewModel
    /// Callback when a slot is tapped: (courtId, courtNumber, time, slot)
    let onSlotTap: (Int, Int, String, TimeSlot?) -> Void

    // Height constants - show 8 slots at once for better readability
    private let visibleSlots: Int = 8
    private let rowHeight: CGFloat = 50
    private let headerHeight: CGFloat = 36
    private let pageLabelHeight: CGFloat = 30

    private var gridHeight: CGFloat {
        pageLabelHeight + headerHeight + (CGFloat(visibleSlots) * rowHeight) + 20
    }

    var body: some View {
        VStack(spacing: 8) {
            // Page indicator above the grid
            PageIndicatorView(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                onPageChange: { viewModel.currentPage = $0 }
            )

            // Swipeable pages for courts
            TabView(selection: $viewModel.currentPage) {
                ForEach(0..<viewModel.totalPages, id: \.self) { pageIndex in
                    SinglePageGrid(
                        viewModel: viewModel,
                        pageIndex: pageIndex,
                        onSlotTap: onSlotTap,
                        visibleSlots: visibleSlots,
                        rowHeight: rowHeight,
                        headerHeight: headerHeight
                    )
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: gridHeight)
        }
    }
}

/// Custom page indicator with arrows and dots
struct PageIndicatorView: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Left arrow
            Button(action: {
                if currentPage > 0 {
                    withAnimation { onPageChange(currentPage - 1) }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentPage > 0 ? .green : .gray.opacity(0.3))
            }
            .disabled(currentPage == 0)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation { onPageChange(page) }
                        }
                }
            }

            // Right arrow
            Button(action: {
                if currentPage < totalPages - 1 {
                    withAnimation { onPageChange(currentPage + 1) }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentPage < totalPages - 1 ? .green : .gray.opacity(0.3))
            }
            .disabled(currentPage == totalPages - 1)
        }
        .padding(.vertical, 8)
    }
}

/// Grid for a single page of courts (3 courts per page)
struct SinglePageGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    let pageIndex: Int
    let onSlotTap: (Int, Int, String, TimeSlot?) -> Void
    let visibleSlots: Int
    let rowHeight: CGFloat
    let headerHeight: CGFloat

    private var courtIndices: Range<Int> {
        viewModel.courtIndicesForPage(pageIndex)
    }

    private var scrollAreaHeight: CGFloat {
        CGFloat(visibleSlots) * rowHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page label
            Text(viewModel.pageLabelForPage(pageIndex))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            // Header row with court numbers (fixed)
            HStack(spacing: 0) {
                Text("Zeit")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(width: 60)
                    .frame(height: headerHeight)
                    .background(Color(.systemGray5))

                ForEach(courtIndices, id: \.self) { courtIndex in
                    let courtNumber = viewModel.courtNumbers[courtIndex]
                    Text("P\(courtNumber)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: headerHeight)
                        .background(Color(.systemGray5))
                }
            }

            // Scrollable time slot rows - shows 8 slots, scroll for more
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(viewModel.timeSlots, id: \.self) { time in
                        HStack(spacing: 0) {
                            // Time label
                            Text(time)
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(width: 60)
                                .frame(height: rowHeight)
                                .background(Color(.systemGray6))

                            // Court cells (only for this page's courts)
                            ForEach(courtIndices, id: \.self) { courtIndex in
                                let slot = viewModel.getSlot(courtIndex: courtIndex, time: time)
                                let courtInfo = viewModel.getCourtInfo(courtIndex: courtIndex)

                                TimeSlotCell(
                                    slot: slot,
                                    isPast: viewModel.isSlotInPast(time: time),
                                    canBook: viewModel.canBookSlot(slot, time: time),
                                    isUserBooking: viewModel.isUserBooking(slot),
                                    rowHeight: rowHeight
                                )
                                .onTapGesture {
                                    onSlotTap(courtInfo.id, courtInfo.number, time, slot)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: scrollAreaHeight)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .padding(.horizontal, 4)
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
                        Text(details.bookedFor ?? "Gebucht")
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
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
        .opacity(isPast ? 0.5 : 1.0)
        .overlay(
            isUserBooking && !isPast ?
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.blue, lineWidth: 2)
                    .padding(1)
                : nil
        )
    }

    private var backgroundColor: Color {
        guard let slot = slot else {
            return isPast ? Color(.systemGray4) : .green
        }

        switch slot.status {
        case .available:
            return isPast ? Color(.systemGray4) : .green
        case .reserved:
            return .red
        case .shortNotice:
            return .orange
        case .blocked:
            return Color(.systemGray3)
        }
    }

    private var foregroundColor: Color {
        guard let slot = slot else {
            return isPast ? .gray : .white
        }

        switch slot.status {
        case .available:
            return isPast ? .gray : .white
        case .blocked:
            return .primary
        default:
            return .white
        }
    }
}
