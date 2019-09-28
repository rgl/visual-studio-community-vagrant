libvirt-up:
	vagrant up --provider=libvirt --debug-timestamp 2>vagrant.log

virtualbox-up:
	vagrant up --provider=virtualbox --debug-timestamp 2>vagrant.log
