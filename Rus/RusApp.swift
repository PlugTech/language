import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct RusApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var router = AppRouter()
    @StateObject private var curriculum = CurriculumStore.shared
    @StateObject private var notifications = NotificationManager.shared
    @StateObject private var speech = SpeechService.shared

    private let container: ModelContainer
    static let refreshTaskID = "vin.plug.Rus.refresh"

    init() {
        let schema = Schema([LessonProgress.self, TestResult.self, ReviewItem.self])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            // An incompatible older store (e.g. a pre-multilanguage schema) can't migrate
            // automatically — wipe it and start fresh rather than crash on launch.
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(filePath: url.path + suffix))
            }
            do {
                container = try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(curriculum)
                .environmentObject(notifications)
                .environmentObject(speech)
                .task {
                    notifications.router = router
                    notifications.registerCategories()
                    await notifications.refreshAuthorizationStatus()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task {
                    await notifications.refreshAuthorizationStatus()
                    notifications.reschedule()
                }
            case .background:
                scheduleBackgroundRefresh()
            default:
                break
            }
        }
    }

    // MARK: Background refresh — keeps the rolling notification window topped up.

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                NotificationManager.shared.reschedule()
                task.setTaskCompleted(success: true)
            }
            scheduleBackgroundRefresh()
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}
