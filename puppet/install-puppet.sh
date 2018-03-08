#!/bin/bash

cd /tmp

if [ ! -e puppet-release-xenial.deb ]; then
  wget -q http://apt.puppetlabs.com/puppet-release-xenial.deb
  dpkg -i puppet-release-xenial.deb
  apt-get update >/dev/null
  apt-get -qy install puppet-agent
fi

export PATH=/opt/puppetlabs/bin:$PATH

puppet module install flypenguin-mkdir --target-dir /vagrant/puppet/modules --version 1.0.4
puppet module install hunner-wordpress --target-dir /vagrant/puppet/modules --version 1.0.0
puppet module install puppetlabs-mysql --target-dir /vagrant/puppet/modules --version 5.3.0
