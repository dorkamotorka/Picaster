# Netboot Raspberry Pi from Raspberry Pi

This was tested with 2x Raspberry Pi 4 (2GB).
I also used a RPi touchscreen at the last stage to ease the debugging of boot process.

Make sure you are using 32GB SD card on RPi Netboot Server. It will make sense later on.

## On the RPi Netboot Client

### Install a RaspberryPi OS onto an SDCard.

### Boot the Rpi4 with the Raspberry OS SDCard, login and run the following to enable ssh (Test the ssh connection, which will also generate a ssh-key neccesery for the next step):

	cd /boot
	touch ssh
	reboot

### Update & Upgrade Pi & Install optional packages

	sudo apt update && sudo apt upgrade -y
	sudo apt install vim

#### NOTE: If you don't have a display, keyboard and a mouse to plug into Pi it is better to add the ssh file already after writing the image to the SD card on PC, otherwise you won't be able to ssh into the Pi. Just open up a folder PI_BOOT(has also other boot files like start.elf etc.) on SD Card and add an empty file named ssh.

### Update the boot loader on the RPi

	wget https://github.com/raspberrypi/rpi-eeprom/raw/master/firmware/stable/pieeprom-2021-04-29.bin
	sudo rpi-eeprom-config pieeprom-2021-04-29.bin > bootconf.txt
#### NOTE: You might want to ensure the firmware version if this post gets old.

Add to the bottom of bootconf.txt:

	BOOT_ORDER=0xf12
	MAX_RESTARTS=5

Then to apply new config, type:

	sudo rpi-eeprom-config --out pieeprom-2021-04-29-netboot.bin --config bootconf.txt pieeprom-2021-04-29.bin
	sudo rpi-eeprom-update -d -f ./pieeprom-2021-04-29-netboot.bin

Before rebooting write down the serial number of the Pi, you get by typing (excluding the 0 in front):

	grep Serial /proc/cpuinfo | cut -d ' ' -f 2 | cut -c 8-16

Reboot Pi and remove the SD card:

	sudo reboot

### Your RPi will now have been rebooted and will be pinging your network for the DHCP response. Both Read and Green LED should Ilumminate and persist ON without blinking.
In order to make sure Netboot client is pinging the network, type on any device connected to the same local network:

	sudo tcpdump -i <network-interface> port bootpc
e.g.
	sudo tcpdump -i eth0 port bootpc # On my RPi Netboot Server
	sudo tcpdump -i wlp4s0 port bootpc # On my PC

and you should be seeing something like:
	
	12:17:24.974995 IP 0.0.0.0.bootpc > 255.255.255.255.bootps: BOOTP/DHCP, Request from dc:a6:32:60:56:7d (oui Unknown), length 322

#### NOTE: If your Pi does not boot it is possible that something went wrong during the boot process. Green LED should help you troubleshoot the situation: https://www.raspberrypi.org/documentation/configuration/led_blink_warnings.md

## On RPi Netboot Server

### Install Ubuntu 20.04 onto the SD Card, plug it into your Pi and boot it up

### Do an

	sudo apt update -y 
	sudo apt upgrade -y

setup your password, install some packages etc.

### Since I will be using the same OS for Netboot client as I am using on the Netboot server I will copy file system of the Netboot Server to a folder, do some configuration and share it to the client.
In order to do so, mount the drive(the second partition of the SD Card plug into the Netboot Server). If your server is RPi, SD Card will most likely be recognized as mmcblk0. 
If that is the case type:

	sudo mkdir /mnt/Ubuntu20.04 # Creates a mounting directory
	sudo mount /dev/mmcblk0p2 /mnt/Ubuntu20.04/ # Mount second partition the the directory
	
