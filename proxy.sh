#!/bin/bash

set -e

PROXY_USER="user"
PROXY_PASS="P@ssv0rd"
PROXY_PORT_HTTP="53131"
PROXY_PORT_SOCKS="53132"

# 1. Установка зависимостей
apt update
apt install -y build-essential wget unzip libssl-dev

# 2. Скачивание и установка 3proxy
cd /tmp
wget -q https://github.com/3proxy/3proxy/archive/refs/tags/0.9.3.zip -O 3proxy.zip
unzip -o 3proxy.zip
cd 3proxy-0.9.3
make -f Makefile.Linux

# 3. Копирование бинарника
mkdir -p /usr/local/bin
cp ./src/../bin/3proxy /usr/local/bin/3proxy
chmod +x /usr/local/bin/3proxy

# 4. Создание пользователя 3proxy
id 3proxy &>/dev/null || useradd -r -s /usr/sbin/nologin 3proxy

# 5. Создание директории и конфига
mkdir -p /etc/3proxy
cat >/etc/3proxy/3proxy.cfg <<EOF
nscache 65536
daemon

users $PROXY_USER:CL:$PROXY_PASS
auth strong

socks -p$PROXY_PORT_SOCKS -a
proxy -p$PROXY_PORT_HTTP -a
EOF

chown -R 3proxy:3proxy /etc/3proxy

# 6. Создание systemd unit-файла
cat >/etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3Proxy Server
After=network.target

[Service]
Type=simple
User=3proxy
Group=3proxy
ExecStart=/usr/local/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 7. Права
chown 3proxy:3proxy /usr/local/bin/3proxy

# 8. Перезапуск systemd, запуск прокси
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

echo "=== 3proxy установлен и запущен ==="
echo "HTTP: $(curl -s ifconfig.me):$PROXY_PORT_HTTP"
echo "SOCKS5: $(curl -s ifconfig.me):$PROXY_PORT_SOCKS"
echo "Логин: $PROXY_USER"
echo "Пароль: $PROXY_PASS"
echo
echo "Проверить статус: systemctl status 3proxy"
echo "Логи: journalctl -u 3proxy -f"
echo "Редактировать конфиг: /etc/3proxy/3proxy.cfg"
