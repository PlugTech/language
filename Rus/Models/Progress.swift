import Foundation
import SwiftData

/// Records that a given study day's content was opened/completed, used for streaks and the
/// Today dashboard. Keyed by absolute day index since the course start.
@Model
final class LessonProgress {
    var lang: String = "ru"                 // language code; progress is per-language
    var dayIndex: Int = 0                   // 0-based days since course start
    var studiedAt: Date?
    var testedAt: Date?

    init(lang: String, dayIndex: Int, studiedAt: Date? = nil, testedAt: Date? = nil) {
        self.lang = lang
        self.dayIndex = dayIndex
        self.studiedAt = studiedAt
        self.testedAt = testedAt
    }
}

/// One completed quiz attempt, for the Progress screen's accuracy history.
@Model
final class TestResult {
    var lang: String = "ru"
    var date: Date = Date.now
    var dayIndex: Int = 0
    var total: Int = 0
    var correct: Int = 0

    init(lang: String, date: Date, dayIndex: Int, total: Int, correct: Int) {
        self.lang = lang
        self.date = date
        self.dayIndex = dayIndex
        self.total = total
        self.correct = correct
    }

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}
