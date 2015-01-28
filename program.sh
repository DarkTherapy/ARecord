#!/bin/bash

# set a var of $pin to save some typing later.
pin="/usr/local/bin/gpio"

# Set GPIO pin 5 as an input (button) and turn on its pull down resistor.
$pin mode 5 in
$pin mode 5 down

# Set GPIO pin 3 as an input for a power button.
$pin mode 3 in
$pin 3 down

# Set pins 4 and 6 as outputs (green and red LED's).
$pin mode 4 out #Green LED
$pin mode 6 out #Red LED

# Turn off both the LED's.
$pin write 4 0
$pin write 6 0

# Store the recording state, 0 = not recording.
RecordingState="0"

# clear the screen
clear

# Make a recordings folder (if there isn't one).
mkdir -p /root/ARecord/recordings

# Make sure the USB Sound card is detected!
# If it's not, blink the RED LED.
CheckUSB(){
USBstatus=$(lsusb | grep "Sound" | cut -d" " -f7)

if [ "$USBstatus" = "C-Media" ]
	then
		clear
		SYSTEM="GO"
		$pin write 6 0 #red off
		$pin write 4 1 #green on
	else
		SYSTEM="STOP"
		BlinkError
fi
}

# Blink the RED LED. And output error message. Then check the USB again.
BlinkError(){
clear
$pin 4 0 #green off
echo "[+] ERROR: No USB Sound Card Detected! [+]"

for i in `seq 1 10`;
	do
		$pin write 6 1 #red on
		sleep .1
		$pin write 6 0 #red off
		sleep .1
done
CheckUSB
}

# Record with Arecord to a recordings folder.
Record(){
clear
RecordingState="1"
$pin write 4 0
$pin write 6 1
screen -S record -d -m arecord -D plughw:0,0 -f dat -vv /root/ARecord/recordings/$(date -d "today" +"%Y%m%d%H%M")_Input.wav
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
						$pin write 6 0 #red off
						$pin write 4 1 #green on
						screen -S record -X stuff '^C'
						sleep 2
						RecordingState="0"
			elif [ "$(/usr/local/bin/gpio read 3)" = "1" ]
				then
					clear
					echo "[+ ]Shutting down NOW! [+]"
					for i in `seq 1 20`;
						do
							$pin write 6 1 #red on
							$pin write 4 0 #green off
							sleep .1
							$pin write 6 0 #red off
							$pin write 4 1 #green on
							sleep .1
						done
					$pin write 6 0 #red off
					$pin write 4 0 #green off
					halt
					SYSTEM="STOP"
		fi
	done
