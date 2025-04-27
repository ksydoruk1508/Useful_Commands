#!/bin/bash

# Цвета текста / Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета) / No color (reset)

# Заголовок / Header
echo -e "${GREEN}"
cat << "EOF"
TEST4
EOF
echo -e "${NC}"

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
function clear_memory_cache {
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

# Утилиты tmux / tmux utilities
function tmux_utils {
    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}tmux не установлен / tmux is not installed${NC}"
        return
    fi
    while true; do
        echo -e "${YELLOW}Меню утилит tmux / tmux Utilities Menu:${NC}"
        echo -e "${CYAN}1. Список активных сессий / List active sessions${NC}"
        echo -e "${CYAN}2. Создать новую сессию / Create new session${NC}"
        echo -e "${CYAN}3. Подключиться к сессии / Attach to session${NC}"
        echo -e "${CYAN}4. Завершить сессию / Kill session${NC}"
        echo -e "${CYAN}5. Очистка завершенных сессий / Clean up detached sessions${NC}"
        echo -e "${CYAN}6. Вернуться в главное меню / Back to main menu${NC}"
        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read tmux_choice
        case $tmux_choice in
            1)
                echo -e "${BLUE}Активные сессии tmux / Active tmux sessions:${NC}"
                tmux list-sessions 2>/dev/null | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
            ;;
            2)
                echo -e "${YELLOW}Введите имя новой сессии (или оставьте пустым для имени по умолчанию) / Enter name for new session (or leave empty for default):${NC}"
                read session_name
                if [ -n "$session_name" ]; then
                    tmux new-session -s "$session_name" -d && echo -e "${GREEN}Сессия '$session_name' создана / Session '$session_name' created${NC}" || echo -e "${RED}Не удалось создать сессию / Failed to create session${NC}"
                else
                    tmux new-session -d && echo -e "${GREEN}Сессия создана / Session created${NC}" || echo -e "${RED}Не удалось создать сессию / Failed to create session${NC}"
                fi
            ;;
            3)
                echo -e "${BLUE}Список активных сессий для подключения / List of active sessions to attach:${NC}"
                tmux list-sessions 2>/dev/null | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
                echo -e "${YELLOW}Введите имя или номер сессии для подключения / Enter session name or number to attach:${NC}"
                read session
                if [ -n "$session" ] && tmux list-sessions 2>/dev/null | grep -q "$session"; then
                    tmux attach-session -t "$session" && echo -e "${GREEN}Подключено к сессии '$session' / Attached to session '$session'${NC}" || echo -e "${RED}Не удалось подключиться к сессии / Failed to attach to session${NC}"
                else
                    echo -e "${RED}Сессия '$session' не найдена или не указана / Session '$session' not found or not specified${NC}"
                fi
            ;;
            4)
                echo -e "${BLUE}Список активных сессий для завершения / List of active sessions to kill:${NC}"
                tmux list-sessions 2>/dev/null | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
                echo -e "${YELLOW}Введите имя или номер сессии для завершения / Enter session name or number to kill:${NC}"
                read session
                if [ -n "$session" ] && tmux list-sessions 2>/dev/null | grep -q "$session"; then
                    echo -e "${YELLOW}Внимание: Сессия будет завершена безвозвратно / Warning: Session will be permanently terminated.${NC}"
                    echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                    read answer
                    if [ "$answer" = "y" ]; then
                        tmux kill-session -t "$session" && echo -e "${GREEN}Сессия '$session' завершена / Session '$session' killed${NC}" || echo -e "${RED}Не удалось завершить сессию / Failed to kill session${NC}"
                    else
                        echo -e "${YELLOW}Завершение отменено / Termination cancelled${NC}"
                    fi
                else
                    echo -e "${RED}Сессия '$session' не найдена или не указана / Session '$session' not found or not specified${NC}"
                fi
            ;;
            5)
                echo -e "${BLUE}Проверка завершенных (detached) сессий / Checking detached sessions:${NC}"
                tmux list-sessions 2>/dev/null | grep -v "(attached)" | column -t || echo -e "${YELLOW}Нет завершенных сессий / No detached sessions${NC}"
                echo -e "\n${YELLOW}Внимание: Это завершит все завершенные (detached) сессии / Warning: This will terminate all detached sessions.${NC}"
                echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                read answer
                if [ "$answer" = "y" ]; then
                    tmux kill-server 2>/dev/null && echo -e "${GREEN}Все завершенные сессии очищены / All detached sessions cleaned${NC}" || echo -e "${YELLOW}Нет сессий для очистки / No sessions to clean${NC}"
                else
                    echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                fi
            ;;
            6) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить / Press Enter to continue...${NC}"
        read
    done
}

