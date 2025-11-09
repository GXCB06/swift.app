import Foundation

struct EfficiencyCalculator {
    /// Simple example formula: completion (1/0.5/0) * difficulty * log(1 + minutes)
    static func calculate(reflection: Reflection, durationMinutes: Double) -> Double {
        let completionValue: Double
        switch reflection.completion {
        case .yes: completionValue = 1.0
        case .partial: completionValue = 0.5
        case .no: completionValue = 0.0
        }
        let difficultyFactor = Double(reflection.difficulty) / 5.0 // normalize 0..1
        let timeFactor = log(1 + durationMinutes)
        let base = completionValue * difficultyFactor * timeFactor
        // normalize to 0..100 (naive)
        let normalized = min(max(base / 1.5 * 100.0, 0.0), 100.0)
        return Double(round(100 * normalized) / 100)
    }

    // Convenience
    static func calculate(reflection: Reflection, session: Session) -> Double {
        let mins = Double(max(1, session.durationSeconds)) / 60.0
        return calculate(reflection: reflection, durationMinutes: mins)
    }
}
