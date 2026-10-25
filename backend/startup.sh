#!/usr/bin/env bash
# wait for database to be ready
if [ ! -n "$DJANGO_SETTINGS_MODULE" ]; then
  export DJANGO_SETTINGS_MODULE=ciso_assistant.settings
fi
if [ ! -n "$DJANGO_SECRET_KEY" ]; then
  if [ ! -f db/django_secret_key ]; then
    openssl rand -hex 32 | install -m 600 /dev/stdin db/django_secret_key
    echo "generating initial Django secret key"
  fi
  export DJANGO_SECRET_KEY=$(<db/django_secret_key)
  echo "Django secret key read from file"
fi
while ! python manage.py showmigrations iam >/dev/null; do
  echo "database not ready; waiting"
  sleep 15
done
python manage.py migrate --settings="${DJANGO_SETTINGS_MODULE}" || { echo "ERROR: database migration failed (see traceback above); backend not started, fix the error then restart the container" >&2; exit 1; }
python manage.py storelibraries --settings="${DJANGO_SETTINGS_MODULE}" || echo "WARNING: storing built-in libraries failed (see traceback above); backend starting anyway, new or updated libraries may be missing" >&2
if [ -n "$DJANGO_SUPERUSER_EMAIL" ]; then
  python manage.py createsuperuser --noinput --settings="${DJANGO_SETTINGS_MODULE}"
fi

# Set default values for Gunicorn configuration
GUNICORN_WORKERS=${GUNICORN_WORKERS:-3}
GUNICORN_TIMEOUT=${GUNICORN_TIMEOUT:-100}
GUNICORN_KEEPALIVE=${GUNICORN_KEEPALIVE:-30}
GUNICORN_LIMIT_REQUEST_LINE=${GUNICORN_LIMIT_REQUEST_LINE:-5120}
GUNICORN_PORT=${PORT:-8000}

# AdhereOne: optionally run the Huey task worker inside this container (RUN_HUEY=true).
# Upstream shares the SQLite queue file between two containers through ./db; Render services
# cannot share a filesystem, so on Render the worker runs next to the API instead.
if [ "${RUN_HUEY:-false}" = "true" ]; then
  python manage.py run_huey -w "${HUEY_WORKERS:-2}" --scheduler-interval 60 &
fi

exec gunicorn --chdir ciso_assistant \
  --bind :$GUNICORN_PORT \
  --timeout $GUNICORN_TIMEOUT \
  --keep-alive $GUNICORN_KEEPALIVE \
  --workers=$GUNICORN_WORKERS \
  --limit-request-line=$GUNICORN_LIMIT_REQUEST_LINE \
  --env RUN_MAIN=true \
  ciso_assistant.wsgi:application
