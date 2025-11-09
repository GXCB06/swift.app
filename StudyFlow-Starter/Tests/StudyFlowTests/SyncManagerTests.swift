import XCTest
@testable import StudyFlow

/// Mock API client for testing sync behavior
class MockAPIClient {
    static var shared = MockAPIClient()
    var shouldSucceed = true
    var uploadedSessions: [Session] = []
    var uploadedReflections: [Reflection] = []
    
    func uploadSession(_ session: Session, reflections: [Reflection]) async throws -> Bool {
        if !shouldSucceed { throw APIError.networkError }
        uploadedSessions.append(session)
        uploadedReflections.append(contentsOf: reflections)
        return true
    }
    
    func reset() {
        uploadedSessions = []
        uploadedReflections = []
        shouldSucceed = true
    }
}

final class SyncManagerTests: XCTestCase {
    var store: LocalStore!
    var syncManager: SyncManager!
    let mockAPI = MockAPIClient.shared
    
    override func setUpWithError() throws {
        store = LocalStore()
        syncManager = SyncManager(store: store, intervalSeconds: 0.1) // Fast interval for testing
        mockAPI.reset()
    }
    
    override func tearDown() {
        syncManager.stop()
        super.tearDown()
    }
    
    func testSyncSuccessful() async throws {
        // Create unsynced session + reflection
        let s = store.createSession(subject: "Test sync")
        store.endSession(s)
        let r = Reflection(sessionId: s.id, taskText: "Test reflection", completion: .yes, difficulty: 3)
        store.saveReflection(r)
        
        mockAPI.shouldSucceed = true
        let success = await syncManager.performSync()
        XCTAssertTrue(success)
        
        // Verify mock API received the data
        XCTAssertEqual(mockAPI.uploadedSessions.count, 1)
        XCTAssertEqual(mockAPI.uploadedSessions.first?.id, s.id)
        XCTAssertEqual(mockAPI.uploadedReflections.count, 1)
    }
    
    func testSyncFailure() async throws {
        let s = store.createSession(subject: "Test sync failure")
        store.endSession(s)
        
        mockAPI.shouldSucceed = false
        let success = await syncManager.performSync()
        XCTAssertFalse(success)
        
        // Session should still be unsynced
        XCTAssertEqual(store.fetchUnsyncedSessions().count, 1)
    }
    
    func testBackoffOnFailure() async throws {
        let s = store.createSession()
        store.endSession(s)
        
        mockAPI.shouldSucceed = false
        
        // First attempt
        let success1 = await syncManager.performSync()
        XCTAssertFalse(success1)
        
        // Second attempt (should have increased delay)
        let success2 = await syncManager.performSync()
        XCTAssertFalse(success2)
        
        // Session should still be unsynced
        XCTAssertEqual(store.fetchUnsyncedSessions().count, 1)
    }
}