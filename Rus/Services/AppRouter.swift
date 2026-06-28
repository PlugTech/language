import Foundation
import SwiftUI

/// Drives navigation, including deep-links opened from notifications.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case today, study, test, progress, settings }

    @Published var selectedTab: Tab = .today

    /// When a notification is tapped, we record the requested mode so the app can jump
    /// straight into Study or Test for that day.
    @Published var pendingDayIndex: Int?

    func openStudy(dayIndex: Int?) {
        pendingDayIndex = dayIndex
        selectedTab = .study
    }

    func openTest(dayIndex: Int?) {
        pendingDayIndex = dayIndex
        selectedTab = .test
    }
}
