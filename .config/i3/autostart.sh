#!/bin/bash
# Autostart script for i3
# Set wallpaper
~/.fehbg &

# Kill all existing compositors first
killall -q picom compton xcompmgr
while pgrep -x picom >/dev/null || pgrep -x compton >/dev/null; do
    sleep 0.1
done

# Start compositor
if command -v picom &> /dev/null; then
    picom &
elif command -v compton &> /dev/null; then
    compton &
fi

# Start xsettingsd
pgrep -x xsettingsd > /dev/null || xsettingsd &

# Kill and restart polybar
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done
polybar &

# Start eww daemon
pgrep -x eww > /dev/null || eww daemon &
