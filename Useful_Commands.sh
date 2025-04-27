# Проверка свободной памяти и что ее занимает / Check available memory and what is using it
function check_memory {
    echo -e "${BLUE}Проверка свободной памяти / Checking available memory:${NC}"
    free -h
    echo -e "\n${BLUE}ТОП-5 процессов по использованию памяти / Top 5 processes by memory usage:${NC}"
    ps aux --sort=-%mem | head -n 6 | awk '{print $1, $2, $3, $4, $11}' | column -t
}

# Проверка занятых портов / Check used ports
function check_used_ports {
    echo -e "${BLUE}Список занятых портов / List of used ports:${NC}"
    ss -tuln | column -t
    echo -e "\n${BLUE}Детали по процессам, использующим порты / Details of processes using ports:${NC}"
    sudo netstat -tulnp 2>/dev/null | column -t || echo -e "${RED}netstat не установлен, используйте ss / netstat is not installed, use ss${NC}"
}

# Проверка, свободен ли порт / Check if a port is free
function check_port {
    echo -e "${BLUE}Проверка статуса порта / Checking port status:${NC}"
    echo -e "${YELLOW}Введите номер порта для проверки (1-65535) / Enter port number to check (1-65535):${NC}"
    read port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}Недопустимый номер порта. Введите число от 1 до 65535 / Invalid port number. Enter a number between 1 and 65535.${NC}"
        return
    fi
    if ss -tuln | grep -q ":${port}\b"; then
        echo -e "${RED}Порт $port занят / Port $port is in use:${NC}"
        ss -tuln | grep ":${port}\b" | column -t
        sudo netstat -tulnp 2>/dev/null | grep ":${port}\b" | column -t || echo -e "${YELLOW}Дополнительная информация недоступна / Additional information unavailable${NC}"
    else
        echo -e "${GREEN}Порт $port свободен / Port $port is free${NC}"
    fi
}

# Проверка активных сессий tmux / Check active tmux sessions
function check_tmux_sessions {
    echo -e "${BLUE}Список активных сессий tmux / List of active tmux sessions:${NC}"
    if command -v tmux &> /dev/null; then
        tmux list-sessions 2>/dev/null || echo -e "${YELLOW}Нет активных сессий tmux / No active tmux sessions${NC}"
    else
        echo -e "${RED}tmux не установлен / tmux is not installed${NC}"
    fi
}

# Проверка активных сессий screen / Check active screen sessions
function check_screen_sessions {
    echo -e "${BLUE}Список активных сессий screen / List of active screen sessions:${NC}"
    if command -v screen &> /dev/null; then
        screen -ls 2>/dev/null || echo -e "${YELLOW}Нет активных сессий screen / No active screen sessions${NC}"
    else
        echo -e "${RED}screen не установлен / screen is not installed${NC}"
    fi
}

# Проверка использования CPU / Check CPU usage
function check_cpu {
    echo -e "${BLUE}ТОП-5 процессов по использованию CPU / Top 5 processes by CPU usage:${NC}"
    ps aux --sort=-%cpu | head -n 6 | awk '{print $1, $2, $3, $4, $11}' | column -t
    echo -e "\n${BLUE}Общая загрузка CPU / Overall CPU usage:${NC}"
    top -bn1 | head -n 3
}

# Проверка статуса системных служб / Check system services status
function check_services {
    echo -e "${BLUE}Список активных системных служб / List of active system services:${NC}"
    systemctl list-units --type=service --state=running | head -n 10
    echo -e "\n${YELLOW}Для полного списка используйте 'systemctl list-units --type=service' / For a full list, use 'systemctl list-units --type=service'${NC}"
}

