import Foundation
import SwiftData

/// Result of scheduling one review — pure values, no persistence. Kept separate so the
/// SM-2 math can be unit-tested without SwiftData.
struct SRSState: Equatable {
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var lapses: Int
}

/// Pure SM-2 spaced-repetition math. `quality` is 0–5 (SuperMemo scale); the app maps a
/// wrong answer to 2 and a correct answer to 4 via `quality(forCorrect:)`.
enum SRS {
    static func quality(forCorrect correct: Bool) -> Int { correct ? 4 : 2 }

    /// Compute the next SRS state from the current one and the answer quality.
    static func next(from state: SRSState, quality: Int) -> SRSState {
        var s = state
        let q = max(0, min(5, quality))

        if q < 3 {
            // Lapse: reset the learning streak, re-show tomorrow.
            s.repetitions = 0
            s.intervalDays = 1
            s.lapses += 1
        } else {
            switch s.repetitions {
            case 0: s.intervalDays = 1
            case 1: s.intervalDays = 6
            default: s.intervalDays = Int((Double(s.intervalDays) * s.easeFactor).rounded())
            }
            s.repetitions += 1
        }

        // Adjust ease factor (SM-2 formula), floored at 1.3.
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        s.easeFactor = max(1.3, s.easeFactor + delta)
        return s
    }

    static func dueDate(from now: Date, intervalDays: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: max(1, intervalDays), to: now) ?? now
    }
}

/// Persists SRS state via SwiftData and answers "what is due to review right now?".
@MainActor
final class SRSEngine {
    let context: ModelContext
    let lang: String
    private let calendar: Calendar

    init(context: ModelContext, lang: String, calendar: Calendar = .current) {
        self.context = context
        self.lang = lang
        self.calendar = calendar
    }

    /// Namespaced SRS key so the same spelling in two languages doesn't collide.
    private func key(_ word: String) -> String { "\(lang):\(word)" }

    /// Introduce vocab the first time it's studied, so it enters the review queue.
    func introduce(_ items: [VocabItem], now: Date = .now) {
        for item in items where existing(id: key(item.id)) == nil {
            let review = ReviewItem(
                id: key(item.id),
                lang: lang,
                english: item.english,
                dueDate: SRS.dueDate(from: now, intervalDays: 1, calendar: calendar),
                introducedAt: now
            )
            context.insert(review)
        }
        try? context.save()
    }

    /// Grade an answer and reschedule the item. Creates the item if it wasn't introduced yet.
    func grade(id rawId: String, english: String, correct: Bool, now: Date = .now) {
        let id = key(rawId)
        let item = existing(id: id) ?? {
            let new = ReviewItem(id: id, lang: lang, english: english,
                                 dueDate: now, introducedAt: now)
            context.insert(new)
            return new
        }()

        let current = SRSState(easeFactor: item.easeFactor,
                               intervalDays: item.intervalDays,
                               repetitions: item.repetitions,
                               lapses: item.lapses)
        let updated = SRS.next(from: current, quality: SRS.quality(forCorrect: correct))
        item.easeFactor = updated.easeFactor
        item.intervalDays = updated.intervalDays
        item.repetitions = updated.repetitions
        item.lapses = updated.lapses
        item.dueDate = SRS.dueDate(from: now, intervalDays: updated.intervalDays, calendar: calendar)
        try? context.save()
    }

    /// Words due for review (this language), most overdue first. Ids are the raw words.
    func dueItems(now: Date = .now, limit: Int = 50) -> [(id: String, english: String)] {
        let lang = self.lang
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.lang == lang && $0.dueDate <= now },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        let items = (try? context.fetch(descriptor)) ?? []
        let prefix = "\(lang):"
        return items.prefix(limit).map { (id: String($0.id.dropFirst(prefix.count)), english: $0.english) }
    }

    func dueCount(now: Date = .now) -> Int {
        let lang = self.lang
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate { $0.lang == lang && $0.dueDate <= now })
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    private func existing(id: String) -> ReviewItem? {
        let descriptor = FetchDescriptor<ReviewItem>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}
