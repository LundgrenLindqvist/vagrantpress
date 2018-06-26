#!/bin/bash

cd /tmp

if ! [ -x "$(command -v puppet)" ]; then
  wget -q http://apt.puppetlabs.com/puppet-release-xenial.deb
  dpkg -i puppet-release-xenial.deb
  rm puppet-release-xenial.deb
  apt-get update >/dev/null
  apt-get -qy install puppet-agent
fi

export PATH=/opt/puppetlabs/bin:$PATH

if [ ! -d /vagrant/puppet/modules/stdlib ]; then
  puppet module install puppetlabs-stdlib --target-dir /vagrant/puppet/modules --version 4.24.0
fi

if [ ! -d /vagrant/puppet/modules/mkdir ]; then
  puppet module install flypenguin-mkdir --target-dir /vagrant/puppet/modules --version 1.0.4
fi

if [ ! -d /vagrant/puppet/modules/wordpress ]; then
  puppet module install hunner-wordpress --target-dir /vagrant/puppet/modules --version 1.0.0
fi

if [ ! -d /vagrant/puppet/modules/mysql ]; then
  puppet module install puppetlabs-mysql --target-dir /vagrant/puppet/modules --version 5.3.0
fi
