class { 'locales':
  locales => [ 'en_US.UTF-8 UTF-8'],
  default_locale => 'en_US.UTF-8',
}


class { 'postgresql::server':
  ip_mask_allow_all_users    => '0.0.0.0/0',
  listen_addresses           => '*',
  postgres_password          => 'postgres',
  ipv4acls                   => ['local all all trust', 'host all all 0.0.0.0/0 trust'],
  manage_pg_hba_conf         => true,
  require  => Package['postgresql-server-dev-9.1'],
}

#postgresql::server::role { 'openerp':
#  password_hash => postgresql_password('openerp', 'openerp'),
#}

postgresql::server::db { 'openerpdev':
  user     => 'openerp',
  password => postgresql_password('openerp', 'openerp'),
}

#postgresql::server::database_grant { 'openerpdev':
#  privilege => 'ALL',
#  db        => 'openerpdev',
#  role      => 'openerp',
#}

package { 'postgresql-server-dev-9.1':
    ensure => installed,
    require  => Exec['apt-get update'],
}

package { 'wget':
  ensure => installed,
  require  => Exec['apt-get update'],
}

exec { "apt-get update":
    command => "/usr/bin/apt-get update",
    onlyif => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
}