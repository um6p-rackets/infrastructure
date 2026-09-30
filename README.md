# Racket UM6P - Infrastructure

This repository is the central control hub for the Racket UM6P platform. It contains the Docker Compose configurations, the NGINX API Gateway, the PostgreSQL database setup, and the orchestration scripts needed to run the entire microservices architecture both locally and in production.

## 📁 Repository Structure

here is what each file and folder does:

* **`setup.sh`**: A bash script that automatically clones the `backend` and `frontend` repositories into the same parent directory and generates your `.env` file.
* **`Makefile`**: The central command-line interface for the team. It abstracts complex Docker Compose commands into simple, memorable shortcuts.
* **`docker-compose.yml`**: The base production configuration. It defines the core network, the database, and the gateway, and expects pre-built microservice images.
* **`docker-compose.dev.yml`**: The local development override. It maps local source code into the containers for hot-reloading and builds images directly from your local `backend` and `frontend` folders.
* **`database/`**: Contains the PostgreSQL infrastructure.
* `Dockerfile`: Builds the custom database image.
* `tools/`: Directory containing database initialization scripts (e.g., creating `db_auth`, `db_club`, `db_notif` on first boot).


* **`gateway/`**: Contains the NGINX API Gateway infrastructure.
* `Dockerfile`: Builds the NGINX reverse proxy image.
* `conf/`: Directory containing the NGINX routing configuration files that direct traffic to the correct microservice or frontend.



## 🚀 Getting Started (Local Development)

To get the entire stack running on your machine for the first time, follow these steps:

1. **Clone this repository** into a dedicated workspace folder:
```bash
git clone git@github.com:um6p-rackets/infrastructure.git
cd racket-infra

```


2. **Run the setup script** to clone the sibling repositories:
```bash
make setup

```


3. **Build and start the local development stack**:
```bash
make dev-build

```



Once running, the NGINX Gateway will listen on port `80` (or `8080` if configured), routing `/api/*` traffic to your NestJS services and the rest to your Next.js frontend.

## 🛠️ Essential Makefile Commands

Use these commands during your daily workflow to manage the system:

| Command | Description |
| --- | --- |
| `make setup` | Clones frontend/backend repos and initializes the `.env` file. |
| `make dev` | Starts the local environment (uses existing builds + hot reload). |
| `make dev-build` | Forces a rebuild of all local Dockerfiles and starts the environment. |
| `make dev-down` | Stops and removes the local development containers. |
| `make logs` | Tails the logs for all running containers in real-time. |
| `make logs-gateway` | Tails only the NGINX Gateway logs (useful for debugging API routing). |
| `make db-shell` | Drops you into an interactive `psql` terminal inside the database container. |
| `make db-reset` | **WARNING:** Destroys the database volume and restarts it from scratch. |
| `make clean` | Prunes dangling Docker images, volumes, and networks to free up disk space. |

## 🏗️ Architecture Notes for the Team

* **Database Isolation:** Even though there is only one PostgreSQL container running (`racket_db`), it holds three completely separate logical databases (`db_auth`, `db_club`, `db_notif`). Do not attempt to write SQL joins across these databases.
* **API Gateway Routing:** All frontend API calls must be made to the single gateway domain, not directly to the microservices. NGINX will route the request based on the path (e.g., `/api/clubs/` goes to the Club Service). Check `gateway/conf/` if a route is returning a 404.