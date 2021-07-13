# Netboot Multiple Pis

This guide assumes you followed first the netboot guide for a single Pi and got it successfully to run.
Also for any Raspberry Pi you add to you stack of Netboot RPi clients, make sure you followed the configuration of eeprom etc.

We will use an overlayfs mount on your server to provide multiple Pis their operating system using a single base root file system and then using overlays to give each Pi its own read-write layer on top of base root fs for storage and FS modifications.
If you got this far then this should be easy:

# On the Netboot Server

1) We want to use the root file system (Ubuntu 20.04 in my case) for multiple client but preserve the unchanged one on the netboot server also. OverlayFS enables us to  create multiple read-write layers on top of it, each for one Netboot client.

Create mounts for overlayFS based mounts so we can use the root fs as a lower dir/layer

- In order for this to happen, modify /etc/fstab:

        overlay /srv/nfs/<SERIAL> overlay defaults,lowerdir=/srv/nfs/netboot_ubuntu_20_04,upperdir=/srv/nfs/<SERIAL>-upper,workdir=/srv/nfs/<SERIAL>-work,nfs_export=on,index=on 0 0

- Before mounting, create dirs you declared as upper/work/merged:

	mkdir /srv/nfs/<SERIAL>
	mkdir /srv/nfs/<SERIAL>-upper
	mkdir /srv/nfs/<SERIAL>-work
	sudo mount -a

2) Create the FS system to support the overlays. My /srv/nfs then looks like this for 2 Raspberry Pi 4(The same serial number).

        drwxr-xr-x  1 root root 4096 Sep  7 12:47 <SERIAL>
        drwxr-xr-x  3 root root 4096 Sep  7 12:47 <SERIAL>-upper
        drwxr-xr-x  3 root root 4096 Sep  7 13:25 <SERIAL>-work
        drwxr-xr-x 21 root root 4096 Sep  6 19:58 netboot_ubuntu_20_04

3) You need to put an /etc/fstab(the same as before when we were booting one client) inside the merged folder(plain serial named one) for the mount, which will override the netboot_ubuntu_20_04 provided ones.

4) Create and modify /boot/cmdline.txt inside each merged folder as we did for one client

5) Export the merged folders over nfs so RPis can use them as before:

This is done by modifying /etc/exports:

        /srv/nfs/<SERIAL> *(rw,sync,no_subtree_check,no_root_squash)

And type in terminal:

        sudo exportfs -ra

#### TODO: 
hook script inside the initrd of your RaspberryPi SD card which updates the bootloader for you and pings a web server with its serial which then will add the mounts by the time the Pi has rebooted itself, its already booting off the network.


#### TODO: Incorporate debug info from here:
https://linuxhit.com/raspberry-pi-pxe-boot-netbooting-a-pi-4-without-an-sd-card/#14-create-the-nfs-tftp-boot-directories-and-create-our-base-netboot-filesystem

