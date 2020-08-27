libvirt-up:
	vagrant up --provider=libvirt --debug-timestamp --no-destroy-on-error 2>vagrant.log

virtualbox-up:
	vagrant up --provider=virtualbox --debug-timestamp --no-destroy-on-error 2>vagrant.log
