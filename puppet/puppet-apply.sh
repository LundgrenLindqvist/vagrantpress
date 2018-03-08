#!/bin/sh

cd "$(dirname "$0")"

if [ ! -e puppet-release-xenial.deb ]; then
  wget -q http://apt.puppetlabs.com/puppet-release-xenial.deb
  dpkg -i puppet-release-xenial.deb
  apt-get update
  apt-get -qy install puppet-agent
fi

export PATH=/opt/puppetlabs/bin:$PATH

puppet module install flypenguin-mkdir --target-dir modules --version 1.0.4
puppet module install hunner-wordpress --target-dir modules --version 1.0.0
puppet module install puppetlabs-mysql --target-dir modules --version 5.3.0

puppet apply --modulepath=modules --hiera_config=hiera.yaml manifests/init.pp
