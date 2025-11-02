#!/usr/bin/env python3
"""
Prompt Annealer — iteratively trims prompt tokens while preserving semantics.

Workflow:
1. Seeds search from baseline prompt file(s).
2. Applies mutations (delete clause, reorder bullet, swap lines).
3. Evaluates candidate by:
   - Running user-provided command (e.g., om-agent) to gather outputs.
   - Measuring semantic similarity (cosine) vs baseline outputs using sentence-transformers.
   - Computing entropy/compression proxy metrics.
4. Accepts candidate if information density improves (shorter prompt, similar semantics).

Requires: python3, sentence-transformers, numpy, scipy, jq (if parsing JSON metadata).
"""

import argparse
import hashlib
import json
import math
import os
import random
import shutil
import string
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

try:
    import numpy as np
except ImportError:
    print("[prompt-annealer] numpy required", file=sys.stderr)
    sys.exit(1)

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("[prompt-annealer] sentence-transformers required (pip install sentence-transformers)", file=sys.stderr)
    sys.exit(1)


@dataclass
class PromptCandidate:
    text: str
    score: float
    length: int
    similarity: float
    entropy: float


def shannon_entropy(tokens: Sequence[str]) -> float:
    if not tokens:
        return 0.0
    counts = {}
    for tok in tokens:
        counts[tok] = counts.get(tok, 0) + 1
    total = len(tokens)
    entropy = 0.0
    for freq in counts.values():
        p = freq / total
        entropy -= p * math.log(p, 2)
    return entropy


def compress_size(text: str) -> int:
    """Returns size of zstd-compressed text in bytes (using system zstd)."""
    with tempfile.NamedTemporaryFile(delete=False) as tmp_in:
        tmp_in.write(text.encode("utf-8"))
        tmp_in_path = tmp_in.name
    tmp_out_path = tmp_in_path + ".zst"
    try:
        subprocess.run(
            ["zstd", "-q", "-T0", "-22", "-f", tmp_in_path, "-o", tmp_out_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        size = os.path.getsize(tmp_out_path)
    finally:
        os.unlink(tmp_in_path)
        if os.path.exists(tmp_out_path):
            os.unlink(tmp_out_path)
    return size


def evaluate_prompt(prompt_text: str, base_command: List[str], sample_inputs: List[str], model: SentenceTransformer, baseline_vectors: List[np.ndarray]) -> PromptCandidate:
    outputs = []
    combined_tokens = []

    for sample in sample_inputs:
        env = os.environ.copy()
        env["PROMPT_OVERRIDE"] = prompt_text
        proc = subprocess.run(
            base_command,
            input=sample.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
        out = proc.stdout.decode("utf-8", errors="replace")
        outputs.append(out.strip())
        combined_tokens.extend(out.split())

    vectors = model.encode(outputs)
    sims = []
    for vec, base_vec in zip(vectors, baseline_vectors):
        denom = np.linalg.norm(vec) * np.linalg.norm(base_vec)
        sims.append(float(np.dot(vec, base_vec) / denom) if denom else 0.0)

    avg_sim = float(np.mean(sims)) if sims else 0.0
    entropy = shannon_entropy(combined_tokens)
    compressed = compress_size(prompt_text)

    score = compressed + entropy * 100 - avg_sim * 1000
    return PromptCandidate(
        text=prompt_text,
        score=score,
        length=len(prompt_text),
        similarity=avg_sim,
        entropy=entropy,
    )


def mutate_prompt(lines: List[str]) -> List[str]:
    candidate = lines.copy()
    if not candidate:
        return candidate

    action = random.choice(["delete", "swap", "shuffle", "trim"])
    if action == "delete" and len(candidate) > 1:
        idx = random.randrange(len(candidate))
        candidate.pop(idx)
    elif action == "swap" and len(candidate) > 1:
        a, b = random.sample(range(len(candidate)), 2)
        candidate[a], candidate[b] = candidate[b], candidate[a]
    elif action == "shuffle":
        random.shuffle(candidate)
    elif action == "trim":
        idx = random.randrange(len(candidate))
        tokens = candidate[idx].split()
        if len(tokens) > 4:
            take = max(1, len(tokens) - random.randint(1, 3))
            candidate[idx] = " ".join(tokens[:take])
    return candidate


def anneal(prompt_path: Path, base_command: List[str], sample_inputs: List[str], iterations: int, temperature: float, output_path: Path):
    baseline_text = prompt_path.read_text(encoding="utf-8")
    baseline_lines = baseline_text.splitlines()

    model = SentenceTransformer("all-MiniLM-L6-v2")
    baseline_outputs = []
    for sample in sample_inputs:
        env = os.environ.copy()
        env["PROMPT_OVERRIDE"] = baseline_text
        proc = subprocess.run(
            base_command,
            input=sample.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
        baseline_outputs.append(proc.stdout.decode("utf-8", errors="replace").strip())

    baseline_vectors = model.encode(baseline_outputs)
    baseline_candidate = evaluate_prompt(baseline_text, base_command, sample_inputs, model, baseline_vectors)

    best_candidate = baseline_candidate
    current_lines = baseline_lines

    for step in range(iterations):
        temp = max(0.01, temperature * (1.0 - step / iterations))
        mutated_lines = mutate_prompt(current_lines)
        mutated_text = "\n".join(mutated_lines)

        candidate = evaluate_prompt(mutated_text, base_command, sample_inputs, model, baseline_vectors)

        delta = candidate.score - best_candidate.score
        accept = delta < 0 or math.exp(-delta / temp) > random.random()

        if accept:
            current_lines = mutated_lines
            if candidate.score < best_candidate.score:
                best_candidate = candidate
                output_path.write_text(candidate.text, encoding="utf-8")
                print(f"[annealer] improved @ step {step}: score={candidate.score:.2f} len={candidate.length} sim={candidate.similarity:.3f}", flush=True)

    print("[annealer] baseline:", baseline_candidate)
    print("[annealer] best:", best_candidate)


def main():
    parser = argparse.ArgumentParser(description="Kolmogorov Prompt Annealer")
    parser.add_argument("prompt", type=Path, help="Path to prompt file")
    parser.add_argument("--input", "-i", action="append", default=[], help="Sample input file(s)")
    parser.add_argument("--cmd", "-c", required=True, help="Command to run (quoted string)")
+    parser.add_argument("--iterations", type=int, default=100, help="Number of annealing steps")
+    parser.add_argument("--temperature", type=float, default=1.0, help="Initial temperature")
+    parser.add_argument("--output", "-o", type=Path, default=None, help="Where to write best prompt")
    args = parser.parse_args()

    sample_inputs = []
    for path in args.input:
        sample_inputs.append(Path(path).read_text(encoding="utf-8"))
    if not sample_inputs:
        sample_inputs = [""]  # default empty input

    base_command = ["bash", "-lc", args.cmd]
    output_path = args.output or (args.prompt.parent / (args.prompt.stem + ".annealed" + args.prompt.suffix))
    anneal(args.prompt, base_command, sample_inputs, args.iterations, args.temperature, output_path)


if __name__ == "__main__":
    main()
