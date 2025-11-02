#!/usr/bin/env python3
import pathlib, re, json, time

def read_text(p):
    try: return pathlib.Path(p).read_text(encoding='utf-8')
    except: return ""

def norm(s):
    return re.sub(r'\s+', ' ', s.lower()).strip()

def shingles(s, k=8):
    s = norm(s)
    return { s[i:i+k] for i in range(max(0, len(s)-k+1)) } if s else set()

def jacc(a,b):
    if not a or not b: return 0.0
    u = len(a|b); i=len(a&b)
    return i/u if u else 0.0

def main():
    lessons = list(pathlib.Path("speccy-lab/lessons").glob("*.yml"))
    if not lessons:
        print("[lessons] none")
        return
    metas = []
    for f in lessons:
        t = read_text(f)
        metas.append((f, t, shingles(t), len(t)))

    metas.sort(key=lambda x: -x[3])  # longest first as canonical
    canon = []
    merged = []
    THRESH = 0.90

    for f, t, sh, _ in metas:
        dup = None
        for cf, ct, csh in canon:
            if jacc(sh, csh) >= THRESH:
                dup = cf; break
        if dup:
            merged.append((f, dup))
        else:
            canon.append((f, t, sh))

    outdir = pathlib.Path("speccy-lab/lessons/_compacted")
    arcdir = pathlib.Path("speccy-lab/lessons/_archive")
    outdir.mkdir(exist_ok=True); arcdir.mkdir(exist_ok=True)

    # keep canonical as-is; archive duplicates with manifest
    manifest = {"ts": time.time(), "merged": []}
    for src, dst in merged:
        src.rename(arcdir / src.name)
        manifest["merged"].append({"src": src.name, "into": dst.name})

    (outdir / "compactor.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"[lessons] canon={len(canon)} archived_dups={len(merged)} -> {outdir/'compactor.json'}")

if __name__ == "__main__":
    main()