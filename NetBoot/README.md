The following guide gave me a good start: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net_tutorial.md

dnsmasq service failed to run: https://askubuntu.com/questions/191226/dnsmasq-failed-to-create-listening-socket-for-port-53-address-already-in-use
# Enable the service systemd-resolved back on when you get dnsmasq service running, otherwise the apt update won't work

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
	

1) Install a RaspberryPi OS onto an SDCard.

2) Boot the Rpi4 with the Raspberry OS SDCard, login and run the following to enable ssh (Test the ssh connection, which will also generate a ssh-key neccesery for the next step):

	cd /boot
	touch ssh
	reboot

*) update and upgrade Pi

	sudo apt update && sudo apt upgrade

NOTE: If you don't have a display, keyboard and a mouse to plug into Pi it is better to add the ssh file already after writing the image to the SD card on PC, otherwise you won't be able to ssh into the Pi.

3) Update the boot loader on the RPi, from another machine. If you know the IP address of the PI and you enabled ssh (above), script /scripts/update-bootloader.sh will set the boot code to 0xf12 which means it will try the network, sdcard, reboot in that order over and over. 
You might want to ensure the firmware version if this post gets old.
Make sure you have previously SSH to the Pi from the machine you are running this script.

	sudo ./update-bootloader.sh <ip-address-of-the-pi> <ip-address-of-your-nfs-server>

Your RPi will now have been rebooted and will be pinging your network for the DHCP response. Both Read and Green LED should Ilumminate and persist ON.
In order to make sure Netboot client is pinging the network, type on any device connected to the same local network:

	sudo tcpdump -i eth0 port bootpc # On my RPi Netboot Server
	sudo tcpdump -i wlp4s0 port bootpc # On my PC

and you should be seeing something like:
	
	12:17:24.974995 IP 0.0.0.0.bootpc > 255.255.255.255.bootps: BOOTP/DHCP, Request from dc:a6:32:60:56:7d (oui Unknown), length 322

If your Pi does not boot it is possible that something went wrong during the boot process. 
Green LED should help you troubleshoot the situation: https://www.raspberrypi.org/documentation/configuration/led_blink_warnings.md

4) Install Ubuntu 20.04 onto the SD Card

5) Plug the SDCard into your Pi and boot it up

6) Do an

	apt update -y; apt upgrade -y

setup your pass, install some packages etc.

7) shutdown the pi

	halt -p


On your server

8) Take the Ubuntu 20.04.1 installed SDCard, plug it into your server, mount the drive(the second partition). If your server is another RPi, SD Card will most likely be recognized as mmcblk0. 
If that is the case type:

	sudo mkdir /mnt/Ubuntu20.04 # Creates a mounting directory
	sudo mount /dev/mmcblk0p2 /mnt/Ubuntu20.04/ # Mount second partition the the directory
	
