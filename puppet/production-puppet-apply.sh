#!/bin/sh

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

if ! [ -x "$(command -v puppet)" ]; then
  wget -q http://apt.puppetlabs.com/puppet-release-xenial.deb
  dpkg -i puppet-release-xenial.deb
  rm puppet-release-xenial.deb
  apt-get update
  apt-get -qy install puppet-agent
fi

export PATH=/opt/puppetlabs/bin:$PATH

puppet module install puppetlabs-stdlib --target-dir modules --version 4.25.1
puppet module install flypenguin-mkdir --target-dir modules --version 1.0.4
puppet module install hunner-wordpress --target-dir modules --version 1.0.0
puppet module install puppetlabs-mysql --target-dir modules --version 6.2.0
puppet module install puppet-logrotate --target-dir modules --version 3.4.0

puppet apply --modulepath=modules --hiera_config=hiera.yaml manifests/init.pp
