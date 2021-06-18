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

	Additionaly, on the client-side I noticed sometimes It takes quite a while to connect to NTP Server if both reboots. I partially solved this by adding:
		
		server <Server-IP> maxpoll 2 # Maximum time interval without pooling time from NTP Server
		initstepslew 5 <Server-IP> # Allow chrony to make a step if system clock error on boot is larger than threshold
		makestep 1 10 # Updated default values to enable the Client to make a time step 10-times if the system clock error is larger than threshold(1 in our case)

# Double-check

Check on Client, by typing to the terminal:

	chronyc tracking

where it should display the Server IP and time tracking information.  
