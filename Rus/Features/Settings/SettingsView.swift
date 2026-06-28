import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var curriculum: CurriculumStore
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var speech: SpeechService
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var context

    @State private var selectedLanguage = CurriculumStore.shared.language
    @State private var startDate = CurriculumStore.shared.startDate
    @State private var settings = NotificationSettings.load()
    @State private var notificationsEnabled = NotificationSettings.enabled
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Learning", selection: $selectedLanguage) {
                        ForEach(Language.allCases) { lang in
                            Text("\(lang.flag) \(lang.displayName) · \(lang.nativeName)").tag(lang)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, lang in switchLanguage(to: lang) }
                }

                Section("Schedule") {
                    DatePicker("Course start date", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, new in
                            curriculum.startDate = new
                            notifications.reschedule()
                        }
                }

                Section("Reminders") {
                    Toggle("Hourly reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, on in
                            NotificationSettings.enabled = on
                            Task {
                                if on { await notifications.requestAuthorization() }
                                notifications.reschedule()
                            }
                        }
                    hourStepper("Study from", value: $settings.studyStartHour, range: 5...11)
                    hourStepper("Switch to quizzes at", value: $settings.studyEndHour, range: 10...15)
                    hourStepper("Last quiz at", value: $settings.testEndHour, range: 15...23)
                    Text("Study prompts \(settings.studyStartHour):00–\(settings.studyEndHour):00, quizzes \(settings.studyEndHour):00–\(settings.testEndHour):00, hourly.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .onChange(of: settings.studyStartHour) { _, _ in applySettings() }
                .onChange(of: settings.studyEndHour) { _, _ in applySettings() }
                .onChange(of: settings.testEndHour) { _, _ in applySettings() }

                Section("Audio") {
                    HStack {
                        Text("\(selectedLanguage.displayName) voice")
                        Spacer()
                        Text(speech.currentVoiceName ?? "Not installed")
                            .foregroundStyle(.secondary)
                    }
                    Button("Test voice") { speech.speak(selectedLanguage.samplePhrase) }
                    if !speech.hasVoice {
                        Text("Install a \(selectedLanguage.displayName) voice in Settings → Accessibility → Spoken Content → Voices.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Button("Reset \(selectedLanguage.displayName) progress", role: .destructive) {
                        showResetConfirm = true
                    }
                }

                Section {
                    Text("\(curriculum.course.title) · \(curriculum.course.weeks) weeks")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all \(selectedLanguage.displayName) study progress and reviews?",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset \(selectedLanguage.displayName)", role: .destructive) { resetCurrentLanguage() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func switchLanguage(to lang: Language) {
        curriculum.setLanguage(lang)
        speech.languageCode = lang.speechLocale
        startDate = curriculum.startDate     // per-language start date
        router.pendingDayIndex = nil
        router.selectedTab = .today
        notifications.reschedule()
    }

    private func hourStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper("\(label): \(value.wrappedValue):00", value: value, in: range)
    }

    private func applySettings() {
        if settings.studyEndHour <= settings.studyStartHour { settings.studyEndHour = settings.studyStartHour + 1 }
        if settings.testEndHour < settings.studyEndHour { settings.testEndHour = settings.studyEndHour }
        settings.save()
        notifications.reschedule()
    }

    private func resetCurrentLanguage() {
        let lang = curriculum.language.rawValue
        try? context.delete(model: LessonProgress.self, where: #Predicate { $0.lang == lang })
        try? context.delete(model: TestResult.self, where: #Predicate { $0.lang == lang })
        try? context.delete(model: ReviewItem.self, where: #Predicate { $0.lang == lang })
        try? context.save()
    }
}
