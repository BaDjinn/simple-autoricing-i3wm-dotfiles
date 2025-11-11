#!/bin/bash

# Toggle dengan redirect output
if eww active-windows | grep -q "control_center_window"; then
    eww close control_center_window > /dev/null 2>&1
else
    eww open control_center_window > /dev/null 2>&1
fi
