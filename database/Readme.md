# PostgreSQL Database Architecture (Schema-per-Service)

## Overview
For the `ft_transcendence` project, we are using the **Shared Database Microservices Pattern**. Instead of running multiple separate database containers (which breaks relational foreign keys) or using one monolithic `public` schema (which violates microservice isolation), we use a **Schema-per-Service** design.

We run a single lightweight `postgres:18.6-alpine3.24` container, but internally, the database is partitioned into strict, logical schemas (`auth`, `club`, `notification`). Each NestJS backend service has its own dedicated PostgreSQL Role (user) and is locked into its respective schema.

### Advantages of this Design
1. **Data Integrity (ACID compliance):** We retain PostgreSQL's native ability to enforce Foreign Keys and `ON DELETE CASCADE` across different microservices (e.g., deleting a User in `auth` automatically cascades to their `club` memberships).
2. **Security & Isolation:** The `auth` service logs in as `auth_svc` and cannot accidentally drop tables or modify data owned by the `club` service.
3. **No Distributed Transactions:** We avoid the immense complexity of "Saga patterns" or slow cross-container HTTP network requests just to combine user data with club data.
4. **Automated Migrations:** We do not manually write SQL `CREATE TABLE` scripts. The database provides the empty "plots of land" (schemas), and our backend ORM constructs the buildings (tables).

---

## Configuration Files

### 1. The `Dockerfile`
Our Dockerfile copies our custom configuration and our initialization shell script. It enforces strict permission boundaries before booting.

```dockerfile
FROM postgres:18.6-alpine3.24

# 1. Copy the custom configuration file
COPY ./config/postgresql.conf /etc/postgresql/postgresql.conf

# 2. Copy the initialization script to the magic folder
COPY ./tools/setup.sh /docker-entrypoint-initdb.d/setup.sh
RUN chmod +x /docker-entrypoint-initdb.d/setup.sh

# 3. Security: Change ownership to the restricted 'postgres' user
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/ \
    && chown postgres:postgres /etc/postgresql/postgresql.conf \
    && chmod 644 /etc/postgresql/postgresql.conf

# 4. Expose the default port for the Docker internal network
EXPOSE 5432

# 5. Boot using the custom configuration
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

```

### 2. The Initialization Script (`setup.sh`)

Because we rely on our backend ORM to create the tables, our database initialization only handles **infrastructure provisioning**. This script dynamically reads Docker secrets to create isolated roles and binds them to specific search paths.

```bash
#!/bin/sh
set -e

# Connect to Postgres and execute setup commands
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v auth_pw="$(cat /run/secrets/auth_db_password)" \
  -v club_pw="$(cat /run/secrets/club_db_password)" \
  -v notif_pw="$(cat /run/secrets/notification_db_password)" <<'EOF'

  -- Create isolated service roles with passwords
  CREATE ROLE auth_svc  LOGIN PASSWORD :'auth_pw';
  CREATE ROLE club_svc  LOGIN PASSWORD :'club_pw';
  CREATE ROLE notif_svc LOGIN PASSWORD :'notif_pw';

  -- Create schemas owned by their respective services
  CREATE SCHEMA auth         AUTHORIZATION auth_svc;
  CREATE SCHEMA club         AUTHORIZATION club_svc;
  CREATE SCHEMA notification AUTHORIZATION notif_svc;

  -- Default each service to its own schema (so they don't use 'public')
  ALTER ROLE auth_svc  SET search_path = auth;
  ALTER ROLE club_svc  SET search_path = club;
  ALTER ROLE notif_svc SET search_path = notification;

  -- Lock down the public schema for security
  REVOKE ALL ON SCHEMA public FROM PUBLIC;
EOF

```

---

## The "First Boot" Setup Rule (CRITICAL)

PostgreSQL is highly protective of your data. The automated setup process (which runs `setup.sh`) **only triggers if the mapped storage volume is 100% empty.**

If you modify `setup.sh` and rebuild the container, PostgreSQL will see existing data in the storage directory, skip the initialization folder, and your new schemas/roles will not be created.

**To apply infrastructure changes:** You must completely wipe the host data volume using `make fclean` before rebuilding the stack.

---

## Testing & Verification Commands

Once the container is running and healthy, use these commands to verify the Schema-per-Service architecture was built correctly.

### 1. Verify Superuser Infrastructure

Enter the container and connect as the admin:

```bash
docker exec -it database sh
psql -U admin -d rackets_db

```

Inside the `psql` prompt, check your Roles and Schemas:

* `\du` : Lists all roles. You should see `admin`, `auth_svc`, `club_svc`, and `notif_svc`.
* `\dn+` : Lists all schemas. You should see `auth`, `club`, and `notification` owned by their respective service roles.
* `\q` : Quit the database.

### 2. Verify Service Isolation (The Ultimate Test)

To prove the architecture works, attempt to log in as a specific microservice (it will prompt for the password defined in your secrets):

```bash
psql -U auth_svc -d rackets_db -W

```

Once inside, verify that your default routing is locked to your specific schema:

```sql
SHOW search_path;

```

*(This should output `auth`, proving the service is perfectly isolated).*

---

## Backend Integration (How NestJS Uses This)

Our NestJS microservices will connect to this database using **Prisma** (our chosen ORM).

Because the database handles the isolation layer, the backends require very little configuration:

1. **Connection Strings:** Each NestJS service gets a unique database URL injected via `.env`. For example, the Auth service connects using `postgres://auth_svc:<secret>@database:5432/rackets_db?schema=auth`.
2. **Automated Migrations:** When a backend container boots, Prisma automatically detects the empty `auth` schema, reads our TypeScript backend models, and executes the SQL to generate the `users` table seamlessly.
3. **Cross-Service References:** Because all schemas live in `rackets_db`, Prisma can safely declare foreign key relations (e.g., Club Service mapping a member to `auth.users`) while respecting the database boundaries.