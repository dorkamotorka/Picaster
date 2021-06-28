# Samba

Samba is a re-implementation of the SMB (Server Message Block) networking protocol and allows Linux computers to integrate into Microsoft’s active directory environments seamlessly.
By using Samba on our Raspberry Pi, we can easily share directories in a way that they can be accessed on almost every operating system.

## SMB (Server Message Block)

SMB is a file sharing protocol that was invented by IBM and has been around since the mid-eighties.

## What is /etc/fstab?

fstab is a system's filesystem table, that is used to define a set of rules how different filesystems are treated each time they are introduced to a system.(e.g. when you plugin USB stick, should it be automatically mounted to the filesystem OR in case of Samba to automatically mount shared file system when detected) 

## Samba Pi Server & Client

### Install dependencies

For both Server and Client install:

	sudo apt update
	sudo apt install cifs-utils samba samba-common-bin

### Create a shared folder on a Server

This command sets the sticky bit (1) to help prevent the directory from being accidentally deleted and gives everyone read/write/execute (777) permissions on it.

	sudo mkdir -m 1777 /share
	
### Configure the Server

Add to the bottom of the /etc/samba/smb.conf:

	[share]
	Comment = Pi shared folder
	Path = <ABSOLUTE-PATH-TO-THE-SHARED-FOLDER>
	Browseable = yes
	Writeable = Yes
	only guest = no
	create mask = 0777
	directory mask = 0777
	Public = yes
	Guest ok = yes

Set password with:

	sudo smbpasswd -a <USER>

In order for configuration to take place, restart the service:

	sudo systemctl restart smbd.service

## Connect Client to Server

	sudo mount -t cifs //<IP-SAMBA-SERVER>/<NAME-IN-[]-IN-SMB.CONF-ON-SAMBA-SERVER> -o username=<USER-ON-CLIENT>,password=<PASSWORD-CREATED-ON-SERVER> <DIR-WHERE-TO-MOUNT-ON-CLIENT>

## Verify sharing

On the Server to see connected clients, type in terminal:

	sudo smbdstatus

## Permanent mount

If you restart the Client the connection to the server and the mounted files will be lost. In order for the client to automatically connect to the Server we must modify /etc/fstab:

	//<IP-SAMBA-SERVER>/<NAME-IN-[]-IN-SMB.CONF-ON-SAMBA-SERVER>   <DIR-WHERE-TO-MOUNT-ON-CLIENT>  cifs  credentials=/etc/samba/user.cred,,x-systemd.automount 0 0

and add into the /etc/samba/user.cred:

	username=<USER-ON-CLIENT>
	password=<PASSWORD-CREATED-ON-SERVER>

and modify the permissions:

	sudo chmod 600 /etc/samba/user.cred

WARNING: Make sure you test /etc/fstab with:

	sudo mount -a

because if it broken, you won't be able to boot!
