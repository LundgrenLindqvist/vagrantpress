# Install nginx

class nginx::install {

  package { 'nginx':
    ensure => present,
  }->

  file { '/etc/nginx/sites-available/default.conf':
    source  => '/vagrant/files/etc/nginx/sites-available/default.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }->

  file { '/etc/nginx/sites-enabled/default.conf':
    ensure  => link,
    target  => '/etc/nginx/sites-available/default.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }~>

  service { 'nginx':
    ensure  => running,
  }

}
