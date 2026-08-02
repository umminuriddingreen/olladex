# Olladex

**A local route control panel for Codex and Ollama.**

Olladex is a small, open-source macOS companion that shows exactly where new Codex tasks will run, discovers models from your local Ollama server, and switches the active Codex provider without making your configuration a one-way door.

## Why Olladex?

Ollama already supports launching Codex. Olladex focuses on the operational gap around that integration:

- See the active Codex provider and model before starting work.
- Discover the models actually installed on the current machine.
- Show those local models in Codex's model picker while the Ollama route is active.
- Check Ollama, model, and Codex configuration readiness in one place.
- Back up `~/.codex/config.toml` before every activation.
- Restore the exact previous configuration with one action.
- Keep everything local: no accounts, telemetry, or background agent.

## Requirements

- macOS 14 or newer
- [Ollama](https://ollama.com) running locally
- The Codex desktop app
- A tool-capable model installed in Ollama

## Build and run

```sh
git clone https://github.com/umminuriddingreen/olladex.git
cd olladex
swift run Olladex
```

Build an ad-hoc signed `.app` bundle:

```sh
chmod +x scripts/package-app.sh
./scripts/package-app.sh
open dist/Olladex.app
```

## Configuration contract

When you activate a model, Olladex:

1. Copies the current file to `~/.codex/olladex-backups/config-<timestamp>.toml`.
2. Generates `~/.codex/olladex-models.json` from the models currently installed in Ollama.
3. Changes the top-level `model`, `model_provider`, and `model_catalog_json` values.
4. Adds the `model_providers.olladex-ollama` provider if it is absent.
5. Writes the result atomically, then restarts Codex so its model picker reloads.

The provider points to Ollama's loopback-only OpenAI-compatible Responses endpoint at `http://127.0.0.1:11434/v1/`. Existing comments, project trust, tools, MCP servers, and approval settings remain in place.

While Ollama mode is active, Codex's model menu displays the local Ollama catalog. Restoring the previous configuration restores the OpenAI catalog. Existing tasks retain the provider with which they were created.

## Current scope

Version 0.1 targets macOS and the standard local Ollama endpoint. Remote hosts, model downloads, automated Codex restarts, Windows packaging, and configuration merging across multiple tools are intentionally deferred.

## Development

```sh
swift build
swift test
```

Olladex is independent open-source software and is not affiliated with or endorsed by OpenAI or Ollama.

## License

MIT
