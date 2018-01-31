#!/bin/bash

cd /tmp
wget http://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
dpkg -i puppetlabs-release-pc1-xenial.deb
apt-get -q update
apt-get -qy install puppet-common
echo "PATH=/opt/puppetlabs/bin:$PATH" >> /etc/bash.bashrc
echo "export PATH" >> /etc/bash.bashrc
export PATH=/opt/puppetlabs/bin:$PATH
