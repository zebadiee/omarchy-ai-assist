# SAFEOPS — Universal Guardrails (Omarchy / Linux)

PRINCIPLES
- No direct edits to /etc/sudoers. Use /etc/sudoers.d/*.conf and validate with `visudo -c`.
- No recursive chmod/chown without an explicit allowlist.
- Prefer user-level systemd units (`~/.config/systemd/user/*.service`). If root is necessary, justify and add hardening.
- All risky ops run inside a snapshot or container first.

REQUIRED STEPS (BEFORE APPLY)
1) Snapshot:
   - btrfs: `sudo btrfs subvolume snapshot / /root-backup-$(date +%Y%m%d-%H%M)`
   - Omarchy: `omarchy-snapshot create pre-change-$(date +%s)`
2) Staging sandbox: systemd-nspawn (or Docker) with bind mounts.
3) Static checks: shellcheck, shfmt, grep for dangerous patterns.
4) Dry-runs: package managers, systemd unit validation, ufw rules listing.
5) Review unified diff. Human approval required.

CONFIG UPDATES (Omarchy)
- Keep all custom configs in `~/.config/omarchy/` and app-specific `conf.d` drop-ins.
- Track upstream diffs: `diff -r ~/.local/share/omarchy ~/.config/omarchy/`
- Commit a "BEFORE" and "AFTER" of each Omarchy update.

DEPENDENCIES
- Scripts must guard for GPU/tool presence (intel/nvidia/amd), and utilities (jq, gawk, bc, playerctl).

SECRETS & KEYS
- Never commit private keys. Pre-commit hooks block them. `.gitignore` protects `**/*.key`, `**/id_*`, etc.

RED FLAGS (ALWAYS BLOCK)
- `rm -rf /` or any absolute root removal
- `chmod -R 777` outside allowlisted paths
- Direct `/etc/sudoers` edits
- Plaintext secrets in tracked files
- Services running as root without hardening
- Authentication stack changes without rollback

SAFE PATHS FOR RECUR PERMISSIONS
- `/opt` - Optional software packages
- `/usr/local` - Local compiled software
- `/home/$USER` - User home directory only

EXECUTION RULE (for LLMs)
Any script or command proposed by an agent MUST be written to `./proposed/*.sh` and executed only via:
```
./tools/safe_run.sh ./proposed/<file>.sh [args...]
```
Direct execution is forbidden.