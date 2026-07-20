# !/bin/bash
WINDOWS=$(hyprctl activeworkspace -j | jq -r ".windows")
LAYOUT=$(hyprctl -j activeworkspace | jq -r '.tiledLayout')

if [[ "$LAYOUT" == "master" ]]; then
	LAYOUT="m"
	echo "$LAYOUT[$WINDOWS]"
else
	LAYOUT="M"
	echo "$LAYOUT{$WINDOWS}"
fi

