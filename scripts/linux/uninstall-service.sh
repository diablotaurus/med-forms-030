#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="med-forms-030"
if [[ $EUID -ne 0 ]]; then
  echo "Запустите: sudo scripts/linux/uninstall-service.sh" >&2
  exit 1
fi

systemctl disable --now "$SERVICE" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE}.service"
systemctl daemon-reload
systemctl reset-failed
echo "Служба $SERVICE удалена. Код и база данных сохранены."
