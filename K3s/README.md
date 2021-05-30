# K3s 

The following steps got me a good headstart: 

	https://computingforgeeks.com/install-kubernetes-on-ubuntu-using-k3s/

I installed K3s to Raspberry Pi (Server), with the following command:

	curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v0.9.1 K3S_KUBECONFIG_MODE="644" sh -

I didn't installed the latest version, because it was causing me to many problems, bt I will definitely consider upgrading it later.
(One of the commands in the guide above in link is setup smh for amd64 ~ make sure you change this into arm64)

As always along the way I had couple of problems, such as:

1.)
	The connection to the server localhost:8080 was refused - did you specify the right host or port?

I solved it, by:

Checking 

	kubectl config view

which should look like:

	apiVersion: v1
	clusters:
	- cluster:
	    certificate-authority-data: DATA+OMITTED
	    server: https://127.0.0.1:6443
	  name: default
	contexts:
	- context:
	    cluster: default
	    user: default
	  name: default
	current-context: default
	kind: Config
	preferences: {}
	users:
	- name: default
	  user:
	    client-certificate-data: REDACTED
	    client-key-data: REDACTED

SOLUTION:
I broke file on my own with copy-paste things from Public Forums :)


2.) Command below:

	sudo systemctl status k3s

Failed with:

	k3s.service - Lightweight Kubernetes
	   Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: enabled)
	   Active: activating (auto-restart) (Result: exit-code) since Sun 2021-05-30 15:31:27 UTC; 4s ago
	     Docs: https://k3s.io
	  Process: 27750 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
	  Process: 27751 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
	  Process: 27752 ExecStart=/usr/local/bin/k3s server (code=exited, status=1/FAILURE)
	 Main PID: 27752 (code=exited, status=1/FAILURE)

SOLUTION:
Command:

	cat memory /proc/cgroups

should output **memory** row in 3rd column with 1, like:

	memory	2	58	1

If not, add to /boot/firmware/cmdline.txt:

	cgroup_enable=cpuset
	cgroup_enable=memory
	cgroup_memory=1

3.) If command

	kubectl <command>

is asking you for Username and Passwrd you know nothing about, this means you are trying to access someone elses Kubernetes Server and you should change kubectl config file, like in the 1.) mentioned problem above. 


TIP:

1.) In order to debug FAILED status of a Service run:

	journalctl -u <service-name>

2.) In order to remove k3s-agent:

	/usr/local/bin/k3s-agent-uninstall.sh


4.) k3s-agent service Failed to run and solved it with:

a.) by installing k3s-agent with command:

	curl -sfL http://get.k3s.io | INSTALL_K3S_VERSION=v0.9.1 K3S_URL=https://<master_IP>:6443 K3S_TOKEN=<join_token> sh -s - --docker

b.) by adding:

cgroup_enable=cpuset
cgroup_enable=memory
cgroup_memory=1

to /boot/firmware/cmdline.txt.


If k3s-agent service fails to run and you get an error:

	Node password rejected, contents of '/var/lib/rancher/k3s/agent/node-password.txt' may not match server passwd entry ...

meant in my case that I needed to update the password on the Kubernetes master, because when I re-created worker it updated it's password but on the Kubernetes Server it stayed the same, so make sure passwords in files below match:

	/var/lib/rancher/k3s/server/cred/node-passwd # On Kubernetes Server
	/var/lib/rancher/k3s/agent/node-password.txt # On Kubernetes Client


Error didn't yet cause me any troubles later on:
	Info: waiting for node node2: nodes \"node2\" is forbidden: User \"node\" cannot get resource \"nodes\" in API group \"\ ...
	Error: Unable to watch for tunnel endpoints: unknown (get endpoints)

## Helm

I also installed Helm (package manager for Kubernetes). I notices I had to retry every command, because the first time it hanged, but then it worked.

