day=$((($(date +%s) - $(date -d $(sed -n '/upgrade$/x;${x;s/.\([0-9-]*\).*/\1/p}' /var/log/pacman.log) +%s)) / 86400))
echo "${day}d since upd"
