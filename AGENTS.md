# Repository Guidelines

## Project Structure & Module Organization
- `omai.js` is the main CLI for OpenRouter orchestration; keep companion helpers at repo root.
- `mcp-superagents/` contains planner, implementor, knowledge, and workflow adapters; name new agents `<role>-mcp.js` and share utilities via `tools/`.
- `prompts/`, `training-data/`, `knowledge-outbox/`, and `training-logs/` hold prompt corpora, generated datasets, exported knowledge, and run logs; regenerate with `ecosystem-training-data.js` and review diffs before committing.
- Integration launchers (`lm-studio-bridge.js`, `ollama-integration.js`, `omarchy-launcher*`) pair the assistant with external runtimes; document added binaries in `CLI_DOCUMENTATION.md`.

## Build, Test, and Development Commands
- `npm install` – install Node dependencies for the CLI and MCP agents.
- `node omai.js "Diagnose networking issue"` – run the assistant; add `--handoff` for multi-agent flows or `--usage` to inspect token spend.
- `node ecosystem-training-data.js` – refresh `ecosystem-training-data.json` and the companion prompt from the current workspace.
- `go run go-system-monitor.go` – launch the metrics endpoint on `:3000` to watch runtime health.

## Coding Style & Naming Conventions
- Use two-space indentation, trailing semicolons, and CommonJS `require` in Node files; prefer focused modules with explicit logging.
- Keep agent filenames and exported functions descriptive (`planner-mcp.js`, `token-manager-mcp.js`), and organize shared helpers under `tools/`.
- Run `gofmt` on Go sources; exported structs need doc comments and `CamelCase` names, while internal helpers stay `camelCase`.
- JSON artifacts stay generator-owned and pretty-printed with two spaces; avoid manual edits to long-lived snapshots.

## Testing Guidelines
- Smoke-test CLI changes with `node omai.js --usage` to confirm token tracking, rate limits, and model rotation.
- Validate data generators by comparing fresh outputs in `training-logs/` and `knowledge-outbox/`; flag unexpected churn before merging.
- Add automated coverage incrementally: place Node specs in `tests/` (e.g. `omai.spec.js`) wired into `npm test`, and back Go additions with table-driven `*_test.go` suites run via `go test ./...`.

## Commit & Pull Request Guidelines
- Write short, imperative commit subjects (`Add planner concurrency guard`) and optionally prefix scope (`mcp:`, `launcher:`) when it clarifies context.
- Separate generated artifacts from logic edits, and note verification commands in the commit or PR description.
- Pull requests should reference issues, summarize changes, list executed checks, and attach terminal output when behavior shifts.

## Security & Configuration Tips
- Keep API secrets such as `OPENROUTER_API_KEY` in `~/.npm-global/bin/.env`; share sanitized examples rather than real keys.
- Review knowledge exports for sensitive content, rotate models via `omai.js --handoff` after configuration changes, and confirm port `3000` is free before launching monitors.
