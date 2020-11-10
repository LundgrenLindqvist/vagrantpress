define phpmyadmin::install (
  $version = "4.7.9",
  $install_dir = "/var/www/phpmyadmin",
  $group = "vagrant",
  $owner = "vagrant"
) {

  file { $install_dir:
    ensure => directory,
    recurse => true,
    group => $group,
    owner => $owner
  }

  exec { "download-phpmyadmin-${install_dir}":
    command => "/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-all-languages.tar.gz",
    cwd => "${install_dir}/",
    group => $group,
    user => $owner,
    require => File[$install_dir],
    creates => "${install_dir}/phpMyAdmin-${version}-all-languages.tar.gz"
  }->

  exec { "untar-phpmyadmin-${install_dir}":
    command => "/bin/tar xzf ${install_dir}/phpMyAdmin-${version}-all-languages.tar.gz --strip-components=1",
    cwd => "${install_dir}/",
    group => $group,
    user => $owner,
    creates => "${install_dir}/index.php",
  }

}
