#!/bin/bash

# Set GPIO pin 5 as an input (button) and turn on its pull down resistor.
/usr/local/bin/gpio mode 5 in
/usr/local/bin/gpio mode 5 down

/usr/local/bin/gpio mode 3 in
/usr/local/bin/gpio mode 3 down

# Set pins 4 and 6 as outputs (green and red LED's).
/usr/local/bin/gpio mode 4 out
/usr/local/bin/gpio mode 6 out

# Turn off the LED's.
/usr/local/bin/gpio write 4 0
/usr/local/bin/gpio write 6 0

# Store the recording boolean
RecordingState="0"

# clear the screen
clear

# Check to make sure the USB Sound card is detected!
# If it's not, blink the RED LED.
CheckUSB(){
USBstatus=$(lsusb | grep "Sound" | cut -d":" -f3)

if [ "$USBstatus" = "" ]
	then
		SYSTEM="STOP"
		BlinkError
	else
		clear
		echo "[+] USB Sound Card Detected! [+]"
		SYSTEM="GO"
		/usr/local/bin/gpio write 6 0 #red off
		/usr/local/bin/gpio write 4 1 #green on
		sleep 1
fi
}

# Blink the RED LED. And output error message. Then check the USB again.
BlinkError(){
clear
/usr/local/bin/gpio write 4 0 #green off
echo "[+] ERROR: No USB Sound Card Detected! [+]"

for i in `seq 1 10`;
	do
		/usr/local/bin/gpio write 6 1 #red on
		sleep .1
		/usr/local/bin/gpio write 6 0 #red off
		sleep .1
done
CheckUSB
}

Record(){
clear
RecordingState="1"
/usr/local/bin/gpio write 4 0
/usr/local/bin/gpio write 6 1
screen -S record -d -m arecord -D plughw:0,0 -f cdr -vv /root/recordings/$(date -d "today" +"%Y%m%d%H%M")_Input.mp3
sleep 2
}

CheckUSB

while [ $SYSTEM = "GO" ]
	do
		clear
		if [ $RecordingState = "1" ]
			then
				echo "[+] RECORDING! [+]"
				echo ""
			else
				echo "[+] Not Recording [+]"
		fi

		echo "[+] Waiting for a button press.. [+]"
		if [ "$(/usr/local/bin/gpio read 5)" = "1" ] && [ $RecordingState = "0" ]
			then
				sleep .5
				Record
			elif [ "$(/usr/local/bin/gpio read 5)" = "1" ] && [ $RecordingState = "1" ]
				then
						sleep 1
						/usr/local/bin/gpio write 6 0 #red off
						/usr/local/bin/gpio write 4 1 #green on
						screen -S record -X stuff '^C'
						sleep 2
						RecordingState="0"
			elif [ "$(/usr/local/bin/gpio read 3)" = "1" ]
				then
					clear
					echo "[+ ]Shutting down NOW! [+]"
					/usr/local/bin/gpio write 4 0 #green off
					for i in `seq 1 10`;
						do
							/usr/local/bin/gpio write 6 1 #red on
							/usr/local/bin/gpio write 4 0 #green off
							sleep .1
							/usr/local/bin/gpio write 6 0 #red off
							/usr/local/bin/gpio write 4 1 #green on
							sleep .1
					#done
							halt
							SYSTEM="STOP"
							done
		fi
done
