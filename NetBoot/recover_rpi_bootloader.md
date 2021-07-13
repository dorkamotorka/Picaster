# Recovering RPi EEPROM after corrupt

First wipe out all files from the SD card and format it to FAT16 or FAT32.
The easiest way to do that is to do it with rpi-imager. First install it and then run it:

	sudo apt install rpi-imager
	rpi-imager

Then download the recovery file. I found recovery files here: 

	https://github.com/raspberrypi/rpi-eeprom/releases

Then extract the content of the zip folder to the SD card, plug into Pi and the Green LED should blink forever.
