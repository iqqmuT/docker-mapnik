#!/usr/bin/env bash

# Start PostgreSQL server.
# It cannot be run as root.

PREFIX=""
if [ "$(id -u)" = '0' ]; then
	PREFIX="gosu postgres"
fi

# internal start of server in order to allow setup using psql client
# does not listen on external TCP/IP and waits until start finishes
$PREFIX pg_ctl -D "${PGDATA}" -o "-c listen_addresses=''" -w start
