#!/bin/sh

# Tuning the PostgreSQL server for OSM2PGSQL.
# https://osm2pgsql.org/doc/manual.html#tuning-the-postgresql-server
#
# You can see run-time values by:
# $ psql -d gis -c 'SHOW ALL'

set -e
export PGUSER="$POSTGRES_USER"

psql -c "ALTER SYSTEM SET shared_buffers='${PG_SHARED_BUFFERS:-1GB}';"
# work_mem and maintenance_work_mem is set in tune-postgis.sh
psql -c "ALTER SYSTEM SET autovacuum_work_mem='${PG_AUTOVACUUM_WORK_MEM:-1GB}';"
psql -c "ALTER SYSTEM SET wal_level='${PG_WAL_LEVEL:-minimal}';"
psql -c "ALTER SYSTEM SET checkpoint_timeout='${PG_CHECKPOINT_TIMEOUT:-60min}';"
psql -c "ALTER SYSTEM SET max_wal_size='${PG_MAX_WAL_SIZE:-5GB}';"
psql -c "ALTER SYSTEM SET checkpoint_completion_target='${PG_CHECKPOINT_COMPLETION_TARGET:-0.9}';"
psql -c "ALTER SYSTEM SET max_wal_senders='${PG_MAX_WAL_SENDERS:-0}';"
psql -c "ALTER SYSTEM SET random_page_cost='${PG_RANDOM_PAGE_COST:-1.0}';"
