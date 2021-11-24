define nginx::install (
  $web_hostname = 'vagrantpress.test',
  $web_root = '/var/www/vagrantpress.test/public_html',
  $log_dir = '/var/www/vagrantpress.test/logs',
  $is_vagrant_env = true,
  $wp_upload_proxy_url = false,
  $adminer_allow_ip = false,
  $is_default_host = true,
) {

  if $facts['os']['distro']['codename'] == 'xenial' {
    $php_socket = 'unix:/run/php/php7.0-fpm.sock'
  } elsif $facts['os']['distro']['codename'] == 'bionic' {
    $php_socket = 'unix:/run/php/php7.2-fpm.sock'
  } elsif $facts['os']['distro']['codename'] == 'focal' {
    $php_socket = 'unix:/run/php/php7.4-fpm.sock'
  }

  ensure_packages(['nginx'])

  $server_ip = $serverip;

  ensure_resource('file', '/etc/nginx/sites-enabled/default', {
    ensure => absent,
    require => Package['nginx']
  })

  file { "/etc/nginx/sites-available/${web_hostname}.conf":
    content => template('nginx/nginx.conf.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Package['nginx']
  } ~>

  file { "/etc/nginx/sites-enabled/${web_hostname}.conf":
    ensure => link,
    target => "/etc/nginx/sites-available/${web_hostname}.conf",
    owner => 'root',
    group => 'root',
    mode => '0644',
    notify => Service['nginx'],
  }

  ensure_resource('service', 'nginx', {
    ensure => running,
  })

}
