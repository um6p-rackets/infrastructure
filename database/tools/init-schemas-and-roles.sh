#!/bin/sh

set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v auth_pw="$(cat /run/secrets/auth_service_password)" \
  -v club_pw="$(cat /run/secrets/club_service_password)" \
  -v notif_pw="$(cat /run/secrets/notification_service_password)" <<'EOF'

  CREATE ROLE auth_service  LOGIN PASSWORD :'auth_pw';
  CREATE ROLE club_service  LOGIN PASSWORD :'club_pw';
  CREATE ROLE notif_service LOGIN PASSWORD :'notif_pw';

  CREATE SCHEMA auth         AUTHORIZATION auth_service;
  CREATE SCHEMA club         AUTHORIZATION club_service;
  CREATE SCHEMA notification AUTHORIZATION notif_service;


  ALTER ROLE auth_service  SET search_path = auth;
  ALTER ROLE club_service  SET search_path = club;
  ALTER ROLE notif_service SET search_path = notification;

  REVOKE ALL ON SCHEMA public FROM PUBLIC;
EOF