import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppRouter.Tab.today)

            StudyView()
                .tabItem { Label("Study", systemImage: "book") }
                .tag(AppRouter.Tab.study)

            TestView()
                .tabItem { Label("Test", systemImage: "checkmark.circle") }
                .tag(AppRouter.Tab.test)

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(AppRouter.Tab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppRouter.Tab.settings)
        }
    }
}
