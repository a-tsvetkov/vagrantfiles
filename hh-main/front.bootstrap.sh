#!/usr/bin/env bash

# User name and folder to store projects
USER=vagrant
PROJECTS_FOLDER=/home/${USER}/projects

export DEBIAN_FRONTEND=noninteractive

# Add custom repositories and install necessary packages
apt-get update
apt-get install -y python-software-properties

apt-add-repository
apt-add-repository ppa:lucid-bleed/ppa
apt-add-repository ppa:chris-lea/python-pylibmc
apt-add-repository ppa:chris-lea/libmemcached/

apt-get update
apt-get install -y nginx \
    debhelper cdbs \
    git-core git-buildpackage \
    python-pip python-dev \
    python-setuptools python-pycurl python-lxml python-dateutil \
    python-simplejson python-daemon python-protobuf python-pylibmc \
    maven2

# Alias maven to act as mvn-hh
ln -s /usr/bin/mvn /usr/bin/mvn-hh

# Give back project folder permission to our user
sudo -u vagrant mkdir $PROJECTS_FOLDER
chown ${USER}:${USER} $PROJECTS_FOLDER

cd $PROJECTS_FOLDER/

# Get custom packages and repos
sudo -u ${USER} wget https://www.dropbox.com/s/0j2mz0o1lwheo1n/hh-proto-api_1.139_all.deb
sudo -u ${USER} wget https://www.dropbox.com/s/3khi07dy2tksftv/python-hhsession_0.3.5.5_all.deb
sudo -u ${USER} wget https://www.dropbox.com/s/kz7ett0yi1hzcrf/python-protobuf_2.3.0-2ubuntu1_all.deb
sudo -u ${USER} wget https://www.dropbox.com/s/eigc1rnit1vo0gh/python-hhtranslations2-client_0.1.1_all.deb
sudo -u ${USER} git clone https://github.com/hhru/tornado.git
sudo -u ${USER} git clone https://github.com/hhru/tornado-util.git
sudo -u ${USER} git clone https://github.com/hhru/frontik.git

# Build and install dependencies
cd $PROJECTS_FOLDER/tornado
sudo -u ${USER} git-buildpackage
cd $PROJECTS_FOLDER/tornado-util
sudo -u ${USER} git-buildpackage --git-ignore-new
dpkg -i $PROJECTS_FOLDER/*.deb

# Build and install frontik
cd $PROJECTS_FOLDER/frontik
sudo -u ${USER} git-buildpackage
dpkg -i $PROJECTS_FOLDER/*.deb

# Build and install hh-frontik-common
cd $PROJECTS_FOLDER/hh.sites.common
sudo -u ${USER} git-buildpackage --git-ignore-new
dpkg -i $PROJECTS_FOLDER/hh-frontik-common_*_all.deb

# Use our frontik config
rm /etc/frontik/frontik.cfg
ln -s /vagrant/front.frontik.conf /etc/frontik/frontik.cfg

# Build main application
cd $PROJECTS_FOLDER/hh.sites.main
sudo -u ${USER} python setup.py build
python setup.py install

# Install pycrypto (required to run main application)
pip install pycrypto

/etc/init.d/frontik start

# Configure nginx as a proxy for main application and to serve static
cp /vagrant/front.nginx.conf /etc/nginx/sites-available/
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/front.nginx.conf /etc/nginx/sites-enabled/
/etc/init.d/nginx restart
