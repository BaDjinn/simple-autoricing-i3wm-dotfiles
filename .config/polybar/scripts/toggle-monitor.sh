#!/bin/bash

# Toggle dengan redirect output
if eww active-windows | grep -q "performance_monitor"; then
    eww close performance_monitor > /dev/null 2>&1
else
    eww open performance_monitor > /dev/null 2>&1
fi
