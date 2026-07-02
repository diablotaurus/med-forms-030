#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PORT:-5000}"

echo "== Установка med-forms-030 =="

for command in python3 git; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Ошибка: не найдена команда $command." >&2
    echo "Установите зависимости: sudo apt update && sudo apt install -y python3 python3-venv git" >&2
    exit 1
  fi
done

cd "$ROOT"
python3 -m venv .venv
"$ROOT/.venv/bin/python" -m pip install --upgrade pip
"$ROOT/.venv/bin/pip" install -r requirements.txt
mkdir -p backups logs

if command -v ufw >/dev/null 2>&1; then
  echo
  echo "UFW обнаружен. При необходимости откройте порт: sudo ufw allow ${PORT}/tcp"
fi

echo
echo "Установка завершена. Для проверки: scripts/linux/start.sh"
echo "Для автозапуска: sudo scripts/linux/install-service.sh"
