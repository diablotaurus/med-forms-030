#!/usr/bin/env bash
set -Eeuo pipefail

TIMER="med-forms-030-update"
if [[ $EUID -ne 0 ]]; then
  echo "Запустите: sudo scripts/linux/uninstall-update-timer.sh" >&2
  exit 1
fi
systemctl disable --now "${TIMER}.timer" 2>/dev/null || true
rm -f "/etc/systemd/system/${TIMER}.timer" "/etc/systemd/system/${TIMER}.service"
systemctl daemon-reload
systemctl reset-failed
echo "Таймер автоматического обновления удалён."
