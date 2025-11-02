#!/usr/bin/env python3
import json, sys, hashlib, os, pathlib, re

# Simple shingle Jaccard + SimHash-lite to catch near-duplicates without libs
def shingles(text, k=8):
    t = re.sub(r'\s+', ' ', text.lower()).strip()
    return { t[i:i+k] for i in range(max(0, len(t)-k+1)) } if t else set()

def jaccard(a, b):
    if not a or not b: return 0.0
    inter = len(a & b); union = len(a | b)
    return inter / union if union else 0.0

def simkey(text, buckets=64):
    t = re.sub(r'\s+', ' ', text.lower()).strip().encode('utf-8')
    h = hashlib.sha256(t).digest()
    # map to 64-bit fingerprint
    return int.from_bytes(h[:8], 'big')

def condense_index(index_path, out_path, archive_path, jacc_min=0.88):
    keep = []
    seen_hash = set()
    buckets = {}  # simkey -> list of (idx, shingles)

    archived = []
    with open(index_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                obj = json.loads(line)
            except Exception:
                continue
            txt = (obj.get('text') or '').strip()
            if not txt:
                continue
            # exact hash
            ex = hashlib.sha256(txt.encode('utf-8')).hexdigest()
            if ex in seen_hash:
                archived.append(obj)
                continue
            # near-dup test inside similar bucket
            key = simkey(txt)
            sh = shingles(txt)
            near = False
            bucket = buckets.setdefault(key, [])
            for idx, sh_ref in bucket:
                if jaccard(sh, sh_ref) >= jacc_min:
                    near = True
                    break
            if near:
                archived.append(obj)
            else:
                seen_hash.add(ex)
                bucket.append((len(keep), sh))
                keep.append(obj)

    with open(out_path, 'w', encoding='utf-8') as wf:
        for obj in keep:
            wf.write(json.dumps(obj, ensure_ascii=False) + '\n')
    if archived:
        with open(archive_path, 'a', encoding='utf-8') as af:
            for obj in archived:
                af.write(json.dumps(obj, ensure_ascii=False) + '\n')
    return len(keep), len(archived)

def main():
    if len(sys.argv) < 2:
        print("Usage: condenser.py <packs_dir> [jacc_min]", file=sys.stderr)
        sys.exit(2)
    packs_dir = pathlib.Path(sys.argv[1])
    jmin = float(sys.argv[2]) if len(sys.argv) > 2 else 0.88

    total_kept = total_arch = 0
    for p in packs_dir.glob('*/index.jsonl'):
        pack_dir = p.parent
        out = pack_dir / 'index.compact.jsonl'
        arc = pack_dir / 'index.archive.jsonl'
        kept, arch = condense_index(str(p), str(out), str(arc), jmin)
        # atomically switch to compact if it helped
        try:
            os.replace(out, p)  # overwrite original with compacted
        except Exception:
            pass
        total_kept += kept; total_arch += arch
        print(f"[condense] {pack_dir.name}: kept={kept} archived={arch}")
    print(f"[condense] total kept={total_kept} archived={total_arch}")

if __name__ == '__main__':
    main()