# L+L server configuration

This repository contains [Puppet](https://puppet.com/) scripts for setting up a new Linux with WordPress and phpMyAdmin installed.

There's also a Vagrantfile here! That's because these server configuration scripts grew out of our fork of [vagrantpress](https://github.com/vagrantpress/vagrantpress). Now, we use the same server deployment scripts for production and development environments, so it makes sense to keep it all in one place.

## Getting started with a development environment

1. [Download](https://github.com/LundgrenLindqvist/vagrantpress/archive/master.tar.gz) the project
2. Extract the directory and `cd` into it
3. Run `vagrant plugin install vagrant-hostsupdater` if you haven't already
4. Change the variables in `puppet/data/common.yaml` as needed
5. Run `vagrant up`
6. Open [vagrantpress.test](http://vagrantpress.test) in your browser
7. That's it! 🐵

## Getting started with a production environment

1. Deploy a new server with [Linode Manager](https://manager.linode.com)
2. SSH into the server as `root` (you can use the web console if you like)
3. Run `wget https://github.com/LundgrenLindqvist/vagrantpress/archive/master.tar.gz`
4. Run `tar xzvf master.tar.gz`
5. Change the variables in `vagrantpress-master/puppet/data/common.yaml` as needed
6. Run `vagrantpress-master/puppet/production-puppet-apply.sh`
7. Remove the setup files by running `rm -r master.tar.gz vagrantpress-master` . Only the root user can access them, but they still contain user passwords that could be sensitive if left lying around.
8. That's it! 🐵

## Acknowledgments

This repo started as a fork of [Vagrantpress](https://github.com/vagrantpress/vagrantpress/). We've changed pretty much every aspect of it since then, but we still owe some gratitude to the original authors for getting us off the ground. Thank you [Chad Thompson](https://chadthompson.me/), and fellow contributors!
