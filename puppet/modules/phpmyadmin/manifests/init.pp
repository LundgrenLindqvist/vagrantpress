# Install latest phpMyAdmin

class phpmyadmin::install {

  exec { 'download-phpmyadmin':
    command => '/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/4.7.7/phpMyAdmin-4.7.7-all-languages.tar.gz',
    cwd     => '/vagrant/',
    creates => '/vagrant/phpMyAdmin-4.7.7-all-languages.zip'
  }

  exec { 'untar-phpmyadmin':
    cwd     => '/vagrant/',
    command => '/bin/tar xzf /vagrant/phpMyAdmin-4.7.7-all-languages.tar.gz',
    require => Exec['download-phpmyadmin'],
    creates => '/vagrant/phpMyAdmin-4.7.7-all-languages',
  }->

  file { '/vagrant/phpmyadmin':
    ensure => 'directory',
    recurse => true,
    source => 'file:///vagrant/phpMyAdmin-4.7.7-all-languages',
    before => File['/vagrant/phpMyAdmin-4.7.7-all-languages'],
  }->

  file { '/vagrant/phpMyAdmin-4.7.7-all-languages':
    ensure => 'absent',
    purge => true,
    recurse => true,
    force => true,
  }

}
