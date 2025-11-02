# Prompt Annealer

Automates Kolmogorov Prompt Collapse for Omarchy prompts.

## Requirements
- python3
- pip install sentence-transformers numpy
- zstd binary in PATH
- jq (optional for advanced pipelines)

## Usage

```bash
# inside repo
python3 tools/prompt_annealer.py prompts/subagents/pln.md \
  --cmd 'PROMPT_PATH=$PROMPT_OVERRIDE ./scripts/run_prompt.sh' \
  --input samples/input1.txt --input samples/input2.txt \
  --iterations 200 --temperature 0.8 --output prompts/subagents/pln.optim.md
```

- `PROMPT_OVERRIDE` is injected into the command and should be read by your driver script.
- The script runs the baseline prompt, captures outputs, measures similarity via sentence-transformers, and iteratively proposes trimmed variations.
- Improved prompts are written to `.optim` path; logs show score, length, similarity, entropy.

## Quick Wrapper

`tools/prompt_annealer.sh` proxies to `prompt_annealer.py`.

Example hooking into `om-agent` directly:

```bash
export OMARCHY_AGENT_ID=sherlock-ohms
python3 tools/prompt_annealer.py prompts/subagents/pln.md \
  --cmd 'printf "%s" "$PROMPT_OVERRIDE" > /tmp/prompt_override && cat /tmp/prompt_override && echo "$INPUT" | om-agent sherlock-ohms gemini'
```

Adjust command to feed the prompt content into your pipeline (e.g., by replacing file contents or passing via env).

## Output Metrics
- `score`: lower is better (compressed size + entropy penalty - similarity bonus)
- `similarity`: average cosine vs baseline outputs (close to 1.0 is ideal)
- `entropy`: Shannon entropy of generated tokens

Fail-safe: baseline prompt stored; only accepted if score is lower (meaning better information density).
