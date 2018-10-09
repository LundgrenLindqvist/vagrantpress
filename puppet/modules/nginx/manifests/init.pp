class nginx::install (
  $web_hostname = 'vagrantpress.test',
  $web_root = '/var/www/vagrantpress.test/public_html',
  $log_dir = '/var/www/vagrantpress.test/logs',
  $is_dev_env = true
) {

  package { 'nginx':
    ensure => present,
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
    require => Package['nginx']
  }

  file { "/etc/nginx/sites-available/${web_hostname}.conf":
    content => template('nginx/nginx.conf.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Package['nginx']
  }->

  file { "/etc/nginx/sites-enabled/${web_hostname}.conf":
    ensure => link,
    target => "/etc/nginx/sites-available/${web_hostname}.conf",
    owner => 'root',
    group => 'root',
    mode => '0644',
  }~>

  service { 'nginx':
    ensure => running,
  }

}
