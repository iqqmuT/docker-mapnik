#!/usr/bin/env bash

set -e

start_db.sh

# create database
createdb gis

psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

# allow root user to use database too
psql -c 'CREATE USER root;'
psql -c 'GRANT ALL PRIVILEGES ON DATABASE gis TO root;'

export OSM2PGSQL_CACHE=512
export OSM2PGSQL_NUMPROC=${OSM2PGSL_NUMPROC:-1}
export OSM2PGSQL_DATAFILE=${OSM2PGSQL_DATAFILE:-data.osm.pbf}

cd /opt/osm
osm2pgsql \
--cache $OSM2PGSQL_CACHE \
--number-processes $OSM2PGSQL_NUMPROC \
--hstore \
--multi-geometry \
--database gis \
--slim \
--drop \
--style openstreetmap-carto.style \
--tag-transform-script openstreetmap-carto.lua \
$OSM2PGSQL_DATAFILE

# download required shapefiles
scripts/get-external-data.py

# granting privileges on db is not enough; do the same for tables
psql -d gis -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO root;'

stop_db.sh
