import XCTest
@testable import Rus

/// Validates the source-of-truth curriculum JSON directly from disk (independent of
/// app bundling), so a malformed or incomplete week fails the build.
final class CurriculumTests: XCTestCase {

    private var curriculumDir: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()      // RusTests/
            .deletingLastPathComponent()      // project root
            .appending(path: "Rus/Resources/Curriculum")
    }

    /// Language subfolders that contain a course.json (ru, bg, …).
    private func languageDirs() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: curriculumDir, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .filter { FileManager.default.fileExists(atPath: $0.appending(path: "course.json").path) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func testCourseDecodes() throws {
        let dirs = try languageDirs()
        XCTAssertFalse(dirs.isEmpty, "Expected at least one language folder with course.json")
        for dir in dirs {
            let url = dir.appending(path: "course.json")
            let course = try JSONDecoder().decode(Course.self, from: Data(contentsOf: url))
            XCTAssertEqual(course.weeks, 26, "\(dir.lastPathComponent): expected 26 weeks")
            XCTAssertFalse(course.title.isEmpty)
        }
    }

    func testAllPresentWeeksAreValid() throws {
        let files = try languageDirs().flatMap { dir in
            (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        }
            .filter { $0.lastPathComponent.hasPrefix("week-") }
            .sorted { $0.path < $1.path }

        XCTAssertFalse(files.isEmpty, "Expected at least one week-NN.json")

        for file in files {
            let week = try JSONDecoder().decode(Week.self, from: Data(contentsOf: file))
            let label = file.lastPathComponent

            XCTAssertEqual(week.days.count, 7, "\(label): expected 7 days")
            XCTAssertEqual(week.days.map(\.day), Array(1...7), "\(label): day numbers must be 1...7")
            XCTAssertEqual(week.days.filter(\.isReview).count, 1, "\(label): expected exactly one review day")
            XCTAssertFalse(week.theme.isEmpty, "\(label): theme is empty")

            for day in week.days {
                if !day.isReview {
                    XCTAssertGreaterThanOrEqual(day.vocab.count, 5,
                                                "\(label) day \(day.day): study days need >=5 vocab")
                }
                for v in day.vocab {
                    XCTAssertFalse(v.russian.isEmpty, "\(label) day \(day.day): empty russian")
                    XCTAssertFalse(v.translit.isEmpty, "\(label) day \(day.day): \(v.russian) missing translit")
                    XCTAssertFalse(v.english.isEmpty, "\(label) day \(day.day): \(v.russian) missing english")
                    XCTAssertFalse(v.pos.isEmpty, "\(label) day \(day.day): \(v.russian) missing pos")
                    XCTAssertNotNil(v.example, "\(label) day \(day.day): \(v.russian) missing example")
                }
            }
        }
    }
}
