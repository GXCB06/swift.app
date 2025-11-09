import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    var userId: UUID? = nil
    var subject: String?
    var startedAt: Date
    var endedAt: Date?
    var synced: Bool = false

    var durationSeconds: Int {
        let end = endedAt ?? Date()
        return Int(end.timeIntervalSince(startedAt))
    }

    init(id: UUID = UUID(), startedAt: Date = Date(), subject: String? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.subject = subject
    }
}
