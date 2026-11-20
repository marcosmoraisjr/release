#!/bin/sh
# Sincroniza em segundo plano (a cada SYNC_INTERVAL s) e serve com o nginx em primeiro plano.
mkdir -p "${DATA:-/data}"
/usr/local/bin/sync.sh &
exec nginx -g 'daemon off;'
