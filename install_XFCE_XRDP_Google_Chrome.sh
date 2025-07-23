#!/bin/bash

set -e  # остановка при ошибке

# === Обновление системы ===
sudo apt update && sudo apt upgrade -y

# === Установка XFCE и XRDP ===
sudo apt install -y xrdp xfce4 xfce4-goodies

# === Установка Google Chrome ===
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# === Назначение Chrome браузером по умолчанию ===
xdg-settings set default-web-browser google-chrome.desktop

# === Исправление запуска Chrome с --no-sandbox ===
sudo sed -i 's|^Exec=.*|Exec=/usr/bin/google-chrome-stable --no-sandbox %U|' /usr/share/applications/google-chrome.desktop

# === Настройка XRDP ===
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini

# === Настройка XFCE как сессии по умолчанию ===
echo xfce4-session > ~/.xsession

# === Автоматическое редактирование startwm.sh ===
STARTWM="/etc/xrdp/startwm.sh"

# Удаляем стандартные строки запуска
sudo sed -i '/^test -x/d' "$STARTWM"
sudo sed -i '/^exec/d' "$STARTWM"

# Добавляем запуск XFCE (только если ещё не добавлен)
if ! grep -q "startxfce4" "$STARTWM"; then
    echo -e "\n#xfce\nstartxfce4" | sudo tee -a "$STARTWM" > /dev/null
fi

# === Запуск и активация XRDP ===
sudo systemctl enable --now xrdp
sudo systemctl restart xrdp

# === Разрешаем порт 3390 в firewall ===
sudo ufw allow 3390/tcp || true

echo -e "\n✅ Установка завершена!"
echo "→ Подключайся по RDP к серверу на порт 3390"
