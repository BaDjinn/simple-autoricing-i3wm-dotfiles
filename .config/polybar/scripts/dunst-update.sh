#!/bin/sh
if [ "$(dunstctl is-paused)" = "true" ]; then
    # Kirim hook 2 (Paused)
    polybar-msg action "#dunst.hook.2"
else
    COUNT=$(dunstctl count displayed)
    if [ "$COUNT" -gt 0 ]; then
        # Kirim hook 1 (Ada notif) - count akan diambil langsung oleh hook
        polybar-msg action "#dunst.hook.1"
    else
        # Kirim hook 0 (Kosong)
        polybar-msg action "#dunst.hook.0"
    fi
fi
