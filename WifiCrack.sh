#!/bin/bash

echo "changing mode to monitor"

ifconfig wlan0 down
airmon-ng check kill
iwconfig wlan0 mode monitor
macchanger -r wlan0
ifconfig wlan0 up
iwconfig wlan0 | grep Mode

echo "scanning.."

# Временный файл для сохранения 
temp_file=$(mktemp)

# Запускаем airodump-ng для сканирования и перенаправляем вывод в файл
airodump-ng wlan0 --output-format csv -w "$temp_file" > /dev/null 2>&1 &

# Получаем PID airodump-ng
airodump_pid=$(pgrep airodump-ng)


sleep 5

echo "Stopping airodump-ng (PID: $airodump_pid)"


kill "$airodump_pid"


wait "$airodump_pid"


echo "Available networks:"
cat "$temp_file-01.csv" | grep -v "Station, First" | grep -v "^$" | awk -F',' '{printf "BSSID: %s, Channel: %s, ESSID: %s\n", $1, $4, $14}'


echo "for next scan type: "

echo "channel (C): "
read channel

echo "BSSID: "
read bssid

echo "and the file name to save: "
read filename

echo "channel is $channel and BSSID is $bssid right? (yes/no)"
read result

while [[ "$result" == "no" ]]
  do
    echo "channel (C): "
    read channel

    echo "BSSID: "
    read bssid

    echo "and the file name to save: "
    read filename

    echo "channel is $channel and BSSID is $bssid right? (yes/no)"
    read result
  done

# Запускаем airodump-ng с указанными параметрами
airodump-ng -c "$channel" -w "$filename" --bssid "$bssid" wlan0

# Удаляем временный файл
rm "$temp_file-01.csv"
