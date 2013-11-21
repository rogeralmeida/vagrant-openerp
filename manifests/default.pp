class { 'locales':
  locales => [ 'en_US.UTF-8 UTF-8'],
  default_locale => 'en_US.UTF-8',
}

include rvm
rvm::system_user { vagrant: ; }

rvm_system_ruby {
  'ruby-1.9.3-p448':
  ensure => 'present',
  require  => Exec['apt-get update'],
  default_use => true;
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

$openerp_dependencies = ["python-dateutil","python-feedparser", "python-gdata", "python-ldap",
"python-libxslt1", "python-lxml", "python-mako", "python-openid", "python-psycopg2", 
"python-pybabel", "python-pychart", "python-pydot", "python-pyparsing", "python-reportlab", 
"python-simplejson", "python-tz", "python-vatnumber", "python-vobject", "python-webdav",
"python-werkzeug", "python-xlwt", "python-yaml", "python-zsi"]

package{ $openerp_dependencies: 
  ensure => installed,
  require  => Exec['apt-get update'],
}

define download_file(
        $site="",
        $cwd="",
        $creates="",
        $require="",
        $user="") {                                                                                         

    exec { $name:                                                                                                                     
        command => "/usr/bin/wget ${site}/${name}",                                                         
        cwd => $cwd,
        creates => "${cwd}/${name}",                                                              
        require => $require,
        user => $user,                                                                                                          
    }

}

download_file { [                                                                                                                     
      "openerp_7.0-20121227-075624-1_all.deb"
    ]:                                                                                                                                
    site => "http://nightly.openerp.com/7.0/nightly/deb/",
    cwd => "${repo_root}/",                                                                            
    creates => "${repo_root}/$name",                                                                  
    require => Package["wget"],                                                                  
    user => $repo_owner,                                                                                                              
}

package { 'openerp' :
  ensure => installed,
  source => '/tmp/openerp_7.0-20121227-075624-1_all.deb',
  provider => 'dpkg',
}

package { 'wget':
  ensure => installed,
  require  => Exec['apt-get update'],
}

exec { 'enable ufw':
  command => 'sudo ufw enable',
  path => ['/usr/bin/','usr/local/bin/', '/bin/'],
}

exec { 'allow connections on port 8069':
  command => 'sudo ufw allow 8069',
  path => ['/usr/bin/','usr/local/bin/', '/bin/'],
}

exec { "apt-get update":
    command => "/usr/bin/apt-get update",
    onlyif => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
}