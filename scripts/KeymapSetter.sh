#!/bin/bash
current="$1"
Maps=("dvorak" "dvp" "us")
echo "$current"
if [[ "${Maps[current]}" == "us" ]]; then
	setxkbmap us
else
	setxkbmap us -variant ${Maps[current]}
fi
echo $(( (current+1)%3 )) > ~/.config/scripts/currentkeymap
