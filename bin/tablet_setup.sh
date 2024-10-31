#!/bin/bash
# to find the stylus ID - use the command
# xsetwacom --list
#
# to find the monitor use the command
# xrandr
# use this command to map the stylus to a specific monitor
xsetwacom set 15  MapToOutput 2560x1440+5120+0
(/usr/bin/gromit-mpx >/dev/null 2>&1 &)
