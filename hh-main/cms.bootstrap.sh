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
    python-pycurl python-support python-all python-all-dev \
    python-nose python-lxml python-werkzeug python-sqlalchemy \
    python-psycopg2 python-configobj w3c-dtd-xhtml python-webdav python-setuptools

# Give back project folder permission to our user
mkdir $PROJECTS_FOLDER
chown ${USER}:${USER} $PROJECTS_FOLDER

cd $PROJECTS_FOLDER

# Build and install custom dependecies
sudo -u ${USER} git clone https://github.com/hhru/lucid-python-cerberus.git

cd $PROJECTS_FOLDER/lucid-python-cerberus
sudo -u ${USER} git-buildpackage

dpkg -i $PROJECTS_FOLDER/build-area/*.deb

# Build and cms package
cd $PROJECTS_FOLDER/hh-cms
sudo -u ${USER} dpkg-buildpackage

dpkg -i $PROJECTS_FOLDER/hh-cms_*_all.deb

# Init DB schema
psql -d hh < $PROJECTS_FOLDER/hh-cms/scripts/init/bootstrap.sql
psql -d hh < $PROJECTS_FOLDER/hh-cms/scripts/init/data.sql

# Add custom user
echo "INSERT INTO cms.account VALUES (5575917)" | psql -d hh
echo "INSERT INTO cms.account_role (userid, role) VALUES (5575917, 'chief_editor')" | psql -d hh

# Update config db url to point to db host
DB_URI="postgresql\:\/\/cms\.app\:123\@$PGHOST\/hh"
sudo sed -i "s/\(url\s*=\s*\).*\$/\1'$DB_URI'/" /etc/hh-cms/db.rc

start hh-cms
