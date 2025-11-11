#!/bin/bash
# ~/.config/polybar/scripts/brightness-volume.sh

# Get colors from Xresources
col_bright=$(xrdb -query | grep '\*color3:' | head -1 | awk '{print $2}')
col_vol=$(xrdb -query | grep '\*color2:' | head -1 | awk '{print $2}')

# Brightness
brightness=$(cat /sys/class/backlight/acpi_video0/brightness 2>/dev/null)
max_brightness=$(cat /sys/class/backlight/acpi_video0/max_brightness 2>/dev/null)

if [ -n "$brightness" ] && [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
    bright_pct=$((brightness * 100 / max_brightness))
else
    bright_pct=0
fi

if [ "$bright_pct" -le 25 ]; then
    bright_icon="󰃞"
elif [ "$bright_pct" -le 50 ]; then
    bright_icon="󰃝"
elif [ "$bright_pct" -le 75 ]; then
    bright_icon="󰃟"
else
    bright_icon="󰃠"
fi

# Volume
muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes')
if [ "$muted" = "yes" ]; then
    vol_icon="󰖁"
    vol_pct=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+(?=%)' | head -1)
else
    vol_pct=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+(?=%)' | head -1)
    
    # Pastikan vol_pct tidak kosong
    if [ -z "$vol_pct" ] || ! [[ "$vol_pct" =~ ^[0-9]+$ ]]; then
        vol_pct=0
    fi
    
    if [ "$vol_pct" -le 30 ]; then
        vol_icon=""
    elif [ "$vol_pct" -le 70 ]; then
        vol_icon=""
    else
        vol_icon=""
    fi
fi

# Pastikan vol_pct ada nilai
if [ -z "$vol_pct" ]; then
    vol_pct=0
fi

# Output format
printf "%%{F%s}%s%%{F-}  %%{F%s}%s%%{F-}\n" \
    "$col_bright" "$bright_icon" \
    "$col_vol" "$vol_icon"
