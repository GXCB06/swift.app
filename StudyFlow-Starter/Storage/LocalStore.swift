import Foundation
import Combine

final class LocalStore: ObservableObject {
    @Published private(set) var sessions: [Session] = []
    @Published private(set) var reflections: [Reflection] = []

    private var grdbStore: GRDBStore?

    init() {
        // Attempt to initialize GRDBStore. If GRDB isn't available, fall back to in-memory store.
        do {
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = appSupport.appendingPathComponent("studyflow.sqlite")
            grdbStore = try GRDBStore(path: dbURL.path)

            // Load persisted data
            let dbSessions = try grdbStore?.fetchSessions() ?? []
            let dbReflections = try grdbStore?.fetchReflections() ?? []
            DispatchQueue.main.async {
                self.sessions = dbSessions
                self.reflections = dbReflections
            }
        } catch {
            // GRDB not available or initialization failed — keep using in-memory store
            print("GRDB store not available or failed to initialize: \(error)")
            grdbStore = nil
        }
    }

    // MARK: - Sessions
    func createSession(subject: String? = nil) -> Session {
        let s = Session(startedAt: Date(), subject: subject)
        sessions.insert(s, at: 0)

        // Persist in background if GRDB is available
        Task.detached { [weak self] in
            guard let store = self?.grdbStore else { return }
            do {
                try store.saveSession(s)
            } catch {
                print("Failed to save session to GRDB: \(error)")
            }
        }

        return s
    }

    func endSession(_ session: Session) {
        guard let idx = sessions.firstIndex(of: session) else { return }
        var updated = sessions[idx]
        updated.endedAt = Date()
        sessions[idx] = updated

        Task.detached { [weak self] in
            guard let store = self?.grdbStore else { return }
            do {
                try store.saveSession(updated)
            } catch {
                print("Failed to persist ended session: \(error)")
            }
        }
    }

    // MARK: - Reflections
    func saveReflection(_ reflection: Reflection) {
        reflections.insert(reflection, at: 0)
        // keep local session marked unsynced
        if let idx = sessions.firstIndex(where: { $0.id == reflection.sessionId }) {
            sessions[idx].synced = false
        }

        Task.detached { [weak self] in
            guard let store = self?.grdbStore else { return }
            do {
                try store.saveReflection(reflection)
            } catch {
                print("Failed to save reflection to GRDB: \(error)")
            }
        }
    }

    // Utility for demo
    func session(for id: UUID) -> Session? {
        sessions.first(where: { $0.id == id })
    }

    // MARK: - Sync helpers (delegate to GRDB store if available)
    func fetchUnsyncedSessions() -> [Session] {
        do {
            if let s = try grdbStore?.fetchUnsyncedSessions() {
                return s
            }
        } catch {
            print("fetchUnsyncedSessions failed: \(error)")
        }
        return sessions.filter { !$0.synced }
    }

    func markSessionSynced(_ id: UUID) {
        // update in-memory
        if let idx = sessions.firstIndex(where: { $0.id == id }) {
            sessions[idx].synced = true
        }
        // persist
        Task.detached { [weak self] in
            guard let store = self?.grdbStore else { return }
            do {
                try store.markSessionSynced(id)
            } catch {
                print("markSessionSynced failed: \(error)")
            }
        }
    }

    func fetchReflections(for sessionId: UUID) -> [Reflection] {
        do {
            if let rows = try grdbStore?.fetchReflections(for: sessionId) {
                return rows
            }
        } catch {
            print("fetchReflections(for:) failed: \(error)")
        }
        return reflections.filter { $0.sessionId == sessionId }
    }

    func fetchSessions(since date: Date) -> [Session] {
        do {
            if let rows = try grdbStore?.fetchSessions(since: date) {
                return rows
            }
        } catch {
            print("fetchSessions(since:) failed: \(error)")
        }
        return sessions.filter { $0.startedAt >= date }
    }
}
