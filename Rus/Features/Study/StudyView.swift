import SwiftUI
import SwiftData

struct StudyView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var curriculum: CurriculumStore
    @Environment(\.modelContext) private var context

    private var dayIndex: Int { router.pendingDayIndex ?? curriculum.currentDayIndex() }
    private var day: Day? { curriculum.day(forDayIndex: dayIndex) }

    var body: some View {
        NavigationStack {
            Group {
                if let day {
                    List {
                        if !day.vocab.isEmpty {
                            Section("Vocabulary") {
                                FlashcardDeck(vocab: day.vocab)
                                    .listRowInsets(EdgeInsets())
                                    .frame(height: 280)
                            }
                            Section("Word list") {
                                ForEach(day.vocab) { VocabRow(item: $0) }
                            }
                        }
                        if let grammar = day.grammar {
                            Section("Grammar — \(grammar.title)") {
                                GrammarView(point: grammar)
                            }
                        }
                        if let reading = day.reading {
                            Section("Reading — \(reading.title)") {
                                ReadingView(passage: reading)
                            }
                        }
                        if let prompt = day.speakingPrompt {
                            Section("Speaking practice") {
                                Text(prompt).font(.body)
                            }
                        }
                        Section {
                            Button("Mark studied ✓") { markStudied(day) }
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                } else {
                    ContentUnavailableView("Nothing to study", systemImage: "book.closed")
                }
            }
            .navigationTitle(day?.isReview == true ? "Review" : "Study")
        }
    }

    private func markStudied(_ day: Day) {
        let lang = curriculum.language.rawValue
        let idx = dayIndex
        SRSEngine(context: context, lang: lang).introduce(day.vocab)
        let fetch = FetchDescriptor<LessonProgress>(
            predicate: #Predicate { $0.lang == lang && $0.dayIndex == idx })
        if let existing = try? context.fetch(fetch).first {
            existing.studiedAt = .now
        } else {
            context.insert(LessonProgress(lang: lang, dayIndex: idx, studiedAt: .now))
        }
        try? context.save()
        router.pendingDayIndex = nil
        router.openTest(dayIndex: idx)
    }
}

struct VocabRow: View {
    let item: VocabItem
    @EnvironmentObject private var speech: SpeechService

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.russian).font(.headline)
                Text("\(item.translit) · \(item.english)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { speech.speak(item.russian) } label: {
                Image(systemName: "speaker.wave.2.fill")
            }
            .buttonStyle(.borderless)
        }
    }
}
