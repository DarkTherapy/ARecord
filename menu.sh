#!/bin/bash

program=$(screen -ls | grep program | cut -d" " -f1 | cut -d"(" -f1)
x=$(screen -ls | grep mixer | cut -d" " -f1 | cut -d"(" -f1 | cut -d"." -f2)

if [ $x = "mixer" ]
	then
		clear
	else
		screen -S mixer -d -m alsamixer
fi

clear
echo ""
echo "		Rasperry Pi Audio Recorder Menu"
echo ""
echo "		1: Monitor Audio Program"
echo "		2: AlsaMixer"
echo "		5: Exit to shell"
echo ""
read answer

if [ $answer = "1" ]
	then
		screen -x $program
		/root/menu.sh
	elif [ $answer = "2" ]
		then
			screen -x $(screen -ls | grep mixer | cut -d" " -f1 | cut -d"(" -f1)
			alsactl store 1
			/root/menu.sh
	elif [ $answer = "5" ]
		then
			exit
fi

