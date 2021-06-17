# NTP Server & Client

I used two Raspberry Pi, one as a NTP Server and the other as a Client.

On both I install chrony:

	sudo apt install chrony

chronyc provides commandline tool that enables you to setup a Server and Client but only until reboot.
In order to apply permanent changes, you must:

- On Server, open /etc/chrony/chrony.conf and add (or uncomment/no need to add if already present):

		local stratum 10
		allow 0/0

- On Client, open /etc/chrony/chrony.conf and add:

		server <Server-IP> iburst prefer

# Double-check

Check on Client, by typing to the terminal:

	chronyc tracking

where it should display the Server IP and time tracking information.  
