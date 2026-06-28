import Foundation

/// Top-level course metadata (loaded from `course.json`).
struct Course: Codable, Hashable {
    var title: String
    var subtitle: String
    var weeks: Int
}

/// One week of the curriculum (loaded from `week-NN.json`).
struct Week: Codable, Hashable, Identifiable {
    var week: Int
    var theme: String
    var days: [Day]

    var id: Int { week }
}

/// A single day's lesson. Study days carry new material; review days focus on testing.
struct Day: Codable, Hashable, Identifiable {
    var day: Int                 // 1...7 within the week
    var title: String
    var isReview: Bool
    var vocab: [VocabItem]
    var grammar: GrammarPoint?
    var reading: ReadingPassage?
    var speakingPrompt: String?

    var id: Int { day }
}

/// A vocabulary entry. `russian` doubles as the stable identity used by the SRS engine.
struct VocabItem: Codable, Hashable, Identifiable {
    var russian: String
    var translit: String
    var english: String
    var pos: String              // part of speech: noun, verb, adj, phrase, ...
    var example: String?
    var exampleEn: String?

    /// Stable key used to track spaced-repetition state across the app.
    var id: String { russian }
}

/// A focused grammar explanation with worked examples.
struct GrammarPoint: Codable, Hashable {
    var title: String
    var explanation: String      // markdown
    var examples: [Bilingual]
}

/// A short reading passage with translation and a word glossary.
struct ReadingPassage: Codable, Hashable {
    var title: String
    var text: String
    var translation: String
    var glossary: [Bilingual]
}

/// A Russian/English pair used in grammar examples, glossaries, and drills.
struct Bilingual: Codable, Hashable, Identifiable {
    var russian: String
    var english: String
    var id: String { russian + "|" + english }
}
