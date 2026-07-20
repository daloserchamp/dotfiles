#!/bin/bash
current=$(cat ~/.config/scripts/currentkeymap)
Maps=("dvorak" "dvp" "us")

if [[ "${Maps[current]}" == "us" ]]; then
	setxkbmap us
else
	setxkbmap us -variant ${Maps[current]}
fi
echo $(( (current+1)%3 )) > ~/.config/scripts/currentkeymap
