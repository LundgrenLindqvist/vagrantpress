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

$web_hostname = lookup('hostname')
$nginx_root = lookup('nginx_root')
$wordpress_root = lookup('wordpress_root')

$wp_admin_user = lookup('wp_admin_user')
$wp_admin_email = lookup('wp_admin_email')
$wp_admin_password = lookup('wp_admin_password')
$wp_site_title = lookup('wp_site_title')
$wp_plugins = lookup('wp_plugins')

if $web_hostname =~ /^\w+\.test/ {
  $is_dev_env = true
} else {
  $is_dev_env = false
}

package { [
  'bash-completion',
  'curl',
  'fail2ban',
  'git',
  'sendmail',
  'ufw',
  'unattended-upgrades',
  'wget'
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
} ->

exec { 'ufw-enable':
  command => 'echo "y" | ufw enable',
  path => ['/bin', '/usr/sbin']
}

file { '/etc/apt/apt.conf.d/10periodic':
  ensure => file,
  content => inline_template($unattended_upgrades_template),
}

file_line { 'ssh_no_root_login':
  path => '/etc/ssh/sshd_config',
  line => 'PermitRootLogin no',
  match => '^PermitRootLogin',
}

user { 'll':
  ensure => 'present',
  home => '/home/ll',
  comment => 'Lundgren+Lindqvist',
  groups => 'sudo',
  password => pw_hash(lookup('ll_password'), 'SHA-512', 'snME3CZ'),
  shell => '/bin/bash',
}

user { 'www-data':
  ensure => 'present',
  home => '/var/www',
  password => pw_hash(lookup('www_data_password'), 'SHA-512', 'CPHsF9v'),
  shell => '/bin/bash',
}

mkdir::p { lookup('nginx_root'):
  owner => 'www-data',
  group => 'www-data',
  before => [
    Class['nginx::install'],
    Class['wordpress'],
    Class['phpmyadmin::install'],
    File["${nginx_root}/index.php"]
  ]
}

file { "${nginx_root}/index.php":
  ensure => file,
  content => inline_template($wp_index_template),
  owner => 'www-data',
  group => 'www-data'
}

class { 'nginx::install':
  web_hostname => $web_hostname,
  web_root => lookup('nginx_root'),
  is_dev_env => $is_dev_env
}

package { [
  'php7.0-fpm',
  'php7.0-gd',
  'php7.0-cli',
  'php7.0-curl',
  'php7.0-mbstring',
  'php7.0-mysql',
  'php-apcu',
  'php-imagick',
  'php-xdebug'
  ]:
  ensure => present
} ->

file_line { 'php_upload_max_filesize':
  path => '/etc/php/7.0/fpm/php.ini',
  line => 'upload_max_filesize = 200M',
  match => '^upload_max_filesize',
} ->

file_line { 'php_post_max_size':
  path => '/etc/php/7.0/fpm/php.ini',
  line => 'post_max_size = 200M',
  match => '^post_max_size',
} ~>

service { 'php7.0-fpm':
  ensure => running,
}

class { 'mysql::server':
  root_password => lookup('mysql_root_password'),
  remove_default_accounts => true
}->

class { 'wordpress':
  wp_owner => 'www-data',
  wp_group => 'www-data',
  db_user => lookup('mysql_wordpress_username'),
  db_password => lookup('mysql_wordpress_password'),
  install_dir => $wordpress_root,
  wp_site_domain => "http://${web_hostname}",
  version => lookup('wordpress_version')
}

exec { 'download-wp-cli':
  command => "/usr/bin/curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /usr/local/bin/wp",
  group => 'root',
  user => 'root',
  creates => '/usr/local/bin/wp',
  require => Class['wordpress']
}->

file { '/usr/local/bin/wp':
  ensure => present,
  owner => 'root',
  group => 'root',
  mode => '0755',
}->

exec { 'install-wp':
  command => "echo '${wp_admin_password}' | wp core install --url=http://${web_hostname} --title=${wp_site_title} --admin_user=${wp_admin_user} --admin_email=${wp_admin_email} --prompt=admin_password",
  path => ['/bin', '/usr/bin', '/usr/local/bin'],
  cwd => $wordpress_root,
  group => 'www-data',
  user => 'www-data',
}->

exec { 'update-wp-siteurl':
  command => "/usr/local/bin/wp option update siteurl http://${web_hostname}/wordpress",
  cwd => $wordpress_root,
  group => 'www-data',
  user => 'www-data',
}->

# Remove default Akismet plugin
file { "$wordpress_root/wp-content/plugins/akismet":
  ensure => absent,
  force => true
}

# Remove default Hello Dolly plugin
file { "$wordpress_root/wp-content/plugins/hello.php":
  ensure => absent,
}

$wp_plugins.each |$plugin, $target| {
  exec { "install-${plugin}":
    command => "/usr/local/bin/wp plugin install '${target}'",
    cwd => $wordpress_root,
    creates => "${wordpress_root}/wp-content/plugins/${plugin}",
    group => 'www-data',
    user => 'www-data',
  }
}

class { 'phpmyadmin::install':
  version => lookup('phpmyadmin_version'),
  install_dir => lookup('phpmyadmin_root'),
  owner => 'www-data',
  group => 'www-data'
}
