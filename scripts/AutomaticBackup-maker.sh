#!bin/bash
dateee=$(date | awk '{print $2 "-" $3 "-" $4 "-" $7}')
mainfile=/dvs/dv1/Backup/AutomaticBackups/
file="${mainfile}${dateee}"
echo "installed packages (including AUR):" >> ${file}
(comm -23 <(pacman -Qqt | sort) <(pacman -Qqg base | sort)) | tr [:space:] " " >> ${file}