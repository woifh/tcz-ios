import SwiftUI

// MARK: - Main Container

struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let isToday: Bool
    let bookingStatus: BookingStatusResponse?
    let onToday: () -> Void
    let onDateSelected: () -> Void

    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var showDatePicker = false
    @State private var dateBeforePicker: Date?
    @State private var scrollToTodayTrigger = false

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Header with date label, badges, and Heute button
            DateHeaderRow(
                selectedDate: selectedDate,
                isToday: isToday,
                bookingStatus: bookingStatus,
                onDateLabelTap: {
                    dateBeforePicker = selectedDate
                    showDatePicker = true
                },
                onToday: {
                    onToday()
                    scrollToTodayTrigger.toggle()
                }
            )

            // Row 2: Horizontal date strip
            DateStripView(
                selectedDate: $selectedDate,
                scrollToTodayTrigger: scrollToTodayTrigger,
                onDateSelected: onDateSelected
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .sheet(isPresented: $showDatePicker, onDismiss: {
            if let before = dateBeforePicker,
               !Calendar.current.isDate(before, inSameDayAs: selectedDate) {
                onDateSelected()
            }
            dateBeforePicker = nil
        }) {
            DatePickerSheet(selectedDate: $selectedDate)
                .presentationDetents([.medium])
                .preferredColorScheme(appTheme.colorScheme)
        }
    }
}

// MARK: - Row 1: Header Row

struct DateHeaderRow: View {
    let selectedDate: Date
    let isToday: Bool
    let bookingStatus: BookingStatusResponse?
    let onDateLabelTap: () -> Void
    let onToday: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E dd.MM.yyyy"
        return formatter
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: selectedDate)
    }

    var body: some View {
        HStack {
            // Date label with dropdown indicator
            Button(action: onDateLabelTap) {
                HStack(spacing: 4) {
                    Text(formattedDate)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Booking badges
            if let status = bookingStatus {
                HStack(spacing: 4) {
                    BookingBadge(
                        current: status.limits.regularReservations.current,
                        limit: status.limits.regularReservations.limit,
                        color: status.limits.regularReservations.canBook ? .secondary : .red
                    )
                    BookingBadge(
                        current: status.limits.shortNoticeBookings.current,
                        limit: status.limits.shortNoticeBookings.limit,
                        color: .orange
                    )
                }
            }

            // Heute button
            Button(action: onToday) {
                Text("Heute")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .gray : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isToday ? Color(.systemGray5) : Color.green.opacity(0.15))
                    .cornerRadius(6)
            }
            .disabled(isToday)
        }
    }
}

// MARK: - Row 2: Date Strip

struct DateStripView: View {
    @Binding var selectedDate: Date
    let scrollToTodayTrigger: Bool
    let onDateSelected: () -> Void

    // Generate dates using DateRangeConstants (pastDays before and futureDays after today)
    private static func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        for offset in -DateRangeConstants.pastDays...DateRangeConstants.futureDays {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
            }
        }
        return dates
    }

    private let dateRange: [Date] = generateDateRange()

    private func dateId(_ date: Date) -> String {
        DateFormatterService.apiDate.string(from: date)
    }

    // Selected date string for comparison (forces view update when selectedDate changes)
    private var selectedDateString: String {
        DateFormatterService.apiDate.string(from: selectedDate)
    }

    // Today's date string for comparison
    private var todayDateString: String {
        DateFormatterService.apiDate.string(from: Date())
    }

    var body: some View {
        let selected = selectedDateString
        let today = todayDateString

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(dateRange, id: \.self) { date in
                        let dateString = dateId(date)
                        DayCell(
                            date: date,
                            isSelected: dateString == selected,
                            isToday: dateString == today
                        )
                        .id(dateString)
                        .onTapGesture {
                            selectedDate = date
                            onDateSelected()
                        }
                    }
                }
                .padding(.horizontal, UIScreen.main.bounds.width / 2 - 30)
            }
            .onAppear {
                // Center on selected date only on initial appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
            .onChange(of: scrollToTodayTrigger) { _ in
                // Scroll to today when "Heute" button is tapped
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(today, anchor: .center)
                }
            }
        }
        .frame(height: 70)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    // German month abbreviations (uppercase)
    private static let germanMonths = [
        "JAN", "FEB", "MÄR", "APR", "MAI", "JUN",
        "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ"
    ]

    // German weekday abbreviations (uppercase)
    private static let germanWeekdays = [
        "SO", "MO", "DI", "MI", "DO", "FR", "SA"
    ]

    private var monthText: String {
        let month = Calendar.current.component(.month, from: date)
        return Self.germanMonths[month - 1]
    }

    private var dayText: String {
        String(Calendar.current.component(.day, from: date))
    }

    private var weekdayText: String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return Self.germanWeekdays[weekday - 1]
    }

    // Background color: selected (green) takes priority, then today (light orange), else gray
    private var backgroundColor: Color {
        if isSelected {
            return Color.green
        } else if isToday {
            return Color.orange.opacity(0.3)
        } else {
            return Color(.systemGray6)
        }
    }

    // Text color: white for selected, primary/secondary for others
    private var primaryTextColor: Color {
        isSelected ? .white : .primary
    }

    private var secondaryTextColor: Color {
        isSelected ? .white : .secondary
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(monthText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(secondaryTextColor)

            Text(dayText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(primaryTextColor)

            Text(weekdayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(secondaryTextColor)
        }
        .frame(width: 50, height: 60)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

#Preview {
    DateNavigationView(
        selectedDate: .constant(Date()),
        isToday: true,
        bookingStatus: nil,
        onToday: {},
        onDateSelected: {}
    )
    .padding()
}
