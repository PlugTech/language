import Foundation

/// Loads the bundled curriculum JSON for the currently-selected language and maps the
/// calendar onto it: given a course start date, it resolves which week/day the learner is
/// on today. Switching `language` swaps the entire curriculum.
@MainActor
final class CurriculumStore: ObservableObject {
    static let shared = CurriculumStore()

    @Published private(set) var language: Language
    @Published private(set) var course: Course

    private var weekCache: [Int: Week] = [:]
    private let bundle: Bundle
    private let calendar: Calendar

    private let startDateKeyPrefix = "courseStartDate."
    private let languageKey = "selectedLanguage"

    init(bundle: Bundle = .main, calendar: Calendar = .current) {
        self.bundle = bundle
        self.calendar = calendar
        let lang = Language(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .ru
        self.language = lang
        self.course = Self.loadCourse(lang, from: bundle)
    }

    /// Switch the taught language; reloads the course and clears the week cache.
    func setLanguage(_ lang: Language) {
        guard lang != language else { return }
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: languageKey)
        weekCache.removeAll()
        course = Self.loadCourse(lang, from: bundle)
        SpeechService.shared.languageCode = lang.speechLocale
    }

    // MARK: Start date (tracked per language)

    private var startDateKey: String { startDateKeyPrefix + language.rawValue }

    /// The day the learner began this language; defaults to the start of today on first use.
    var startDate: Date {
        get {
            if let stored = UserDefaults.standard.object(forKey: startDateKey) as? Date {
                return stored
            }
            let today = calendar.startOfDay(for: .now)
            UserDefaults.standard.set(today, forKey: startDateKey)
            return today
        }
        set { UserDefaults.standard.set(calendar.startOfDay(for: newValue), forKey: startDateKey) }
    }

    /// 0-based number of days since the course began (clamped to the course length).
    func currentDayIndex(now: Date = .now) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        let maxIndex = course.weeks * 7 - 1
        return min(max(0, days), maxIndex)
    }

    // MARK: Lookup

    func coordinates(forDayIndex index: Int) -> (week: Int, day: Int) {
        (week: index / 7 + 1, day: index % 7 + 1)
    }

    func absoluteIndex(week: Int, day: Int) -> Int {
        (week - 1) * 7 + (day - 1)
    }

    func week(_ number: Int) -> Week? {
        if let cached = weekCache[number] { return cached }
        guard let loaded = Self.loadWeek(number, language: language, from: bundle) else { return nil }
        weekCache[number] = loaded
        return loaded
    }

    func day(forDayIndex index: Int) -> Day? {
        let c = coordinates(forDayIndex: index)
        return week(c.week)?.days.first { $0.day == c.day }
    }

    func today(now: Date = .now) -> Day? {
        day(forDayIndex: currentDayIndex(now: now))
    }

    /// All vocab introduced up to and including the given day index (used to seed review pools).
    func vocabThrough(dayIndex: Int) -> [VocabItem] {
        var result: [VocabItem] = []
        for idx in 0...max(0, dayIndex) {
            if let day = day(forDayIndex: idx) { result.append(contentsOf: day.vocab) }
        }
        return result
    }

    // MARK: Loading

    private static func loadCourse(_ lang: Language, from bundle: Bundle) -> Course {
        if let course: Course = decode("course", language: lang, from: bundle) { return course }
        return Course(title: "\(lang.displayName) in 6 Months",
                      subtitle: "From the alphabet to A2", weeks: 26)
    }

    private static func loadWeek(_ number: Int, language lang: Language, from bundle: Bundle) -> Week? {
        decode(String(format: "week-%02d", number), language: lang, from: bundle)
    }

    private static func decode<T: Decodable>(_ resource: String, language lang: Language,
                                             from bundle: Bundle) -> T? {
        let subdir = "Curriculum/\(lang.rawValue)"
        guard let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: subdir)
                ?? bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
