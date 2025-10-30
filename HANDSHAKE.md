---
handshake_version: 1.0
name: Marchy Chat System
owner: Declan
entrypoint:
  control: .marchy/chat_control.md
  constraints: .github/copilot-instructions.md
  subagents:
    pln: prompts/subagents/pln.md
    imp: prompts/subagents/imp.md
    knw: prompts/subagents/knw.md
    mem: prompts/subagents/mem.md
memory:
  policy: memory/ltm_policy.md
  store: memory/ltm_store.jsonl
  format: jsonl
  ttl_days_default: 180
routing:
  # semantic tiers → preferred providers (left→right priority)
  tiers:
    x1: [openai, anthropic, gemini, lmstudio, ollama]
    x0: [lmstudio, ollama, openai, gemini, anthropic]
    free: [ollama, lmstudio, gemini, anthropic, openai]
  # model hints (optional: providers may ignore)
  models:
    openai:
      x1: gpt-4o
      x0: gpt-4o-mini
      free: gpt-4o-mini
    anthropic:
      x1: claude-3-5-sonnet-latest
      x0: claude-3-haiku
      free: claude-3-haiku
    gemini:
      x1: gemini-1.5-pro
      x0: gemini-1.5-flash
      free: gemini-1.5-flash
    lmstudio:
      x1: deepseek-r1-distill-llama-70b
      x0: deepseek-r1-distill-qwen-14b
      free: mistral:7b-instruct
    ollama:
      x1: llama3.1:70b-instruct
      x0: deepseek-r1:14b
      free: mistral:latest
guardrails:
  halt_on_ambiguity: true
  verification_required: true   # link + ≤25-word exact quote
  improv_in_imp: false          # implementor must NOT improvise
io_contracts:
  message_envelope: |
    {
      "agent": "#pln|#imp|#knw|#mem",
      "mode": "default|audit",
      "tier": "x1|x0|free",
      "text": "USER REQUEST"
    }
  memory_line: |
    {
      "ts":"ISO8601",
      "who":"declan|system|agent",
      "type":"fact|preference|term|milestone",
      "scope":"global|project|module",
      "text":"single atomic memory",
      "evidence":[{"file":"","line":0,"quote":""}],
      "ttl_days":180
    }
env_hints:
  # if present in the shell/container, routers should use them
  - OPENAI_API_KEY
  - ANTHROPIC_API_KEY
  - GEMINI_API_KEY
  - LMSTUDIO_BASE_URL
  - LMSTUDIO_API_KEY
  - OLLAMA_HOST
fingerprint:
  repo_paths_must_exist: true
  required_files:
    - .marchy/chat_control.md
    - .github/copilot-instructions.md
    - prompts/subagents/pln.md
    - prompts/subagents/imp.md
    - prompts/subagents/knw.md
    - prompts/subagents/mem.md
    - memory/ltm_policy.md
    - memory/ltm_store.jsonl
notes:
  - Any client/agent SHOULD load this file first and respect routing/guardrails.
  - If a model can't honor tiers/hints, it MUST still honor guardrails.
  - Subagents are activated by a leading tag (#pln/#imp/#knw/#mem).
---