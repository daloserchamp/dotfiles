#!/bin/bash
killall -q polybar
killall -q picom
picom --config ~/art/git/dotfiles/dwm/dwmpicom.conf &
xrandr --output HDMI-0 --mode 1920x1080 --rate 90
xrandr --output DP-4 --mode 1920x1080 --rate 90
xrandr --output DP-0 --mode 1920x1080 --rate 90
xrandr --output XXXX --primary
xset m 00
xset r rate 250 25
feh --bg-scale ~/.config/qtile/Wallpapers/ColoradoMountains.jpg
setxkbmap us -variant dvorak
