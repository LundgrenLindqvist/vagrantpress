# VagrantPress

This is a fork of the original [vagrantpress/vagrantpress](https://github.com/vagrantpress/vagrantpress).
We've made the following changes:

- Drop support for Composer
- Drop support for PHP Quality Assurance Toolchain
- Drop support for Subversion
- Use nginx rather than Apache
- Increase the maximum file upload size in both nginx and PHP config files
- Make www-data the default owner of the synced Vagrant directory

# What's Installed

+ Ubuntu 16.04
+ Wordpress
+ MariaDB
+ PHP
+ phpMyAdmin
+ Git
+ XDebug

# Prerequisites

+ [Vagrant](http://www.vagrantup.com/downloads.html)
+ [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
+ [Vagrant Hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)

## Getting Started

This is a fairly simple project to get up and running. The procedure for
starting up a working WordPress is as follows:

1. [Download](https://github.com/LundgrenLindqvist/vagrantpress/archive/master.zip) the project
2. Extract the directory and `cd` into it
3. Run `vagrant plugin install vagrant-hostsupdater` if you haven't already
4. Run `vagrant up`
5. Open [vagrantpress.dev](http://vagrantpress.dev) in your browser

## Working with the environment

To log in to Wordpress:

URL: http://vagrantpress.dev/wp-admin/
Username: `admin`
Password: `vagrant`

To log in to phpMyAdmin:

URL: http://vagrantpress.dev/phpmyadmin/
Username: `wordpress`
Password: `wordpress`

## Common Troubleshooting Tips

* Have a look at the [troubleshooting guide][ts]

## Getting Help

Feel free to file an issue, create a pull request, or contact me at [my website][chadthompson].

[chadthompson]: http://chadthompson.me
[ts]: https://github.com/chad-thompson/vagrantpress/wiki/Troubleshooting-tips
