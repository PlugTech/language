import SwiftUI
import SwiftData

struct TestView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var curriculum: CurriculumStore
    @Environment(\.modelContext) private var context

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var correctCount = 0
    @State private var resolved = false
    @State private var finished = false

    private var dayIndex: Int { router.pendingDayIndex ?? curriculum.currentDayIndex() }

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    ContentUnavailableView {
                        Label("No quiz yet", systemImage: "checkmark.circle")
                    } description: {
                        Text("Study a lesson first, then come back to test yourself.")
                    } actions: {
                        Button("Build a quiz") { buildQuiz() }.buttonStyle(.borderedProminent)
                    }
                } else if finished {
                    resultView
                } else {
                    quizView
                }
            }
            .navigationTitle("Quiz")
            .onAppear { if questions.isEmpty { buildQuiz() } }
        }
    }

    // MARK: Quiz UI

    private var quizView: some View {
        let q = questions[index]
        return VStack(spacing: 20) {
            SwiftUI.ProgressView(value: Double(index), total: Double(questions.count))
                .padding(.horizontal)

            QuestionCard(question: q) { firstTryCorrect in
                handleFinished(firstTryCorrect, for: q)
            }
            .id(q.id)   // reset the card's per-question state when the question changes

            Spacer()

            if resolved {
                Button(index + 1 < questions.count ? "Next" : "Finish") { advance() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom)
            }
        }
        .padding(.top)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rosette").font(.system(size: 60)).foregroundStyle(.orange)
            Text("\(correctCount) / \(questions.count) correct").font(.title.bold())
            Text(scoreBlurb).foregroundStyle(.secondary)
            Button("Done") {
                router.pendingDayIndex = nil
                router.selectedTab = .today
            }
            .buttonStyle(.borderedProminent)
            Button("New quiz") { buildQuiz() }.buttonStyle(.bordered)
        }
        .padding()
    }

    private var scoreBlurb: String {
        let ratio = questions.isEmpty ? 0 : Double(correctCount) / Double(questions.count)
        let lang = curriculum.language
        switch ratio {
        case 0.9...: return "\(lang.praiseExcellent) Excellent work."
        case 0.7..<0.9: return "\(lang.praiseGood) Solid — review the misses."
        default: return "Keep practising — these will stick with review."
        }
    }

    // MARK: Logic

    private func buildQuiz() {
        let srs = SRSEngine(context: context, lang: curriculum.language.rawValue)
        let due = srs.dueItems(limit: 20)
        let todays = curriculum.day(forDayIndex: dayIndex)?.vocab ?? []
        let pool = curriculum.vocabThrough(dayIndex: dayIndex)
        questions = QuizEngine.makeQuiz(todays: todays, due: due, pool: pool, count: 8)
        index = 0; correctCount = 0; resolved = false; finished = false
    }

    /// Called once per question when it resolves. `firstTryCorrect` drives both the score
    /// and SRS grading — answers reached only via hints count as "not yet learned".
    private func handleFinished(_ firstTryCorrect: Bool, for q: Question) {
        guard !resolved else { return }
        if firstTryCorrect { correctCount += 1 }
        resolved = true
        SRSEngine(context: context, lang: curriculum.language.rawValue)
            .grade(id: q.vocabId, english: q.english, correct: firstTryCorrect)
    }

    private func advance() {
        if index + 1 < questions.count {
            index += 1
            resolved = false
        } else {
            recordResult()
            finished = true
        }
    }

    private func recordResult() {
        let lang = curriculum.language.rawValue
        let idx = dayIndex
        context.insert(TestResult(lang: lang, date: .now, dayIndex: idx,
                                  total: questions.count, correct: correctCount))
        let fetch = FetchDescriptor<LessonProgress>(
            predicate: #Predicate { $0.lang == lang && $0.dayIndex == idx })
        if let existing = try? context.fetch(fetch).first {
            existing.testedAt = .now
        } else {
            context.insert(LessonProgress(lang: lang, dayIndex: idx, testedAt: .now))
        }
        try? context.save()
    }
}
