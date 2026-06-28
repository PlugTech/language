import Foundation

/// A language the app can teach. Each one maps to a curriculum folder (`Curriculum/<code>/`)
/// and a text-to-speech locale. Adding a language is: a new case + a curriculum folder.
enum Language: String, CaseIterable, Identifiable {
    case ru
    case bg

    var id: String { rawValue }

    /// English name shown in the picker.
    var displayName: String {
        switch self {
        case .ru: return "Russian"
        case .bg: return "Bulgarian"
        }
    }

    /// Endonym shown alongside the English name.
    var nativeName: String {
        switch self {
        case .ru: return "Русский"
        case .bg: return "Български"
        }
    }

    /// BCP-47 locale used to pick a TTS voice.
    var speechLocale: String {
        switch self {
        case .ru: return "ru-RU"
        case .bg: return "bg-BG"
        }
    }

    var flag: String {
        switch self {
        case .ru: return "🇷🇺"
        case .bg: return "🇧🇬"
        }
    }

    /// The word for "Today" in the target language (used as the dashboard title).
    var todayWord: String {
        switch self {
        case .ru: return "Сегодня"
        case .bg: return "Днес"
        }
    }

    /// A short greeting spoken when the learner taps "Test voice".
    var samplePhrase: String {
        switch self {
        case .ru: return "Привет! Давай учить русский."
        case .bg: return "Здравей! Хайде да учим български."
        }
    }

    /// Notification title for the morning study nudge.
    var studyReminderTitle: String {
        switch self {
        case .ru: return "📚 Время учить"
        case .bg: return "📚 Време за учене"
        }
    }

    /// Notification title for the afternoon quiz nudge.
    var testReminderTitle: String {
        switch self {
        case .ru: return "✅ Проверь себя"
        case .bg: return "✅ Провери се"
        }
    }

    /// Praise shown after a high-scoring quiz.
    var praiseExcellent: String {
        switch self {
        case .ru: return "Отлично!"
        case .bg: return "Отлично!"
        }
    }

    /// Praise shown after a solid quiz.
    var praiseGood: String {
        switch self {
        case .ru: return "Хорошо!"
        case .bg: return "Добре!"
        }
    }
}
