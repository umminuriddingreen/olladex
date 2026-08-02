import AppKit
import Foundation

@MainActor
@Observable
final class AppStore {
    var models: [OllamaModel] = []
    var selectedModel = ""
    var ollamaVersion: String?
    var route = CodexRoute.unknown
    var isWorking = false
    var message: StatusMessage?
    var showingActivationConfirmation = false

    private let ollama = OllamaClient()
    private let config = CodexConfigManager()

    init() {
        Task { await refresh() }
    }

    func refresh() async {
        isWorking = true
        defer { isWorking = false }
        do {
            async let server = ollama.status()
            let currentRoute = try config.currentRoute()
            let result = try await server
            models = result.models.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            ollamaVersion = result.version
            route = currentRoute
            if selectedModel.isEmpty || !models.contains(where: { $0.name == selectedModel }) {
                selectedModel = models.first?.name ?? ""
            }
            message = nil
        } catch {
            route = (try? config.currentRoute()) ?? .unknown
            models = []
            ollamaVersion = nil
            message = .init(kind: .error, text: error.localizedDescription)
        }
    }

    func activateSelectedModel() {
        guard !selectedModel.isEmpty else { return }
        showingActivationConfirmation = true
    }

    func confirmActivation() async {
        showingActivationConfirmation = false
        isWorking = true
        defer { isWorking = false }
        do {
            let receipt = try config.activate(model: selectedModel)
            route = try config.currentRoute()
            message = .init(kind: .success, text: "Local route active. Backup: \(receipt.backup.lastPathComponent)")
        } catch {
            message = .init(kind: .error, text: error.localizedDescription)
        }
    }

    func restoreOpenAI() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let restored = try config.restoreLatestBackup()
            route = try config.currentRoute()
            message = .init(kind: .success, text: restored ? "Restored the previous Codex configuration." : "No Olladex backup was found.")
        } catch {
            message = .init(kind: .error, text: error.localizedDescription)
        }
    }

    func openCodex() {
        let candidates = ["com.openai.codex", "com.openai.chatgpt"]
        for identifier in candidates {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                NSWorkspace.shared.openApplication(at: url, configuration: .init())
                message = .init(kind: .success, text: "Opened Codex. Start a new task to use the active route.")
                return
            }
        }
        message = .init(kind: .error, text: "Codex was not found in Applications.")
    }
}

struct StatusMessage: Equatable {
    enum Kind { case success, error }
    let kind: Kind
    let text: String
}
