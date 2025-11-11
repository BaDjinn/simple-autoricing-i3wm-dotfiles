#!/bin/bash
# ~/.config/polybar/scripts/system-status.sh

# Get colors from Xresources
col_wifi=$(xrdb -query | grep '\*color6:' | head -1 | awk '{print $2}')
col_dunst=$(xrdb -query | grep '\*color5:' | head -1 | awk '{print $2}')

# WiFi status - menggunakan nmcli
wifi_interface="wlan0"
wifi_state=$(cat /sys/class/net/$wifi_interface/operstate 2>/dev/null)

if [ "$wifi_state" = "up" ]; then
    # Coba beberapa metode untuk mendapatkan signal strength
    
    # Metode 1: nmcli (paling reliable)
    wifi_signal=$(nmcli -t -f SIGNAL dev wifi | head -n1 2>/dev/null)
    
    # Metode 2: jika nmcli gagal, coba dari /proc/net/wireless
    if [ -z "$wifi_signal" ] || ! [[ "$wifi_signal" =~ ^[0-9]+$ ]]; then
        wifi_signal=$(awk 'NR==3 {print int($3 * 100 / 70)}' /proc/net/wireless 2>/dev/null)
    fi
    
    # Metode 3: jika masih gagal, coba grep dari /sys
    if [ -z "$wifi_signal" ] || ! [[ "$wifi_signal" =~ ^[0-9]+$ ]]; then
        wifi_signal=$(cat /sys/class/net/$wifi_interface/wireless/link 2>/dev/null)
    fi
    
    # Jika semua metode gagal, set default 100
    if [ -z "$wifi_signal" ] || ! [[ "$wifi_signal" =~ ^[0-9]+$ ]]; then
        wifi_signal=100
    fi
    
    # Set icon based on signal strength (0-100%)
    if [ "$wifi_signal" -le 20 ]; then
        wifi_icon="󰤯 "
    elif [ "$wifi_signal" -le 40 ]; then
        wifi_icon="󰤟 "
    elif [ "$wifi_signal" -le 60 ]; then
        wifi_icon="󰤢 "
    elif [ "$wifi_signal" -le 80 ]; then
        wifi_icon="󰤥 "
    else
        wifi_icon="󰤨 "
    fi
    
    # Calculate network speed
    # Read current values
    rx_bytes_1=$(cat /sys/class/net/$wifi_interface/statistics/rx_bytes)
    tx_bytes_1=$(cat /sys/class/net/$wifi_interface/statistics/tx_bytes)
    
    # Wait 1 second
    sleep 1
    
    # Read values again
    rx_bytes_2=$(cat /sys/class/net/$wifi_interface/statistics/rx_bytes)
    tx_bytes_2=$(cat /sys/class/net/$wifi_interface/statistics/tx_bytes)
    
    # Calculate difference (bytes per second)
    rx_rate=$((rx_bytes_2 - rx_bytes_1))
    tx_rate=$((tx_bytes_2 - tx_bytes_1))
    
    # Format speed to human readable
    format_speed() {
        local bytes=$1
        if [ $bytes -lt 1024 ]; then
            echo "${bytes}B/s"
        elif [ $bytes -lt 1048576 ]; then
            echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")K/s"
        else
            echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")M/s"
        fi
    }
    
    downspeed=$(format_speed $rx_rate)
    upspeed=$(format_speed $tx_rate)
    
    wifi_display="$wifi_icon ↓$downspeed ↑$upspeed"
else
    wifi_icon="󰤮 "
    wifi_display="$wifi_icon Disconnected"
fi

# Dunst notification status
dunst_paused=$(dunstctl is-paused)
if [ "$dunst_paused" = "true" ]; then
    dunst_icon="%{F$col_dunst}󰂛%{F-}"
else
    dunst_count=$(dunstctl count waiting)
    if [ "$dunst_count" -gt 0 ]; then
        dunst_icon="%{F$col_dunst}󰂚%{F-} $dunst_count"
    else
        dunst_icon="%{F$col_dunst}󰂚%{F-}"
    fi
fi

# Output format
printf "%%{F%s}%s%%{F-}  %s\n" \
    "$col_wifi" "$wifi_display" \
    "$dunst_icon"
