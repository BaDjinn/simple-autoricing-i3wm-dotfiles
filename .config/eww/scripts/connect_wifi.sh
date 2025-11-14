#!/bin/bash

# Usage: ./connect_wifi.sh "SSID" ["password"]

SSID="$1"
PASSWORD="$2"

if [ -z "$SSID" ]; then
    notify-send "WiFi Error" "No SSID provided"
    exit 1
fi

# Check if network is already known
KNOWN=$(nmcli -t -f NAME connection show | grep "^${SSID}$")

if [ -n "$KNOWN" ]; then
    # Network is known, just connect
    if nmcli connection up "$SSID" 2>/dev/null; then
        notify-send "WiFi Connected" "Connected to $SSID"
        exit 0
    else
        notify-send "WiFi Error" "Failed to connect to $SSID"
        exit 1
    fi
fi

# New network, need password
if [ -z "$PASSWORD" ]; then
    # Prompt for password using rofi or zenity
  if command -v rofi &> /dev/null; then
        PASSWORD=$(rofi -dmenu -password \
            -p " $SSID" \
            -theme ~/.config/rofi/wifi-password.rasi \
            -mesg "Enter WiFi Password")
    elif command -v zenity &> /dev/null; then
        PASSWORD=$(zenity --password --title="WiFi Password" --text="Enter password for $SSID:")
    else
        notify-send "WiFi Error" "No password input method available (install rofi or zenity)"
        exit 1
    fi
    
    # Check if user cancelled
    if [ -z "$PASSWORD" ]; then
        exit 1
    fi
fi

# Connect to new network
if nmcli device wifi connect "$SSID" password "$PASSWORD" 2>/dev/null; then
    notify-send "WiFi Connected" "Successfully connected to $SSID"
    exit 0
else
    notify-send "WiFi Error" "Failed to connect to $SSID. Check password."
    exit 1
fi
