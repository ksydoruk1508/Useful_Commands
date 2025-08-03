#!/bin/bash

PURPLE='\033[0;35m'
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

PROXY_USER="proxy3"
PROXY_GROUP="proxy3"
PROXY_BIN="/usr/local/bin/3proxy"
PROXY_CFG="/etc/3proxy/3proxy.cfg"
PROXY_SERVICE="/etc/systemd/system/3proxy.service"
PROXY_LOG_DIR="/var/log/3proxy"
PROXY_LOG="$PROXY_LOG_DIR/3proxy.log"

show_header() {
    echo -e "${PURPLE}"
    cat << EOF
 ____  ____                                      
|  _ \\|  _ \\ _ __ _____  ___   _                 
| |_) | |_) | '__/ _ \\ \\/ / | | |                
|  __/|  __/| | | (_) >  <| |_| |                
|_|   |_|   |_|  \\___/_/\\_\\\\__,_|               

          3proxy Quick Installer by c6zr7
EOF
    echo -e "${NC}"
}

install_proxy() {
    echo -e "${CYAN}[*] Проверка пользователя $PROXY_USER...${NC}"
    id $PROXY_USER &>/dev/null || sudo useradd -r -M -d /nonexistent -s /usr/sbin/nologin $PROXY_USER

    echo -e "${CYAN}[*] Создание директорий и выдача прав...${NC}"
    sudo mkdir -p $(dirname $PROXY_CFG)
    sudo mkdir -p $PROXY_LOG_DIR
    sudo chown $PROXY_USER:$PROXY_GROUP $PROXY_LOG_DIR
    sudo chmod 750 $PROXY_LOG_DIR

    if [ ! -f $PROXY_BIN ]; then
        echo -e "${CYAN}[*] Скачивание и установка 3proxy...${NC}"
        wget -qO- https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.3.tar.gz | tar xz
        cd 3proxy-0.9.3
        make -f Makefile.Linux
        sudo cp src/3proxy $PROXY_BIN
        cd ..
        rm -rf 3proxy-0.9.3
    fi
    sudo chown $PROXY_USER:$PROXY_GROUP $PROXY_BIN
    sudo chmod 750 $PROXY_BIN

    echo -e "${CYAN}[*] Создание конфига 3proxy...${NC}"
    sudo tee $PROXY_CFG >/dev/null <<EOF
nscache 65536
daemon
log $PROXY_LOG D
rotate 3
users user:CL:P@ssv0rd
auth strong
socks -p53132 -a
proxy -p53131 -a
EOF
    sudo chown $PROXY_USER:$PROXY_GROUP $PROXY_CFG
    sudo chmod 640 $PROXY_CFG

    echo -e "${CYAN}[*] Создание systemd unit...${NC}"
    sudo tee $PROXY_SERVICE >/dev/null <<EOF
[Unit]
Description=3Proxy Server
After=network.target

[Service]
Type=simple
User=$PROXY_USER
Group=$PROXY_GROUP
ExecStart=$PROXY_BIN $PROXY_CFG
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${CYAN}[*] Перезапуск сервиса...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable 3proxy
    sudo systemctl restart 3proxy

    echo -e "${GREEN}[+] Прокси установлен и запущен.${NC}"
    echo -e "${YELLOW}Логин: user   Пароль: P@ssv0rd${NC}"
    echo -e "${YELLOW}SOCKS5 порт: 53132   HTTP порт: 53131${NC}"
    echo -e "${YELLOW}Конфиг: $PROXY_CFG${NC}"
}

check_status() {
    echo -e "${CYAN}--- STATUS 3proxy ---${NC}"
    sudo systemctl status 3proxy --no-pager
    echo -e "${CYAN}--- LAST 20 LOG LINES ---${NC}"
    sudo tail -n 20 $PROXY_LOG 2>/dev/null || echo -e "${RED}Нет логов / No logs${NC}"
}

main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}1. Установить прокси на сервер"
        echo -e "2. Проверить статус прокси"
        echo -e "3. Назад${NC}"
        echo -ne "${YELLOW}Выберите пункт: ${NC}"
        read choice
        case $choice in
            1) install_proxy ;;
            2) check_status ;;
            3) break ;;
            *) echo -e "${RED}Неверный выбор${NC}";;
        esac
        echo -e "${YELLOW}Нажмите Enter для продолжения...${NC}"
        read
    done
}

main_menu
