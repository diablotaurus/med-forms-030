# Развёртывание на Linux

Поддерживаются **Ubuntu Server 24.04 LTS** и **Debian 12**. Каждый сервер
использует собственную локальную базу `base.db`; базы двух зданий не связаны.

## Рекомендуемая конфигурация

- 2 vCPU;
- 2 ГБ RAM;
- 25 ГБ SSD;
- статический IP;
- доступ только из внутренней сети организации.

## Установка

```bash
sudo apt update
sudo apt install -y python3 python3-venv git
sudo git clone https://github.com/diablotaurus/med-forms-030.git /opt/med-forms-030
sudo chown -R "$USER":"$USER" /opt/med-forms-030
cd /opt/med-forms-030
chmod +x scripts/linux/*.sh
scripts/linux/setup.sh
sudo scripts/linux/install-service.sh
```

Установщик запускает приложение от текущего обычного пользователя, а не от
`root`. Поэтому выполняйте `sudo scripts/linux/install-service.sh` из сеанса
обычного администратора. Если используется только root-сеанс, заранее создайте
служебного пользователя и передайте его явно через `APP_USER`.

Проверка службы:

```bash
systemctl status med-forms-030
journalctl -u med-forms-030 -f
```

Приложение будет доступно по адресу `http://IP-СЕРВЕРА:5000`. После первого
входа (`admin` / `admin`) обязательно смените пароль.

Если включён UFW:

```bash
sudo ufw allow from ВАША_ПОДСЕТЬ to any port 5000 proto tcp
```

Например, для сети `192.168.10.0/24`:

```bash
sudo ufw allow from 192.168.10.0/24 to any port 5000 proto tcp
```

## Ручное обновление

```bash
cd /opt/med-forms-030
scripts/linux/update.sh
```

Скрипт остановит службу, создаст копию `base.db`, обновит код и зависимости,
затем снова запустит службу. Для `sudo systemctl` может потребоваться пароль.

## Ручная резервная копия

```bash
scripts/linux/backup.sh
```

Оставить только 30 последних копий:

```bash
scripts/linux/backup.sh 30
```

Копии сохраняются в `backups/`, который не отслеживается Git. Сценарий использует
SQLite Backup API и создаёт согласованную копию, включая последние WAL-транзакции.

## Удаление службы

```bash
sudo scripts/linux/uninstall-service.sh
```

Код, настройки и `base.db` при этом не удаляются.

## Перенос существующей базы с Windows

1. Остановить приложение на обоих серверах.
2. Скопировать Windows-файл `base.db` в `/opt/med-forms-030/base.db`.
3. Назначить владельца и запустить службу:

```bash
sudo chown "$USER":"$USER" /opt/med-forms-030/base.db
sudo systemctl start med-forms-030
```

Формат SQLite кроссплатформенный. Не размещайте `base.db` на общей сетевой папке
и не подключайте к одному файлу две машины одновременно.
