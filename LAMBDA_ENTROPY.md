# Lambda-Entropy Prompt Optimizer

Implements the "Lambda-Entropy Convergence" heuristic discussed in theory notes:
minimize `E = α*C + β*D + γ*T` where:
- `C` = prompt token cost
- `D` = semantic distance between baseline intent and candidate output distributions
- `T` = temporal decay proxy (variance of repeated outputs)

## Tools
- `~/.local/bin/om-lambda-opt`: CLI wrapper (routes to `tools/om_lambda_opt.py`)
- `tools/om_lambda_opt.py`: Python engine using sentence-transformers + local om-agent runs

## Requirements
- python3
- pip install `sentence-transformers numpy`
- `om-agent` commands must respect `PROMPT_OVERRIDE`

## Usage
```bash
# Example: optimize a prompt file
om-lambda-opt prompts/subagents/pln.md --alpha 0.4 --beta 0.4 --gamma 0.2 --samples 3 --provider gemini --agent sherlock-ohms
```

Outputs e.g.
```
[lambda-opt] energy= 123.4567
[lambda-opt] components: C= 42.00 D= 0.0314 T= 0.000021
[lambda-opt] optimized prompt:
<prompt text>
```

Pass `--json` to receive a machine-readable summary.

## Notes
- Baseline intent vector derived from current prompt outputs (acts as target semantics).
- Mutation operator is simple (token drop/shuffle) — extend as needed.
- Because it invokes `om-agent`, this can incur API cost/time; consider smaller `--samples` for quick runs.
