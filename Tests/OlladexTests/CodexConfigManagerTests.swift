import Foundation
import Testing
@testable import Olladex

@Suite("Codex configuration")
struct CodexConfigManagerTests {
    @Test("Activation preserves unrelated configuration and creates a backup")
    func activationIsSurgical() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let codex = home.appending(path: ".codex")
        try FileManager.default.createDirectory(at: codex, withIntermediateDirectories: true)
        let config = codex.appending(path: "config.toml")
        try """
        model = "gpt-5.6"
        approval_policy = "never"

        [features]
        memories = true
        """.write(to: config, atomically: true, encoding: .utf8)

        let manager = CodexConfigManager(home: home)
        let receipt = try manager.activate(model: "qwen3:8b")
        let changed = try String(contentsOf: config, encoding: .utf8)

        #expect(changed.contains("model = \"qwen3:8b\""))
        #expect(changed.contains("model_provider = \"olladex-ollama\""))
        #expect(changed.contains("approval_policy = \"never\""))
        #expect(changed.contains("memories = true"))
        #expect(FileManager.default.fileExists(atPath: receipt.backup.path))
        #expect(try manager.currentRoute() == .ollama(model: "qwen3:8b"))
    }

    @Test("Restore returns the exact previous bytes")
    func restoreIsExact() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let codex = home.appending(path: ".codex")
        try FileManager.default.createDirectory(at: codex, withIntermediateDirectories: true)
        let config = codex.appending(path: "config.toml")
        let original = "model = \"gpt-5.6\"\n# keep this comment\n"
        try original.write(to: config, atomically: true, encoding: .utf8)

        let manager = CodexConfigManager(home: home)
        _ = try manager.activate(model: "qwen3:8b")
        #expect(try manager.restoreLatestBackup())
        #expect(try String(contentsOf: config, encoding: .utf8) == original)
    }
}
