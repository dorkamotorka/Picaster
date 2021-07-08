# Ansible

Ansible is an open source automation and orchestration tool for software provisioning, configuration management, and software deployment. 
It functions by connecting via SSH to the clients, so it doesn't need a special agent on the client-side, and by pushing modules to the clients, the modules are then executed locally on the client-side and the output is pushed back to the Ansible server.

## Inventory file

In order to keep a list of all the provisioned servers, ansible has an inventory file, by default /etc/ansible/hosts.

### Verify connection between servers

In terminal on Ansible server, type:

	ansible -i hosts all -m ping

You should see SUCCESS for each server. 

If you get an error like 

	Failed to connect to the host via ssh: ubuntu@192.168.50.207: Permission denied (publickey,password).

Try resolving with(On the Ansible server):
	
	ssh-keygen -t rsa
	ssh-copy-id <ANSIBLE-CLIENT>@<ANSIBLE-CLIENT>
