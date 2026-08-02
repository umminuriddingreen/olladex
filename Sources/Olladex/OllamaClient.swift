import Foundation

struct OllamaModel: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let size: Int64?

    var formattedSize: String {
        guard let size else { return "Local" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct OllamaStatus {
    let version: String
    let models: [OllamaModel]
}

enum OllamaError: LocalizedError {
    case unavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unavailable: "Ollama is not reachable at 127.0.0.1:11434. Open Ollama, then refresh."
        case .invalidResponse: "Ollama returned an unreadable response."
        }
    }
}

struct OllamaClient {
    private let baseURL = URL(string: "http://127.0.0.1:11434")!

    func status() async throws -> OllamaStatus {
        do {
            async let versionData = URLSession.shared.data(from: baseURL.appending(path: "api/version"))
            async let modelsData = URLSession.shared.data(from: baseURL.appending(path: "api/tags"))
            let ((versionBytes, versionResponse), (modelBytes, modelResponse)) = try await (versionData, modelsData)
            guard (versionResponse as? HTTPURLResponse)?.statusCode == 200,
                  (modelResponse as? HTTPURLResponse)?.statusCode == 200 else { throw OllamaError.unavailable }
            let version = try JSONDecoder().decode(VersionResponse.self, from: versionBytes).version
            let models = try JSONDecoder().decode(ModelResponse.self, from: modelBytes).models
            return .init(version: version, models: models)
        } catch let error as OllamaError {
            throw error
        } catch {
            throw OllamaError.unavailable
        }
    }

    private struct VersionResponse: Codable { let version: String }
    private struct ModelResponse: Codable { let models: [OllamaModel] }
}
