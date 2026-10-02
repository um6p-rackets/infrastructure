#!/bin/sh

set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v auth_pw="$(cat /run/secrets/auth_db_password)" \
  -v club_pw="$(cat /run/secrets/club_db_password)" \
  -v notif_pw="$(cat /run/secrets/notification_db_password)" <<'EOF'

  CREATE ROLE auth_svc  LOGIN PASSWORD :'auth_pw';
  CREATE ROLE club_svc  LOGIN PASSWORD :'club_pw';
  CREATE ROLE notif_svc LOGIN PASSWORD :'notif_pw';

  CREATE SCHEMA auth         AUTHORIZATION auth_svc;
  CREATE SCHEMA club         AUTHORIZATION club_svc;
  CREATE SCHEMA notification AUTHORIZATION notif_svc;


  ALTER ROLE auth_svc  SET search_path = auth;
  ALTER ROLE club_svc  SET search_path = club;
  ALTER ROLE notif_svc SET search_path = notification;

  REVOKE ALL ON SCHEMA public FROM PUBLIC;
EOF