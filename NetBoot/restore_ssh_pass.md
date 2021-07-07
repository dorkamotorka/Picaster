# Restore SSH Password for Netboot Client

I forgot the SSH password for Netboot client, but since I had root permissions over it's file system on the Netboot Server I could fix that.
All the command below are executed on the Raspberry Pi Netboot Server.

First I chrooted into the directory of the Netboot Client file system:

	sudo chroot <NETBOOT-CLIENT-ROOT-FS>

You should have been logged into as a root, then type:

	passwd <USER-ON-THE-NETBOOT-CLIENT>

Modify the password and exit out of the chroot.
Reboot your Netboot client and you should be able to log into the user you changed the password for.
