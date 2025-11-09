import XCTest
@testable import StudyFlow
#if canImport(GRDB)
import GRDB
#endif

final class GRDBStoreTests: XCTestCase {
    var tempDBURL: URL!
    var store: GRDBStore?
    
    override func setUpWithError() throws {
        tempDBURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        store = try GRDBStore(path: tempDBURL.path)
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDBURL)
    }
    
    func testSaveAndFetchSession() throws {
        #if !canImport(GRDB)
        throw XCTSkip("GRDB not available")
        #else
        let s = Session(subject: "Test subject")
        try store?.saveSession(s)
        
        let fetched = try store?.fetchSessions()
        XCTAssertEqual(fetched?.count, 1)
        XCTAssertEqual(fetched?.first?.id, s.id)
        XCTAssertEqual(fetched?.first?.subject, "Test subject")
        #endif
    }
    
    func testSaveAndFetchReflection() throws {
        #if !canImport(GRDB)
        throw XCTSkip("GRDB not available")
        #else
        let s = Session()
        try store?.saveSession(s)
        
        let r = Reflection(sessionId: s.id, taskText: "Test reflection", completion: .yes, difficulty: 3)
        try store?.saveReflection(r)
        
        let fetched = try store?.fetchReflections(for: s.id)
        XCTAssertEqual(fetched?.count, 1)
        XCTAssertEqual(fetched?.first?.id, r.id)
        XCTAssertEqual(fetched?.first?.taskText, "Test reflection")
        #endif
    }
    
    func testFetchUnsyncedSessions() throws {
        #if !canImport(GRDB)
        throw XCTSkip("GRDB not available")
        #else
        let s1 = Session()
        let s2 = Session()
        try store?.saveSession(s1)
        try store?.saveSession(s2)
        
        // Mark one synced
        try store?.markSessionSynced(s1.id)
        
        let unsynced = try store?.fetchUnsyncedSessions()
        XCTAssertEqual(unsynced?.count, 1)
        XCTAssertEqual(unsynced?.first?.id, s2.id)
        #endif
    }
}