class glance(
  $package_ensure = 'present',
  $keystone_auth_host = '127.0.0.1',
  $keystone_auth_port = '35357',
  $keystone_auth_protocol = 'http',
  $keystone_auth_uri = 'http://127.0.0.1:5000/',
  $keystone_admin_user = 'glance',
  $keystone_admin_password = 'SERVICE_PASSWORD',
  $keystone_admin_tenant_name = 'service',
  $api_flavor = '',
  $registry_flavor = ''
) {


  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'root',
    mode    => 770,
    require => Package['openstack-glance']
  }

  package { 'openstack-glance': ensure => $package_ensure }
  package { 'python-migrate': ensure => 'present' }

}
