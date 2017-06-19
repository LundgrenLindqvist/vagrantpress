# Install PHP

class php5::install {

    package { [
      'php5-fpm',
      'php5-gd',
      'php5-cli',
      'php5-curl',
      'php5-mysql',
      'php5-apcu',
      'php5-xdebug'
    ]:
    ensure => present
    }->

    file { '/etc/php5/fpm/php.ini':
      source => '/vagrant/files/etc/php5/fpm/php.ini',
    }->

    service { 'php5-fpm':
      ensure => running,
    }

}