# Утилиты screen / screen utilities
function screen_utils {
    if ! command -v screen &> /dev/null; then
        echo -e "${RED}screen не установлен / screen is not installed${NC}"
        return
    fi
    while true; do
        echo -e "${YELLOW}Меню утилит screen / screen Utilities Menu:${NC}"
        echo -e "${CYAN}1. Список активных сессий / List active sessions${NC}"
        echo -e "${CYAN}2. Создать новую сессию / Create new session${NC}"
        echo -e "${CYAN}3. Подключиться к сессии / Attach to session${NC}"
        echo -e "${CYAN}4. Завершить сессию / Kill session${NC}"
        echo -e "${CYAN}5. Очистка завершенных сессий / Clean up detached sessions${NC}"
        echo -e "${CYAN}6. Вернуться в главное меню / Back to main menu${NC}"
        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read screen_choice
        case $screen_choice in
            1)
                echo -e "${BLUE}Активные сессии screen / Active screen sessions:${NC}"
                screen -ls 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\.' | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
            ;;
            2)
                echo -e "${YELLOW}Введите имя новой сессии (или оставьте пустым для имени по умолчанию) / Enter name for new session (or leave empty for default):${NC}"
                read session_name
                if [ -n "$session_name" ]; then
                    screen -S "$session_name" -d -m && echo -e "${GREEN}Сессия '$session_name' создана / Session '$session_name' created${NC}" || echo -e "${RED}Не удалось создать сессию / Failed to create session${NC}"
                else
                    screen -d -m && echo -e "${GREEN}Сессия создана / Session created${NC}" || echo -e "${RED}Не удалось создать сессию / Failed to create session${NC}"
                fi
            ;;
            3)
                echo -e "${BLUE}Список активных сессий для подключения / List of active sessions to attach:${NC}"
                screen -ls 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\.' | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
                echo -e "${YELLOW}Введите имя или PID сессии для подключения / Enter session name or PID to attach:${NC}"
                read session
                if [ -n "$session" ] && screen -ls 2>/dev/null | grep -q "$session"; then
                    screen -r "$session" && echo -e "${GREEN}Подключено к сессии '$session' / Attached to session '$session'${NC}" || echo -e "${RED}Не удалось подключиться к сессии / Failed to attach to session${NC}"
                else
                    echo -e "${RED}Сессия '$session' не найдена или не указана / Session '$session' not found or not specified${NC}"
                fi
            ;;
            4)
                echo -e "${BLUE}Список активных сессий для завершения / List of active sessions to kill:${NC}"
                screen -ls 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\.' | column -t || echo -e "${YELLOW}Нет активных сессий / No active sessions${NC}"
                echo -e "${YELLOW}Введите имя или PID сессии для завершения / Enter session name or PID to kill:${NC}"
                read session
                if [ -n "$session" ] && screen -ls 2>/dev/null | grep -q "$session"; then
                    echo -e "${YELLOW}Внимание: Сессия будет завершена безвозвратно / Warning: Session will be permanently terminated.${NC}"
                    echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                    read answer
                    if [ "$answer" = "y" ]; then
                        screen -S "$session" -X quit && echo -e "${GREEN}Сессия '$session' завершена / Session '$session' killed${NC}" || echo -e "${RED}Не удалось завершить сессию / Failed to kill session${NC}"
                    else
                        echo -e "${YELLOW}Завершение отменено / Termination cancelled${NC}"
                    fi
                else
                    echo -e "${RED}Сессия '$session' не найдена или не указана / Session '$session' not found or not specified${NC}"
                fi
            ;;
            5)
                echo -e "${BLUE}Проверка завершенных (detached) сессий / Checking detached sessions:${NC}"
                screen -ls 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\..*Detached' | column -t || echo -e "${YELLOW}Нет завершенных сессий / No detached sessions${NC}"
                echo -e "\n${YELLOW}Продолжить с очисткой завершенных сессий? (y/n) / Proceed with cleaning detached sessions? (y/n)${NC}"
                read answer
                if [ "$answer" = "y" ]; then
                    screen -wipe 2>/dev/null && echo -e "${GREEN}Завершенные сессии очищены / Detached sessions cleaned${NC}" || echo -e "${YELLOW}Нет сессий для очистки / No sessions to clean${NC}"
                else
                    echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                fi
            ;;
            6) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить / Press Enter to continue...${NC}"
        read
    done
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
        echo -e "${CYAN}4. Просмотр логов контейнера / View container logs${NC}"
        echo -e "${CYAN}5. Проверка использования образа / Check image usage${NC}"
        echo -e "${CYAN}6. Проверка использования ресурсов Docker / Check Docker resource usage${NC}"
        echo -e "${CYAN}7. Запуск контейнера / Start a container${NC}"
        echo -e "${CYAN}8. Остановка контейнера / Stop a container${NC}"
        echo -e "${CYAN}9. Управление Docker Compose / Manage Docker Compose${NC}"
        echo -e "${CYAN}10. Удаление контейнера / Remove a container${NC}"
        echo -e "${CYAN}11. Удаление образа / Remove an image${NC}"
        echo -e "${CYAN}12. Очистка неиспользуемых контейнеров, образов и сетей / Clean up unused containers, images, and networks${NC}"
        echo -e "${CYAN}13. Вернуться в главное меню / Back to main menu${NC}"
        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read docker_choice
        case $docker_choice in
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
                echo -e "${BLUE}Список всех контейнеров для выбора / List of all containers for selection:${NC}"
                docker ps -a --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t
                echo -e "${YELLOW}Введите ID или имя контейнера для просмотра логов / Enter container ID or name to view logs:${NC}"
                read container
                if [ -n "$container" ]; then
                    if docker ps -a --format "{{.ID}} {{.Names}}" | grep -q "$container"; then
                        echo -e "${BLUE}Логи контейнера $container / Logs for container $container:${NC}"
                        docker logs --tail 50 "$container" 2>/dev/null || echo -e "${RED}Не удалось получить логи / Failed to retrieve logs${NC}"
                    else
                        echo -e "${RED}Контейнер с ID или именем '$container' не найден / Container with ID or name '$container' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя контейнера не введено / Container ID or name not provided${NC}"
                fi
            ;;
            5)
                echo -e "${BLUE}Список образов для проверки / List of images to check:${NC}"
                docker images --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | column -t
                echo -e "${YELLOW}Введите ID или имя образа (в формате repository:tag) для проверки / Enter image ID or name (in format repository:tag) to check:${NC}"
                read image
                if [ -n "$image" ]; then
                    if docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}" | grep -q "$image"; then
                        image_id=$(docker images --filter "reference=$image" --format "{{.ID}}" | head -n 1)
                        echo -e "${BLUE}Контейнеры, использующие образ $image (ID: $image_id) / Containers using image $image (ID: $image_id):${NC}"
                        docker ps -a --filter "ancestor=$image_id" --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t || echo -e "${YELLOW}Нет контейнеров, использующих этот образ / No containers using this image${NC}"
                    else
                        echo -e "${RED}Образ с ID или именем '$image' не найден / Image with ID or name '$image' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя образа не введено / Image ID or name not provided${NC}"
                fi
            ;;
            6)
                echo -e "${BLUE}Использование ресурсов Docker / Docker resource usage:${NC}"
                docker system df | column -t
            ;;
            7)
                echo -e "${BLUE}Список остановленных контейнеров для запуска / List of stopped containers to start:${NC}"
                docker ps -a --filter "status=exited" --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t
                echo -e "${YELLOW}Введите ID или имя контейнера для запуска / Enter container ID or name to start:${NC}"
                read container
                if [ -n "$container" ]; then
                    if docker ps -a --filter "status=exited" --format "{{.ID}} {{.Names}}" | grep -q "$container"; then
                        echo -e "${BLUE}Запуск контейнера $container / Starting container $container:${NC}"
                        docker start "$container" && echo -e "${GREEN}Контейнер запущен / Container started${NC}" || echo -e "${RED}Не удалось запустить контейнер / Failed to start container${NC}"
                    else
                        echo -e "${RED}Остановленный контейнер с ID или именем '$container' не найден / Stopped container with ID or name '$container' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя контейнера не введено / Container ID or name not provided${NC}"
                fi
            ;;
            8)
                echo -e "${BLUE}Список запущенных контейнеров для остановки / List of running containers to stop:${NC}"
                docker ps --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t
                echo -e "${YELLOW}Введите ID или имя контейнера для остановки / Enter container ID or name to stop:${NC}"
                read container
                if [ -n "$container" ]; then
                    if docker ps --format "{{.ID}} {{.Names}}" | grep -q "$container"; then
                        echo -e "${BLUE}Остановка контейнера $container / Stopping container $container:${NC}"
                        docker stop "$container" && echo -e "${GREEN}Контейнер остановлен / Container stopped${NC}" || echo -e "${RED}Не удалось остановить контейнер / Failed to stop container${NC}"
                    else
                        echo -e "${RED}Запущенный контейнер с ID или именем '$container' не найден / Running container with ID or name '$container' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя контейнера не введено / Container ID or name not provided${NC}"
                fi
            ;;
            9)
                if ! command -v docker-compose &> /dev/null; then
                    echo -e "${RED}Docker Compose не установлен / Docker Compose is not installed${NC}"
                else
                    echo -e "${YELLOW}Выберите действие для Docker Compose / Select Docker Compose action:${NC}"
                    echo -e "${CYAN}1. Запустить Compose-проект / Start Compose project${NC}"
                    echo -e "${CYAN}2. Остановить Compose-проект / Stop Compose project${NC}"
                    echo -e "${CYAN}3. Просмотреть статус Compose-проекта / View Compose project status${NC}"
                    echo -e "${YELLOW}Введите номер действия / Enter choice:${NC}"
                    read compose_choice
                    case $compose_choice in
                        1)
                            echo -e "${YELLOW}Введите путь к файлу docker-compose.yml (или оставьте пустым для текущей директории) / Enter path to docker-compose.yml (or leave empty for current directory):${NC}"
                            read compose_file
                            compose_file=${compose_file:-docker-compose.yml}
                            if [ -f "$compose_file" ]; then
                                echo -e "${BLUE}Запуск Compose-проекта из $compose_file / Starting Compose project from $compose_file:${NC}"
                                docker-compose -f "$compose_file" up -d && echo -e "${GREEN}Compose-проект запущен / Compose project started${NC}" || echo -e "${RED}Не удалось запустить Compose-проект / Failed to start Compose project${NC}"
                            else
                                echo -e "${RED}Файл $compose_file не найден / File $compose_file not found${NC}"
                            fi
                        ;;
                        2)
                            echo -e "${YELLOW}Введите путь к файлу docker-compose.yml (или оставьте пустым для текущей директории) / Enter path to docker-compose.yml (or leave empty for current directory):${NC}"
                            read compose_file
                            compose_file=${compose_file:-docker-compose.yml}
                            if [ -f "$compose_file" ]; then
                                echo -e "${BLUE}Остановка Compose-проекта из $compose_file / Stopping Compose project from $compose_file:${NC}"
                                docker-compose -f "$compose_file" down && echo -e "${GREEN}Compose-проект остановлен / Compose project stopped${NC}" || echo -e "${RED}Не удалось остановить Compose-проект / Failed to stop Compose project${NC}"
                            else
                                echo -e "${RED}Файл $compose_file не найден / File $compose_file not found${NC}"
                            fi
                        ;;
                        3)
                            echo -e "${YELLOW}Введите путь к файлу docker-compose.yml (или оставьте пустым для текущей директории) / Enter path to docker-compose.yml (or leave empty for current directory):${NC}"
                            read compose_file
                            compose_file=${compose_file:-docker-compose.yml}
                            if [ -f "$compose_file" ]; then
                                echo -e "${BLUE}Статус Compose-проекта из $compose_file / Status of Compose project from $compose_file:${NC}"
                                docker-compose -f "$compose_file" ps | column -t
                            else
                                echo -e "${RED}Файл $compose_file не найден / File $compose_file not found${NC}"
                            fi
                        ;;
                        *)
                            echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}"
                        ;;
                    esac
                fi
            ;;
            10)
                echo -e "${BLUE}Список всех контейнеров для удаления / List of all containers for removal:${NC}"
                docker ps -a --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t
                echo -e "${YELLOW}Введите ID или имя контейнера для удаления / Enter container ID or name to remove:${NC}"
                read container
                if [ -n "$container" ]; then
                    if docker ps -a --format "{{.ID}} {{.Names}}" | grep -q "$container"; then
                        echo -e "${YELLOW}Внимание: Контейнер будет удален безвозвратно / Warning: Container will be permanently removed.${NC}"
                        echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker rm -f "$container" && echo -e "${GREEN}Контейнер удален / Container removed${NC}" || echo -e "${RED}Не удалось удалить контейнер / Failed to remove container${NC}"
                        else
                            echo -e "${YELLOW}Удаление отменено / Removal cancelled${NC}"
                        fi
                    else
                        echo -e "${RED}Контейнер с ID или именем '$container' не найден / Container with ID or name '$container' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя контейнера не введено / Container ID or name not provided${NC}"
                fi
            ;;
            11)
                echo -e "${BLUE}Список образов для удаления / List of images for removal:${NC}"
                docker images --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | column -t
                echo -e "${YELLOW}Введите ID или имя образа (в формате repository:tag) для удаления / Enter image ID or name (in format repository:tag) to remove:${NC}"
                read image
                if [ -n "$image" ]; then
                    if docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}" | grep -q "$image"; then
                        echo -e "${YELLOW}Внимание: Образ будет удален безвозвратно / Warning: Image will be permanently removed.${NC}"
                        echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker rmi -f "$image" && echo -e "${GREEN}Образ удален / Image removed${NC}" || echo -e "${RED}Не удалось удалить образ / Failed to remove image${NC}"
                        else
                            echo -e "${YELLOW}Удаление отменено / Removal cancelled${NC}"
                        fi
                    else
                        echo -e "${RED}Образ с ID или именем '$image' не найден / Image with ID or name '$image' not found${NC}"
                    fi
                else
                    echo -e "${YELLOW}ID или имя образа не введено / Image ID or name not provided${NC}"
                fi
            ;;
            12)
                echo -e "${YELLOW}Выберите тип очистки / Select cleanup type:${NC}"
                echo -e "${CYAN}1. Очистка только 'dangling' образов / Clean only 'dangling' images${NC}"
                echo -e "${CYAN}2. Очистка всех неиспользуемых образов (включая с тегами) / Clean all unused images (including tagged)${NC}"
                echo -e "${CYAN}3. Очистка остановленных контейнеров / Clean stopped containers${NC}"
                echo -e "${CYAN}4. Очистка неиспользуемых сетей / Clean unused networks${NC}"
                echo -e "${CYAN}5. Полная очистка (все неиспользуемые ресурсы) / Full cleanup (all unused resources)${NC}"
                echo -e "${CYAN}6. Отмена / Cancel${NC}"
                echo -e "${YELLOW}Введите номер действия / Enter choice:${NC}"
                read cleanup_choice
                case $cleanup_choice in
                    1)
                        echo -e "${BLUE}Проверка 'dangling' образов / Checking 'dangling' images:${NC}"
                        docker images --filter "dangling=true" --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | column -t || echo -e "${YELLOW}Нет 'dangling' образов / No 'dangling' images${NC}"
                        echo -e "\n${YELLOW}Продолжить с очисткой 'dangling' образов? (y/n) / Proceed with cleaning 'dangling' images? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker image prune -f
                            echo -e "${GREEN}'Dangling' образы очищены / 'Dangling' images cleaned${NC}"
                        else
                            echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                        fi
                    ;;
                    2)
                        echo -e "${BLUE}Проверка всех неиспользуемых образов / Checking all unused images:${NC}"
                        docker images --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | while read -r id repo tag size; do
                            if ! docker ps -a --filter "ancestor=$id" --format "{{.ID}}" | grep -q .; then
                                echo "$id $repo $tag $size"
                            fi
                        done | column -t || echo -e "${YELLOW}Нет неиспользуемых образов / No unused images${NC}"
                        echo -e "\n${YELLOW}Внимание: Это удалит все образы, не связанные с контейнерами, включая те с тегами / Warning: This will remove all images not used by containers, including tagged ones.${NC}"
                        echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker image prune -a -f
                            echo -e "${GREEN}Все неиспользуемые образы очищены / All unused images cleaned${NC}"
                        else
                            echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                        fi
                    ;;
                    3)
                        echo -e "${BLUE}Проверка остановленных контейнеров / Checking stopped containers:${NC}"
                        docker ps -a --filter "status=exited" --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t || echo -e "${YELLOW}Нет остановленных контейнеров / No stopped containers${NC}"
                        echo -e "\n${YELLOW}Продолжить с очисткой остановленных контейнеров? (y/n) / Proceed with cleaning stopped containers? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker container prune -f
                            echo -e "${GREEN}Остановленные контейнеры очищены / Stopped containers cleaned${NC}"
                        else
                            echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                        fi
                    ;;
                    4)
                        echo -e "${BLUE}Проверка неиспользуемых сетей / Checking unused networks:${NC}"
                        docker network ls --filter "dangling=true" --format "{{.ID}} {{.Name}} {{.Driver}}" | column -t || echo -e "${YELLOW}Нет неиспользуемых сетей / No unused networks${NC}"
                        echo -e "\n${YELLOW}Продолжить с очисткой неиспользуемых сетей? (y/n) / Proceed with cleaning unused networks? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker network prune -f
                            echo -e "${GREEN}Неиспользуемые сети очищены / Unused networks cleaned${NC}"
                        else
                            echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                        fi
                    ;;
                    5)
                        echo -e "${BLUE}Проверка неиспользуемых ресурсов / Checking unused resources:${NC}"
                        echo -e "${YELLOW}Остановленные контейнеры / Stopped containers:${NC}"
                        docker ps -a --filter "status=exited" --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | column -t || echo -e "${YELLOW}Нет остановленных контейнеров / No stopped containers${NC}"
                        echo -e "\n${YELLOW}Неиспользуемые (dangling) образы / Unused (dangling) images:${NC}"
                        docker images --filter "dangling=true" --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | column -t || echo -e "${YELLOW}Нет неиспользуемых образов / No dangling images${NC}"
                        echo -e "\n${YELLOW}Неиспользуемые образы с тегами / Unused tagged images:${NC}"
                        docker images --format "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" | while read -r id repo tag size; do
                            if ! docker ps -a --filter "ancestor=$id" --format "{{.ID}}" | grep -q .; then
                                echo "$id $repo $tag $size"
                            fi
                        done | column -t || echo -e "${YELLOW}Нет неиспользуемых образов с тегами / No unused tagged images${NC}"
                        echo -e "\n${YELLOW}Неиспользуемые сети / Unused networks:${NC}"
                        docker network ls --filter "dangling=true" --format "{{.ID}} {{.Name}} {{.Driver}}" | column -t || echo -e "${YELLOW}Нет неиспользуемых сетей / No unused networks${NC}"
                        echo -e "\n${YELLOW}Внимание: Это удалит все неиспользуемые ресурсы, включая образы с тегами / Warning: This will remove all unused resources, including tagged images.${NC}"
                        echo -e "${YELLOW}Продолжить? (y/n) / Proceed? (y/n)${NC}"
                        read answer
                        if [ "$answer" = "y" ]; then
                            docker system prune --all -f
                            echo -e "${GREEN}Все неиспользуемые ресурсы очищены / All unused resources cleaned${NC}"
                        else
                            echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                        fi
                    ;;
                    6)
                        echo -e "${YELLOW}Очистка отменена / Cleanup cancelled${NC}"
                    ;;
                    *)
                        echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}"
                    ;;
                esac
            ;;
            13) break ;;
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
        echo -e "${CYAN}1. Проверка использования CPU / Check CPU usage${NC}"
        echo -e "${CYAN}2. Проверка свободной памяти / Check available memory${NC}"
        echo -e "${CYAN}3. Проверка дискового пространства / Check disk space${NC}"
        echo -e "${CYAN}4. Проверка занятых портов / Check used ports${NC}"
        echo -e "${CYAN}5. Проверка, свободен ли порт / Check if a port is free${NC}"
        echo -e "${CYAN}6. Проверка статуса системных служб / Check system services status${NC}"
        echo -e "${CYAN}7. Управление tmux сессиями / Manage tmux sessions${NC}"
        echo -e "${CYAN}8. Управление screen сессиями / Manage screen sessions${NC}"
        echo -e "${CYAN}9. Очистка кэша памяти / Clear memory cache${NC}"
        echo -e "${CYAN}10. Утилиты Docker / Docker utilities${NC}"
        echo -e "${CYAN}11. Выход / Exit${NC}"
        echo -e "${YELLOW}Введите номер действия / Enter choice:${NC} "
        read choice
        case $choice in
            1) check_cpu ;;
            2) check_memory ;;
            3) check_disk_space ;;
            4) check_used_ports ;;
            5) check_port ;;
            6) check_services ;;
            7) tmux_utils ;;
            8) screen_utils ;;
            9) clear_memory_cache ;;
            10) docker_utils ;;
            11) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова / Invalid choice, try again.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Нажмите Enter, чтобы продолжить / Press Enter to continue...${NC}"
        read
    done
}

main_menu
