# Installs and configures the swift proxy node.
#
# [*Parameters*]
#
# [*allow_account_management*]
# [*account_autocreate*] Rather accounts should automatically be created.
#  I think this may be tempauth specific
# [*proxy_local_net_ip*] The address that the proxy will bind to.
#   Optional. Defaults to 0.0.0.0
# [*proxy_port*] Port that the swift proxy service will bind to.
#   Optional. Defaults to 11211
# [*auth_type*] - Type of authorization to use.
#  valid values are tempauth, swauth, and keystone.
#  Optional. Defaults to tempauth.
# [*package_ensure*] Ensure state of the swift proxy package.
#   Optional. Defaults to present.
#
# == sw auth specific configuration
# [*swauth_endpoint*]
# [*swauth_super_admin_user*]
#
# == Dependencies
#
#   Class['memcached']
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::proxy(
  $allow_account_management = true,
  $account_autocreate = false,
  $proxy_local_net_ip = '0.0.0.0',
  $proxy_port = '11211',
  $auth_type = 'tempauth',
  $swauth_endpoint = '127.0.0.1',
  $swauth_super_admin_key = 'swauthkey',
  $package_ensure = 'present'
) inherits swift {

  Class['memcached'] -> Class['swift::proxy']

  validate_re($auth_type, 'tempauth|swauth|keystone')

  if(auth_type == 'keystone') {
    fail('Keystone is currently not supported, it should be supported soon :)')
  }

  package { 'openstack-swift-proxy':
    ensure => $package_ensure,
  }

  if($auth_type == 'swauth') {
    package { 'python-swauth':
      ensure  => $package_ensure,
      before  => Package['openstack-swift-proxy'],
    }
  }

  file { "/etc/swift/proxy-server.conf":
    ensure  => present,
    owner   => 'swift',
    group   => 'swift',
    mode    => 0660,
    content => template('swift/proxy-server.conf.erb'),
    require => Package['openstack-swift-proxy'],
  }

  # TODO - this needs to be updated once the init file is not broken

  file { '/etc/init/swift-proxy.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => '
# swift-proxy - SWIFT Proxy Server
# This is temporarily managed by Puppet
# until 917893 is fixed
# The swift proxy server.

description     "SWIFT Proxy Server"
author          "Marc Cluet <marc.cluet@ubuntu.com>"

start on runlevel [2345]
stop on runlevel [016]

pre-start script
  if [ -f "/etc/swift/proxy-server.conf" ]; then
    exec /usr/bin/swift-init proxy-server start
  else
    exit 1
  fi
end script

post-stop exec /usr/bin/swift-init proxy-server stop',
    before => Service['openstack-swift-proxy'],
  }

  service { 'openstack-swift-proxy':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/swift/proxy-server.conf'],
  }
}
