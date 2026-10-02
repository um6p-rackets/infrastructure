# Infrastructure

Docker setup for the project. It runs the database and gateway, and clones the frontend and backend repos next to this one.

## Requirements

- Docker + Docker Compose
- make
- git

## Structure

```
infrastructure/
├── database/                 # PostgreSQL image, config and init scripts
├── gateway/                  # Nginx gateway
├── secrets/                  # Secret files (not committed)
├── docker-compose.dev.yml    # Development
├── docker-compose.yml        # Production
├── .env.example
└── Makefile
```

After `make setup`, the parent directory looks like this:

```
../
├── infrastructure/
├── frontend/
└── backend/
```

## Getting started

1. Create the env file and fill in the values:

   ```bash
   cp .env.example .env
   ```

2. Create the password files in `secrets/` (default password: `pass1337`):

   ```bash
   mkdir -p secrets
   echo "pass1337" > secrets/db_password.txt
   echo "pass1337" > secrets/auth_db_password.txt
   echo "pass1337" > secrets/club_db_password.txt
   echo "pass1337" > secrets/notification_db_password.txt
   ```

   > Use this default for development only. Change the passwords in production.

3. Clone the repos, build and start:

   ```bash
   make
   ```

## Modes

Default mode is `dev`. For production:

```bash
MODE=prod make up
```

## Commands

| Command              | What it does                                      |
| -------------------- | ------------------------------------------------- |
| `make setup`         | Create data folder and clone frontend and backend |
| `make up`            | Start containers                                  |
| `make build`         | Build images and start containers                 |
| `make down`          | Stop and remove containers                        |
| `make stop`          | Stop containers                                   |
| `make start`         | Start stopped containers                          |
| `make status`        | Show running containers                           |
| `make pull_frontend` | `git pull` in `../frontend`                       |
| `make pull_backend`  | `git pull` in `../backend`                        |
| `make clean`         | Remove containers, volumes and orphans            |
| `make fclean`        | `clean` + delete database data + prune Docker     |
| `make re`            | `fclean` then rebuild                             |

> **Warning:** `make fclean` deletes `~/data/database` and runs `docker system prune -a --volumes`, which removes all unused Docker images and volumes on your machine.

## Database

- PostgreSQL, port `5432` in dev
- Data is stored in `~/data/database`
- User and database name come from `.env` (`DB_USER`, `DB_NAME`)
- Passwords are read from `secrets/`:

| File                           | Used for             |
| ------------------------------ | -------------------- |
| `db_password.txt`              | Main database user   |
| `auth_db_password.txt`         | Auth service         |
| `club_db_password.txt`         | Club service         |
| `notification_db_password.txt` | Notification service |
