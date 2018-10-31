#!/usr/bin/env bash
######################################################################
# Starts up the API and dependent services via
# docker-compose. The API will be available on localhost:9000
#
# Options:
#   -t, --timeout seconds: overwrite default timeout, default of 60
######################################################################

DIR=$( cd $(dirname $0) ; pwd -P )
TIMEOUT=60

function usage {
    printf "usage: docker-up-api-server.sh [OPTIONS]\n\n"
    printf "starts up a local VinylDNS API installation using docker compose\n\n"
    printf "options:\n"
    printf "\t-t, --timeout seconds: overwrite the timeout used when waiting for components to startup, default of 60\n"
}

while [ "$1" != "" ]; do
    case "$1" in
        -t | --timeout ) TIMEOUT="$2";  shift;;
        * ) usage; exit;;
    esac
    shift
done

echo "timeout set to $TIMEOUT"

set -a # Required in order to source docker/.env
# Source customizable env files
source "$DIR"/.env
source "$DIR"/../docker/.env

echo "Starting API server and all dependencies in the background..."
docker-compose -f "$DIR"/../docker/docker-compose-api.yml up -d

echo "Waiting for API to be ready at ${VINYLDNS_API_URL} ..."
DATA=""
RETRY="$TIMEOUT"
while [ "$RETRY" -gt 0 ]
do
    DATA=$(curl -I -s "${VINYLDNS_API_URL}/ping" -o /dev/null -w "%{http_code}")
    if [ $? -eq 0 ]
    then
        echo "Succeeded in connecting to VinylDNS API!"
        break
    else
        echo "Retrying Again" >&2

        let RETRY-=1
        sleep 1

        if [ "$RETRY" -eq 0 ]
        then
          echo "Exceeded retries waiting for VinylDNS API to be ready, failing"
          exit 1
        fi
    fi
done
