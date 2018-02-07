# Install nginx

class nginx::install {

  package { 'nginx':
    ensure => present,
  }->

  file { '/etc/nginx/sites-available/vagrantpress.conf':
    source  => '/vagrant/files/etc/nginx/sites-available/vagrantpress.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }->

  file { '/etc/nginx/sites-enabled/vagrantpress.conf':
    ensure  => link,
    target  => '/etc/nginx/sites-available/vagrantpress.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }~>

  service { 'nginx':
    ensure  => running,
  }

}
