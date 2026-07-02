#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="med-forms-030"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WAS_ACTIVE=0

cd "$ROOT"
echo "== Обновление med-forms-030 =="

[[ -d .git ]] || { echo "Ошибка: $ROOT не является git-репозиторием." >&2; exit 1; }
[[ -x .venv/bin/pip ]] || { echo "Ошибка: сначала выполните scripts/linux/setup.sh" >&2; exit 1; }

if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
  WAS_ACTIVE=1
  echo "Останавливаю службу $SERVICE ..."
  sudo systemctl stop "$SERVICE"
fi

restart_on_error() {
  local code=$?
  if (( code != 0 && WAS_ACTIVE == 1 )); then
    echo "Обновление завершилось с ошибкой; запускаю прежнюю установку..." >&2
    sudo systemctl start "$SERVICE" || true
  fi
  exit "$code"
}
trap restart_on_error EXIT

if [[ -f base.db ]]; then
  scripts/linux/backup.sh
else
  echo "base.db ещё не создана — резервное копирование пропущено."
fi

BEFORE="$(git rev-parse --short HEAD)"
git fetch origin
git reset --hard origin/main
AFTER="$(git rev-parse --short HEAD)"

"$ROOT/.venv/bin/pip" install -r requirements.txt

if (( WAS_ACTIVE == 1 )) || systemctl list-unit-files "${SERVICE}.service" --no-legend 2>/dev/null | grep -q "$SERVICE"; then
  echo "Запускаю службу $SERVICE ..."
  sudo systemctl start "$SERVICE"
  sudo systemctl --no-pager --full status "$SERVICE" || true
else
  echo "Служба не установлена. Для запуска: scripts/linux/start.sh"
fi

trap - EXIT
echo "Обновлено: $BEFORE -> $AFTER"
echo "== Обновление завершено =="
