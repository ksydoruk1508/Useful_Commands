#!/bin/bash

PROXY_USER="proxy3"
PROXY_GROUP="proxy3"
PROXY_DIR="/etc/3proxy"
PROXY_CFG="$PROXY_DIR/3proxy.cfg"
PROXY_BIN="/usr/local/bin/3proxy"
SOCKS_PORT=53132
HTTP_PORT=53131
LOGIN="user"
PASS="P@ssv0rd"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function pause() {
    read -p "Нажмите Enter для продолжения..."
}

function create_user_and_dirs() {
    echo -e "${CYAN}[*] Проверка пользователя $PROXY_USER...${NC}"
    if ! id $PROXY_USER &>/dev/null; then
        sudo useradd -r -s /usr/sbin/nologin $PROXY_USER
    fi

    echo -e "${CYAN}[*] Создание директорий и выдача прав...${NC}"
    sudo mkdir -p $PROXY_DIR
    sudo chown -R $PROXY_USER:$PROXY_GROUP $PROXY_DIR
    sudo chmod 750 $PROXY_DIR
}

function install_proxy() {
    echo -e "${CYAN}Запускается установка/переустановка 3Proxy...${NC}"

    create_user_and_dirs

    if [ ! -f $PROXY_BIN ]; then
        echo -e "${CYAN}[*] Скачивание и установка 3proxy...${NC}"
        wget -qO- https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.3.tar.gz | tar xz
        cd 3proxy-0.9.3
        ln -s Makefile.Linux Makefile.var
        cd src
        make -f Makefile.Linux
        if [ ! -f 3proxy ]; then
            echo -e "${NC}[!] Ошибка сборки 3proxy!${NC}"
            pause
            return
        fi
        sudo cp 3proxy $PROXY_BIN
        sudo chown $PROXY_USER:$PROXY_GROUP $PROXY_BIN
        sudo chmod 755 $PROXY_BIN
        cd ../..
        rm -rf 3proxy-0.9.3
    fi

    echo -e "${CYAN}[*] Создание конфига 3proxy...${NC}"
    cat <<EOF | sudo tee $PROXY_CFG > /dev/null
daemon
maxconn 2000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid $PROXY_GROUP
setuid $PROXY_USER
auth strong
users $LOGIN:CL:$PASS
allow $LOGIN
proxy -p$HTTP_PORT -a -i0.0.0.0 -e0.0.0.0
socks -p$SOCKS_PORT -i0.0.0.0 -e0.0.0.0
EOF
    sudo chown $PROXY_USER:$PROXY_GROUP $PROXY_CFG
    sudo chmod 640 $PROXY_CFG

    echo -e "${CYAN}[*] Создание systemd unit...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/3proxy.service > /dev/null
[Unit]
Description=3Proxy Server
After=network.target

[Service]
Type=simple
User=$PROXY_USER
Group=$PROXY_GROUP
ExecStart=$PROXY_BIN $PROXY_CFG
Restart=always
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable 3proxy --now
    sudo systemctl restart 3proxy

    echo -e "${GREEN}[+] Прокси установлен и запущен.${NC}"
    echo "Логин: $LOGIN   Пароль: $PASS"
    echo "SOCKS5 порт: $SOCKS_PORT   HTTP порт: $HTTP_PORT"
    echo "Конфиг: $PROXY_CFG"
    pause
}

function check_proxy_status() {
    echo -e "${CYAN}[*] Статус сервиса 3proxy:${NC}"
    sudo systemctl status 3proxy --no-pager
    echo ""
    echo -e "${CYAN}[*] Последние 20 строк лога:${NC}"
    sudo journalctl -u 3proxy -n 20 --no-pager
    pause
}

function main_menu() {
    while true; do
        clear
        echo ""
        echo "1. Установить прокси на сервер"
        echo "2. Проверить статус прокси"
        echo "3. Назад"
        echo -n "Выберите пункт: "
        read choice

        case $choice in
            1) install_proxy ;;
            2) check_proxy_status ;;
            3) exit 0 ;;
            *) echo "Некорректный выбор."; sleep 1 ;;
        esac
    done
}

main_menu
