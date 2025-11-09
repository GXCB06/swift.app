import SwiftUI

@main
struct StudyFlowApp: App {
    @StateObject private var store: LocalStore
    private var syncManager: SyncManager?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let s = LocalStore()
        _store = StateObject(wrappedValue: s)
        syncManager = SyncManager(store: s)
        // don't start yet; we'll manage start/stop with scene phase
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DashboardView()
            }
            .environmentObject(store)
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .active:
                    syncManager?.start()
                default:
                    syncManager?.stop()
                }
            }
        }
    }
}
