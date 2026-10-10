# Schema-per-Service Pattern

One PostgreSQL container, one schema per microservice, one DB role per schema.

## Definition

Each service owns a database schema that is private to it. No other service reads or writes that schema. The services share a database server, but not their data.

Source: [Database per service, microservices.io](https://microservices.io/patterns/data/database-per-service) (Chris Richardson). It lists three ways to keep service data private:

| Variant | Isolation | Overhead |
|---|---|---|
| Private tables per service | Lowest | Lowest |
| **Schema per service (this project)** | Medium | Low |
| Database server per service | Highest | Highest |

## Architecture

```
            ┌────────────────── Postgres container ──────────────────┐
auth-service ──(auth_user)───▶  schema: auth                         │
club-service ──(club_user)───▶  schema: club                         │
notif-service ─(notif_user)──▶  schema: notification                 │
            └────────────────────────────────────────────────────────┘
```

## How it is enforced

Initialization runs once, from `init-db.sh`, when the data volume is empty.

| Step | SQL | Effect |
|---|---|---|
| 1 | `CREATE ROLE <svc>_user LOGIN PASSWORD ...` | One login per service |
| 2 | `CREATE SCHEMA <svc> AUTHORIZATION <svc>_user` | The role owns its schema |
| 3 | `ALTER ROLE <svc>_user SET search_path = <svc>` | Unqualified table names resolve to its own schema |
| 4 | `REVOKE ALL ON SCHEMA public FROM PUBLIC` | Nobody can use `public` by default |

Passwords come from Docker secrets (`/run/secrets/*`). Usernames and schema names come from environment variables.

## Rules

1. A service connects only with its own role.
2. No cross-schema queries, joins, or foreign keys.
3. To get another service's data, call its API or consume its events.
4. Never grant a service role access to another service's schema.

Breaking rules 2 to 4 turns this into a shared database, which the pattern exists to avoid ([Shared database](https://microservices.io/patterns/data/shared-database.html)).

## Connection strings

```
postgresql://<svc>_user:<password>@db:5432/<POSTGRES_DB>
```

- **Prisma (NestJS):** add `?schema=<svc_schema>`, otherwise it targets `public`, which is locked down.
- **SQLAlchemy / FastAPI:** the role's `search_path` already handles it. No extra config needed.

## Operations

- **Re-run the init script:** `docker compose down -v`, then `docker compose up`. This deletes all data.
- **Add a service:** add its secret, env vars, and the three statements (role, schema, `search_path`) to the script, then re-init, or run them manually on the live DB.
- **Migrations:** run per service, each with its own role.

## Trade-offs

| | Schema per service | Server per service |
|---|---|---|
| Containers / RAM | 1 | N |
| Backups | One | N |
| Failure isolation | Shared | Per service |
| Resource isolation | Shared | Per service |
| Split later | Config change, if rule 2 is respected | n/a |

**Use schema per service when** the team is small, resources are limited, and services have no special load or compliance needs.
**Move to server per service when** one service needs independent scaling, a different DB engine, or physical separation.