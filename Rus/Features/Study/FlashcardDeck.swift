import SwiftUI

/// A swipeable, tap-to-flip flashcard deck for the day's vocabulary.
struct FlashcardDeck: View {
    let vocab: [VocabItem]
    @State private var index = 0
    @State private var flipped = false
    @EnvironmentObject private var speech: SpeechService

    var body: some View {
        VStack(spacing: 12) {
            if vocab.indices.contains(index) {
                let item = vocab[index]
                Button {
                    withAnimation(.spring(duration: 0.3)) { flipped.toggle() }
                } label: {
                    cardFace(item)
                }
                .buttonStyle(.plain)

                HStack {
                    Button { step(-1) } label: { Image(systemName: "chevron.left") }
                        .disabled(index == 0)
                    Spacer()
                    Text("\(index + 1) / \(vocab.count)").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Button { step(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(index == vocab.count - 1)
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 8)
    }

    private func cardFace(_ item: VocabItem) -> some View {
        VStack(spacing: 10) {
            if flipped {
                Text(item.english).font(.title.bold())
                Text(item.translit).font(.headline).foregroundStyle(.secondary)
                if let ex = item.example { Text(ex).font(.subheadline).multilineTextAlignment(.center) }
            } else {
                Text(item.russian).font(.system(size: 40, weight: .bold))
                Button { speech.speak(item.russian) } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                Text("Tap to flip").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(flipped ? Color.green.opacity(0.12) : Color.blue.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func step(_ delta: Int) {
        flipped = false
        index = min(max(0, index + delta), vocab.count - 1)
    }
}
