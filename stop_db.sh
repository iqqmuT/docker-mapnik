#!/usr/bin/env bash

# Stop PostgreSQL server.

PREFIX=""
if [ "$(id -u)" = '0' ]; then
	PREFIX="gosu postgres"
fi

$PREFIX pg_ctl -D "${PGDATA}" -m fast -w stop
