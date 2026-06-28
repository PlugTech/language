import SwiftUI

struct GrammarView: View {
    let point: GrammarPoint
    @EnvironmentObject private var speech: SpeechService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(point.explanation))
                .font(.body)
            ForEach(point.examples) { ex in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.russian).font(.callout.weight(.medium))
                        Text(ex.english).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { speech.speak(ex.russian) } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

struct ReadingView: View {
    let passage: ReadingPassage
    @EnvironmentObject private var speech: SpeechService
    @State private var showTranslation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(passage.text).font(.body)
            HStack {
                Button { speech.speak(passage.text) } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                Button(showTranslation ? "Hide translation" : "Show translation") {
                    withAnimation { showTranslation.toggle() }
                }
                .buttonStyle(.bordered)
            }
            if showTranslation {
                Text(passage.translation)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !passage.glossary.isEmpty {
                DisclosureGroup("Glossary") {
                    ForEach(passage.glossary) { g in
                        HStack {
                            Text(g.russian).fontWeight(.medium)
                            Spacer()
                            Text(g.english).foregroundStyle(.secondary)
                        }
                        .font(.callout)
                    }
                }
            }
        }
    }
}
