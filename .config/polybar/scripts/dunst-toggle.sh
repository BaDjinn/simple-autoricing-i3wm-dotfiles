#!/bin/sh

# Toggle pause
dunstctl set-paused toggle

# Langsung panggil script update agar icon di bar berubah
~/.config/polybar/scripts/dunst-update.sh
