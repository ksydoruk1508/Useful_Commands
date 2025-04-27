#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Заголовок
echo -e "${GREEN}"
cat << "EOF"
TEST
EOF
echo -e "${NC}"

# Функция проверки свободной памяти и что ее занимает
function check_memory {
    echo -e "${BLUE}Проверка свободной памяти:${NC}"
    free -h
    echo -e "\n${BLUE}ТОП-5 процессов по использованию памяти:${NC}"
    ps aux --sort=-%mem | head -n 6 | awk '{print $1, $2, $3, $4, $11}' | column -t
}

# Функция проверки занятых портов
function check_used_ports {
    echo -e "${BLUE}Список занятых портов:${NC}"
    ss -tuln | column -t
    echo -e "\n${BLUE}Детали по процессам, использующим порты:${NC}"
    sudo netstat -tulnp 2>/dev/null | column -t || echo -e "${RED}netstat не установлен, используйте ss${NC}"
}

# Функция проверки, свободен ли конкретный порт
function check_port {
    echo -e "${BLUE}Проверка статуса порта:${NC}"
    echo -e "${YELLOW}Введите номер порта для проверки (1-65535):${NC}"
    read port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}Недопустимый номер порта. Введите число от 1 до 65535.${NC}"
        return
    fi
    if ss -tuln | grep -q ":${port}\b"; then
        echo -e "${RED}Порт $port занят:${NC}"
        ss -tuln | grep ":${port}\b" | column -t
        sudo netstat -tulnp 2>/dev/null | grep ":${port}\b" | column -t || echo -e "${YELLOW}Дополнительная информация недоступна${NC}"
    else
        echo -e "${GREEN}Порт $port свободен${NC}"
    fi
}

# Функция просмотра активных сессий tmux
function check_tmux_sessions {
    echo -e "${BLUE}Список активных сессий tmux:${NC}"
    if command -v tmux &> /dev/null; then
        tmux list-sessions 2>/dev/null || echo -e "${YELLOW}Нет активных сессий tmux${NC}"
    else
        echo -e "${RED}tmux не установлен${NC}"
    fi
}

# Функция просмотра активных сессий screen
function check_screen_sessions {
    echo -e "${BLUE}Список активных сессий screen:${NC}"
    if command -v screen &> /dev/null; then
        screen -ls 2>/dev/null || echo -e "${YELLOW}Нет активных сессий screen${NC}"
    else
        echo -e "${RED}screen не установлен${NC}"
    fi
}

# Функция проверки использования CPU
function check_cpu {
    echo -e "${BLUE}ТОП-5 процессов по использованию CPU:${NC}"
    ps aux --sort=-%cpu | head -n 6 | awk '{print $1, $2, $3, $4, $11}' | column -t
    echo -e "\n${BLUE}Общая загрузка CPU:${NC}"
    top -bn1 | head -n 3
}

# Функция проверки статуса системных служб
function check_services {
    echo -e "${BLUE}Список активных системных служб:${NC}"
    systemctl list-units --type=service --state=running | head -n 10
    echo -e "\n${YELLOW}Для полного списка используйте 'systemctl list-units --type=service'${NC}"
}

# Функция очистки кэша памяти
function clear_memory_cache {
    echo -e "${BLUE}Очистка кэша памяти:${NC}"
    echo -e "${YELLOW}Текущее состояние памяти:${NC}"
    free -h
    echo -e "${YELLOW}Примечание: Колонка 'buff/cache' показывает память, занятую кэшем, которую можно освободить.${NC}"
    echo -e "${YELLOW}Внимание: Очистка кэша может временно замедлить работу приложений, зависящих от кэшированных данных.${NC}"
    echo -e "${YELLOW}Требуются права root. Продолжить? (y/n)${NC}"
    read answer
    if [ "$answer" = "y" ]; then
        sudo sync
        sudo sysctl -w vm.drop_caches=3
        echo -e "${GREEN}Кэш памяти очищен${NC}"
        echo -e "${BLUE}Состояние памяти после очистки:${NC}"
        free -h
    else
        echo -e "${YELLOW}Очистка отменена${NC}"
    fi
}

# Функция проверки дискового пространства
function check_disk_space {
    echo -e "${BLUE}Проверка дискового пространства:${NC}"
    df -h | column -t
}

# Главное меню
function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Проверка свободной памяти и что ее занимает${NC}"
        echo -e "${CYAN}2. Проверка занятых портов${NC}"
        echo -e "${CYAN}3. Проверить, свободен ли порт${NC}"
        echo -e "${CYAN}4. Список активных сессий tmux${NC}"
        echo -e "${CYAN}5. Список активных сессий screen${NC}"
        echo -e "${CYAN}6. Проверка использования CPU${NC}"
        echo -e "${CYAN}7. Проверка статуса системных служб${NC}"
        echo -e "${CYAN}8. Очистка кэша памяти${NC}"
        echo -e "${CYAN}9. Проверка дискового пространства${NC}"
        echo -e "${CYAN}10. Выход${NC}"

        echo -e "${YELLOW}Введите номер действия:${NC} "
        read choice
        case $choice in
            1) check_memory ;;
            2) check_used_ports ;;
            3) check_port ;;
            4) check_tmux_sessions ;;
            5) check_screen_sessions ;;
            6) check_cpu ;;
            7) check_services ;;
            8) clear_memory_cache ;;
            9) check_disk_space ;;
            10) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить...${NC}"
        read
    done
}

main_menu
