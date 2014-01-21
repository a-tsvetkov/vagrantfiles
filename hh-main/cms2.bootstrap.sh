#!/usr/bin/env bash

# Customize this to point to your DB host
export PGHOST=192.168.14.20
export PGUSER=postgres
export PGPASSWORD=1234

USER=vagrant
PROJECTS_FOLDER=/home/${USER}/projects

# Install necessary packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y uwsgi-plugin-python \
    git git-buildpackage \
    cdbs debhelper \
    postgresql-client-8.4 \
    python-setuptools python-virtualenv python-all python-dev \
    debhelper libxslt-dev libpcre++-dev w3c-dtd-xhtml libpq-dev coffeescript

# Give back project folder permission to our user
mkdir $PROJECTS_FOLDER
chown ${USER}:${USER} $PROJECTS_FOLDER

cd $PROJECTS_FOLDER

# Build and cms package
cp -r $PROJECTS_FOLDER/hh-cms /tmp
cd /tmp/hh-cms
python setup.py nosetests
dpkg-buildpackage

dpkg -i /tmp/hh-cms_*.deb

# # Init DB schema
# psql -d hh < $PROJECTS_FOLDER/hh-cms/scripts/init/bootstrap.sql
# psql -d hh < $PROJECTS_FOLDER/hh-cms/scripts/init/data.sql

# # Add custom user
# echo "INSERT INTO cms.account VALUES (5575917)" | psql -d hh
# echo "INSERT INTO cms.account_role (userid, role) VALUES (5575917, 'chief_editor')" | psql -d hh

# Update config db url to point to db host
DB_URI="postgresql\:\/\/cms\.app\:123\@$PGHOST\/hh"
sudo sed -i "s/\(db.url\s*=\s*\).*\$/\1$DB_URI/" /etc/hh-cms/hh-cms.conf

STATIC_HOST="http:\/\/i.hh.ru.dev\/cms\/"
sudo sed -i "s/\(webassets.base_url\s*=\s*\).*\$/\1$STATIC_HOST/" /etc/hh-cms/hh-cms.conf

start hh-cms
