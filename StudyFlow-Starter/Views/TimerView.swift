import SwiftUI

struct TimerView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) var dismiss

    @State private var session: Session? = nil
    @State private var elapsed: Int = 0
    @State private var timerTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Timer")
                .font(.title)

            Text(timeString)
                .font(.system(size: 48, weight: .semibold, design: .monospaced))

            HStack(spacing: 16) {
                Button(action: start) {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: stop) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .onDisappear { timerTask?.cancel() }
    }

    var timeString: String {
        let s = elapsed
        let minutes = s / 60
        let seconds = s % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard session == nil else { return }
        let s = store.createSession()
        session = s
        elapsed = 0
        timerTask = Task { [weak self] in
            while !(Task.isCancelled) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    self?.elapsed += 1
                }
            }
        }
    }

    func stop() {
        guard let s = session else { return }
        timerTask?.cancel()
        var ended = s
        ended.endedAt = Date()
        store.endSession(ended)
        // show reflection view modally
        // Dismiss this sheet and present reflection on top of dashboard by using NotificationCenter or simple pattern: open reflection sheet
        // For simplicity, dismiss and then present reflection via a short delay
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Present a reflection by posting notification
            NotificationCenter.default.post(name: .didEndSession, object: ended)
        }
    }
}

extension Notification.Name {
    static let didEndSession = Notification.Name("StudyFlow.didEndSession")
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            .environmentObject(LocalStore())
    }
}
