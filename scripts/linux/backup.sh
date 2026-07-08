#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEEP="${1:-0}"

cd "$ROOT"
if [[ ! -f base.db ]]; then
  echo "Ошибка: база $ROOT/base.db не найдена." >&2
  exit 1
fi

mkdir -p backups
STAMP="$(date +%Y%m%d_%H%M%S)"
TARGET="backups/base_${STAMP}.db"
PYTHON="$ROOT/.venv/bin/python"
[[ -x "$PYTHON" ]] || PYTHON="$(command -v python3)"
"$PYTHON" scripts/sqlite_backup.py base.db "$TARGET"
echo "Резервная копия создана: $TARGET ($(du -h "$TARGET" | cut -f1))"

if [[ "$KEEP" =~ ^[0-9]+$ ]] && (( KEEP > 0 )); then
  mapfile -t OLD < <(find backups -maxdepth 1 -type f -name 'base_*.db' -printf '%T@ %p\n' \
    | sort -nr | tail -n "+$((KEEP + 1))" | cut -d' ' -f2-)
  if (( ${#OLD[@]} > 0 )); then
    rm -- "${OLD[@]}"
    echo "Удалено старых копий: ${#OLD[@]}; оставлено последних: $KEEP"
  fi
fi
