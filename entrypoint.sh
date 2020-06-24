#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Send to sleep imediatly when you choose to run container in debug mode
if [ $1 = "debug" ]
then
	exec tail -f /dev/null
fi

# Set default gunicorn config values
export SERVICE_TIMEOUT=${SERVICE_TIMEOUT:-60}
export SUPERSET_LOAD_EXAMPLES=${SUPERSET_LOAD_EXAMPLES:-"true"}
export SUPERSET_GUNICORN_PORT=${SUPERSET_GUNICORN_PORT:-8088}
export SUPERSET_GUNICORN_WORKERS=${SUPERSET_GUNICORN_WORKERS:-3}
export SUPERSET_GUNICORN_TIMEOUT=${SUPERSET_GUNICORN_TIMEOUT:-120}
export SUPERSET_GUNICORN_GRACEFUL_TIMEOUT=${SUPERSET_GUNICORN_GRACEFUL_TIMEOUT:-120}
export SUPERSET_GUNICORN_MAX_REQUESTS=${SUPERSET_GUNICORN_MAX_REQUESTS:-1000}
export SUPERSET_GUNICORN_LIMIT_REQUEST_LINE=${SUPERSET_GUNICORN_LIMIT_REQUEST_LINE:-0}
export SUPERSET_GUNICORN_LIMIT_REQUEST_FIELD_SIZE=${SUPERSET_GUNICORN_LIMIT_REQUEST_FIELD_SIZE:-0}

# Wait for external services
for temp_host in $(env | grep WAIT_FOR_SVC | sed s/.*=// | sed '/^$/d')
do

    echo "Attempting to call ${temp_host}"

    wait-for-it -t $SERVICE_TIMEOUT $temp_host

    echo "${temp_host} is up"

done


# Initialize the database
superset db upgrade

# Create admin user
superset fab create-admin \
              --username admin \
              --firstname admin \
              --lastname admin \
              --email email@email.email \
              --password admin

# Optionally load some data to play with 
if [ "$SUPERSET_LOAD_EXAMPLES" = "true" ] 
then
    echo "Loading examples"
    superset load_examples
fi 

# Create default roles and permissions
superset init

# Run superset
case "$1" in
    superset)
            exec gunicorn \
                 --bind 0.0.0.0:$SUPERSET_GUNICORN_PORT \
                 --workers $SUPERSET_GUNICORN_WORKERS \
                 -k gevent \
                 --timeout $SUPERSET_GUNICORN_TIMEOUT \
                 --graceful-timeout $SUPERSET_GUNICORN_GRACEFUL_TIMEOUT \
                 --max-requests ${SUPERSET_GUNICORN_MAX_REQUESTS} \
                 --limit-request-line $SUPERSET_GUNICORN_LIMIT_REQUEST_LINE \
                 --limit-request-field_size $SUPERSET_GUNICORN_LIMIT_REQUEST_FIELD_SIZE \
                "superset.app:create_app()"
      ;;                
	* )
	      echo "Invalid command - Shutting down"
	      exit 1
	;;              
esac

