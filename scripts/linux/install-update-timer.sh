#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMER="med-forms-030-update"
TIME="${1:-03:00}"

if [[ $EUID -ne 0 ]]; then
  echo "Запустите: sudo scripts/linux/install-update-timer.sh [ЧЧ:ММ]" >&2
  exit 1
fi
if [[ ! "$TIME" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
  echo "Время должно быть в формате ЧЧ:ММ, например 03:00." >&2
  exit 1
fi

cat > "/etc/systemd/system/${TIMER}.service" <<EOF
[Unit]
Description=Update med-forms-030 from GitHub
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${ROOT}/scripts/linux/update.sh
Nice=10
IOSchedulingClass=idle
EOF

cat > "/etc/systemd/system/${TIMER}.timer" <<EOF
[Unit]
Description=Nightly update check for med-forms-030

[Timer]
OnCalendar=*-*-* ${TIME}:00
Persistent=true
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now "${TIMER}.timer"
echo "Таймер установлен: ежедневно около $TIME (случайная задержка до 5 минут)."
systemctl list-timers "${TIMER}.timer" --no-pager
