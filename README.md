# SafeOps Project

This project uses SafeOps for secure development workflows.

## SafeOps Tools

- `tools/safe_run.sh` - Safe script execution with sandboxing
- `tools/render_unit.sh` - Generate hardened systemd units
- `tools/common_header.sh` - Safety header for scripts
- `.githooks/pre-commit` - Secret scanning and security checks

## Usage

```bash
# Run Claude's script safely
./tools/safe_run.sh ./claude_proposed_script.sh

# Generate hardened systemd service
./tools/render_unit.sh "My App" "myuser" "mygroup" "/opt/myapp" "/opt/myapp/app.sh" "--serve" "/opt/myapp/data" > myapp.service

# Include safety header in scripts
#!/bin/bash
source ./tools/common_header.sh
# Your script here...
```

## Guardrails

- No direct `/etc/sudoers` edits
- No recursive chmod 777 outside allowlisted paths
- All risky operations require sandbox testing
- Secret scanning prevents committing credentials
- Systemd units are automatically hardened

See [SAFEOPS.md](SAFEOPS.md) for complete documentation.
