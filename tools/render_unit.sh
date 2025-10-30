#!/usr/bin/env bash
# Systemd unit renderer with safety checks
set -euo pipefail

die(){ printf "\e[31m[SAFE]\e[0m %s\n" "$*" >&2; exit 1; }

show_usage() {
    cat << EOF
Usage: $0 <name> <user> <group> <workdir> <binary> <args> <write_dirs>

Example:
  $0 "My Service" "myuser" "mygroup" "/opt/myapp" "/opt/myapp/app.sh" "--serve" "/opt/myapp/data"
EOF
}

[ $# -eq 7 ] || { show_usage; exit 1; }

NAME="$1"
USER="$2"
GROUP="$3"
WORKDIR="$4"
BINARY="$5"
ARGS="$6"
WRITE_DIRS="$7"

# Safety checks
[ -n "$NAME" ] || die "Name cannot be empty"
[ -n "$USER" ] || die "User cannot be empty"
[ -n "$GROUP" ] || die "Group cannot be empty"
[ -n "$WORKDIR" ] || die "Workdir cannot be empty"
[ -n "$BINARY" ] || die "Binary cannot be empty"

# Check if user exists (optional)
if ! id "$USER" >/dev/null 2>&1; then
    echo "[SAFE] Warning: User '$USER' does not exist yet"
fi

# Render the unit
TEMPLATE_DIR="$(dirname "$0")"
TEMPLATE="$TEMPLATE_DIR/systemd_hardened.service.tpl"

[ -f "$TEMPLATE" ] || die "Template not found: $TEMPLATE"

sed -e "s|<<NAME>>|$NAME|g" \
    -e "s|<<USER>>|$USER|g" \
    -e "s|<<GROUP>>|$GROUP|g" \
    -e "s|<<WORKDIR>>|$WORKDIR|g" \
    -e "s|<<BINARY>>|$BINARY|g" \
    -e "s|<<ARGS>>|$ARGS|g" \
    -e "s|<<WRITE_DIRS>>|$WRITE_DIRS|g" \
    "$TEMPLATE"