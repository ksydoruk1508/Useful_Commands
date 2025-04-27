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

echo -e "${GREEN}Установка Python / Installing Python...${NC}"

# Обновление списка пакетов / Update package list
echo -e "${BLUE}Обновление списка пакетов / Updating package list...${NC}"
apt update

# Установка зависимостей для сборки Python / Install dependencies for Python
echo -e "${BLUE}Установка зависимостей для Python / Installing Python dependencies...${NC}"
apt install -y software-properties-common build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl libbz2-dev

# Меню выбора версии Python / Python version selection menu
while true; do
    echo -e "${YELLOW}Выберите версию Python для установки / Select Python version to install:${NC}"
    echo -e "${CYAN}1. Установить Python 3.10 / Install Python 3.10${NC}"
    echo -e "${CYAN}2. Установить Python 3.11 / Install Python 3.11${NC}"
    echo -e "${CYAN}3. Отмена / Cancel${NC}"
    echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
    read python_choice
    case $python_choice in
        1)
            PYTHON_VERSION="3.10"
            break
        ;;
        2)
            PYTHON_VERSION="3.11"
            break
        ;;
        3)
            echo -e "${YELLOW}Установка Python отменена / Python installation cancelled${NC}"
            exit 0
        ;;
        *)
            echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}"
        ;;
    esac
done

# Проверка, установлена ли выбранная версия Python / Check if selected Python version is already installed
if command -v "python$PYTHON_VERSION" &> /dev/null; then
    echo -e "${YELLOW}Python $PYTHON_VERSION уже установлен / Python $PYTHON_VERSION is already installed${NC}"
    python$PYTHON_VERSION --version
    exit 0
fi

# Добавление репозитория deadsnakes для установки нужной версии Python / Add deadsnakes PPA
echo -e "${BLUE}Добавление репозитория deadsnakes / Adding deadsnakes PPA...${NC}"
add-apt-repository -y ppa:deadsnakes/ppa
apt update

# Установка выбранной версии Python / Install selected Python version
echo -e "${BLUE}Установка Python $PYTHON_VERSION / Installing Python $PYTHON_VERSION...${NC}"
apt install -y python$PYTHON_VERSION python$PYTHON_VERSION-dev python$PYTHON_VERSION-venv python3-pip
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Python $PYTHON_VERSION успешно установлен / Python $PYTHON_VERSION installed successfully${NC}"
    python$PYTHON_VERSION --version
    # Установка pip для выбранной версии
    echo -e "${BLUE}Установка pip для Python $PYTHON_VERSION / Installing pip for Python $PYTHON_VERSION...${NC}"
    python$PYTHON_VERSION -m ensurepip --upgrade
    python$PYTHON_VERSION -m pip install --upgrade pip
    echo -e "${GREEN}pip для Python $PYTHON_VERSION установлен / pip for Python $PYTHON_VERSION installed${NC}"
else
    echo -e "${RED}Не удалось установить Python $PYTHON_VERSION / Failed to install Python $PYTHON_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}Установка Python завершена / Python installation completed!${NC}"
