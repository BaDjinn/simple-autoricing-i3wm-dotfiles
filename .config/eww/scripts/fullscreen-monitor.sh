#!/bin/bash

# Fungsi untuk cek apakah ada window fullscreen
is_fullscreen() {
    i3-msg -t get_tree | jq -r '.. | select(.focused? == true) | .fullscreen_mode' | grep -q 1
}

# Loop terus menerus
prev_state="not_fullscreen"

while true; do
    if is_fullscreen; then
        current_state="fullscreen"
        if [ "$prev_state" != "fullscreen" ]; then
            eww close bar  # Hide bar
            prev_state="fullscreen"
        fi
    else
        current_state="not_fullscreen"
        if [ "$prev_state" != "not_fullscreen" ]; then
            eww open bar   # Show bar
            prev_state="not_fullscreen"
        fi
    fi
    
    sleep 0.3  # Cek setiap 0.3 detik (bisa diubah lebih cepat/lambat)
done
