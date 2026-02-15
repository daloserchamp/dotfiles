#!/bin/bash
killall -q polybar
killall -q picom
polybar example &
picom --config ~/.config/picom/picom.conf &
xrandr --output HDMI-0 --mode 1920x1080 --rate 90
xrandr --output DP-0 --mode 1920x1080 --rate 90
xrandr --output XXXX --primary
xset m 00
xset r rate 250 25
feh --bg-scale ~/.config/qtile/Wallpapers/ColoradoMountains.jpg
