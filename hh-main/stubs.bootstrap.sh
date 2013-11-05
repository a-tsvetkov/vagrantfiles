#!/usr/bin/env bash

# Customize this to point to your DB host
export PGHOST=192.168.14.20
export PGUSER=postgres
export PGPASSWORD=1234

# User name and folder to store projects
USER=vagrant
PROJECTS_FOLDER=/home/${USER}/projects

# Install necessary packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git-core git-buildpackage \
    postgresql-client-8.4 \
    debhelper cdbs \
    python-lxml \
    nginx apache2 libapache2-mod-wsgi \
    php5-pgsql php5-cli php5-xcache spawn-fcgi php5-curl php5-cgi psmisc

# Give back project folder permission to our user
mkdir $PROJECTS_FOLDER
chown ${USER}:${USER} $PROJECTS_FOLDER

# Build and install stub translation service
cd $PROJECTS_FOLDER/hh-php-app
git checkout unstable
sudo -u ${USER} dpkg-buildpackage
git checkout master

cd $PROJECTS_FOLDER/hh-php-packages/hh-translation/
sudo -u ${USER} dpkg-buildpackage
mv $PROJECTS_FOLDER/hh-php-packages/hh-translation_* $PROJECTS_FOLDER/

dpkg -i $PROJECTS_FOLDER/*.deb

# Configure apache2 to serve stubs
cp /vagrant/stubs.apache2.conf /etc/apache2/sites-available/
rm /etc/apache2/sites-enabled/000-default
ln -s /etc/apache2/sites-available/stubs.apache2.conf /etc/apache2/sites-enabled/
a2enmod rewrite
a2enmod headers
/etc/init.d/apache2 restart

# Configure nginx for translation service
cp /vagrant/stubs.nginx.conf /etc/nginx/sites-available/
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/stubs.nginx.conf /etc/nginx/sites-enabled/
/etc/init.d/nginx restart

# Create translation schema
psql -d hh < $PROJECTS_FOLDER/hh-php-packages/hh-translation/bootstrap.sql
psql -d hh < $PROJECTS_FOLDER/hh-php-packages/hh-translation/insert_translations.sql

echo "CREATE INDEX translation_key_idx on translation(key);" | psql -d hh

# Load translations
gunzip -c /vagrant/trl.sql | psql -d hh


# Configure translation service to use our db host
cat > /etc/hh-php-app/db.hh-translation.conf.php <<EOF
<?php
   \$conf = array('dsn' => 'pgsql://translation.app:123@$PGHOST/hh?charset=utf8',);

EOF

/etc/init.d/hh-php-app restart
