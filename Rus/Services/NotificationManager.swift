import Foundation
import UserNotifications

/// Owns notification permissions, categories/actions, the rolling schedule, and routing
/// taps back into the app. iOS caps pending local notifications at 64, so we always
/// reschedule a forward window and let it refresh on launch / background refresh.
@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    weak var router: AppRouter?
    private let center = UNUserNotificationCenter.current()
    private let store: CurriculumStore

    // Notification metadata keys / identifiers.
    private enum K {
        static let studyCategory = "STUDY"
        static let testCategory = "TEST"
        static let mode = "mode"          // "study" | "test"
        static let dayIndex = "dayIndex"
        static let maxPending = 60        // stay safely under iOS's 64 limit
    }

    init(store: CurriculumStore = .shared) {
        self.store = store
        super.init()
        center.delegate = self
    }

    func registerCategories() {
        let open = UNNotificationAction(identifier: "OPEN", title: "Open", options: [.foreground])
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 1h", options: [])
        let study = UNNotificationCategory(identifier: K.studyCategory, actions: [open],
                                           intentIdentifiers: [], options: [])
        let test = UNNotificationCategory(identifier: K.testCategory, actions: [open, snooze],
                                          intentIdentifiers: [], options: [])
        center.setNotificationCategories([study, test])
    }

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch { }
        await refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: Scheduling

    /// Rebuild the rolling notification window from `now` forward.
    func reschedule(now: Date = .now, calendar: Calendar = .current) {
        center.removeAllPendingNotificationRequests()
        guard NotificationSettings.enabled else { return }

        let settings = NotificationSettings.load()
        let baseDayIndex = store.currentDayIndex(now: now)
        var scheduled = 0
        var dayOffset = 0

        while scheduled < K.maxPending && dayOffset < 14 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset,
                                           to: calendar.startOfDay(for: now)) else { break }
            let dayIndex = min(baseDayIndex + dayOffset, store.course.weeks * 7 - 1)
            let day = store.day(forDayIndex: dayIndex)

            let slots: [(hour: Int, isStudy: Bool)] =
                settings.studyHours.map { ($0, true) } + settings.testHours.map { ($0, false) }

            for slot in slots {
                guard scheduled < K.maxPending else { break }
                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = slot.hour
                comps.minute = 0
                guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }

                let content = makeContent(day: day, dayIndex: dayIndex, isStudy: slot.isStudy)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                    repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                    content: content, trigger: trigger)
                center.add(request)
                scheduled += 1
            }
            dayOffset += 1
        }
    }

    private func makeContent(day: Day?, dayIndex: Int, isStudy: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = [K.mode: isStudy ? "study" : "test", K.dayIndex: dayIndex]
        content.categoryIdentifier = isStudy ? K.studyCategory : K.testCategory

        if isStudy {
            content.title = store.language.studyReminderTitle
            if let words = day?.vocab.prefix(4), !words.isEmpty {
                let preview = words.map(\.russian).joined(separator: ", ")
                content.body = "Today's words: \(preview)…"
            } else {
                content.body = day?.title ?? "Open today's lesson."
            }
        } else {
            content.title = store.language.testReminderTitle
            content.body = "A quick quiz is ready — test today's words and your reviews."
        }
        return content
    }

    /// Snooze: re-add a single test notification one hour out.
    private func snooze(dayIndex: Int) {
        let content = makeContent(day: store.day(forDayIndex: dayIndex), dayIndex: dayIndex, isStudy: false)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        let mode = info["mode"] as? String
        let dayIndex = info["dayIndex"] as? Int

        await MainActor.run {
            if response.actionIdentifier == "SNOOZE", let idx = dayIndex {
                self.snooze(dayIndex: idx)
                return
            }
            if mode == "study" {
                self.router?.openStudy(dayIndex: dayIndex)
            } else {
                self.router?.openTest(dayIndex: dayIndex)
            }
        }
    }
}
