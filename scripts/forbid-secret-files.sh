#!/usr/bin/env bash

set -euo pipefail

has_error=0

is_allowed_template() {
  case "$1" in
    *.example|*.sample|*.template)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

for path in "$@"; do
  case "$path" in
    .zshrc.local|*.local.json)
      printf 'Blocked local-only file: %s\n' "$path" >&2
      has_error=1
      ;;
    .env|.env.*)
      if is_allowed_template "$path"; then
        continue
      fi
      printf 'Blocked env file: %s\n' "$path" >&2
      has_error=1
      ;;
    *.pem|*.key|*.p12|*.pfx|*.ovpn|id_rsa|id_dsa|id_ecdsa|id_ed25519)
      printf 'Blocked secret-bearing file: %s\n' "$path" >&2
      has_error=1
      ;;
  esac
done

if [[ "$has_error" -ne 0 ]]; then
  cat >&2 <<'EOF'

Store machine-specific values in ignored files such as `.zshrc.local` and commit
only sanitized templates like `.zshrc.local.example` or `.env.example`.
EOF
  exit 1
fi
