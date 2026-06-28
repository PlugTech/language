import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @EnvironmentObject private var curriculum: CurriculumStore
    @Environment(\.modelContext) private var context
    @Query(sort: \LessonProgress.dayIndex) private var progress: [LessonProgress]
    @Query(sort: \TestResult.date, order: .reverse) private var results: [TestResult]

    private var dayIndex: Int { curriculum.currentDayIndex() }
    private var totalDays: Int { curriculum.course.weeks * 7 }

    private var lang: String { curriculum.language.rawValue }
    private var langProgress: [LessonProgress] { progress.filter { $0.lang == lang } }
    private var langResults: [TestResult] { results.filter { $0.lang == lang } }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    statRow("Days into course", "\(dayIndex + 1) / \(totalDays)")
                    statRow("Lessons studied", "\(langProgress.filter { $0.studiedAt != nil }.count)")
                    statRow("Quizzes taken", "\(langResults.count)")
                    statRow("Words in review", "\(reviewCount())")
                    statRow("Average accuracy", averageAccuracyText)
                }

                Section("Curriculum") {
                    ForEach(1...curriculum.course.weeks, id: \.self) { wk in
                        weekRow(wk)
                    }
                }

                if !langResults.isEmpty {
                    Section("Recent quizzes") {
                        ForEach(langResults.prefix(10)) { r in
                            HStack {
                                Text(r.date, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text("\(r.correct)/\(r.total)")
                                    .foregroundStyle(r.accuracy >= 0.7 ? .green : .orange)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    private func weekRow(_ wk: Int) -> some View {
        let startIdx = (wk - 1) * 7
        let studied = (0..<7).filter { offset in
            langProgress.contains { $0.dayIndex == startIdx + offset && $0.studiedAt != nil }
        }.count
        let isCurrent = curriculum.coordinates(forDayIndex: dayIndex).week == wk
        return HStack {
            Image(systemName: studied == 7 ? "checkmark.circle.fill" :
                    (studied > 0 ? "circle.lefthalf.filled" : "circle"))
                .foregroundStyle(studied == 7 ? .green : .secondary)
            Text("Week \(wk)")
            if let theme = curriculum.week(wk)?.theme {
                Text(theme).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text("\(studied)/7").font(.caption).foregroundStyle(.secondary)
        }
        .fontWeight(isCurrent ? .bold : .regular)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }

    private var averageAccuracyText: String {
        guard !langResults.isEmpty else { return "—" }
        let avg = langResults.map(\.accuracy).reduce(0, +) / Double(langResults.count)
        return "\(Int(avg * 100))%"
    }

    private func reviewCount() -> Int {
        let lang = self.lang
        let descriptor = FetchDescriptor<ReviewItem>(predicate: #Predicate { $0.lang == lang })
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}
