class nginx::install (
  $web_hostname = 'vagrantpress.test',
  $web_root = '/var/www',
  $no_sendfile = false
) {

  package { 'nginx':
    ensure => present,
  }->

  file { '/etc/nginx/sites-available/vagrantpress.conf':
    content => template('nginx/vagrantpress.conf.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
  }->

  file { '/etc/nginx/sites-enabled/vagrantpress.conf':
    ensure => link,
    target => '/etc/nginx/sites-available/vagrantpress.conf',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }~>

  service { 'nginx':
    ensure => running,
  }

}
