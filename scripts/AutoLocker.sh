zenity --question --text="Time to read. You have 3 minutes lol" --ok-label "Alrighty" --cancel-label "NOO gimme 5 minutes"
answ=$?
if [ $answ -eq 0 ]; then
	sleep 180
elif [ "$answ" -eq 1 ]; then
	sleep 300
fi

