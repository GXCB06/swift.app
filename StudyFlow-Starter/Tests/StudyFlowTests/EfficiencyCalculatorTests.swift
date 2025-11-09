import XCTest
@testable import StudyFlow

final class EfficiencyCalculatorTests: XCTestCase {
    func testCalculateScore_Complete() throws {
        let reflection = Reflection(
            sessionId: UUID(),
            taskText: "Test task",
            completion: .yes,
            difficulty: 5
        )
        
        // 30 minute session
        let score = EfficiencyCalculator.calculate(reflection: reflection, durationMinutes: 30)
        
        // Score should be bounded 0-100
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
        // High difficulty + complete should yield high score
        XCTAssertGreaterThan(score, 50)
    }
    
    func testCalculateScore_Incomplete() throws {
        let reflection = Reflection(
            sessionId: UUID(),
            taskText: "Test task",
            completion: .no,
            difficulty: 5
        )
        
        let score = EfficiencyCalculator.calculate(reflection: reflection, durationMinutes: 30)
        
        // Incomplete should yield low score regardless of time/difficulty
        XCTAssertLessThan(score, 30)
    }
    
    func testCalculateScore_EdgeCases() throws {
        // Zero duration
        let r1 = Reflection(sessionId: UUID(), completion: .yes, difficulty: 5)
        XCTAssertGreaterThanOrEqual(EfficiencyCalculator.calculate(reflection: r1, durationMinutes: 0), 0)
        
        // Max difficulty
        let r2 = Reflection(sessionId: UUID(), completion: .yes, difficulty: 5)
        XCTAssertLessThanOrEqual(EfficiencyCalculator.calculate(reflection: r2, durationMinutes: 120), 100)
        
        // Min difficulty
        let r3 = Reflection(sessionId: UUID(), completion: .yes, difficulty: 1)
        XCTAssertGreaterThan(EfficiencyCalculator.calculate(reflection: r3, durationMinutes: 30), 0)
    }
}