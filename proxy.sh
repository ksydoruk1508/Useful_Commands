#!/bin/bash

# Скрипт для настройки сервера как прокси-сервера с использованием 3proxy

set -e

echo "=== Настройка прокси-сервера 3proxy 0.9.3 =1=="

# Проверка прав доступа
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами root"
   exit 1
fi

# Получение IP адреса сервера
IP=$(hostname -I | awk '{print $1}')
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi

# Параметры прокси
PORT="53131"
USER="user"
PASS="P@ssv0rd"

echo "Настройка прокси с параметрами:"
echo "IP: $IP"
echo "Port: $PORT"
echo "User: $USER"
echo "Password: $PASS"

# Обновление системы
echo "Обновление системы..."
apt update && apt upgrade -y

# Установка необходимых пакетов и библиотек для сборки
echo "Установка зависимостей..."
apt install -y build-essential wget unzip libc6-dev libssl-dev libpthread-stubs0-dev

# Загрузка и распаковка 3proxy
echo "Загрузка и распаковка 3proxy..."
cd /tmp
rm -rf 3proxy-0.9.3 3proxy.zip
wget -O 3proxy.zip https://github.com/3proxy/3proxy/archive/refs/tags/0.9.3.zip
unzip 3proxy.zip

# Компиляция 3proxy
echo "Компиляция 3proxy..."
cd 3proxy-0.9.3/src
cp ../Makefile.Linux Makefile.var
make -f ../Makefile.Linux

# Установка бинарника
echo "Установка 3proxy..."
cp ../bin/3proxy /usr/local/bin/
chmod +x /usr/local/bin/3proxy

# Создание директории конфигурации
echo "Создание директории конфигурации..."
mkdir -p /etc/3proxy

# Создание пользователя для 3proxy
echo "Создание пользователя 3proxy..."
id proxy3 &>/dev/null || useradd -r -s /bin/false proxy3

# Создание конфигурационного файла
echo "Создание конфигурационного файла..."
cat > /etc/3proxy/3proxy.cfg << EOF
# Конфигурация 3proxy
nscache 65536
daemon
users $USER:CL:$PASS
auth strong
socks -p$PORT -t -a
http -p$PORT -t -a
EOF

# Создание systemd сервиса
echo "Создание systemd сервиса..."
cat > /etc/systemd/system/3proxy.service << EOF
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

# Перезагрузка systemd
echo "Перезагрузка systemd..."
systemctl daemon-reload

# Включение и запуск сервиса
echo "Включение и запуск сервиса..."
systemctl enable 3proxy
systemctl restart 3proxy

# Открытие портов в фаерволе
echo "Настройка фаервола..."
ufw allow $PORT/tcp || true

# Вывод информации о настройке
echo ""
echo "=== Настройка завершена ==="
echo "Параметры подключения:"
echo "IP: $IP"
echo "Port: $PORT"
echo "User: $USER"
echo "Password: $PASS"
echo ""
echo "Для проверки статуса сервиса:"
echo "systemctl status 3proxy"
echo ""
echo "Для просмотра логов:"
echo "journalctl -u 3proxy -f"
echo ""
echo "Для изменения параметров — edit /etc/3proxy/3proxy.cfg и перезапустите сервис командой: systemctl restart 3proxy"
