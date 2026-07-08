#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="med-forms-030"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OWNER="$(stat -c '%U' "$ROOT")"
WAS_ACTIVE=0
CODE_CHANGED=0
BEFORE=""

run_owner() {
  if (( EUID == 0 )) && [[ "$OWNER" != "root" ]]; then
    runuser -u "$OWNER" -- "$@"
  else
    "$@"
  fi
}

systemctl_run() {
  if (( EUID == 0 )); then systemctl "$@"; else sudo systemctl "$@"; fi
}

cd "$ROOT"
echo "== Обновление med-forms-030 =="
[[ -d .git ]] || { echo "Ошибка: $ROOT не является git-репозиторием." >&2; exit 1; }
[[ -x .venv/bin/pip ]] || { echo "Ошибка: сначала выполните scripts/linux/setup.sh" >&2; exit 1; }

# Сначала проверить GitHub. Без нового коммита приложение не перезапускается.
BEFORE="$(run_owner git -C "$ROOT" rev-parse HEAD)"
run_owner git -C "$ROOT" fetch origin
TARGET="$(run_owner git -C "$ROOT" rev-parse origin/main)"
if [[ "$BEFORE" == "$TARGET" ]]; then
  echo "Обновлений нет — приложение уже актуально (${BEFORE:0:7})."
  exit 0
fi
echo "Найдено обновление: ${BEFORE:0:7} -> ${TARGET:0:7}"

if [[ -f base.db ]]; then
  run_owner "$ROOT/scripts/linux/backup.sh"
else
  echo "base.db ещё не создана — резервное копирование пропущено."
fi

if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
  WAS_ACTIVE=1
  echo "Останавливаю службу $SERVICE ..."
  systemctl_run stop "$SERVICE"
fi

recover_on_error() {
  local code=$?
  if (( code != 0 )); then
    if (( CODE_CHANGED == 1 )); then
      echo "Ошибка обновления; возвращаю версию ${BEFORE:0:7} ..." >&2
      run_owner git -C "$ROOT" reset --hard "$BEFORE" || true
      run_owner "$ROOT/.venv/bin/pip" install -r "$ROOT/requirements.txt" || true
    fi
    if (( WAS_ACTIVE == 1 )); then systemctl_run start "$SERVICE" || true; fi
  fi
  exit "$code"
}
trap recover_on_error EXIT

run_owner git -C "$ROOT" reset --hard origin/main
CODE_CHANGED=1
run_owner "$ROOT/.venv/bin/pip" install -r "$ROOT/requirements.txt"

if (( WAS_ACTIVE == 1 )); then
  echo "Запускаю службу $SERVICE ..."
  systemctl_run start "$SERVICE"
  systemctl_run --no-pager --full status "$SERVICE" || true
fi

trap - EXIT
echo "Обновлено: ${BEFORE:0:7} -> ${TARGET:0:7}"
echo "== Обновление завершено =="
