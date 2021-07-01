# Custom EEPROM Raspberry Pi

## What does EEPROM do on a Raspberry Pi?

EEPROM on the Raspberry Pi 4 contains code(bootloader) to boot up the system or to state it differently bootloader is a software inside EEPROM that is responsible for booting a Raspberry Pi 4.
In the previous RPis bootloader code was in /boot/bootcode.bin which is ignored in RPi 4.

## What can I do with RPi EEPROM?

You can configure yourself an EEPROM and this way enable/disable UART debug output on GPIO 14 and 15,
modify boot order (boot from network before from SD card) etc.

More on possible configuration parameters: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md

## Create a Custom EEPROM Configuration

- Install bootloader from: https://github.com/raspberrypi/rpi-eeprom/tree/master/firmware onto a RPi

- Extract the bootloader configuration to a file: 

	sudo rpi-eeprom-config <PI-EEPROM-FILE> > bootconf.txt

- Modify the file, add new configuration parameters etc. (Watch link above)

- When you are done with the configuration, out of it create a new bootloader from your configuration applied to previously installed one

	sudo rpi-eeprom-config --out <NEW-PI-EEPROM-FILE>.bin --config bootconf.txt <PI-EEPROM-FILE> 

- Update EEPROM with the new configuration:

	sudo rpi-eeprom-update -d -f ./<NEW-PI-EEPROM-FILE>.bin

- Reboot the Pi

	sudo reboot

- Check that your configuration was applied with:

	rpi-eeprom-config

