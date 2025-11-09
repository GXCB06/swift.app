import Foundation

enum CompletionStatus: String, Codable, CaseIterable, Identifiable {
    case yes, partial, no
    var id: String { rawValue }
}

struct Reflection: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionId: UUID
    var userId: UUID? = nil
    var taskText: String
    var completion: CompletionStatus
    var difficulty: Int // 1..5
    var efficiencyScore: Double? = nil
    var createdAt: Date = Date()

    init(id: UUID = UUID(), sessionId: UUID, taskText: String = "", completion: CompletionStatus = .partial, difficulty: Int = 3) {
        self.id = id
        self.sessionId = sessionId
        self.taskText = taskText
        self.completion = completion
        self.difficulty = difficulty
    }
}
