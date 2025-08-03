#!/bin/bash

set -e

# === Настройки ===
PROXY_PORT=53131
SOCKS_PORT=53132
PROXY_USER="user"
PROXY_PASS="P@ssv0rd"

# === Обновление системы и установка зависимостей ===
echo "Обновление системы..."
apt update -y
apt upgrade -y
apt install -y build-essential libssl-dev unzip wget

# === Скачиваем и собираем 3proxy ===
echo "Загрузка и сборка 3proxy..."
cd /tmp
rm -rf 3proxy-0.9.3 3proxy.zip
wget -q https://github.com/3proxy/3proxy/archive/refs/tags/0.9.3.zip   -O 3proxy.zip
unzip -q 3proxy.zip
cd 3proxy-0.9.3
make -f Makefile.Linux

# === Останавливаем 3proxy, если работает ===
echo "Останавливаем сервис 3proxy (если запущен)..."
systemctl stop 3proxy 2>/dev/null || true

# === Копируем бинарник ===
echo "Копируем бинарник 3proxy..."
cp -f ./src/../bin/3proxy /usr/local/bin/3proxy
chmod +x /usr/local/bin/3proxy

# === Создаем пользователя, если не существует ===
if ! id "proxy3" &>/dev/null; then
    echo "Создаем пользователя proxy3..."
    useradd -r -s /bin/false proxy3
fi

# === Создаем директорию и конфиг (БЕЗ daemon) ===
mkdir -p /etc/3proxy

cat >/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
# daemon  # УДАЛЕНО: systemd управляет процессом
users $PROXY_USER:CL:$PROXY_PASS
auth strong
socks -p$SOCKS_PORT -a
proxy -p$PROXY_PORT -a
EOF

# === Создаем systemd unit файл ===
cat >/etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3Proxy Server
After=network.target

[Service]
Type=simple
User=proxy3
Group=proxy3
ExecStart=/usr/local/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# === Настраиваем файрвол (UFW) ===
if command -v ufw &>/dev/null; then
    ufw allow $PROXY_PORT/tcp || true
    ufw allow $SOCKS_PORT/tcp || true
fi

# === Перезапускаем systemd и запускаем сервис ===
echo "Перезапуск systemd и запуск 3proxy..."
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

echo "=== Установка и запуск 3proxy завершены ==="
echo "Параметры подключения:"
echo "IP: $(curl -s ifconfig.me)"
echo "SOCKS5 порт: $SOCKS_PORT"
echo "HTTP порт: $PROXY_PORT"
echo "User: $PROXY_USER"
echo "Password: $PROXY_PASS"
echo
echo "Проверка статуса: systemctl status 3proxy"
echo "Логи: journalctl -u 3proxy -f"
