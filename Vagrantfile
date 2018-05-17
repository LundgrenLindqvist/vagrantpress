require "yaml"

hiera_data = YAML.load_file("puppet/data/common.yaml")
hostname = hiera_data["hostname"]

Vagrant.configure("2") do |config|
  # We would prefer to use the official ubuntu/xenial64 box, but it has given us
  # a lot of grief with SSH authentication failures, so we tried this box
  # instead
  config.vm.box = "bento/ubuntu-16.04"

  config.vm.synced_folder ".", "/vagrant", :owner => "www-data", :group => "www-data", :mount_options => ["dmode=755,fmode=644"]
  # Use this line as a template for syncing the theme directory
  # config.vm.synced_folder "/Users/fredrik/Documents/GitHub/lundgrenlindqvist", "/vagrant/wordpress/wp-content/themes/lundgrenlindqvist", :owner => "www-data", :group => "www-data", :mount_options => ["dmode=755,fmode=644"]

  # Setup virtual hostname and provision local IP
  config.vm.hostname = hostname
  config.vm.network :private_network, :ip => "192.168.50.4"
  config.hostsupdater.aliases = ["www.#{hostname}"]
  config.hostsupdater.remove_on_suspend = true

  config.vm.provision :shell, path: "puppet/development-puppet-install.sh"

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.module_path = "puppet/modules"
    puppet.manifest_file = "init.pp"
    puppet.hiera_config_path = "puppet/hiera-development.yaml"
  end

  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
  end
end
