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
  encoding                   => 'UTF8',
  require  => Exec['export language'],
}

postgresql::server::role { 'openerp':
  password_hash => postgresql_password('openerp', 'openerp'),
  createdb      => true,
  login         => true,
  superuser     => true,
}

postgresql::server::pg_hba_rule { 'allow application network to access app database':
  description => "Open up postgresql for openerp in localhost",
  type => 'host',
  database => 'all',
  user => 'openerp',
  address => '0.0.0.0/0',
  auth_method => 'trust',
  order       => 1,
}

user { 'openerp':
  ensure     => "present",
}

#sudo -u postgres createuser -s openerp

# postgresql::server::db { 'openerpdev':
#   user     => 'openerp',
#   password => postgresql_password('openerp', 'openerp'),
# }

# postgresql::server::grant { 'openerpdev':
#   privilege => 'ALL',
#   db        => 'openerpdev',
#   role      => 'openerp',
#   require   => Postgresql::Server::Db['openerpdev']
# }

# package { 'postgresql-server-dev-9.1':
#     ensure => installed,
#     require  => Exec['apt-get update'],
# }


$dependecies=["python-dateutil", "python-feedparser", "python-gdata", "python-ldap", 
"python-libxslt1", "python-lxml", "python-mako", "python-openid", "python-psycopg2", 
"python-pybabel", "python-pychart", "python-pydot", "python-pyparsing", "python-reportlab", 
"python-simplejson", "python-tz", "python-vatnumber", "python-vobject", "python-webdav", 
"docutils-common", "docutils-doc", "python-docutils", "python-jinja2", "python-mock", 
"python-psutil", "python-pygments", "python-roman", "python-unittest2",
"python-werkzeug", "python-xlwt", "python-yaml", "python-zsi", "wget", "bzr", "language-pack-en"] 

#export LC_ALL="en_US.utf-8"
#export LANGUAGE="en_US.utf-8"

exec {"export language":
  command => "/usr/sbin/update-locale LANG=en_US.UTF-8 LC_ALL=en_US.utf-8 LANGUAGE=en_US.utf-8"
}

package {$dependecies:
  ensure => "installed",
  require  => Exec['apt-get update'],
}

exec { "apt-get update":
    command => "/usr/bin/apt-get update",
    onlyif => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
}

#exec { "/usr/bin/wget --continue --progress=dot:mega --tries=0 http://nightly.openerp.com/7.0/nightly/src/openerp-7.0-latest.tar.gz -o /home/vagrant/openerp-7.0-latest.tar.gz":
#  creates  =>  "/home/vagrant/openerp-7.0-latest.tar.gz",
#  require => Package[ "wget" ],
#}

#exec {"/bin/tar -xzf /home/vagrant/openerp-7.0-latest.tar.gz /home/vagrant/openerp":
#  require => Exec["/usr/bin/wget --continue --progress=dot:mega --tries=0 http://nightly.openerp.com/7.0/nightly/src/openerp-7.0-latest.tar.gz -o /home/vagrant/openerp-7.0-latest.tar.gz"]
#}

# a fuller example, including permissions and ownership
file { "/opt/openerp":
    ensure => "directory",
    owner  => "ubuntu",
    group  => "ubuntu",
    mode   => 750,
    require => Package['bzr'],
}

file { "/opt/openerp/v7":
    ensure => "directory",
    owner  => "ubuntu",
    group  => "ubuntu",
    mode   => 750,
    require => File["/opt/openerp"],
}

file { "/opt/openerp/v7/addons":
    ensure => "directory",
    owner  => "ubuntu",
    group  => "ubuntu",
    mode   => 750,
    require => File["/opt/openerp/v7"],
}

exec {"/usr/bin/bzr checkout --lightweight lp:openerp-web/7.0 /opt/openerp/v7/web":
  creates => '/opt/openerp/v7/web/README',
  require => File["/opt/openerp/v7"],
  timeout     => 4800,
}

exec {"/usr/bin/bzr checkout --lightweight lp:openobject-server/7.0 /opt/openerp/v7/server":
  creates => '/opt/openerp/v7/server/README',
  require => File["/opt/openerp/v7"],
  timeout     => 4800,
}

exec {"/usr/bin/bzr checkout --lightweight lp:openobject-addons/7.0 /opt/openerp/v7/addons":
  creates => '/opt/openerp/v7/addons/account/account.py',
  require => File["/opt/openerp/v7/addons"],
  timeout     => 4800,
}

file {"/etc/openerp-server.conf":
  source => "/vagrant/openerp-server.conf",
  require => Exec["/usr/bin/bzr checkout --lightweight lp:openobject-server/7.0 /opt/openerp/v7/server"],
  mode => 640,
  owner => 'ubuntu'
}

file { "/var/log/openerp":
    ensure => "directory",
    owner => 'ubuntu',
    group => 'root'
}

file { "/etc/logrotate.d/openerp-server":
  source => "/opt/openerp/v7/server/install/openerp-server.logrotate",
  mode => 755,
  require => Exec["/usr/bin/bzr checkout --lightweight lp:openobject-server/7.0 /opt/openerp/v7/server"]
}

file {"/home/vagrant/.bashrc":
  source => '/vagrant/.bashrc'
}

# The way I installed OE V7 on Ubuntu 12.04: Add to /etc/apt/sources.lst (warning: no space between http: and //):

# deb http://nightly.openerp.com/7.0/nightly/deb/ ./

# Reread the sources and get the sources:

# sudo apt-get update

# Now install openERP and all the dependencies:

# sudo apt-get install openerp

#--------------- corrigir problema do encoding no postgres

#root@server:~# su postgres
# postgres@server:~ $ psql -U postgres
# psql (9.0.3)
# Type "help" for help.

# postgres=# update pg_database set datallowconn = TRUE where datname = 'template0';
# UPDATE 1
# postgres=# \c template0
# You are now connected to database "template0".
# template0=# update pg_database set datistemplate = FALSE where datname = 'template1';
# UPDATE 1
# template0=# drop database template1;
# DROP DATABASE
# template0=# create database template1 with template = template0 encoding = 'UTF8';
# CREATE DATABASE
# template0=# update pg_database set datistemplate = TRUE where datname = 'template1';
# UPDATE 1
# template0=# \c template1
# You are now connected to database "template1".
# template1=# update pg_database set datallowconn = FALSE where datname = 'template0';
# UPDATE 1
# template1=#