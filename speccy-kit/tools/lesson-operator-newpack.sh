#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C_UTF-8

ROOT="${ROOT:-$PWD}"
LAB="${LAB:-$PWD/speccy-lab}"
PACK_DIR="$LAB/packs/mako"
MEM="$LAB/memory"; LOGS="$LAB/logs"
mkdir -p "$MEM" "$LOGS"

. speccy-kit/tools/safeops.sh

echo "[INFO] Operator Lesson 3: Create new pack 'mako'"

# 1) Create pack skeleton (idempotent)
require_in_lab "$PACK_DIR"
mkdir -p "$PACK_DIR/sources"

# pack.yml
atomic_write "$PACK_DIR/pack.yml" <<'YML'
id: mako
version: 1.0.0
license: MIT
sources:
  - path: sources/mako-*.md
normalize:
  max_chars: 1000
  overlap: 100
fields: [pack_id, source, sha256, text]
YML

# sources
atomic_write "$PACK_DIR/sources/mako-basics.md" <<'MD'
# mako (Wayland notification daemon)

## Config path
- User: `~/.config/mako/config`

## Common options (in config)
```

font=JetBrainsMono 11
default-timeout=5000
border-size=2
background-color=#1e1e2eff
text-color=#ffffffff

```

## Useful commands
- Reload config: `pkill -SIGUSR1 mako`
- Dismiss latest: `makoctl dismiss`
- Dismiss all: `makoctl dismiss -a`
- Pause/resume: `makoctl set-mode do-not-disturb on|off`
MD

# 2) Index the pack
bash speccy-kit/tools/pack.sh mako install

# 3) Verify via chat + log signals
./speccy chat --once "mako dismiss latest"
./speccy chat --once "mako reload config"

echo "REFLECT: $(date -Iseconds) newpack=mako indexed+queried" >> "$MEM/training.log"
echo "DRY-RUN:OK $(date -Iseconds)" >> "$LOGS/lesson-operator3.log"

echo "[SUCCESS] Operator Lesson 3 finished"