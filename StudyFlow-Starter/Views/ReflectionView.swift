import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject var store: LocalStore
    @Environment(\.dismiss) var dismiss

    @State var session: Session
    @State private var taskText: String = ""
    @State private var completion: CompletionStatus = .partial
    @State private var difficulty: Int = 3
    @State private var isSubmitting: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("What did you work on?")) {
                    TextField("Task summary", text: $taskText)
                }

                Section(header: Text("Did you complete your goal?")) {
                    Picker("Completion", selection: $completion) {
                        ForEach(CompletionStatus.allCases) { c in
                            Text(c.rawValue.capitalized).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Difficulty (1-5)")) {
                    Stepper(value: $difficulty, in: 1...5) {
                        Text("Difficulty: \(difficulty)")
                    }
                }

                Section {
                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit Reflection")
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Reflection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    func submit() {
        isSubmitting = true
        var r = Reflection(sessionId: session.id, taskText: taskText, completion: completion, difficulty: difficulty)
        Task {
            do {
                // compute score locally for demo
                let mins = Double(max(1, session.durationSeconds)) / 60.0
                let score = EfficiencyCalculator.calculate(reflection: r, durationMinutes: mins)
                r.efficiencyScore = score
                // save locally
                await MainActor.run {
                    store.saveReflection(r)
                }
                // optionally send to server
                _ = try await APIClient.shared.submitReflection(r)
                isSubmitting = false
                dismiss()
            } catch {
                // handle error gracefully
                isSubmitting = false
            }
        }
    }
}

// Helper: listen for ended session notification and present modal
struct ReflectionPresenter: ViewModifier {
    @EnvironmentObject var store: LocalStore
    @State private var activeSession: Session? = nil
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .didEndSession)) { note in
                if let s = note.object as? Session {
                    activeSession = s
                }
            }
            .sheet(item: $activeSession) { s in
                ReflectionView(session: s)
                    .environmentObject(store)
            }
    }
}

extension View {
    func withReflectionPresenter() -> some View {
        self.modifier(ReflectionPresenter())
    }
}

struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView(session: Session())
            .environmentObject(LocalStore())
    }
}
