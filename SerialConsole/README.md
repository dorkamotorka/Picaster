Adding console=ttyAMA0,115200 to /boot/cmdline.txt got me some nice data through serial. Also remove 'quiet'.

Set enable_uart=1 in /boot/confix.txt (this also sets core_freq=250 and other - check docs)


‘splash’ : enables splash image
‘quiet’ : disable boot message texts
‘plymouth.ignore-serial-consoles’ : not sure about this but seems it’s required when use Plymouth.
‘logo.nologo’ : removes Raspberry Pi logo in top left corner.
‘vt.global_cursor_default=0’ : removes blinking cursor.


# I got it working!

# I also synchronized RPi with my PC using chronyc:
I don't know if that helped but I know I did it.

On PC:

	sudo chronyc -a local stratum 10
	sudo chronyc -a allow 0/0

On RPi:
	sudo chronyc -a add server <LaptopHostname> iburst
	sudo chronyc -a burst 2/4

# Copy of /boot/config.txt

disable_overscan=1
start_x=1
gpu_mem=128
init_uart_baud=38400 (wtf?) - This overrided default 115200 baudrate(Nevertheless I was listening with 115200 baudrate)
boot_delay=2
dtparam=i2c_arm=on
enable_uart=1
dtoverlay=i2c-rtc,mcp7940x

# Copy of /boot/config.txt

dwc_otg.lpm_enable=0 console=tty1 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait logo.nologo splash net.ifnames=0 biosdevname=0 usbhid.mousepoll=0 vt.global_cursor_default=0

# Listening on computer with:

	sudo screen /dev/ttyUSB0 115200

# NOTE:

I only get uncorrupted data on the first output to the serial console. All consequent are garbaged unfortunately.


# TODO: Try flushing the serial port

# Debug

To get baudrate on the serial port write to command line:

	sudo stty -F /dev/ttyUSB0 speed
