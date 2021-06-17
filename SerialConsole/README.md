# Serial Console 

The goal of this task was to retreive boot log from Raspberry Pi through the UART to USB converter to my PC.
Turned out to be harder than I thought. 

## Hardware used

I tested with both Raspberry Pi 4B and 3B+.

## Some Terminology

- /boot/config.txt: https://www.raspberrypi.org/documentation/configuration/config-txt/
- /boot/cmdline.txt: https://www.raspberrypi.org/documentation/configuration/cmdline-txt.md
- ‘splash’ : enables splash image
- ‘quiet’ : disable boot message texts
- ‘plymouth.ignore-serial-consoles’ : not sure about this but seems it’s required when use Plymouth.
- ‘logo.nologo’ : removes Raspberry Pi logo in top left corner.
- ‘vt.global_cursor_default=0’ : removes blinking cursor.

## Boot/Kernel Hacking

- I added to /boot/config.txt

		enable_uart=1 #(which does multiple other settings, more: https://www.raspberrypi.org/documentation/configuration/uart.md)
	
- I added to /boot/cmdline.txt

		console=tty1 # Quite spooky, since the number depends upon how many terminal session you have open on the RPi
		console=ttyAMA0,115200
		logo.nologo
		vt.global_cursor_default=0
	
- I removed from /boot/cmdline.txt

		quiet # Supresses kernel log on boot
		plymouth.ignore-serial-consoles

## Final files

At the ed both files looked like:

### Copy of /boot/config.txt

	disable_overscan=1
	start_x=1
	gpu_mem=128
	init_uart_baud=38400 #(wtf?) - This overrided default 115200 baudrate(Nevertheless I was listening with 115200 baudrate)
	boot_delay=2
	dtparam=i2c_arm=on
	enable_uart=1
	dtoverlay=i2c-rtc,mcp7940x

### Copy of /boot/config.txt

	dwc_otg.lpm_enable=0 console=tty1 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait logo.nologo splash net.ifnames=0 biosdevname=0 usbhid.mousepoll=0 vt.global_cursor_default=0

## Listening on computer with:

	sudo screen /dev/ttyUSB0 115200

## NOTE:

I only get uncorrupted data on the first output to the serial console. All consequent are garbaged unfortunately.


# TODO: Try flushing the serial port

# Debug

To get baudrate on the serial port write to command line:

	sudo stty -F /dev/ttyUSB0 speed
