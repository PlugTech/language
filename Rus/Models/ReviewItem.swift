import Foundation
import SwiftData

/// Spaced-repetition state for a single vocab item, persisted across sessions.
/// `id` is the Russian word (see `VocabItem.id`). The scheduling math lives in `SRSEngine`.
@Model
final class ReviewItem {
    @Attribute(.unique) var id: String   // "<lang>:<word>" — namespaced per language
    var lang: String = "ru"
    var english: String = ""
    var easeFactor: Double = 2.5         // SM-2 ease, starts at 2.5, floored at 1.3
    var intervalDays: Int = 0            // current interval in days
    var repetitions: Int = 0             // consecutive correct answers
    var dueDate: Date = Date.now
    var introducedAt: Date = Date.now
    var lapses: Int = 0                  // times answered wrong after being learned

    init(id: String,
         lang: String,
         english: String,
         easeFactor: Double = 2.5,
         intervalDays: Int = 0,
         repetitions: Int = 0,
         dueDate: Date,
         introducedAt: Date,
         lapses: Int = 0) {
        self.id = id
        self.lang = lang
        self.english = english
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.introducedAt = introducedAt
        self.lapses = lapses
    }
}
