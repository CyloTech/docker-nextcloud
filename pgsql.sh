#!/bin/bash
set -e

POSTGRESQL_USER=${ADMIN_USER}
POSTGRESQL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
POSTGRESQL_DB=${POSTGRESQL_DB:-"nextcloud"}
POSTGRESQL_TEMPLATE=${POSTGRESQL_TEMPLATE:-"DEFAULT"}


echo "<?php
\$AUTOCONFIG = array(
  'dbtype'        => 'pgsql',
  'dbname'        => '${POSTGRESQL_DB}',
  'dbuser'        => '${POSTGRESQL_USER}',
  'dbpass'        => '${POSTGRESQL_PASS}',
  'dbhost'        => 'localhost:5432',
  'dbtableprefix' => 'nc_',
  'adminlogin'    => '${ADMIN_USER}',
  'adminpass'     => '${ADMIN_PASS}',
  'directory'     => '/data',
);" > /config/www/nextcloud/config/autoconfig.php

POSTGRESQL_BIN=/usr/bin/postgres
POSTGRESQL_CONFIG_FILE=/etc/postgresql/9.6/main/postgresql.conf
POSTGRESQL_DATA=/var/lib/postgresql/9.6/main

mkdir -p $POSTGRESQL_DATA

mkdir -p /etc/postgresql/9.6/main

mkdir /var/run/postgresql
chown postgres:postgres /var/run/postgresql

POSTGRESQL_SINGLE="sudo -u postgres $POSTGRESQL_BIN --single --config-file=$POSTGRESQL_CONFIG_FILE"

chown -R postgres:postgres $POSTGRESQL_DATA
sudo -u postgres /usr/bin/initdb -D $POSTGRESQL_DATA -E 'UTF-8'
ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem $POSTGRESQL_DATA/server.crt
ln -s /etc/ssl/private/ssl-cert-snakeoil.key $POSTGRESQL_DATA/server.key

$POSTGRESQL_SINGLE <<< "CREATE USER $POSTGRESQL_USER WITH SUPERUSER;" > /dev/null
$POSTGRESQL_SINGLE <<< "ALTER USER $POSTGRESQL_USER WITH PASSWORD '$POSTGRESQL_PASS';" > /dev/null
$POSTGRESQL_SINGLE <<< "CREATE DATABASE $POSTGRESQL_DB OWNER $POSTGRESQL_USER TEMPLATE $POSTGRESQL_TEMPLATE;" > /dev/null

exec sudo -u postgres $POSTGRESQL_BIN --config-file=$POSTGRESQL_CONFIG_FILE

exec "$@"