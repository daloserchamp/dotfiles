# !/bin/bash
WINDOWS=$(hyprctl activeworkspace -j | jq -r ".windows")
LAYOUT=$(hyprctl -j activeworkspace | jq -r '.tiledLayout')
CURRENTMONITOR=$(hyprctl -j activeworkspace | jq -r '.monitorID')
ADDEDTOMONITOR=$((CURRENTMONITOR + 1))

if [[ "$LAYOUT" == "master" ]]; then
	LAYOUT="m"
	echo "$LAYOUT$ADDEDTOMONITOR[$WINDOWS]"
else
	LAYOUT="M"
	echo "$LAYOUT$ADDEDTOMONITOR{$WINDOWS}"
fi

