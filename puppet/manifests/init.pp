# This puppet manifest will install and configure a WordPress server

$wp_index_template = @(END)
<?php
/**
 * Front to the WordPress application. This file doesn't do anything, but loads
 * wp-blog-header.php which does and tells WordPress to load the theme.
 *
 * @package WordPress
 */

/**
 * Tells WordPress to load the WordPress theme and output it.
 *
 * @var bool
 */
define('WP_USE_THEMES', true);

/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wordpress/wp-blog-header.php' );
END

$unattended_upgrades_template = @(END)
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
END

package { [
  'fail2ban',
  'git',
  'sendmail',
  'ufw',
  'unattended-upgrades',
  ]:
  ensure => present
}

$ports = ['ssh', '80', '443']

$ports.each |String $port| {
  exec { "ufw-allow-${port}":
    command => "/usr/sbin/ufw allow ${port}",
    require => Package['ufw'],
  }
}

service { 'ufw':
  ensure => running,
}->

exec { 'ufw-enable':
  command => 'echo "y" | ufw enable',
  path => ['/bin', '/usr/sbin']
}

file { '/etc/apt/apt.conf.d/10periodic':
  ensure => file,
  content => inline_template($unattended_upgrades_template),
  owner => 'root',
  group => 'root'
}

user { 'll':
  ensure => 'present',
  home => '/home/ll',
  groups => 'sudo',
  password => 'dumbpass',
  shell => '/bin/bash',
}

user { 'www-data':
  ensure => 'present',
  home => '/var/www',
  password => 'dumbpass',
  shell => '/bin/bash',
}

file { [
  '/var/www',
  '/var/www/vagrantpress.test',
  ]:
  ensure => 'directory',
  recurse => true,
  owner => 'www-data',
  group => 'www-data'
}

class { 'nginx::install':
  web_hostname => 'vagrantpress.test',
  web_root => '/var/www/vagrantpress.test',
  no_sendfile => true
}

class { 'php7::install': }

class { 'mysql::server':
  root_password => 'strongpassword',
  remove_default_accounts => true
}

class { 'wordpress':
  wp_owner => 'www-data',
  wp_group => 'www-data',
  db_user => 'wordpress',
  db_password => 'hvyH(S%t(016',
  install_dir => '/var/www/vagrantpress.test/wordpress',
  wp_site_domain => 'http://vagrantpress.test',
  version => '4.9'
}

file { '/var/www/vagrantpress.test/index.php':
  ensure => file,
  content => inline_template($wp_index_template),
  owner => 'www-data',
  group => 'www-data'
}

class { 'phpmyadmin::install':
  version => '4.7.9',
  install_dir => '/var/www/vagrantpress.test/phpmyadmin',
  owner => 'www-data',
  group => 'www-data'
}
