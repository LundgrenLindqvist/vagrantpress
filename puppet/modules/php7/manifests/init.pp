# Install PHP

class php7::install {

    package { [
      'php7.0-fpm',
      'php7.0-gd',
      'php7.0-cli',
      'php7.0-curl',
      'php7.0-mbstring',
      'php7.0-mysql',
      'php-apcu',
      'php-xdebug'
    ]:
    ensure => present
    }->

    file { '/etc/php/7.0/fpm/php.ini':
      source => '/vagrant/files/etc/php/7.0/fpm/php.ini',
    }->

    service { 'php7.0-fpm':
      ensure => running,
    }

}
