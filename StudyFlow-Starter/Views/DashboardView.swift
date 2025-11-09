import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: LocalStore
    @State private var showTimer = false

    var unsyncedCount: Int { store.fetchUnsyncedSessions().count }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("StudyFlow")
                    .font(.largeTitle)
                    .bold()
                if unsyncedCount > 0 {
                    Text("Unsynced: \(unsyncedCount)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                Spacer()
            }

            Button(action: { showTimer = true }) {
                Label("Start Session", systemImage: "timer")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            List {
                Section(header: Text("Recent Sessions")) {
                    ForEach(store.sessions) { s in
                        VStack(alignment: .leading) {
                            Text(s.subject ?? "Study Session")
                                .font(.headline)
                            Text("Started: \(s.startedAt.formatted())")
                                .font(.caption)
                            if let ended = s.endedAt {
                                Text("Duration: \(s.durationSeconds) sec")
                                    .font(.caption2)
                            } else {
                                Text("Running…")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                Section(header: Text("Reflections")) {
                    ForEach(store.reflections) { r in
                        VStack(alignment: .leading) {
                            Text(r.taskText.isEmpty ? "Quick reflection" : r.taskText)
                                .font(.subheadline)
                            if let score = r.efficiencyScore {
                                Text("Score: \(score, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showTimer) {
            TimerView()
                .environmentObject(store)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(LocalStore())
    }
}
