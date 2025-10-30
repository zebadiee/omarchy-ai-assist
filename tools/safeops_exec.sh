#!/usr/bin/env bash
set -euo pipefail
mkdir -p proposed
f="proposed/$(date +%Y%m%d-%H%M%S)-cmd.sh"
printf '#!/usr/bin/env bash\nset -euo pipefail\n%s\n' "$*" > "$f"
chmod +x "$f"
./tools/safe_run.sh "$f"
