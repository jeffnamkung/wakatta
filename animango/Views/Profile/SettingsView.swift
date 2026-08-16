import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false

    var body: some View {
        List {
            Section("Audio") {
                HStack {
                    Image(systemName: "speaker.wave.2")
                    Text("TTS Language")
                    Spacer()
                    Text("Japanese (ja-JP)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data") {
                Button {
                    SampleData.loadIfNeeded(modelContext: modelContext)
                } label: {
                    Label("Reload Sample Data", systemImage: "arrow.clockwise")
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset All Progress", systemImage: "trash")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("App")
                    Spacer()
                    Text("animango")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Reset All Progress",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                resetProgress()
            }
        } message: {
            Text("This will delete all your study progress. Your library will not be affected.")
        }
    }

    private func resetProgress() {
        do {
            try modelContext.delete(model: UserProgress.self)
            try modelContext.save()
        } catch {
            // Handle error silently
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserProgress.self], inMemory: true)
}
