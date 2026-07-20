# !/bin/sh
if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
	SDL_VIDEODRIVER=x11 "/opt/ue$1/Engine/Binaries/Linux/UnrealEditor"
else
	"/opt/ue$1/Engine/Binaries/Linux/UnrealEditor"
fi
