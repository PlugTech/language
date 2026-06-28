import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var curriculum: CurriculumStore
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.modelContext) private var context
    @Query private var progress: [LessonProgress]

    private var dayIndex: Int { curriculum.currentDayIndex() }
    private var today: Day? { curriculum.day(forDayIndex: dayIndex) }
    private var coords: (week: Int, day: Int) { curriculum.coordinates(forDayIndex: dayIndex) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if notifications.authorizationStatus != .authorized {
                        permissionCard
                    }

                    if let today {
                        lessonCard(today)
                        actions
                    } else {
                        ContentUnavailableView("No lesson found",
                                               systemImage: "questionmark.folder",
                                               description: Text("Curriculum content for week \(coords.week), day \(coords.day) isn't available yet."))
                    }
                }
                .padding()
            }
            .navigationTitle(curriculum.language.todayWord)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(curriculum.course.title).font(.title2.bold())
            HStack(spacing: 12) {
                Label("Week \(coords.week)", systemImage: "calendar")
                Label("Day \(coords.day)", systemImage: "\(min(coords.day,50)).circle")
                Label("\(currentStreak()) day streak", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Enable hourly reminders", systemImage: "bell.badge")
                .font(.headline)
            Text("Get a study nudge each morning and a quiz each afternoon.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Turn on notifications") {
                Task {
                    await notifications.requestAuthorization()
                    notifications.reschedule()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
    }

    private func lessonCard(_ day: Day) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day.isReview ? "Review & Test Day" : day.title)
                .font(.headline)
            if !day.vocab.isEmpty {
                Text("\(day.vocab.count) new words")
                    .font(.subheadline).foregroundStyle(.secondary)
                FlowChips(words: day.vocab.prefix(4).map(\.russian))
            }
            if let grammar = day.grammar {
                Label(grammar.title, systemImage: "textformat.abc")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                router.openStudy(dayIndex: dayIndex)
            } label: {
                Label("Study now", systemImage: "book.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                router.openTest(dayIndex: dayIndex)
            } label: {
                Label("Take the quiz", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    /// Count consecutive days (ending today) with a study or test record for this language.
    private func currentStreak() -> Int {
        let lang = curriculum.language.rawValue
        let done = Set(progress
            .filter { $0.lang == lang && ($0.studiedAt != nil || $0.testedAt != nil) }
            .map(\.dayIndex))
        var streak = 0
        var idx = dayIndex
        while idx >= 0 && done.contains(idx) { streak += 1; idx -= 1 }
        return streak
    }
}

/// Simple wrapping row of word chips.
struct FlowChips: View {
    let words: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(words, id: \.self) { w in
                    Text(w)
                        .font(.callout)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.blue.opacity(0.15), in: Capsule())
                }
            }
        }
    }
}
