import Foundation

enum CodexRoute: Equatable {
    case openAI(model: String?)
    case ollama(model: String)
    case custom(provider: String, model: String?)
    case unknown

    var providerName: String {
        switch self {
        case .openAI: "OpenAI"
        case .ollama: "Ollama"
        case .custom(let provider, _): provider
        case .unknown: "Unknown"
        }
    }

    var modelName: String {
        switch self {
        case .openAI(let model), .custom(_, let model): model ?? "Default"
        case .ollama(let model): model
        case .unknown: "Not configured"
        }
    }
}

struct ConfigReceipt {
    let backup: URL
    let config: URL
}

enum ConfigError: LocalizedError {
    case invalidModel
    case missingBackup

    var errorDescription: String? {
        switch self {
        case .invalidModel: "Choose an installed Ollama model first."
        case .missingBackup: "The saved Codex backup could not be read."
        }
    }
}

struct CodexConfigManager {
    private let fileManager = FileManager.default
    private let home: URL

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
    }

    private var codexDirectory: URL { home.appending(path: ".codex", directoryHint: .isDirectory) }
    private var configURL: URL { codexDirectory.appending(path: "config.toml") }
    private var backupDirectory: URL { codexDirectory.appending(path: "olladex-backups", directoryHint: .isDirectory) }

    func currentRoute() throws -> CodexRoute {
        guard fileManager.fileExists(atPath: configURL.path) else { return .openAI(model: nil) }
        let text = try String(contentsOf: configURL, encoding: .utf8)
        let values = topLevelValues(in: text)
        let provider = values["model_provider"] ?? "openai"
        let model = values["model"]
        if provider == "olladex-ollama" || provider == "ollama" || provider == "ollama-launch" {
            return .ollama(model: model ?? "Unknown")
        }
        if provider == "openai" { return .openAI(model: model) }
        return .custom(provider: provider, model: model)
    }

    func activate(model: String) throws -> ConfigReceipt {
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !model.contains("\n"), !model.contains("\r"), !model.contains("\"") else { throw ConfigError.invalidModel }
        try fileManager.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let original = (try? Data(contentsOf: configURL)) ?? Data()
        let backup = backupDirectory.appending(path: "config-\(timestamp()).toml")
        try original.write(to: backup, options: .atomic)

        var text = String(data: original, encoding: .utf8) ?? ""
        text = setTopLevel(key: "model", value: model, in: text)
        text = setTopLevel(key: "model_provider", value: "olladex-ollama", in: text)
        text = upsertProvider(in: text)
        try Data(text.utf8).write(to: configURL, options: .atomic)
        return .init(backup: backup, config: configURL)
    }

    func restoreLatestBackup() throws -> Bool {
        guard let backups = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil),
              let latest = backups.filter({ $0.pathExtension == "toml" }).sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first else {
            return false
        }
        guard let data = try? Data(contentsOf: latest) else { throw ConfigError.missingBackup }
        try data.write(to: configURL, options: .atomic)
        return true
    }

    private func topLevelValues(in text: String) -> [String: String] {
        var values: [String: String] = [:]
        var inTable = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") { inTable = true }
            guard !inTable, !trimmed.hasPrefix("#"), let equal = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<equal].trimmingCharacters(in: .whitespaces)
            let raw = trimmed[trimmed.index(after: equal)...].trimmingCharacters(in: .whitespaces)
            values[key] = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return values
    }

    private func setTopLevel(key: String, value: String, in text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        let replacement = "\(key) = \"\(value)\""
        var tableIndex = lines.firstIndex { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") } ?? lines.endIndex
        if let index = lines[..<tableIndex].firstIndex(where: { line in
            line.trimmingCharacters(in: .whitespaces).hasPrefix("\(key) ") || line.trimmingCharacters(in: .whitespaces).hasPrefix("\(key)=")
        }) {
            lines[index] = replacement
        } else {
            lines.insert(replacement, at: tableIndex)
            tableIndex += 1
        }
        return lines.joined(separator: "\n")
    }

    private func upsertProvider(in text: String) -> String {
        let header = "[model_providers.olladex-ollama]"
        if text.contains(header) { return text }
        let suffix = """

        \(header)
        name = "Ollama via Olladex"
        base_url = "http://127.0.0.1:11434/v1/"
        wire_api = "responses"
        """
        return text.trimmingCharacters(in: .newlines) + "\n" + suffix + "\n"
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}
