#!/bin/bash

# Скрипт для настройки сервера как прокси-сервера с использованием 3proxy

set -e

echo "=== Настройка прокси-сервера 3proxy ==="

# Проверка прав доступа
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами root"
   exit 1
fi

# Обновление системы
echo "Обновление системы..."
apt update && apt upgrade -y

# Установка необходимых пакетов
echo "Установка зависимостей..."
apt install -y build-essential wget unzip

# Загрузка и компиляция 3proxy
echo "Загрузка и компиляция 3proxy..."
cd /tmp
wget https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.3.zip
unzip 0.9.3.zip
cd 3proxy-0.9.3

# Компиляция
echo "Компиляция 3proxy..."
make -f Makefile.Linux

# Установка
echo "Установка 3proxy..."
make install

# Создание директории конфигурации
echo "Создание директории конфигурации..."
mkdir -p /etc/3proxy

# Создание пользователя для 3proxy
echo "Создание пользователя 3proxy..."
useradd -r -s /bin/false proxy3

# Создание конфигурационного файла
echo "Создание конфигурационного файла..."
cat > /etc/3proxy/3proxy.cfg << EOF
# Конфигурация 3proxy
nscache 65536
daemon
users proxy3:CL:$(openssl rand -base64 12)
auth strong
socks -p1080 -t -a
http -p3128 -t -a
EOF

# Создание systemd сервиса
echo "Создание systemd сервиса..."
cat > /etc/systemd/system/3proxy.service << EOF
[Unit]
Description=3Proxy Server
After=network.target

[Service]
Type=forking
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
systemctl start 3proxy

# Открытие портов в фаерволе
echo "Настройка фаервола..."
ufw allow 1080/tcp
ufw allow 3128/tcp

# Вывод информации о настройке
echo ""
echo "=== Настройка завершена ==="
echo "Параметры подключения:"
echo "SOCKS5: port 1080"
echo "HTTP: port 3128"
echo "Пользователь: proxy3"
echo "Пароль: будет сгенерирован автоматически"
echo ""
echo "Для проверки статуса сервиса:"
echo "systemctl status 3proxy"
echo ""
echo "Для просмотра логов:"
echo "journalctl -u 3proxy -f"
echo ""
echo "Для изменения пароля:"
echo "echo 'proxy3:CL:НОВЫЙ_ПАРОЛЬ' > /etc/3proxy/3proxy.cfg && systemctl restart 3proxy"

# Показать текущий пароль
echo ""
echo "Текущий пароль (в формате CL):"
grep "proxy3:CL:" /etc/3proxy/3proxy.cfg | cut -d':' -f3
