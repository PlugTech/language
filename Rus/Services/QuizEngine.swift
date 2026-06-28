import Foundation

/// A single quiz question. `vocabId` is the SRS key (the Russian word) used to grade.
struct Question: Identifiable, Equatable {
    enum Kind: String {
        case ruToEn      // show Russian, choose English
        case enToRu      // show English, choose Russian
        case listening   // hear Russian (TTS), choose English
        case typeRu      // show English, type the Russian word
    }

    let id = UUID()
    let kind: Kind
    let vocabId: String
    let russian: String
    let english: String
    let prompt: String
    let options: [String]   // empty for `typeRu`
    let answer: String      // the correct option, or expected typed text

    static func == (lhs: Question, rhs: Question) -> Bool { lhs.id == rhs.id }
}

/// Builds a quiz from the day's new vocab plus spaced-repetition items that are due,
/// drawing distractors from everything learned so far.
enum QuizEngine {
    /// - Parameters:
    ///   - todays: today's new vocab (prioritised).
    ///   - due: vocab keys/glosses that are due for review.
    ///   - pool: all vocab learned so far, used for distractors and to resolve due items.
    static func makeQuiz(todays: [VocabItem],
                         due: [(id: String, english: String)],
                         pool: [VocabItem],
                         count: Int = 8) -> [Question] {
        // Resolve every candidate to a full VocabItem, preferring richer pool entries.
        var byId: [String: VocabItem] = [:]
        for v in pool { byId[v.id] = v }
        for v in todays { byId[v.id] = v }

        var candidates: [VocabItem] = []
        candidates.append(contentsOf: todays)
        for d in due {
            let item = byId[d.id] ?? VocabItem(russian: d.id, translit: "", english: d.english, pos: "")
            candidates.append(item)
        }
        // Dedup preserving order (today's first).
        var seen = Set<String>()
        candidates = candidates.filter { seen.insert($0.id).inserted }

        // Top up from the pool if we don't have enough.
        if candidates.count < count {
            for v in pool.shuffled() where seen.insert(v.id).inserted {
                candidates.append(v)
                if candidates.count >= count { break }
            }
        }

        let chosen = Array(candidates.shuffled().prefix(count))
        let kinds: [Question.Kind] = [.ruToEn, .enToRu, .listening, .typeRu]

        return chosen.enumerated().map { idx, item in
            let kind = kinds[idx % kinds.count]
            return question(for: item, kind: kind, pool: pool)
        }
    }

    private static func question(for item: VocabItem, kind: Question.Kind, pool: [VocabItem]) -> Question {
        switch kind {
        case .ruToEn:
            return Question(kind: kind, vocabId: item.id, russian: item.russian, english: item.english,
                            prompt: item.russian,
                            options: options(correct: item.english, from: pool.map(\.english)),
                            answer: item.english)
        case .listening:
            return Question(kind: kind, vocabId: item.id, russian: item.russian, english: item.english,
                            prompt: item.russian,   // spoken via TTS in the view
                            options: options(correct: item.english, from: pool.map(\.english)),
                            answer: item.english)
        case .enToRu:
            return Question(kind: kind, vocabId: item.id, russian: item.russian, english: item.english,
                            prompt: item.english,
                            options: options(correct: item.russian, from: pool.map(\.russian)),
                            answer: item.russian)
        case .typeRu:
            return Question(kind: kind, vocabId: item.id, russian: item.russian, english: item.english,
                            prompt: item.english, options: [], answer: item.russian)
        }
    }

    /// Build a 4-way multiple choice: the correct answer plus up to 3 distinct distractors.
    private static func options(correct: String, from candidates: [String]) -> [String] {
        var opts: [String] = [correct]
        for c in candidates.shuffled() where c != correct && !opts.contains(c) {
            opts.append(c)
            if opts.count >= 4 { break }
        }
        return opts.shuffled()
    }

    /// Number of attempts a learner gets (with hints) before the answer is revealed.
    static let maxAttempts = 3

    /// Progressive hint for a wrong answer: reveals one more leading character per attempt
    /// (attempt is 1-based). For typed questions it also states the length.
    static func hint(answer: String, kind: Question.Kind, attempt: Int) -> String {
        let shown = String(answer.prefix(max(1, attempt)))
        switch kind {
        case .typeRu: return "\(answer.count) letters · starts with “\(shown)…”"
        default:      return "It starts with “\(shown)…”"
        }
    }

    /// Whether running out of attempts should now reveal the answer.
    static func shouldReveal(afterWrongAttempts attempts: Int) -> Bool {
        attempts >= maxAttempts
    }

    /// Case/whitespace-insensitive answer check for typed Russian (ё/е treated as equal).
    static func isCorrect(typed: String, expected: String) -> Bool {
        func norm(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "ё", with: "е")
        }
        return norm(typed) == norm(expected)
    }
}
