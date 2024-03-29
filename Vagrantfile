# link to the gitlab-vagrant environment.
config_gitlab_fqdn  = 'gitlab.example.com'
config_gitlab_ip    = '10.10.9.99'

Vagrant.configure(2) do |config|
  config.vm.box = "windows-2022-amd64"
  #config.vm.box = "windows-10-20h2-amd64"

  config.vm.provider "libvirt" do |lv, config|
    lv.memory = 6*1024
    lv.cpus = 4
    lv.cpu_mode = "host-passthrough"
    lv.nested = true
    lv.keymap = "pt"
    config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: ENV["USER"], smb_password: ENV["VAGRANT_SMB_PASSWORD"]
  end

  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 6*1024
    vb.cpus = 4
    vb.customize ['modifyvm', :id, '--nested-hw-virt', 'on']
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
    vb.customize ["modifyvm", :id, "--usbxhci", "on"]
    audio_driver = case RUBY_PLATFORM
      when /linux/
        "alsa"
      when /darwin/
        "coreaudio"
      when /mswin|mingw|cygwin/
        "dsound"
      else
        raise "Unknown RUBY_PLATFORM=#{RUBY_PLATFORM}"
      end
    vb.customize ["modifyvm", :id, "--audio", audio_driver, "--audiocontroller", "hda"]
  end

  config.vm.provider 'hyperv' do |hv, override|
    hv.linked_clone = true
    hv.memory = 6*1024
    hv.cpus = 4
    hv.enable_virtualization_extensions = true # nested virtualization.
    hv.vlan_id = ENV['HYPERV_VLAN_ID']
    # see https://github.com/hashicorp/vagrant/issues/7915
    # see https://github.com/hashicorp/vagrant/blob/10faa599e7c10541f8b7acf2f8a23727d4d44b6e/plugins/providers/hyperv/action/configure.rb#L21-L35
    override.vm.network :private_network, bridge: ENV['HYPERV_SWITCH_NAME'] if ENV['HYPERV_SWITCH_NAME']
    override.vm.synced_folder '.', '/vagrant',
      type: 'smb',
      smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
      smb_password: ENV['VAGRANT_SMB_PASSWORD']
  end

  config.trigger.before :up do |trigger|
    trigger.run = {
      inline: '''bash -euc \'
certs=(
  ../gitlab-vagrant/tmp/gitlab.example.com-crt.der
)
for cert_path in "${certs[@]}"; do
  if [ -f $cert_path ]; then
    mkdir -p tmp
    cp $cert_path tmp
  fi
done
\'
'''
    }
  end

  config.vm.provision "shell", inline: "echo '#{config_gitlab_ip} #{config_gitlab_fqdn}' | Out-File -Encoding ASCII -Append c:/Windows/System32/drivers/etc/hosts"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-choco.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-powershellget.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-dotnet.ps1", reboot: true
  config.vm.provision "shell", path: "ps.ps1", args: ["-retry", "provision-hyper-v.ps1"]
  config.vm.provision "shell", path: "ps.ps1", args: "provision-wsl.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-containers-feature.ps1", reboot: true
  config.vm.provision "shell", path: "ps.ps1", args: "provision.ps1", reboot: true
  config.vm.provision "shell", path: "ps.ps1", args: "provision-docker-ce.ps1"
  # config.vm.provision "shell", path: "ps.ps1", args: "provision-docker-ee.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-docker-compose.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-docker-reg.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "portainer/provision.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-vs.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: ["-retry", "provision-iis.ps1"]
  config.vm.provision "shell", path: "ps.ps1", args: "provision-iis-dotnet-hosting.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-dotnet-sdk.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-wdk.ps1"
  # config.vm.provision "shell", path: "ps.ps1", args: "provision-qt-creator.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-wsl2.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-wsl-ubuntu.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-shortcuts.ps1"
end