# Очистка кэша памяти / Clear memory cache
function check_memory_cache {
    echo -e "${BLUE}Очистка кэша памяти / Clearing memory cache:${NC}"
    echo -e "${YELLOW}Текущее состояние памяти / Current memory status:${NC}"
    free -h
    echo -e "${YELLOW}Примечание: Колонка 'buff/cache' показывает память, занятую кэшем, которую можно освободить / Note: The 'buff/cache' column shows memory used by cache, which can be freed.${NC}"
    echo -e "${YELLOW}Внимание: Очистка кэша может временно замедлить работу приложений, зависящих от кэшированных данных / Warning: Clearing cache may temporarily slow down applications relying on cached data.${NC}"
    echo -e "${YELLOW}Требуются права root. Продолжить? (y/n) / Root privileges required. Proceed? (y/n)${NC}"
    read answer
    if [ "$answer" = "y" ]; then
        sudo sync
        sudo sysctl -w vm.drop_caches=3
        echo -e "${GREEN}Кэш памяти очищен / Memory cache cleared${NC}"
        echo -e "${BLUE}Состояние памяти после очистки / Memory status after clearing:${NC}"
        free -h
    else
        echo -e "${YELLOW}Очистка отменена / Clearing cancelled${NC}"
    fi
}

# Анализ директории (вспомогательная функция для рекурсивного анализа)
function analyze_directory {
    local dir="$1"
    local root_dirs="$2"
    echo -e "${BLUE}Детальный анализ директории $dir / Detailed analysis of directory $dir:${NC}"
    du_output=$(sudo du -h --max-depth=1 "$dir" 2>/dev/null | sort -hr | head -n 10)
    echo "$du_output" | column -t
    subdirs=$(echo "$du_output" | awk '{print $2}' | grep -v "^${dir}$")
    if [ -z "$subdirs" ]; then
        echo -e "${YELLOW}Нет подкаталогов для анализа / No subdirectories to analyze${NC}"
        return
    fi
    echo -e "\n${YELLOW}Выберите действие / Select action:${NC}"
    echo -e "${CYAN}1. Углубиться в подкаталог / Drill down into a subdirectory${NC}"
    echo -e "${CYAN}2. Вернуться к списку корневых директорий / Return to root directories list${NC}"
    echo -e "${CYAN}3. Завершить анализ / Finish analysis${NC}"
    echo -e "${YELLOW}Введите номер действия / Enter choice:${NC}"
    read choice
    case $choice in
        1)
            echo -e "${YELLOW}Выберите подкаталог для анализа / Select subdirectory for analysis:${NC}"
            echo "$subdirs" | nl -w2 -s'. '
            echo -e "${YELLOW}Введите номер подкаталога / Enter subdirectory number:${NC}"
            read subdir_number
            selected_subdir=$(echo "$subdirs" | sed -n "${subdir_number}p")
            if [ -z "$selected_subdir" ] || [ ! -d "$selected_subdir" ]; then
                echo -e "${RED}Неверный выбор или подкаталог недоступен / Invalid choice or subdirectory unavailable${NC}"
                analyze_directory "$dir" "$root_dirs"
            else
                analyze_directory "$selected_subdir" "$root_dirs"
            fi
            ;;
        2)
            echo -e "${YELLOW}Возвращаемся к списку корневых директорий / Returning to root directories list:${NC}"
            select_root_directory "$root_dirs"
            ;;
        3)
            echo -e "${YELLOW}Анализ завершен / Analysis finished${NC}"
            ;;
        *)
            echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}"
            analyze_directory "$dir" "$root_dirs"
            ;;
    esac
}

# Выбор корневой директории (вспомогательная функция)
function select_root_directory {
    local root_dirs="$1"
    echo -e "${YELLOW}Выберите директорию для детального анализа / Select a directory for detailed analysis:${NC}"
    echo "$root_dirs" | nl -w2 -s'. '
    echo -e "${YELLOW}Введите номер директории / Enter directory number:${NC}"
    read dir_number
    selected_dir=$(echo "$root_dirs" | sed -n "${dir_number}p")
    if [ -z "$selected_dir" ] || [ ! -d "$selected_dir" ]; then
        echo -e "${RED}Неверный выбор или директория недоступна / Invalid choice or directory unavailable${NC}"
        select_root_directory "$root_dirs"
    else
        analyze_directory "$selected_dir" "$root_dirs"
    fi
}

