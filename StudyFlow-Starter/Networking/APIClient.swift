import Foundation

enum APIError: Error {
    case networkError
    case invalidResponse
}

struct APIClient {
    static let shared = APIClient()

    private init() {}

    // Stub: simulate sending reflection and receiving efficiency score
    func submitReflection(_ reflection: Reflection) async throws -> Double {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        // Use local calculation for demo; real app would call backend
        let score = EfficiencyCalculator.calculate(reflection: reflection, durationMinutes: 10)
        return score
    }

    // Stub: upload a session payload; returns true on success
    func uploadSession(_ session: Session, reflections: [Reflection]) async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        // Simulate success
        return true
    }

    // Stub: upload a reflection individually
    func uploadReflection(_ reflection: Reflection) async throws -> Bool {
        try await Task.sleep(nanoseconds: 200_000_000)
        return true
    }
}
