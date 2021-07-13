## RPi EEPROM

The Raspberry Pi 4 has an SPI-attached EEPROM (4MBits/512KB), which contains code to boot up the system and replaces bootcode.bin previously found in the boot partition of the SD card.
Note that if a bootcode.bin is present in the boot partition of the SD card in a Pi 4, it is ignored.
We are modyfing eeprom configuration with a purpose to change the boot order (network, sdcard, reboot)
More info: https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
           https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md
