#!/usr/bin/env python3
"""PennyLane QAOA demo for module selection (N≤16)."""
import argparse
import numpy as np
import pennylane as qml

parser = argparse.ArgumentParser()
parser.add_argument("--qubo", required=True)
parser.add_argument("--layers", type=int, default=2)
parser.add_argument("--shots", type=int, default=1000)
parser.add_argument("--seed", type=int, default=42)
args = parser.parse_args()

np.random.seed(args.seed)
Q = np.load(args.qubo)
n = Q.shape[0]
dev = qml.device("default.qubit", wires=n, shots=args.shots)

@qml.qnode(dev)
def circuit(gammas, betas):
    for w in range(n):
        qml.Hadamard(wires=w)
    for layer in range(len(gammas)):
        gamma = gammas[layer]
        beta = betas[layer]
        for i in range(n):
            qml.RZ(2 * gamma * Q[i, i], wires=i)
        for i in range(n):
            for j in range(i + 1, n):
                if abs(Q[i, j]) > 1e-9:
                    qml.CNOT(wires=[i, j])
                    qml.RZ(2 * gamma * Q[i, j], wires=j)
                    qml.CNOT(wires=[i, j])
        for i in range(n):
            qml.RX(2 * beta, wires=i)
    return qml.sample()

L = args.layers
init_gammas = 0.01 * np.random.randn(L)
init_betas = 0.01 * np.random.randn(L)
params = np.concatenate([init_gammas, init_betas])

opt = qml.GradientDescentOptimizer(stepsize=0.1)

cost_fn = qml.ExpvalCost(lambda p:
    circuit(p[:L], p[L:]), dev, qml.Hermitian(Q, wires=range(n))
)

params = opt.step(cost_fn, params)
bitstrings = circuit(params[:L], params[L:])
counts = {}
for bitstring in bitstrings:
    key = "".join(str(b) for b in bitstring)
    counts[key] = counts.get(key, 0) + 1

for key, count in sorted(counts.items(), key=lambda x: -x[1])[:10]:
    print(key, count)
