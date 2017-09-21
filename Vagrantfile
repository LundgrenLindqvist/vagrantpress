# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.synced_folder ".", "/vagrant", :owner => "www-data"
  # Use this line as a template for syncing the theme directory
  # config.vm.synced_folder "/Users/fredrik/Documents/GitHub/lundgrenlindqvist", "/vagrant/wordpress/wp-content/themes/lundgrenlindqvist", :owner => "www-data"

  # Setup virtual hostname and provision local IP
  config.vm.hostname = "vagrantpress.dev"
  config.vm.network :private_network, :ip => "192.168.50.4"
  config.hostsupdater.aliases = %w{www.vagrantpress.dev}
  config.hostsupdater.remove_on_suspend = true

  # Allows running commands globally in shell for installed composer libraries
  config.vm.provision :shell, path: "files/scripts/install-puppet.sh"

  config.vm.provision :puppet do |puppet|
    puppet.environment = "production"
    puppet.environment_path = "../../"

    puppet.manifests_path = "puppet/manifests"
    puppet.module_path = "puppet/modules"
    puppet.manifest_file = "init.pp"
    # puppet.options = "--verbose --debug"
  end

  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
  end
end
