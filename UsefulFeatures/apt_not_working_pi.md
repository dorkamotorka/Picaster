# Apt not working on the RPi

The solution to that is to add to /etc/resolv.conf:

	nameserver 8.8.8.8

This will point the Pi to the Google DNS, therefore bypassing the (possibly) faulty one that the Pi points to.
