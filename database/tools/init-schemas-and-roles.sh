#!/bin/sh
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v auth_pw="$(cat /run/secrets/auth_service_password)" \
  -v club_pw="$(cat /run/secrets/club_service_password)" \
  -v notif_pw="$(cat /run/secrets/notification_service_password)" \
  -v auth_user="$AUTH_USER" \
  -v club_user="$CLUB_USER" \
  -v notif_user="$NOTIFICATION_USER" \
  -v auth_schema="$AUTH_SCHEMA" \
  -v club_schema="$CLUB_SCHEMA" \
  -v notif_schema="$NOTIFICATION_SCHEMA" <<'EOF'

  CREATE ROLE :"auth_user"  LOGIN PASSWORD :'auth_pw';
  CREATE ROLE :"club_user"  LOGIN PASSWORD :'club_pw';
  CREATE ROLE :"notif_user" LOGIN PASSWORD :'notif_pw';

  CREATE SCHEMA :"auth_schema"  AUTHORIZATION :"auth_user";
  CREATE SCHEMA :"club_schema"  AUTHORIZATION :"club_user";
  CREATE SCHEMA :"notif_schema" AUTHORIZATION :"notif_user";

  ALTER ROLE :"auth_user"  SET search_path = :"auth_schema";
  ALTER ROLE :"club_user"  SET search_path = :"club_schema";
  ALTER ROLE :"notif_user" SET search_path = :"notif_schema";

  REVOKE ALL ON SCHEMA public FROM PUBLIC;
EOF
