DB_NETWORK=192.168.14.0/24
SUPERUSER_PASSWORD=1234

# Install postgresql database server
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y postgresql

# Update locale settings
cat /usr/share/i18n/SUPPORTED | grep '\(ru_RU\|en_US\)' > /var/lib/locales/supported.d/local
dpkg-reconfigure locales

# Set default locale to support UTF-8
pg_dropcluster --stop 8.4 main
pg_createcluster --start --locale=en_US.UTF-8 8.4 main

# Allow database network access
echo "host    all         all         $DB_NETWORK       md5" >> /etc/postgresql/8.4/main/pg_hba.conf
echo "listen_addresses = '*'" >> /etc/postgresql/8.4/main/postgresql.conf

/etc/init.d/postgresql-8.4 restart

# Create main database
sudo -u postgres createdb hh

# Add hh-specific roles
echo "CREATE ROLE role_rw;" | sudo -u postgres psql hh
echo "CREATE ROLE role_ro;" | sudo -u postgres psql hh

# Set superuser password
echo "ALTER ROLE \"postgres\" WITH PASSWORD '$SUPERUSER_PASSWORD';" | sudo -u postgres psql
