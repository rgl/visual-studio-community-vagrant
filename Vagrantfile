Vagrant.configure(2) do |config|
  config.vm.box = "windows_2012_r2"
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 4096
    vb.customize ["modifyvm", :id, "--vram", 64]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
    vb.customize [
      "storageattach", :id,
      "--storagectl", "IDE Controller",
      "--device", 0,
      "--port", 1,
      "--type", "dvddrive",
      "--medium", "emptydrive"]
  end
  config.vm.provision "shell", inline: "$env:chocolateyVersion='0.10.1'; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex", name: "Install Chocolatey"
  config.vm.provision "shell", path: "provision.ps1"
  config.vm.provision :reload
  config.vm.provision "shell", path: "provision-1.ps1"
end
