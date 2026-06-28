import Foundation
import AVFoundation

/// On-device Russian text-to-speech via AVSpeechSynthesizer. Free, offline, no network.
@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()

    /// BCP-47 locale of the language currently being taught (set by `CurriculumStore`).
    var languageCode: String = (Language(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") ?? .ru).speechLocale

    /// Speak text in the current language. Picks the best available voice for the locale;
    /// rate is slightly slowed for learners.
    func speak(_ text: String, rate: Float = 0.42) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        configureSessionForPlayback()
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: languageCode)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        synth.speak(utterance)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    /// True if a voice exists for the current language (used to warn the learner).
    var hasVoice: Bool { Self.voice(for: languageCode) != nil }

    var currentVoiceName: String? { Self.voice(for: languageCode)?.name }

    private func configureSessionForPlayback() {
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        #endif
    }

    /// Prefer an enhanced voice for the locale's language if downloaded, else any matching voice.
    static func voice(for localeCode: String) -> AVSpeechSynthesisVoice? {
        let prefix = String(localeCode.prefix(2))
        let matching = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(prefix) }
        return matching.first { $0.quality == .enhanced }
            ?? matching.first
            ?? AVSpeechSynthesisVoice(language: localeCode)
    }
}
