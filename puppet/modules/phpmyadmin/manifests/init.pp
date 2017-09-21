# Install latest phpMyAdmin

class phpmyadmin::install {

  exec { 'download-phpmyadmin':
    command => '/usr/bin/wget https://files.phpmyadmin.net/phpMyAdmin/4.7.1/phpMyAdmin-4.7.1-all-languages.zip',
    cwd     => '/vagrant/',
    creates => '/vagrant/phpMyAdmin-4.7.1-all-languages.zip'
  }

  package { 'unzip':
    ensure => present,
    notify => Exec['unzip-phpmyadmin']
  }

  exec { 'unzip-phpmyadmin':
    cwd     => '/vagrant/',
    user    => 'root',
    command => '/usr/bin/unzip /vagrant/phpMyAdmin-4.7.1-all-languages.zip',
    require => Exec['download-phpmyadmin'],
    creates => '/vagrant/phpMyAdmin-4.7.1-all-languages',
  }->

  file { '/vagrant/phpmyadmin':
    ensure => 'directory',
    recurse => true,
    source => 'file:///vagrant/phpMyAdmin-4.7.1-all-languages',
    before => File['/vagrant/phpMyAdmin-4.7.1-all-languages'],
  }->

  file { '/vagrant/phpMyAdmin-4.7.1-all-languages':
    ensure => 'absent',
    purge => true,
    recurse => true,
    force => true,
  }

}
