#!/usr/bin/env bash

RPI_IP=$1
KICKSTART_IP=$2
RPI_DEFAULT_PASS="raspberry"
# NOTE: Other versions can be found here: https://github.com/raspberrypi/rpi-eeprom/tree/master/firmware/stable
PI_EEPROM_DATE="2021-04-29"
PI_EEPROM_VERSION="pieeprom-${PI_EEPROM_DATE}"
PI_EEPROM_FILE="${PI_EEPROM_VERSION}.bin"
PI_EEPROM_LINK="https://github.com/raspberrypi/rpi-eeprom/raw/master/firmware/stable/${PI_EEPROM_FILE}"
UBUNTU_IMAGE_NAME="ubuntu-20.04.1-preinstalled-server-arm64+raspi.img"
UBUNTU_IMAGE_FILE="${UBUNTU_IMAGE_NAME}.xz"
UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# NOTE: It is expected that you previously ssh into the Pi and therefore sshkey will already be stored on the same machine
echo ">> On remote"
ssh-keyscan -H ${RPI_IP} >> ~/.ssh/known_hosts
ssh -tt pi@${RPI_IP} << EOF
	if [[ -f ${PI_EEPROM_FILE} ]];then
	  rm ${PI_EEPROM_FILE}
	  echo '>> Removed eeprom file'
	fi

	rm *.rpi.env
	echo '>> Removed old env'

	rm bootconf.txt
	echo '>> Removed bootconf.txt'

	if [[ ! -f ${PI_EEPROM_FILE} ]];then
	  wget ${PI_EEPROM_LINK}
	fi

	echo ">> Extracting boot config from EEPROM"
	sudo rpi-eeprom-config ${PI_EEPROM_FILE} > bootconf.txt

	echo ">> Updating bootconfig"
	echo "MAX_RESTARTS=5" | sudo tee -a bootconf.txt
	echo "BOOT_ORDER=0xf12" | sudo tee -a bootconf.txt

	echo ">> Writing EEPROM"
	sudo rpi-eeprom-config --out ${PI_EEPROM_VERSION}-netboot.bin --config bootconf.txt ${PI_EEPROM_FILE}

	echo ">> Updating EEPROM on RPi"
	sudo rpi-eeprom-update -d -f ./${PI_EEPROM_VERSION}-netboot.bin

	echo ">> Getting Serial and MAC"
	cat /proc/cpuinfo | grep Serial | awk -F ': ' '{print \$2}' | tail -c 9 | awk '{print "RPI_SERIAL="\$1}' > ${UUID}.rpi.env
	ip addr show eth0 | grep ether | awk '{print \$2}' | awk '{print "RPI_MAC="\$1}' >> ${UUID}.rpi.env
EOF

ssh -tt pi@${RPI_IP} << EOF
	sudo reboot
EOF

echo ">> Script done!"
