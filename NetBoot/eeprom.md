## RPi EEPROM

The Raspberry Pi 4 has an SPI-attached EEPROM (4MBits/512KB), which contains code to boot up the system and replaces bootcode.bin previously found in the boot partition of the SD card.
Note that if a bootcode.bin is present in the boot partition of the SD card in a Pi 4, it is ignored.
We are modyfing eeprom configuration with a purpose to change the boot order (network, sdcard, reboot)
More info: https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
           https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md
           
## Recovering EEPROM after corrupt

First wipe out all files from the SD card:

        sudo dd if=/dev/zero of=/dev/<SD-CARD> bs=4096 status=progress (WARNING: dd command can destroy your PC disk if used wrong!)

Create the partition table with:

        sudo parted /dev/<SD-CARD> --script -- mklabel msdos

and create a FAT32 partition that takes the whole space:

        sudo parted /dev/<SD-CARD> --script -- mkpart primary fat32 1MiB 100%

Form the boot partition to FAT32:

        sudo mkfs.vfat -F32 /dev/<SD-CARD>1 (NOTE: 1 as first partition)
