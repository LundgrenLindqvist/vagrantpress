# L+L server configuration

This repository contains [Puppet](https://puppet.com/) scripts for setting up a new Linux with WordPress and phpMyAdmin installed.

There's also a Vagrantfile here! That's because these server configuration scripts grew out of our fork of [vagrantpress](https://github.com/vagrantpress/vagrantpress). Now, we use the same server deployment scripts for production and development environments, so it makes sense to keep it all in one place.

## Getting started with a development environment

1. [Download](https://github.com/LundgrenLindqvist/vagrantpress/archive/master.zip) the project
2. Extract the directory and `cd` into it
3. Run `vagrant plugin install vagrant-hostsupdater` if you haven't already
4. Change the variables in `puppet/data/common.yaml` as needed
5. Run `vagrant up`
6. Open [vagrantpress.test](http://vagrantpress.test) in your browser

## Getting started with a production environment

1. Deploy a new server with [Linode Manager](https://manager.linode.com)
2. Use the web console to SSH into the server as root
3. Run `wget https://github.com/LundgrenLindqvist/vagrantpress/archive/master.zip`
4. Run `unzip master.zip`
5. Change the variables in `master/puppet/data/common.yaml` as needed
6. Run `./master/puppet-apply.sh`
