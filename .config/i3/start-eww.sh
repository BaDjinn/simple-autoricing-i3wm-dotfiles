#!/bin/bash

# Kill semua window tapi JANGAN kill daemon
eww close-all

# Cek daemon status
if ! eww ping &>/dev/null; then
    # Daemon mati, restart
    killall -q eww
    eww daemon &
    sleep 1
fi

# Buka bar
eww open bar
