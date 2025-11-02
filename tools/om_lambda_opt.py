#!/usr/bin/env python3
"""Lambda-Entropy prompt optimizer prototype.

Given a prompt seed, generates paraphrase candidates (via local heuristics),
computes energy functional E = α*C + β*D + γ*T, and selects minimum-energy candidate.

Components:
- C: token cost (prompt length)
- D: semantic distance to baseline intent (cosine distance in embedding space)
- T: temporal decay proxy (variance across sampled responses)
"""

import argparse
import json
import os
import random
import subprocess
import sys
from typing import List, Tuple

try:
    import numpy as np
except ImportError:
    print("[om-lambda-opt] numpy required", file=sys.stderr)\n    sys.exit(1)

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("[om-lambda-opt] sentence-transformers required", file=sys.stderr)
    sys.exit(1)


class PromptOptimizer:
    def __init__(self, alpha: float, beta: float, gamma: float, samples: int, provider: str, agent: str):
        self.alpha = alpha
        self.beta = beta
        self.gamma = gamma
        self.samples = samples
        self.provider = provider
        self.agent = agent
        self.model = SentenceTransformer("all-MiniLM-L6-v2")

    def token_cost(self, prompt: str) -> float:
        return len(prompt.split())

    def embed(self, texts: List[str]) -> np.ndarray:
        return self.model.encode(texts)

    def semantic_distance(self, target_vec: np.ndarray, candidate_vec: np.ndarray) -> float:
        denom = np.linalg.norm(target_vec) * np.linalg.norm(candidate_vec)
        if denom == 0:
            return 1.0
        cos = float(np.dot(target_vec, candidate_vec) / denom)
        return max(0.0, 1.0 - cos)

    def temporal_decay(self, outputs: List[str]) -> float:
        if len(outputs) <= 1:
            return 0.0
        vecs = self.embed(outputs)
        var = np.mean(np.var(vecs, axis=0))
        return float(var)

    def generate_outputs(self, prompt: str) -> List[str]:
        outputs = []
        for _ in range(self.samples):
            env = os.environ.copy()
            env["PROMPT_OVERRIDE"] = prompt
            proc = subprocess.run(
                ["om-agent", self.agent, self.provider],
                input=b"",
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )
            outputs.append(proc.stdout.decode("utf-8", errors="replace").strip())
        return outputs

    def mutate_prompt(self, prompt: str) -> List[str]:
        tokens = prompt.split()
        candidates = set()
        candidates.add(prompt)
        if len(tokens) > 4:
            indices = list(range(len(tokens)))
            random.shuffle(indices)
            for i in indices[: min(3, len(indices))]:
                new_tokens = tokens[:i] + tokens[i + 1 :]
                candidates.add(" ".join(new_tokens))
        for _ in range(3):
            random.shuffle(tokens)
            candidates.add(" ".join(tokens))
        return list(candidates)

    def energy(self, prompt: str, target_vec: np.ndarray) -> Tuple[float, float, float, float]:
        C = self.token_cost(prompt)
        outputs = self.generate_outputs(prompt)
        if not outputs:
            return float("inf"), C, float("inf"), float("inf")
        output_vec = np.mean(self.embed(outputs), axis=0)
        D = self.semantic_distance(target_vec, output_vec)
        T = self.temporal_decay(outputs)
        E = self.alpha * C + self.beta * D + self.gamma * T
        return E, C, D, T

    def optimize(self, prompt: str) -> Tuple[str, float, float, float, float]:
        baseline_outputs = self.generate_outputs(prompt)
        if not baseline_outputs:
            raise RuntimeError("No baseline outputs generated")
        intent_vec = np.mean(self.embed(baseline_outputs), axis=0)

        baseline_energy, C, D, T = self.energy(prompt, intent_vec)
        best_prompt = prompt
        best_energy = baseline_energy
        best_components = (C, D, T)

        for candidate in self.mutate_prompt(prompt):
            energy_val, c_val, d_val, t_val = self.energy(candidate, intent_vec)
            if energy_val < best_energy:
                best_prompt = candidate
                best_energy = energy_val
                best_components = (c_val, d_val, t_val)

        return best_prompt, best_energy, best_components[0], best_components[1], best_components[2]


def main():
    parser = argparse.ArgumentParser(description="Lambda-Entropy prompt optimizer")
    parser.add_argument("prompt", type=str, help="Prompt text or path to file")
    parser.add_argument("--alpha", type=float, default=0.4)
    parser.add_argument("--beta", type=float, default=0.4)
    parser.add_argument("--gamma", type=float, default=0.2)
    parser.add_argument("--samples", type=int, default=3)
    parser.add_argument("--provider", type=str, default="gemini")
    parser.add_argument("--agent", type=str, default="sherlock-ohms")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if os.path.isfile(args.prompt):
        prompt_text = open(args.prompt, "r", encoding="utf-8").read()
    else:
        prompt_text = args.prompt

    optimizer = PromptOptimizer(
        alpha=args.alpha,
        beta=args.beta,
        gamma=args.gamma,
        samples=args.samples,
        provider=args.provider,
        agent=args.agent,
    )

    best_prompt, energy, C, D, T = optimizer.optimize(prompt_text)

    result = {
        "prompt": best_prompt,
        "energy": energy,
        "token_cost": C,
        "semantic_distance": D,
        "temporal_decay": T,
    }

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"[lambda-opt] energy={energy:.4f}")
        print(f"[lambda-opt] components: C={C:.2f} D={D:.4f} T={T:.6f}")
        print("[lambda-opt] optimized prompt:\n" + result["prompt"])


if __name__ == "__main__":
    main()
