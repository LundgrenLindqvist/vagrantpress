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

$certbot_renewal_hook_template = @(END)
#!/bin/bash
systemctl reload nginx
END

package { [
  'bash-completion',
  'certbot',
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
} ->

file_line { 'unattended_upgrades_autoremove':
  path => '/etc/apt/apt.conf.d/50unattended-upgrades',
  line => 'Unattended-Upgrade::Remove-Unused-Dependencies "true";',
  match => '^Remove-Unused-Dependencies',
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

$fail2ban_whitelist_ip = lookup('fail2ban_whitelist_ip')

if $fail2ban_whitelist_ip {
  file_line { 'fail2ban_whitelist':
    path => '/etc/fail2ban/jail.conf',
    line => "ignoreip = 127.0.0.1/8 ::1 ${fail2ban_whitelist_ip}",
    match => '^#?ignoreip =',
  } ~>

  service { 'fail2ban':
    ensure => running,
  }
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
} ->

file { '/var/www':
  ensure => 'directory',
  owner => 'www-data',
  group => 'www-data',
  recurse => true
}

# When we run in a Vagrant environment, we need to wait for Vagrant to finish
# mounting the shared folders before starting nginx. Why? Because nginx will
# protest when the log directories aren't present otherwise
if $::is_vagrant_env {
  file { '/etc/systemd/system/nginx.service':
    ensure => present,
    source => '/lib/systemd/system/nginx.service',
    require => Package['nginx']
  } ->

  file_line { 'systemctl_nginx_vagrant':
    path => '/etc/systemd/system/nginx.service',
    line => 'WantedBy=vagrant.mount',
    match => '^WantedBy=',
  } ~>

  exec { 'nginx_systemd_reenable':
    command => '/bin/systemctl reenable nginx',
    refreshonly => true
  }
}

if $facts['os']['distro']['codename'] == 'xenial' {
  $php_version = '7.0'
} elsif $facts['os']['distro']['codename'] == 'bionic' {
  $php_version = '7.2'
} elsif $facts['os']['distro']['codename'] == 'focal' {
  $php_version = '7.4'
}

$php_packages = [
  "php${php_version}-fpm",
  "php${php_version}-gd",
  "php${php_version}-cli",
  "php${php_version}-curl",
  "php${php_version}-intl",
  "php${php_version}-mbstring",
  "php${php_version}-mysql",
  "php${php_version}-soap",
  "php${php_version}-xml",
  "php${php_version}-zip",
  'php-apcu',
  'php-imagick'
]

$opcache_blacklist_path = "/etc/php/${php_version}/fpm/opcache_blacklist.txt"

package { $php_packages:
  ensure => present
} ->

file { $opcache_blacklist_path:
  ensure => file,
  owner => 'root',
  group => 'root',
  mode => '0775',
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

file_line { 'php_opcache_blacklist_filename':
  path => "/etc/php/${php_version}/fpm/php.ini",
  line => "opcache.blacklist_filename=${opcache_blacklist_path}",
  match => 'opcache.blacklist_filename=',
} ->

file_line { 'php_opcache_enable_cli':
  path => "/etc/php/${php_version}/fpm/php.ini",
  line => 'opcache.enable_cli=1',
  match => 'opcache.enable_cli=',
} ->

file_line { 'php_opcache_revalidate_freq':
  path => "/etc/php/${php_version}/fpm/php.ini",
  line => 'opcache.revalidate_freq=60',
  match => 'opcache.revalidate_freq=',
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
  package_name => 'mariadb-server',
  root_password => lookup('mysql_root_password'),
  remove_default_accounts => true,
  override_options => {
    mysqld => {
      'log-error' => '/var/log/mysql/mariadb.log',
      'pid-file'  => '/var/run/mysqld/mysqld.pid',
    },
    mysqld_safe => {
      'log-error' => '/var/log/mysql/mariadb.log',
    },
  },
} ->

exec { 'download-wp-cli':
  command => "/usr/bin/curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /usr/local/bin/wp",
  group => 'root',
  user => 'root',
  creates => '/usr/local/bin/wp',
} ->

file { '/usr/local/bin/wp':
  ensure => present,
  owner => 'root',
  group => 'root',
  mode => '0755',
} ->

mkdir::p { '/etc/letsencrypt/renewal-hooks/post':
  owner => 'root',
  group => 'root',
} ->

file { '/etc/letsencrypt/renewal-hooks/post/nginx.sh':
  ensure => file,
  content => inline_template($certbot_renewal_hook_template),
  owner => 'root',
  group => 'root',
  mode => '0775',
}

$sites = lookup('sites')

$sites.each |$web_hostname, $config| {
  $nginx_root = $config['nginx_root']
  $log_dir = $config['log_dir']
  $wordpress_root = "${nginx_root}/wordpress"
  $adminer_root = "${nginx_root}/adminer"

  $wp_url = $config['wp_url']
  $wp_admin_user = $config['wp_admin_user']
  $wp_admin_email = $config['wp_admin_email']
  $wp_admin_password = $config['wp_admin_password']
  $wp_site_title = $config['wp_site_title']
  $wp_plugins = $config['wp_plugins']

  mkdir::p { "${nginx_root}":
    owner => 'www-data',
    group => 'www-data',
  } ->

  mkdir::p { "${log_dir}":
    owner => 'www-data',
    group => 'www-data',
  } ->

  file { "${nginx_root}/index.php":
    ensure => file,
    content => $wp_index_template,
    owner => 'www-data',
    group => 'www-data'
  } ->

  nginx::install { $web_hostname:
    web_hostname => $web_hostname,
    web_root => $nginx_root,
    log_dir => $log_dir,
    is_vagrant_env => $::is_vagrant_env,
    wp_upload_proxy_url => $config['wp_upload_proxy_url'],
    adminer_allow_ip => $fail2ban_whitelist_ip,
    is_default_host => length($sites) == 1,
  } ->

  logrotate::rule { $web_hostname:
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

  file_line { "opcache_blacklist_${web_hostname}":
    path => $opcache_blacklist_path,
    line => "${wordpress_root}/wp-content/themes/**/*",
  }

  wordpress::instance { $web_hostname:
    wp_owner => 'www-data',
    wp_group => 'www-data',
    db_name => $web_hostname,
    db_user => $config['mysql_username'],
    db_password => $config['mysql_password'],
    install_dir => $wordpress_root,
    version => $config['wp_version']
  }

  exec { "install-wp-${web_hostname}":
    command => "echo '${wp_admin_password}' | wp core install --url=${wp_url} --title='${wp_site_title}' --admin_user='${wp_admin_user}' --admin_email=${wp_admin_email} --prompt=admin_password",
    path => ['/bin', '/usr/bin', '/usr/local/bin'],
    cwd => $wordpress_root,
    group => 'www-data',
    user => 'www-data',
    require => Wordpress::Instance[$web_hostname]
  } ->

  exec { "update-wp-siteurl-${web_hostname}":
    command => "/usr/local/bin/wp option update siteurl ${wp_url}/wordpress",
    cwd => $wordpress_root,
    group => 'www-data',
    user => 'www-data',
  } ->

  # Remove default Akismet plugin
  file { "${wordpress_root}/wp-content/plugins/akismet":
    ensure => absent,
    force => true
  } ->

  # Remove default Hello Dolly plugin
  file { "${wordpress_root}/wp-content/plugins/hello.php":
    ensure => absent,
  }

  $wp_plugins.each |$plugin, $target| {
    exec { "install-${plugin}-${web_hostname}":
      command => "/usr/local/bin/wp plugin install '${target}'",
      cwd => $wordpress_root,
      creates => "${wordpress_root}/wp-content/plugins/${plugin}",
      group => 'www-data',
      user => 'www-data',
      require => Wordpress::Instance[$web_hostname]
    }
  }

  if $::is_vagrant_env {
    file_line { 'wordpress_environment_development':
      path => "${wordpress_root}/wp-config.php",
      line => "define('WP_ENVIRONMENT_TYPE', 'development');",
      require => Exec["install-wp-${web_hostname}"]
    }
  }

  adminer::install { $web_hostname:
    install_dir => $adminer_root,
    owner => 'www-data',
    group => 'www-data'
  }
}
