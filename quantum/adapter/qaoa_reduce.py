#!/usr/bin/env python3
import sys, json, os, random, hashlib, time

def hash_prompt(s): return hashlib.sha256(s.encode()).hexdigest()[:12]

def classical_reduce(prompt:str)->str:
    # Cheap λ-entropy proxy: strip duplicate whitespace, collapse repeated lines,
    # keep VBH header + single CONFIRM if present, trim boilerplate.
    lines = [l.rstrip() for l in prompt.splitlines()]
    header, confirm, body = [], [], []
    for l in lines:
        if l.startswith("#VBH:"): header = [l]; continue
        if l.startswith("CONFIRM:") and not confirm: confirm = [l]; continue
        body.append(l)
    # remove duplicate blank lines
    nb=[]; last=''
    for l in body:
        if not l and not last: continue
        nb.append(l); last=l
    body = nb
    out = "\n".join(header + confirm + body).strip()
    return out

def pseudo_qaoa_energy(s):
    # Toy energy = length + repeat penalty; lower is better
    length = len(s)
    repeats = sum(s.count(w) for w in set(s.split()) if len(w)>6) // 5
    return length + 5*repeats

def attempt_qaoa(prompt):
    # If PennyLane/Qiskit installed, you'd call them here. For now, random local search.
    best = classical_reduce(prompt)
    bestE = pseudo_qaoa_energy(best)
    for _ in range(32):
        cand = best.replace("  "," ").replace("\n\n\n","\n\n")
        if random.random()<0.3: cand = cand.replace("  ", " ")
        if random.random()<0.2:  cand = "\n".join([l for i,l in enumerate(cand.splitlines()) if i==0 or l.strip()])
        E = pseudo_qaoa_energy(cand)
        if E < bestE: best, bestE = cand, E
    return best, bestE

def main():
    raw = sys.stdin.read()
    t0 = time.time()
    reduced, energy = attempt_qaoa(raw)
    diag = {
        "ts": time.time(),
        "in_hash": hash_prompt(raw),
        "out_hash": hash_prompt(reduced),
        "energy": energy,
        "len_in": len(raw),
        "len_out": len(reduced),
        "gain": len(raw) - len(reduced),
        "adapter": "qaoa-fallback"
    }
    print(reduced)
    print(json.dumps(diag), file=sys.stderr)

if __name__ == "__main__":
    main()