Then copy the OS files from partition 2(if above executed this should be in /mnt/Ubuntu20.04), to your nfs location for sharing the root to the PI (probably /srv/nfs/<some-name>/):

	sudo mkdir -p /srv/nfs/<some-name>
	sudo cp -r /mnt/Ubuntu20.04/* /srv/nfs/<some-name>

After you are done copying clean up with:

	sudo umount /mnt/Ubuntu20.04
	sudo rm -rf /mnt/Ubuntu20.04

9) Mount the boot folder of the RPi files (stored in the NFS share) to your TFTP location so your TFTP can serve up the boot files, I'm using a PI here to serve the other PIs so edit as needed)
- Create a TFTP directory

	sudo mkdir /srv/tftpboot/<some-name>

- And add to the /etc/fstab at the bottom:

	/srv/nfs/<some-name>/boot /srv/tftpboot/<some-name> none defaults,bind 0 0

Then mount the new location with:
	
	sudo mount -a

10) Extract your vmlinuz on the boot folder of your nfs share into vmlinux as the Receiving Pi wont decompress the vmlinuz kernel

	zcat /srv/nfs/<some-name>/boot/vmlinuz > /src/nfs/<some-name>/boot/vmlinux

11) Create symlinks inside the /srv/nfs/<some-name>/boot partition to point to the bcm2711-rpi-4-b.dtb, start4.elf, fixup4.dat files which are missing in the boot folder for the TFTP to find them in the dtb and firmware folders

	sudo cp /boot/firmware/fixup4.dat /boot/firmware/start4.elf /boot/firmware/syscfg.txt /boot/firmware/usercfg.txt /srv/nfs/netboot_ubuntu_20_04/boot/firmware
	sudo ln -s firmware/syscfg.txt syscfg.txt
	sudo ln -s firmware/usercfg.txt usercfg.txt
	sudo ln -s firmware/fixup4.dat fixup4.dat
	sudo ln -s firmware/start4.elf start4.elf
	sudo ln -s dtbs/5.4.0-1038-raspi/bcm2711-rpi-4-b.dtb bcm2711-rpi-4-b.dtb

12) update some configs in the /srv/nfs/<some-name>/boot partition

#/srv/nfs/<some-name>/boot/config.txt

	[pi4]
	max_framebuffers=2

	[all]
	arm_64bit=1
	device_tree_address=0x03000000
	enable_uart=1
	cmdline=cmdline.txt
	include syscfg.txt
	include usercfg.txt
	kernel=vmlinux-5.4.0-1016-raspi
	initramfs initrd.img-5.4.0-1016-raspi followkernel
	#/srv/nfs/<serial>/boot/cmdline.txt
	net.ifnames=0 dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 nfsrootdebug elevator=deadline rootwait fixrtc init=initrd.img ip=dhcp rootfstype=nfs4 root=/dev/nfs nfsroot=<nfs ip>:/srv/nfs/<some-name> rw

13) Update the fstab - this is the fstab which is sent to the Netbooted Pi

	#/srv/nfs/<some-name>/etc/fstab
	proc            /proc           proc    defaults        0       0
	<nfs ip>:/srv/nfs/<some-name> /       nfs4     defaults,rw,nolock             0       0 # data to be shared to server
	<nfs ip>:/srv/nfs/<some-name>/boot/firmware /boot/firmware       nfs4     defaults,rw,nolock             0       1 # data to be shared to server
	none            /tmp            tmpfs   defaults        0       0
	none            /var/run        tmpfs   defaults        0       0
	none            /var/lock       tmpfs   defaults        0       0
	none            /var/tmp        tmpfs   defaults        0       0

14) Install an NFS server to serve the Pi

	sudo apt install nfs-common nfs-kernel-server

and add to /etc/exports:

	/srv/nfs/<some-name> *(insecure,rw,async,no_root_squash)

then type in terminal:	
	
	sudo exportfs -ra
	sudo systemctl enable nfs-kernel-server
	sudo systemctl restart nfs-kernel-server

15) Now you need to modify the dnsmasq configuration to enable DHCP to reply to the device (when it is pinging the network for a DHCP response in step 3).
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

16) Now if you restart dnsmasq service you should be seeing netboot log by typing:

	sudo systemctl enable dnsmasq.service
	sudo systemctl restart dnsmasq.service
	tail -F /var/log/dnsmasq.log # Log file you specified in /etc/dnsmasq.conf

16) Clusters? You have more than one Pi? You can use an overlayfs mount on your server to provide multiple Pis their operating system using a single base root file system and then using overlays to give each Pi its own space for storage and FS modifications.

If you got this far then this should be easy:

On your proper server - not a pi

17) Create mounts for overlay fs based mounts so we can use the root fs as a lower dir (google overlayfs)

	#/etc/fstab

	overlay /srv/nfs/6b0bb1f6 overlay defaults,lowerdir=/srv/nfs/ubuntu-rpi4-lower,upperdir=/srv/nfs/6b0bb1f6-upper,workdir=/srv/nfs/6b0bb1f6-work,nfs_export=on,index=on 0 0
	overlay /srv/nfs/68e71308 overlay defaults,lowerdir=/srv/nfs/ubuntu-rpi4-lower,upperdir=/srv/nfs/68e71308-upper,workdir=/srv/nfs/68e71308-work,nfs_export=on,index=on 0 0

18) Create the FS system to support the overlays, mine looks like this for 3 pis.

	# this is inside /srv/nfs

	drwxr-xr-x  1 root root 4096 Sep  7 12:47 68e71308
	drwxr-xr-x  3 root root 4096 Sep  7 12:47 68e71308-upper
	drwxr-xr-x  3 root root 4096 Sep  7 13:25 68e71308-work
	drwxr-xr-x  1 root root 4096 Sep  7 12:13 6b0bb1f6
	drwxr-xr-x  2 root root 4096 Sep  7 12:13 6b0bb1f6-upper
	drwxr-xr-x  4 root root 4096 Sep  7 13:25 6b0bb1f6-work
	drwxr-xr-x  1 root root 4096 Sep  7 12:47 917c9833
	drwxr-xr-x  2 root root 4096 Sep  7 11:49 917c9833-upper
	drwxr-xr-x  2 root root 4096 Sep  7 11:34 917c9833-work
	drwxr-xr-x 21 root root 4096 Sep  6 19:58 ubuntu-rpi4-lower

19) You need to put an /etc/fstab inside the merged folder for the mount (not the upper or work dirs, just the plain serial named one), which will override the ubuntu-rpi4-lower provided ones. Google fusefs or overlayfs for more info, (it's how docker containers work don't ya know :)

20) Create a cmdline.txt inside each merged folder inside /srv/nfs/<serial>/boot/cmdline.txt

21) Export the merged folders over nfs so ours pis can use them as before:

	#/etc/exports
	/srv/nfs/6b0bb1f6 *(rw,sync,no_subtree_check,no_root_squash,fsid=1)
	/srv/nfs/917c9833 *(rw,sync,no_subtree_check,no_root_squash,fsid=2)
	/srv/nfs/68e71308 *(rw,sync,no_subtree_check,no_root_squash,fsid=3)
	exportfs -ra

22) Adding a new Pi is then just a case:

22.0) Update the boot loader

22.1 Creating three empty folders on the server

	mkdir /srv/nfs/<serial>
	mkdir /srv/nfs/<serial>-work
	mkdir /srv/nfs/<serial>-upper

22.2) Adding an fstab with the mount options for the new serial and upper/work dirs

22.3) Adding an cmdline.txt with the right NFS location

23) Uber automation If you want you can create a hook script inside the initrd of your RaspberryPi SD card which updates the bootloader for you and pings a web server with its serial which then will add the mounts by the time the Pi has rebooted itself, its already booting off the network. Ill provide that at some point.
