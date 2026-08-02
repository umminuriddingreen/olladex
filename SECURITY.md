# Security policy

Please report vulnerabilities privately through GitHub Security Advisories.

Olladex reads Ollama's loopback API and updates only `~/.codex/config.toml`. It stores timestamped configuration backups in `~/.codex/olladex-backups/`. It does not read Codex authentication files or send telemetry.
