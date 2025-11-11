#!/bin/bash
# Generate rofi image
magick /home/diaz/.config/wpg/.current -resize 800x -quality 100 /home/diaz/.config/wpg/.current-rofi.jpg &

# Restart polybar di background
(
  killall -q polybar
  sleep 0.5
  polybar example 2>&1 | tee -a /tmp/polybar.log >/dev/null &
) &

bash ~/.config/dunst/generate-dunstrc.sh &

# Reload eww setelah pywal generate warna baru
eww reload &

exit 0
