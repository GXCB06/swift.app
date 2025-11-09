import Foundation
#if canImport(GRDB)
import GRDB
#endif

/// GRDBStore: lightweight example showing how to persist Session and Reflection
/// This file expects GRDB to be added via Swift Package Manager.
/// It stores model JSON in a simple table. For production, prefer column-mapping and indexes.

public final class GRDBStore {
#if canImport(GRDB)
    private let dbQueue: DatabaseQueue

    public init(path: String) throws {
        // Ensure directory exists
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        dbQueue = try DatabaseQueue(path: path)
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createTables") { db in
            try db.create(table: "sessions") { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text)
                t.column("subject", .text)
                t.column("started_at", .datetime).notNull().indexed()
                t.column("ended_at", .datetime)
                t.column("synced", .boolean).notNull().defaults(to: false).indexed()
                t.column("created_at", .datetime).notNull()
            }
            try db.create(table: "reflections") { t in
                t.column("id", .text).primaryKey()
                t.column("session_id", .text).notNull().indexed()
                t.column("user_id", .text)
                t.column("task_text", .text)
                t.column("completion", .text)
                t.column("difficulty", .integer)
                t.column("efficiency_score", .double)
                t.column("created_at", .datetime).notNull()
            }
        }
        return migrator
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Sessions
    // Convert Session <-> SessionRecord for typed storage
    struct SessionRecord: Codable, FetchableRecord, PersistableRecord {
        var id: String
        var user_id: String?
        var subject: String?
        var started_at: Date
        var ended_at: Date?
        var synced: Bool
        var created_at: Date

        init(session: Session) {
            self.id = session.id.uuidString
            self.user_id = session.userId?.uuidString
            self.subject = session.subject
            self.started_at = session.startedAt
            self.ended_at = session.endedAt
            self.synced = session.synced
            self.created_at = session.startedAt
        }

        func toSession() -> Session {
            var s = Session(id: UUID(uuidString: id) ?? UUID(), startedAt: started_at, subject: subject)
            s.endedAt = ended_at
            s.synced = synced
            return s
        }
    }

    public func saveSession(_ s: Session) throws {
        let record = SessionRecord(session: s)
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    public func fetchSessions() throws -> [Session] {
        try dbQueue.read { db in
            let rows = try SessionRecord.fetchAll(db, sql: "SELECT * FROM sessions ORDER BY created_at DESC")
            return rows.map { $0.toSession() }
        }
    }

    // MARK: - Reflections
    struct ReflectionRecord: Codable, FetchableRecord, PersistableRecord {
        var id: String
        var session_id: String
        var user_id: String?
        var task_text: String?
        var completion: String?
        var difficulty: Int?
        var efficiency_score: Double?
        var created_at: Date

        init(reflection: Reflection) {
            self.id = reflection.id.uuidString
            self.session_id = reflection.sessionId.uuidString
            self.user_id = reflection.userId?.uuidString
            self.task_text = reflection.taskText
            self.completion = reflection.completion.rawValue
            self.difficulty = reflection.difficulty
            self.efficiency_score = reflection.efficiencyScore
            self.created_at = reflection.createdAt
        }

        func toReflection() -> Reflection {
            var r = Reflection(id: UUID(uuidString: id) ?? UUID(), sessionId: UUID(uuidString: session_id) ?? UUID(), taskText: task_text ?? "", completion: CompletionStatus(rawValue: completion ?? "partial") ?? .partial, difficulty: difficulty ?? 3)
            r.efficiencyScore = efficiency_score
            r.createdAt = created_at
            return r
        }
    }

    public func saveReflection(_ r: Reflection) throws {
        let record = ReflectionRecord(reflection: r)
        try dbQueue.write { db in
            try record.insert(db)
        }
    }

    public func fetchReflections() throws -> [Reflection] {
        try dbQueue.read { db in
            let rows = try ReflectionRecord.fetchAll(db, sql: "SELECT * FROM reflections ORDER BY created_at DESC")
            return rows.map { $0.toReflection() }
        }
    }

    // MARK: - Query helpers useful for sync
    /// Fetch sessions that haven't been synced to the server yet.
    public func fetchUnsyncedSessions() throws -> [Session] {
        try dbQueue.read { db in
            let rows = try SessionRecord.fetchAll(db, sql: "SELECT * FROM sessions WHERE synced = 0 ORDER BY started_at ASC")
            return rows.map { $0.toSession() }
        }
    }

    /// Mark a session as synced (server acknowledged).
    public func markSessionSynced(_ id: UUID) throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE sessions SET synced = 1 WHERE id = ?", arguments: [id.uuidString])
        }
    }

    /// Fetch reflections for a given session id.
    public func fetchReflections(for sessionId: UUID) throws -> [Reflection] {
        try dbQueue.read { db in
            let rows = try ReflectionRecord.fetchAll(db, sql: "SELECT * FROM reflections WHERE session_id = ? ORDER BY created_at DESC", arguments: [sessionId.uuidString])
            return rows.map { $0.toReflection() }
        }
    }

    /// Fetch sessions since a given date (inclusive)
    public func fetchSessions(since date: Date) throws -> [Session] {
        try dbQueue.read { db in
            let rows = try SessionRecord.fetchAll(db, sql: "SELECT * FROM sessions WHERE started_at >= ? ORDER BY started_at DESC", arguments: [date])
            return rows.map { $0.toSession() }
        }
    }

#else
    // If GRDB isn't available, provide compile-time stubs that throw a clear error.
    public enum GRDBStoreError: Error {
        case grdbNotAvailable
    }

    public init(path: String) throws {
        throw GRDBStoreError.grdbNotAvailable
    }

    public func saveSession(_ s: Session) throws { throw GRDBStoreError.grdbNotAvailable }
    public func fetchSessions() throws -> [Session] { throw GRDBStoreError.grdbNotAvailable }
    public func saveReflection(_ r: Reflection) throws { throw GRDBStoreError.grdbNotAvailable }
    public func fetchReflections() throws -> [Reflection] { throw GRDBStoreError.grdbNotAvailable }
#endif
}
