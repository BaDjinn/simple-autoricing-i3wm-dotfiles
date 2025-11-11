#!/bin/bash
# ~/.config/polybar/scripts/dunst-hooks.sh

COLOR=$(xrdb -query | grep '^\*color5:' | awk '{print $2}')

case "$1" in
    0)
        echo "%{F$COLOR}󰂚%{F-} 0"
        ;;
    1)
        COUNT=$(dunstctl count displayed)
        echo "%{F$COLOR}󰂚%{F-} $COUNT"
        ;;
    2)
        echo "%{F$COLOR}󰂛%{F-}"
        ;;
esac
