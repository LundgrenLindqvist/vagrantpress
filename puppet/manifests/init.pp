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
$log_dir = lookup('log_dir')
$wordpress_root = lookup('wordpress_root')

$wp_url = lookup('wp_url')
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
} ~>

service { 'unattended-upgrades':
  ensure => running,
}

file_line { 'ssh_no_root_login':
  path => '/etc/ssh/sshd_config',
  line => 'PermitRootLogin no',
  match => '^PermitRootLogin',
} ~>

service { 'ssh':
  ensure => running,
}

# This is a good one! sendmail wants to send from a FQDN (fully qualified domain
# name) because otherwise it takes up to 1 minute to send a single email.
# "localhost" isn't a FQDN, but "localhost.localdomain" is. That domain name
# isn't in /etc/hosts by default, so we add it.
host { 'localhost.localdomain':
  ip => '127.0.0.1',
}

user { 'll':
  ensure => 'present',
  home => '/home/ll',
  managehome => true,
  comment => 'Lundgren+Lindqvist',
  groups => 'sudo',
  password => pw_hash(lookup('ll_password'), 'SHA-512', 'snME3CZ'),
  shell => '/bin/bash',
}

user { 'www-data':
  ensure => 'present',
  home => '/var/www',
  managehome => true,
  password => pw_hash(lookup('www_data_password'), 'SHA-512', 'CPHsF9v'),
  shell => '/bin/bash',
}

mkdir::p { "${nginx_root}":
  owner => 'www-data',
  group => 'www-data',
  before => [
    Class['nginx::install'],
    Class['wordpress'],
    Class['phpmyadmin::install'],
    File["${nginx_root}/index.php"]
  ]
}

mkdir::p { "${log_dir}":
  owner => 'www-data',
  group => 'www-data',
  before => [
    Class['nginx::install'],
    Logrotate::Rule["${web_hostname}"]
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
  web_root => $nginx_root,
  log_dir => $log_dir,
  is_dev_env => $is_dev_env
} ->

logrotate::rule { "${web_hostname}":
  path => "${log_dir}/*.log",
  create => true,
  create_group => 'www-data',
  create_mode => '0640',
  create_owner => 'www-data',
  delaycompress => true,
  ifempty => false,
  missingok => true,
  rotate => 14,
  rotate_every => 'day',
  sharedscripts => true,
  prerotate =>
    'if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
      run-parts /etc/logrotate.d/httpd-prerotate; \
    fi',
  postrotate => '[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`',
}

if $facts['os']['distro']['codename'] == 'xenial' {
  $php_version = '7.0'
} elsif $facts['os']['distro']['codename'] == 'bionic' {
  $php_version = '7.2'
}

package { [
  "php${php_version}-fpm",
  "php${php_version}-gd",
  "php${php_version}-cli",
  "php${php_version}-curl",
  "php${php_version}-mbstring",
  "php${php_version}-mysql",
  'php-apcu',
  'php-imagick',
  'php-xdebug'
  ]:
  ensure => present
} ->

# These three directives are meant to configure php-fpm to be more crash
# tolerant. They are taken from the nexamchemical.com project, where php-fpm
# experienced frequent crashes due to the fact that a particular page was being
# crawled by a bot. That page occasionally threw errors, and the combination of
# the bot requests and PHP errors seemed to cause php-fpm to crash completely.
# These directives help php-fpm realize that it should restart the crashed
# processes in similar situations.
file_line { 'php_fpm_emergency_restart_threshold':
  path => "/etc/php/${php_version}/fpm/php-fpm.conf",
  line => 'emergency_restart_threshold = 3',
  match => 'emergency_restart_threshold =',
} ->

file_line { 'php_fpm_emergency_restart_interval':
  path => "/etc/php/${php_version}/fpm/php-fpm.conf",
  line => 'emergency_restart_interval = 1m',
  match => 'emergency_restart_interval =',
} ->

file_line { 'php_fpm_process_control_timeout':
  path => "/etc/php/${php_version}/fpm/php-fpm.conf",
  line => 'process_control_timeout = 5s',
  match => 'process_control_timeout =',
} ->

file_line { 'php_upload_max_filesize':
  path => "/etc/php/${php_version}/fpm/php.ini",
  line => 'upload_max_filesize = 200M',
  match => '^upload_max_filesize',
} ->

file_line { 'php_post_max_size':
  path => "/etc/php/${php_version}/fpm/php.ini",
  line => 'post_max_size = 200M',
  match => '^post_max_size',
} ~>

service { "php$php_version-fpm":
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
  command => "echo '${wp_admin_password}' | wp core install --url=${wp_url} --title='${wp_site_title}' --admin_user='${wp_admin_user}' --admin_email=${wp_admin_email} --prompt=admin_password",
  path => ['/bin', '/usr/bin', '/usr/local/bin'],
  cwd => $wordpress_root,
  group => 'www-data',
  user => 'www-data',
}->

exec { 'update-wp-siteurl':
  command => "/usr/local/bin/wp option update siteurl http://${wp_url}/wordpress",
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
