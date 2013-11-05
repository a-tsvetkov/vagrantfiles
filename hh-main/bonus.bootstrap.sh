#!/usr/bin/env bash

# Customize this to point to your DB host
export PGHOST=192.168.14.20
export PGUSER=postgres
export PGPASSWORD=1234

USER=vagrant
PROJECTS_FOLDER=/home/${USER}/projects

# Add custom repositories and install necessary packages
apt-get update
apt-get install -y python-software-properties

apt-add-repository ppa:uwsgi/release

# Install necessary packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y uwsgi-python \
    git-core \
    git-buildpackage \
    cdbs debhelper \
    python-support \
    python-all \
    python-all-dev \
    python \
    python-lxml \
    postgresql-client-8.4 \
    python-sqlalchemy \
    python-psycopg2 \
    python-configobj \
    python \
    python \
    python-dateutil \
    python-pkg-resources \
    curl \
    python-imaging \
    python-nose \
    python-webdav \
    python-setuptools

# Give back project folder permission to our user
mkdir $PROJECTS_FOLDER
chown ${USER}:${USER} $PROJECTS_FOLDER

cd $PROJECTS_FOLDER

# Build and install custom dependecies
sudo -u ${USER} git clone https://github.com/hhru/lucid-python-cerberus.git
sudo -u ${USER} git clone https://github.com/hhru/lucid-python-werkzeug.git
sudo -u ${USER} git clone https://github.com/hhru/pika.git

cd $PROJECTS_FOLDER/lucid-python-cerberus
sudo -u ${USER} git-buildpackage

cd $PROJECTS_FOLDER/lucid-python-werkzeug
sudo -u ${USER} git-buildpackage

cd $PROJECTS_FOLDER/pika
sudo -u ${USER} git checkout -b 0.9 origin/0.9
sudo -u ${USER} dpkg-buildpackage

dpkg -i $PROJECTS_FOLDER/build-area/*.deb
dpkg -i $PROJECTS_FOLDER/*.deb

# Build and cms package
cd $PROJECTS_FOLDER/employer-bonus
sudo -u ${USER} nosetests -v tests/
sudo -u ${USER} dpkg-buildpackage

dpkg -i $PROJECTS_FOLDER/hh-employer-bonus_*_all.deb

# Drop old schema
echo "DROP SCHEMA bonus CASCADE" | psql -d hh

# Init DB schema
psql -d hh < $PROJECTS_FOLDER/employer-bonus/scripts/init/bootstrap.sql
psql -d hh < $PROJECTS_FOLDER/employer-bonus/scripts/applied/EWD-731-hh-alter-before.sql

# Update config db url to point to db host
DB_URI="postgresql\:\/\/bonus\.app\:123\@$PGHOST\/hh"
sed -i "s/\(url\s*=\s*\).*\$/\1'$DB_URI'/" /etc/hh-employer-bonus/db.rc

# Update config db url to point to session host
SESSION_HOST="192\.168\.14\.11\/sessionHost\/"
SERVICE_HOST="http\:\/\/192\.168\.14\.11\/serviceHost\/"
sed -i "s/\(host\s*=\s*\)localhost\:19203\/\$/\1'$SESSION_HOST'/" /etc/hh-employer-bonus/common.rc
sed -i "s/\(dictionariesHost\s*=\s*\).*\$/\1'$SERVICE_HOST'/" /etc/hh-employer-bonus/common.rc

CRM_HOST="http\:\/\/192\.168\.14\.11\/crmHost"
sed -i "s/\(crm_sync_url\s*=\s*\).*\$/\1'$CRM_HOST\/CrmService'/" /etc/hh-employer-bonus/sync.rc
sed -i "s/\(crm_login_url\s*=\s*\).*\$/\1'$CRM_HOST\/HhidService'/" /etc/hh-employer-bonus/sync.rc

DAV_HOST="http:\/\/192.168.14.1"
sed -i "s/\(put_uri\s*=\s*\).*\$/\1'$DAV_HOST:8024\/ebonus\/'/" /etc/hh-employer-bonus/webdav.rc
sed -i "s/\(get_uri\s*=\s*\).*\$/\1'$DAV_HOST:8025\/ebonus\/'/" /etc/hh-employer-bonus/webdav.rc

start hh-employer-bonus
