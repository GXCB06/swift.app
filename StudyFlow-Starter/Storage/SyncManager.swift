import Foundation

/// SyncManager: simple periodic sync worker that uploads unsynced sessions and their reflections.
final class SyncManager {
    private let store: LocalStore
    private var task: Task<Void, Never>? = nil
    private let intervalSeconds: TimeInterval
    private var consecutiveFailureCount: Int = 0

    init(store: LocalStore, intervalSeconds: TimeInterval = 30) {
        self.store = store
        self.intervalSeconds = intervalSeconds
    }

    func start() {
        guard task == nil else { return }
        consecutiveFailureCount = 0
        task = Task.detached { [weak self] in
            await self?.runLoop()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func runLoop() async {
        while !(Task.isCancelled) {
            let success = await performSync()

            // Apply exponential backoff on repeated failures, capped to 5 minutes
            let maxDelay: TimeInterval = 300 // 5 minutes
            let multiplier = success ? 1.0 : min(pow(2.0, Double(consecutiveFailureCount)), maxDelay / max(1.0, intervalSeconds))
            let delay = max(1.0, intervalSeconds * multiplier)

            if success {
                consecutiveFailureCount = 0
            } else {
                consecutiveFailureCount += 1
            }

            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                break
            }
        }
    }

    /// Perform a single sync pass: upload unsynced sessions and mark synced on success.
    /// Perform a single sync pass: upload unsynced sessions and mark synced on success.
    /// Returns true if all uploads succeeded (or there was nothing to sync); false if any failed.
    func performSync() async -> Bool {
        let unsynced = store.fetchUnsyncedSessions()
        guard !unsynced.isEmpty else { return true }

        var allSucceeded = true
        for session in unsynced {
            if Task.isCancelled { return false }
            let reflections = store.fetchReflections(for: session.id)
            do {
                let success = try await APIClient.shared.uploadSession(session, reflections: reflections)
                if success {
                    store.markSessionSynced(session.id)
                } else {
                    allSucceeded = false
                }
            } catch {
                // on error: log and mark as failed; will be retried with backoff
                allSucceeded = false
                print("Sync error uploading session \(session.id): \(error)")
            }
        }

        return allSucceeded
    }
}
