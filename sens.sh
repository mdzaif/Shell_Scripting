#!/bin/bash

cat /sys/class/thermal/thermal_zone*/type 2> /dev/null | cat /sys/class/thermal/thermal_zone*/temp 2> /dev/null | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/' 2>/dev/null