# Проверка дискового пространства / Check disk space
function check_disk_space {
    echo -e "${BLUE}Проверка дискового пространства / Checking disk space:${NC}"
    echo -e "${YELLOW}Общее использование диска / Overall disk usage:${NC}"
    df -h | column -t
    echo -e "\n${YELLOW}Размеры каталогов в / (отсортированы по убыванию) / Directory sizes in / (sorted by size, largest first):${NC}"
    du_output=$(sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -n 10)
    echo "$du_output" | column -t
    directories=$(echo "$du_output" | awk '{print $2}' | grep -v '^/$')
    echo -e "\n${YELLOW}Хотите просмотреть содержимое одной из директорий более подробно? (y/n) / Want to view the contents of one of the directories in more detail? (y/n)${NC}"
    read answer
    if [ "$answer" = "y" ]; then
        select_root_directory "$directories"
    else
        echo -e "${YELLOW}Анализ директорий отменен / Directory analysis cancelled${NC}"
    fi
}

# Утилиты Docker / Docker utilities
function docker_utils {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker не установлен / Docker is not installed${NC}"
        return
    fi
    while true; do
        echo -e "${YELLOW}Меню утилит Docker / Docker Utilities Menu:${NC}"
        echo -e "${CYAN}1. Список запущенных контейнеров / List running containers${NC}"
        echo -e "${CYAN}2. Список всех контейнеров (включая остановленные) / List all containers (including stopped)${NC}"
        echo -e "${CYAN}3. Список образов Docker / List Docker images${NC}"
        echo -e "${CYAN}4. Очистка неиспользуемых контейнеров, образов и сетей / Clean up unused containers, images, and networks${NC}"
        echo -e "${CYAN}5. Проверка статуса сервиса Docker / Check Docker service status${NC}"
        echo -e "${CYAN}6. Вернуться в главное меню / Back to main menu${NC}"
        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read docker_choice
        case $choice in
            1)
                echo -e "${BLUE}Запущенные контейнеры / Running containers:${NC}"
                docker ps | column -t
            ;;
            2)
                echo -e "${BLUE}Все контейнеры (включая остановленные) / All containers (including stopped):${NC}"
                docker ps -a | column -t
            ;;
            3)
                echo -e "${BLUE}Образы Docker / Docker images:${NC}"
                docker images | column -t
            ;;
            4)
                echo -e "${YELLOW}Внимание: Это удалит все остановленные контейнеры, неиспользуемые образы и сети / Warning: This will remove all stopped containers, unused images, and networks.${NC}"
                echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                read answer
                if [ "$answer" = "y" ]; then
                    docker system prune -f
                    echo -e "${GREEN}Неиспользуемые ресурсы Docker очищены / Unused Docker resources cleaned${NC}"
                else
                    echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                fi
            ;;
            5)
                echo -e "${BLUE}Статус сервиса Docker / Docker service status:${NC}"
                systemctl status docker --no-pager
            ;;
            6) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить / Press Enter to continue...${NC}"
        read
    done
}

# Главное меню / Main menu
function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие / Select action:${NC}"
        echo -e "${CYAN}1. Проверка свободной памяти и что ее занимает / Check available memory and what is using it${NC}"
        echo -e "${CYAN}2. Проверка занятых портов / Check used ports${NC}"
        echo -e "${CYAN}3. Проверка, свободен ли порт / Check if a port is free${NC}"
        echo -e "${CYAN}4. Список активных сессий tmux / List active tmux sessions${NC}"
        echo -e "${CYAN}5. Список активных сессий screen / List active screen sessions${NC}"
        echo -e "${CYAN}6. Проверка использования CPU / Check CPU usage${NC}"
        echo -e "${CYAN}7. Проверка статуса системных служб / Check system services status${NC}"
        echo -e "${CYAN}8. Очистка кэша памяти / Clear memory cache${NC}"
        echo -e "${CYAN}9. Проверка дискового пространства / Check disk space${NC}"
        echo -e "${CYAN}10. Утилиты Docker / Docker utilities${NC}"
        echo -e "${CYAN}11. Выход / Exit${NC}"

        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read choice
        case $choice in
            1) check_memory ;;
            2) check_used_ports ;;
            3) check_port ;;
            4) check_tmux_sessions ;;
            5) check_screen_sessions ;;
            6) check_cpu ;;
            7) check_services ;;
            8) check_memory_cache ;;
            9) check_disk_space ;;
            10) docker_utils ;;
            11) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить / Press Enter to continue...${NC}"
        read
    done
}

main_menu
