# Marchy Chat System - Docker Clean Room

A minimal, containerized environment for the Marchy Chat System with browser UI and local LLM backend.

## Quick Start

```bash
cd .docker
docker compose up -d

# Optional: Pull a starter model
docker exec -it marchy-ollama ollama pull mistral:latest
```

Open your browser to: **http://localhost:3000**

## Architecture

```
Browser (Open WebUI) → Container: marchy-webui → Container: marchy-ollama
                                                     ↓
                                          Local Models Volume
```

### Services

- **marchy-ollama**: Ollama LLM backend (port 11434)
- **marchy-webui**: Open WebUI frontend (port 3000)

### Environment Variables

The containers are pre-configured with:
- `WEBUI_AUTH=False` (no login required)
- `ENABLE_OPENAI_API=True` (OpenAI-compatible endpoint)
- `OPENAI_API_BASE_URL=http://llm-backend:11434/v1`
- `OPENAI_API_KEY=dummy-local` (local placeholder)
- `OLLAMA_KEEP_ALIVE=24h` (models stay loaded)

### Model Switching

In Open WebUI settings, select your preferred model:
- `mistral:latest` (default, lightweight)
- `llama3.1:8b-instruct` (balanced)
- Any model you pull with `docker exec marchy-ollama ollama pull <model>`

## Alternative: LM Studio Integration

Prefer LM Studio instead of Ollama?

1. Run LM Studio locally (not in Docker)
2. Set WebUI environment variable:
   ```bash
   OPENAI_API_BASE_URL=http://host.docker.internal:1234/v1
   ```
3. Use same Open WebUI container

## Repository Access

The entire repository is mounted read-only at `/workspace` inside containers, so:
- Handshake file: `/workspace/HANDSHAKE.md`
- Subagents: `/workspace/prompts/subagents/`
- Memory: `/workspace/memory/`

## Cleanup

```bash
docker compose down
docker volume rm omarchy-ai-assist_ollama-models  # optional: removes models
```

## Troubleshooting

- **Port conflicts**: Ensure ports 3000 and 11434 are available
- **Model not found**: Pull model first with `docker exec marchy-ollama ollama pull <model>`
- **Slow responses**: Consider larger models or more resources
- **UI not loading**: Check container logs with `docker compose logs webui`