define adminer::install (
  $install_dir = "/var/www/adminer",
  $group = "vagrant",
  $owner = "vagrant"
) {

  file { $install_dir:
    ensure => directory,
    recurse => true,
    group => $group,
    owner => $owner
  }

  exec { "download-adminer-${install_dir}":
    command => "/usr/bin/wget https://www.adminer.org/latest-mysql-en.php -O index.php",
    cwd => "${install_dir}/",
    group => $group,
    user => $owner,
    require => File[$install_dir],
    creates => "${install_dir}/index.php"
  }

}
