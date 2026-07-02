#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PORT:-5000}"

if [[ ! -x "$ROOT/.venv/bin/python" ]]; then
  echo "Виртуальное окружение не найдено. Сначала запустите scripts/linux/setup.sh" >&2
  exit 1
fi

cd "$ROOT"
exec env HOST="${HOST:-0.0.0.0}" PORT="$PORT" THREADS="${THREADS:-8}" \
  "$ROOT/.venv/bin/python" "$ROOT/serve.py"
