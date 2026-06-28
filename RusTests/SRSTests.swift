import XCTest
@testable import Rus

final class SRSTests: XCTestCase {

    func testFirstCorrectSchedulesOneDay() {
        let start = SRSState(easeFactor: 2.5, intervalDays: 0, repetitions: 0, lapses: 0)
        let next = SRS.next(from: start, quality: SRS.quality(forCorrect: true))
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertEqual(next.repetitions, 1)
        XCTAssertGreaterThanOrEqual(next.easeFactor, 1.3)
    }

    func testSecondCorrectSchedulesSixDays() {
        var s = SRSState(easeFactor: 2.5, intervalDays: 0, repetitions: 0, lapses: 0)
        s = SRS.next(from: s, quality: 4)   // -> 1 day, reps 1
        s = SRS.next(from: s, quality: 4)   // -> 6 days, reps 2
        XCTAssertEqual(s.intervalDays, 6)
        XCTAssertEqual(s.repetitions, 2)
    }

    func testCorrectLengthensInterval() {
        var s = SRSState(easeFactor: 2.5, intervalDays: 6, repetitions: 2, lapses: 0)
        s = SRS.next(from: s, quality: 4)
        XCTAssertGreaterThan(s.intervalDays, 6, "interval should grow after a correct review")
    }

    func testWrongResetsAndCountsLapse() {
        let s = SRSState(easeFactor: 2.5, intervalDays: 30, repetitions: 5, lapses: 0)
        let next = SRS.next(from: s, quality: SRS.quality(forCorrect: false))
        XCTAssertEqual(next.intervalDays, 1, "wrong answer should reset to 1 day")
        XCTAssertEqual(next.repetitions, 0)
        XCTAssertEqual(next.lapses, 1)
        XCTAssertLessThan(next.easeFactor, 2.5, "ease should drop after a wrong answer")
    }

    func testEaseNeverBelowFloor() {
        var s = SRSState(easeFactor: 1.3, intervalDays: 1, repetitions: 0, lapses: 0)
        for _ in 0..<10 { s = SRS.next(from: s, quality: 0) }
        XCTAssertGreaterThanOrEqual(s.easeFactor, 1.3)
    }

    func testTypedAnswerNormalisation() {
        XCTAssertTrue(QuizEngine.isCorrect(typed: "  Привет ", expected: "привет"))
        XCTAssertTrue(QuizEngine.isCorrect(typed: "ещё", expected: "еще"))   // ё == е
        XCTAssertFalse(QuizEngine.isCorrect(typed: "пока", expected: "привет"))
    }

    // MARK: Quiz hints

    func testRevealsAfterThreeWrongAttempts() {
        XCTAssertFalse(QuizEngine.shouldReveal(afterWrongAttempts: 1))
        XCTAssertFalse(QuizEngine.shouldReveal(afterWrongAttempts: 2))
        XCTAssertTrue(QuizEngine.shouldReveal(afterWrongAttempts: 3))
        XCTAssertEqual(QuizEngine.maxAttempts, 3)
    }

    func testHintRevealsMoreEachAttempt() {
        let h1 = QuizEngine.hint(answer: "привет", kind: .ruToEn, attempt: 1)
        let h2 = QuizEngine.hint(answer: "привет", kind: .ruToEn, attempt: 2)
        XCTAssertTrue(h1.contains("п"))
        XCTAssertTrue(h2.contains("пр"), "second hint should reveal more letters: \(h2)")
    }

    func testTypedHintStatesLength() {
        let h = QuizEngine.hint(answer: "спасибо", kind: .typeRu, attempt: 1)
        XCTAssertTrue(h.contains("7 letters"), "expected length in hint: \(h)")
    }
}
