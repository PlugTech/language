import SwiftUI

/// Renders a single question with a "try again with hints" loop: a wrong answer reveals a
/// progressively bigger hint and lets the learner retry, up to `maxAttempts` times, after
/// which the correct answer is shown. Calls `onFinished(firstTryCorrect:)` exactly once when
/// the question resolves (used for scoring and SRS grading).
struct QuestionCard: View {
    let question: Question
    let onFinished: (_ firstTryCorrect: Bool) -> Void

    @EnvironmentObject private var speech: SpeechService

    @State private var typed = ""
    @State private var selected: String?            // last (wrong) choice tapped
    @State private var eliminated: Set<String> = []
    @State private var attempts = 0
    @State private var resolved = false
    @State private var revealed = false             // resolved by running out of attempts
    @State private var hint: String?

    private let maxAttempts = QuizEngine.maxAttempts

    var body: some View {
        VStack(spacing: 18) {
            Text(promptLabel).font(.caption).foregroundStyle(.secondary)
            prompt

            switch question.kind {
            case .typeRu: typeField
            default: choices
            }

            if let hint, !resolved {
                Label(hint, systemImage: "lightbulb")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                Text("\(maxAttempts - attempts) \(maxAttempts - attempts == 1 ? "try" : "tries") left")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if resolved { feedback }
        }
        .padding(.horizontal)
    }

    private var promptLabel: String {
        switch question.kind {
        case .ruToEn: return "What does this mean?"
        case .enToRu: return "Choose the translation"
        case .listening: return "Listen and choose the meaning"
        case .typeRu: return "Type the word"
        }
    }

    @ViewBuilder private var prompt: some View {
        if question.kind == .listening {
            Button { speech.speak(question.russian) } label: {
                Label("Play again", systemImage: "speaker.wave.3.fill").font(.title3)
            }
            .buttonStyle(.bordered)
            .onAppear { speech.speak(question.russian) }
        } else {
            Text(question.prompt)
                .font(.system(size: question.kind == .ruToEn ? 34 : 26, weight: .bold))
                .multilineTextAlignment(.center)
        }
    }

    private var choices: some View {
        VStack(spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                Button { pick(option) } label: {
                    Text(option).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(tint(for: option))
                .disabled(resolved || eliminated.contains(option))
            }
        }
    }

    private var typeField: some View {
        VStack(spacing: 12) {
            TextField("Type your answer…", text: $typed)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .font(.title3)
                .disabled(resolved)
            if !resolved {
                Button("Check") { checkTyped() }
                    .buttonStyle(.borderedProminent)
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var feedback: some View {
        VStack(spacing: 4) {
            Label(revealed ? "Answer: \(question.answer)" : "Correct",
                  systemImage: revealed ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(revealed ? .red : .green)
                .font(.headline)
            Text("\(question.russian) — \(question.english)")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: Answer handling

    private func pick(_ option: String) {
        guard !resolved else { return }
        if option == question.answer {
            resolve(firstTry: attempts == 0)
        } else {
            registerWrong(choice: option)
        }
    }

    private func checkTyped() {
        guard !resolved else { return }
        if QuizEngine.isCorrect(typed: typed, expected: question.answer) {
            resolve(firstTry: attempts == 0)
        } else {
            registerWrong(choice: nil)
        }
    }

    /// Record a wrong attempt: bump the counter, show a bigger hint, or reveal if out of tries.
    private func registerWrong(choice: String?) {
        attempts += 1
        if let choice { eliminated.insert(choice); selected = choice }
        if QuizEngine.shouldReveal(afterWrongAttempts: attempts) {
            revealed = true
            resolve(firstTry: false)
        } else {
            hint = QuizEngine.hint(answer: question.answer, kind: question.kind, attempt: attempts)
            if question.kind == .listening { speech.speak(question.russian) }
        }
    }

    private func resolve(firstTry: Bool) {
        resolved = true
        onFinished(firstTry)
    }

    private func tint(for option: String) -> Color {
        if resolved && option == question.answer { return .green }
        if eliminated.contains(option) { return .red }
        return .accentColor
    }
}
