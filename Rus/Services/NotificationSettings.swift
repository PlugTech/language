import Foundation

/// User-tunable notification window. Study prompts fire in [studyStart, studyEnd); test
/// prompts fire in [testStart, testEnd] — every hour, on the hour.
struct NotificationSettings {
    var studyStartHour: Int
    var studyEndHour: Int    // exclusive; also the first test hour
    var testEndHour: Int     // inclusive

    static let `default` = NotificationSettings(studyStartHour: 9, studyEndHour: 12, testEndHour: 20)

    private enum Keys {
        static let studyStart = "notif.studyStart"
        static let studyEnd = "notif.studyEnd"
        static let testEnd = "notif.testEnd"
        static let enabled = "notif.enabled"
    }

    static func load(_ defaults: UserDefaults = .standard) -> NotificationSettings {
        guard defaults.object(forKey: Keys.studyStart) != nil else { return .default }
        return NotificationSettings(
            studyStartHour: defaults.integer(forKey: Keys.studyStart),
            studyEndHour: defaults.integer(forKey: Keys.studyEnd),
            testEndHour: defaults.integer(forKey: Keys.testEnd)
        )
    }

    func save(_ defaults: UserDefaults = .standard) {
        defaults.set(studyStartHour, forKey: Keys.studyStart)
        defaults.set(studyEndHour, forKey: Keys.studyEnd)
        defaults.set(testEndHour, forKey: Keys.testEnd)
    }

    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.enabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.enabled) }
    }

    var studyHours: [Int] { Array(studyStartHour..<studyEndHour) }
    var testHours: [Int] { Array(studyEndHour...max(studyEndHour, testEndHour)) }
}
