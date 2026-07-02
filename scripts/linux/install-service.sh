#!/usr/bin/env bash
set -Eeuo pipefail

SERVICE="med-forms-030"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_USER="${APP_USER:-${SUDO_USER:-}}"
PORT="${PORT:-5000}"

if [[ $EUID -ne 0 ]]; then
  echo "Запустите от администратора: sudo scripts/linux/install-service.sh" >&2
  exit 1
fi
if [[ -z "$APP_USER" || "$APP_USER" == "root" ]]; then
  echo "Не запускаю приложение от root." >&2
  echo "Войдите под обычным пользователем и вызовите скрипт через sudo" >&2
  echo "или задайте пользователя явно: sudo APP_USER=medforms scripts/linux/install-service.sh" >&2
  exit 1
fi
if ! id "$APP_USER" >/dev/null 2>&1; then
  echo "Пользователь $APP_USER не существует." >&2
  exit 1
fi
if [[ ! -x "$ROOT/.venv/bin/python" ]]; then
  echo "Сначала выполните scripts/linux/setup.sh от обычного пользователя." >&2
  exit 1
fi

cat > "/etc/systemd/system/${SERVICE}.service" <<EOF
[Unit]
Description=Med Forms 030 web application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${APP_USER}
Group=$(id -gn "$APP_USER")
WorkingDirectory=${ROOT}
Environment=HOST=0.0.0.0
Environment=PORT=${PORT}
Environment=THREADS=8
ExecStart=${ROOT}/.venv/bin/python ${ROOT}/serve.py
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE"
echo "Служба установлена и запущена: $SERVICE"
systemctl --no-pager --full status "$SERVICE" || true
echo "Приложение: http://<IP-сервера>:${PORT}"
