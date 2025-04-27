#!/bin/bash

# Цвета текста / Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета) / No color (reset)

# Проверка, что скрипт запущен с правами root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Этот скрипт требует прав root. Пожалуйста, запустите его с sudo / This script requires root privileges. Please run it with sudo.${NC}"
    exit 1
fi

echo -e "${GREEN}Установка необходимых утилит / Installing required utilities...${NC}"

# Обновление списка пакетов / Update package list
echo -e "${BLUE}Обновление списка пакетов / Updating package list...${NC}"
apt update

# Установка базовых утилит / Install basic utilities
echo -e "${BLUE}Установка базовых утилит (curl, htop, net-tools, jq) / Installing basic utilities (curl, htop, net-tools, jq)...${NC}"
apt install -y curl htop net-tools jq

# Установка tmux / Install tmux
if command -v tmux &> /dev/null; then
    echo -e "${YELLOW}tmux уже установлен / tmux is already installed${NC}"
else
    echo -e "${BLUE}Установка tmux / Installing tmux...${NC}"
    apt install -y tmux
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}tmux успешно установлен / tmux installed successfully${NC}"
    else
        echo -e "${RED}Не удалось установить tmux / Failed to install tmux${NC}"
    fi
fi

# Установка screen / Install screen
if command -v screen &> /dev/null; then
    echo -e "${YELLOW}screen уже установлен / screen is already installed${NC}"
else
    echo -e "${BLUE}Установка screen / Installing screen...${NC}"
    apt install -y screen
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}screen успешно установлен / screen installed successfully${NC}"
    else
        echo -e "${RED}Не удалось установить screen / Failed to install screen${NC}"
    fi
fi

# Установка Docker / Install Docker
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker уже установлен / Docker is already installed${NC}"
else
    echo -e "${BLUE}Установка Docker / Installing Docker...${NC}"
    apt install -y apt-transport-https ca-certificates gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker успешно установлен / Docker installed successfully${NC}"
        # Добавление текущего пользователя в группу docker
        usermod -aG docker $SUDO_USER
        echo -e "${YELLOW}Текущий пользователь добавлен в группу docker. Перезайдите в систему для применения изменений / Current user added to docker group. Please re-login to apply changes.${NC}"
    else
        echo -e "${RED}Не удалось установить Docker / Failed to install Docker${NC}"
    fi
fi

# Установка Docker Compose / Install Docker Compose
if command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose уже установлен / Docker Compose is already installed${NC}"
else
    echo -e "${BLUE}Установка Docker Compose / Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker Compose успешно установлен / Docker Compose installed successfully${NC}"
    else
        echo -e "${RED}Не удалось установить Docker Compose / Failed to install Docker Compose${NC}"
    fi
fi

# Установка Node.js и npm / Install Node.js and npm
if command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js уже установлен / Node.js is already installed${NC}"
    node -v
    npm -v
else
    echo -e "${BLUE}Установка Node.js и npm (версия 20.x) / Installing Node.js and npm (version 20.x)...${NC}"
    # Добавление репозитория NodeSource для Node.js 20.x
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt update
    apt install -y nodejs
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Node.js и npm успешно установлены / Node.js and npm installed successfully${NC}"
        node -v
        npm -v
    else
        echo -e "${RED}Не удалось установить Node.js и npm / Failed to install Node.js and npm${NC}"
    fi
fi

echo -e "${GREEN}Установка утилит завершена / Utility installation completed!${NC}"
