The following link: 
	
	https://pimylifeup.com/raspberry-pi-dns-server/ 

gave me a good head start to setup Raspberry Pi as a DNS Server(RPDS).

In order for RPDS to resolve I needed to add DNS resolutions to /etc/hosts:

	<IP1> host1 
	<IP2> host2 
	<IP3> host3 
	<IP4> host4 

After that we need to restart dnsmasq service, because its configuration(resolutions) was updated:

	sudo systemctl restart dnsmasq

Once RPDS was setup I needed (on the computer where I will be using DNS resolution) to add its IP to /etc/resolv.conf:

	nameserver <DNS-SERVER-IP>