Then copy the OS files from partition 2(if above executed this should be in /mnt/Ubuntu20.04), to your nfs location for sharing the root to the PI:

	sudo mkdir -p /srv/nfs/<RANDOM-NAME>
	sudo cp -r /mnt/Ubuntu20.04/* /srv/nfs/<RANDOM-NAME>

#### NOTE: Since you are almost copying the whole file systems which will double the occupied storage space on the SD card, make sure you have sufficient space available. I used a 32GB SD Card, while with 16GB SD card I got out of space.

After you are done copying clean up with:

	sudo umount /mnt/Ubuntu20.04
	sudo rm -rf /mnt/Ubuntu20.04


- Additionaly you need to reconfigure SSH for the Netboot client

	cd <NETBOOT-CLIENT-ROOT-FS>
	sudo chroot . rm /etc/ssh/ssh_host_*
	sudo chroot . dpkg-reconfigure openssh-server
	sudo chroot . systemctl enable ssh
	
### In order to boot a remote client we need to share the boot files with it once requested. This is done with Trivial File Transfer Protocol (TFTP).
Mount the /boot folder of the RPi files (stored in the NFS share) to your TFTP location so your TFTP can serve up the boot files
- Create a TFTP directory

	sudo mkdir /srv/tftpboot/<RANDOM-NAME>

- And add to the /etc/fstab at the bottom:

	/srv/nfs/<RANDOM-NAME>/boot /srv/tftpboot/<RANDOM-NAME> none defaults,bind 0 0

Then mount the new location with:
	
	sudo mount -a

Now any change that will be done in /srv/nfs/<RANDOM-NAME>/boot will also apply to /srv/tftpboot/<RANDOM-NAME>. 
This will serve /srv/nfs/<RANDOM-NAME>/boot through the /srv/tftpboot/<RANDOM-NAME> which will enable the Pi to boot up (sends boot related files). 
We still have to load the OS somehow.

#### NOTE: The /nfs/<RANDOM-NAME> directory will be the root of the file system for your client Raspberry Pi. If you add more Pis you will need to add more client directories. The /tftpboot directory will be used by all your netbooting Pis. It contains the bootloader and files needed to boot the system. Additionaly NFS Client already requires to be up ("bootloaded") and during the steps here we will also tell where we tell the client during the boot process how to find the (nfs)root file system.

### Extract your vmlinuz on the boot folder of your nfs share into vmlinux as the Receiving Pi wont decompress the vmlinuz kernel

	zcat /srv/nfs/<RANDOM-NAME>/boot/vmlinuz > /src/nfs/<RANDOM-NAME>/boot/vmlinux

### Create symlinks inside the /srv/nfs/<RANDOM-NAME>/boot partition to point to the bcm2711-rpi-4-b.dtb, start4.elf, fixup4.dat files which are missing in the boot folder for the TFTP to find them in the dtb and firmware folders
This might change overtime and Netboot client will need some other files. The boot log (sudo tail -F /var/log/*.log) will tell you later on what is missing - just make sure it is looking for the following files in the right folder.

	sudo cp /boot/firmware/fixup4.dat /boot/firmware/start4.elf /boot/firmware/syscfg.txt /boot/firmware/usercfg.txt /srv/nfs/netboot_ubuntu_20_04/boot/firmware
	sudo ln -s firmware/syscfg.txt syscfg.txt
	sudo ln -s firmware/usercfg.txt usercfg.txt
	sudo ln -s firmware/fixup4.dat fixup4.dat
	sudo ln -s firmware/start4.elf start4.elf
	sudo ln -s dtbs/5.4.0-1038-raspi/bcm2711-rpi-4-b.dtb bcm2711-rpi-4-b.dtb

### Update some configs in the /srv/nfs/<RANDOM-NAME>/boot partition:

- Modify /srv/nfs/<RANDOM-NAME>/boot/config.txt, which is a configuration file instead of BIOS in an old PC that initializes hardware, does preliminary system test and configures it according to values specified: 

	[pi4]
	max_framebuffers=2

	[all]
	arm_64bit=1
	device_tree_address=0x03000000
	enable_uart=1
	cmdline=cmdline.txt
	include syscfg.txt
	include usercfg.txt
	kernel=vmlinux-5.4.0-1038-raspi
	initramfs initrd.img-5.4.0-1038-raspi followkernel

Double check values in this file correspond to your files (In most cases it needs modification).

- Modify /srv/nfs/boot/<serial>/cmdline.txt, which is a command line Linux kernel accepts during boot. 
NOTE: If you mess up this file, your Pi won't be able to boot!

	net.ifnames=0 dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 nfsrootdebug elevator=deadline rootwait fixrtc init=initrd.img ip=dhcp rootfstype=nfs4 root=/dev/nfs nfsroot=<NETBOOT-SERVER-IP>:/srv/nfs/<RANDOM-NAME>,vers=4.1,proto=tcp rw

### Update the fstab - this is the fstab which is sent to the Netbooted Pi and on the boot mounts the nfs file system from the NFS Server

- /srv/nfs/<RANDOM-NAME>/etc/fstab

	<NETBOOT-SERVER-IP>:/srv/nfs/<RANDOM-NAME> /       nfs4     defaults,rw,nolock,proto=tcp,vers=4.1             0       0 # data to be shared to server

14) Up to this stage we did a neccesary configuration that will send boot files to the Netboot client, but in order for the client to be fully-functional we also need to serve the rootfile system.
In order to do so, install an NFS server on the RPi Netboot Server:

	sudo apt install nfs-common nfs-kernel-server

and add to /etc/exports:

	/srv/nfs/<RANDOM-NAME> *(insecure,rw,async,no_root_squash)

then type in terminal:	
	
	sudo exportfs -ra # More on this command can be find here: https://linux.die.net/man/8/exportfs
	sudo systemctl enable nfs-kernel-server
	sudo systemctl restart nfs-kernel-server

### In order to send the boot files and file system we now need to modify the dnsmasq configuration to enable DHCP to reply to the device (when it is pinging the network for a DHCP response in step 3).
Install a dnsmasq server to serve up the dhcp options and tftp the boot images

	sudo apt install dnsmasq

then we need to figure out what is the broadcast address of our local network. We do that by typing:
	ip -4 addr show dev eth0 | grep inet	

which should give an output like:

	inet 192.168.50.70/24 **brd 192.168.50.255** scope global dynamic eth0

where the first address is the current device IP and the second IP is the broadcast address.
A broadcast address is an IP address that is used to target all systems on a specific subnet network instead of single host.

and modify /etc/dnsmasq.conf:

	dhcp-range=<BROADCAST-ADDRESS>,proxy
	log-dhcp
	enable-tftp
	tftp-root=/srv/tftpboot
	pxe-service=0,"Raspberry Pi Boot"
	log-facility=/var/log/dnsmasq.log

### Now if you restart dnsmasq service you should be seeing netboot log by typing:

	sudo systemctl enable dnsmasq.service
	sudo systemctl restart dnsmasq.service
	sudo tail -F /var/log/dnsmasq.log # Log file you specified in /etc/dnsmasq.conf

Also see stats from the NFS Server:

	sudo nfsstat

### If you successfully netboot-ed Raspberry Pi you will see output of above command tail, like:

	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 tags: eth0
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 broadcast response
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 sent size:  1 option: 53 message-type  2
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 sent size:  4 option: 54 server-identifier  192.168.50.70
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 sent size:  9 option: 60 vendor-class  50:58:45:43:6c:69:65:6e:74
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 sent size: 17 option: 97 client-machine-id  00:52:50:69:34:11:31:a0:00:32:2e:f8:ed:10...
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 sent size: 32 option: 43 vendor-encap  06:01:03:0a:04:00:50:58:45:09:14:00:00:11...
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:48:56 dnsmasq-dhcp[4322]: 1795937487 vendor class: PXEClient:Arch:00000:UNDI:002001
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/5b154510/start4.elf not found
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/5b154510/start.elf not found
	Jul  6 05:48:56 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/config.txt to 192.168.50.12
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/vl805.sig not found
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/pieeprom.sig not found
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/recover4.elf not found
	Jul  6 05:48:56 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/recovery.elf not found
	Jul  6 05:48:57 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/start4.elf to 192.168.50.12
	Jul  6 05:48:57 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/fixup4.dat to 192.168.50.12
	Jul  6 05:48:58 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/recovery.elf not found
	Jul  6 05:48:58 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/config.txt to 192.168.50.12
	Jul  6 05:48:58 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/syscfg.txt to 192.168.50.12
	Jul  6 05:48:58 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/usercfg.txt to 192.168.50.12
	Jul  6 05:48:58 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/dt-blob.bin not found
	Jul  6 05:48:59 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/recovery.elf not found
	Jul  6 05:48:59 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/config.txt to 192.168.50.12
	Jul  6 05:48:59 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/syscfg.txt to 192.168.50.12
	Jul  6 05:48:59 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/usercfg.txt to 192.168.50.12
	Jul  6 05:48:59 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/bootcfg.txt not found
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/initrd.img-5.4.0-1038-raspi to 192.168.50.12
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/bcm2711-rpi-4-b.dtb to 192.168.50.12
	Jul  6 05:49:06 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/overlays/overlay_map.dtb not found
	Jul  6 05:49:06 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/overlays/rpi-ft5406.dtbo not found
	Jul  6 05:49:06 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/overlays/rpi-backlight.dtbo not found
	Jul  6 05:49:06 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/overlays/rpi-poe.dtbo not found
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/config.txt to 192.168.50.12
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/syscfg.txt to 192.168.50.12
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/usercfg.txt to 192.168.50.12
	Jul  6 05:49:06 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/cmdline.txt to 192.168.50.12
	Jul  6 05:49:07 dnsmasq-tftp[4322]: error 0 Early terminate received from 192.168.50.12
	Jul  6 05:49:07 dnsmasq-tftp[4322]: failed sending /srv/tftpboot/netboot_ubuntu_20_04/vmlinux to 192.168.50.12
	Jul  6 05:49:07 dnsmasq-tftp[4322]: file /srv/tftpboot/netboot_ubuntu_20_04/armstub8-gic.bin not found
	Jul  6 05:49:13 dnsmasq-tftp[4322]: sent /srv/tftpboot/netboot_ubuntu_20_04/vmlinux to 192.168.50.12
	Jul  6 05:49:22 dnsmasq-dhcp[4322]: 1465857268 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:49:22 dnsmasq-dhcp[4322]: 1465857268 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:49:26 dnsmasq-dhcp[4322]: 2015619180 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:49:26 dnsmasq-dhcp[4322]: 2015619180 client provides name: 192.168.50.12
	Jul  6 05:49:26 dnsmasq-dhcp[4322]: 2015619180 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:49:26 dnsmasq-dhcp[4322]: 2015619180 client provides name: 192.168.50.12
	Jul  6 05:50:58 dnsmasq-dhcp[4322]: 2218240843 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:50:58 dnsmasq-dhcp[4322]: 2218240843 client provides name: ubuntu
	Jul  6 05:50:58 dnsmasq-dhcp[4322]: 2218240843 available DHCP subnet: 192.168.50.255/255.255.255.0
	Jul  6 05:50:58 dnsmasq-dhcp[4322]: 2218240843 client provides name: ubuntu

I don't know why it fails to sent some of the files and in the next try succeeds to do so, but important is that relevant files gets transferred and that you use that client provides back the IP and the hostname. Now you can SSH into the client.

#### NOTE: This post is regularly updated, make sure you use it on your on resposiblity.
