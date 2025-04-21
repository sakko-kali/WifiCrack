#!/bin/bash

echo "---------------------------------WIFI CRACK BY Sak---------------------------------"

ifconfig wlan0 down
airmon-ng check kill
iwconfig wlan0 mode monitor
macchanger -r wlan0
ifconfig wlan0 up
iwconfig wlan0 | grep Mode

sleep 3


# Временный файл
temp_file=$(mktemp)

airodump-ng wlan0 --output-format csv -w "$temp_file" > /dev/null 2>&1 &

# Получаем PID airodump-ng
airodump_pid=$(pgrep airodump-ng)

sleep 5


echo "Stopping airodump-ng (PID: $airodump_pid)"

# Останавливаем airodump-ng
kill "$airodump_pid"

# Ждем завершения процесса
wait "$airodump_pid"

clear

# Вывод списка сетей на экран
echo "Available networks:"
cat "$temp_file-01.csv" | grep -v "Station, First" | grep -v "^$" | awk -F',' '{printf "BSSID: %s, Channel: %s, ESSID: %s\n", $1, $4, $14}'

echo ""
echo ""
echo ""


# Запрашиваем ESSID у пользователя
read -p "Enter the ESSID of the target network: " target_essid

# Ищем строку с ESSID (улучшенная фильтрация)
target_line=$(cat "$temp_file-01.csv" | grep "$target_essid" | grep -v "Station, First" | grep -v "^$" | grep -v "BSSID")

# Извлекаем BSSID и канал (с удалением пробелов)
target_bssid=$(echo "$target_line" | awk -F',' '{print $1}' | tr -d ' ')
echo "$target_bssid"
target_channel=$(echo "$target_line" | awk -F',' '{print $4}' | tr -d ' ')
echo "$target_channel"

# Проверяем, что BSSID и канал найдены
if [ -z "$target_bssid" ] || [ -z "$target_channel" ]; then
  echo "Error: Could not find BSSID or channel for ESSID '$target_essid'"
  exit 1
fi

# Запрашиваем имя файла для сохранения
read -p "Enter the file name to save the results: " filename

# Запускаем airodump-ng с указанными параметрами (убраны лишние кавычки)
echo "Starting deep scan on BSSID '$target_bssid', channel '$target_channel'..."
airodump-ng -c "$target_channel" -w "$filename" --bssid "$target_bssid" wlan0

# Удаляем временный файл
rm "$temp_file-01.csv"

