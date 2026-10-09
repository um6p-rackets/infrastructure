# ==============================================================================
#                                VARIABLES
# ==============================================================================
MKDIR        = mkdir -p
RM           = rm -rf

FRONTEND_URL = https://github.com/um6p-rackets/frontend.git
BACKEND_URL  = https://github.com/um6p-rackets/backend.git

DATABASE_VOL = $(HOME)/data/database
RABBITMQ_VOL = $(HOME)/data/rabbitmq

MODE ?= dev

ifeq ($(MODE), dev)
  COMPOSE = docker compose -f ./docker-compose.dev.yml
else ifeq ($(MODE), prod)
  COMPOSE = docker compose -f ./docker-compose.yml
else
  $(error Invalid MODE specified. Please use 'dev' or 'prod')
endif

# ==============================================================================
#                                 TARGETS
# ==============================================================================
all: setup build

setup: init ../frontend ../backend

../frontend:
	git clone $(FRONTEND_URL) $@

../backend:
	git clone $(BACKEND_URL) $@

init:
	$(MKDIR) $(DATABASE_VOL)
	$(MKDIR) $(RABBITMQ_VOL)

up: setup
	$(COMPOSE) up -d

build: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

status:
	docker ps

clean: down
	$(COMPOSE) down --volumes --remove-orphans

fclean: clean
	@sudo $(RM) $(DATABASE_VOL)
	@sudo $(RM) $(RABBITMQ_VOL)
	docker system prune -a --volumes --force

pull_backend: ../backend
	git -C ../backend pull
pull_frontend: ../frontend
	git -C ../frontend pull

re: fclean all

# ==============================================================================
#                                 Development Targets
# ==============================================================================

INFRA        = database rabbitmq
CONCURRENTLY = ../backend/node_modules/.bin/concurrently

# Install deps only when the lockfile changes (or node_modules is missing)
../backend/node_modules: ../backend/package-lock.json
	cd ../backend && npm install
	@touch $@
../frontend/node_modules: ../frontend/package-lock.json
	cd ../frontend && npm install
	@touch $@

deps: setup ../backend/node_modules ../frontend/node_modules

# --wait blocks until the containers are healthy, so the apps never start too early
dev-infra: init
	$(COMPOSE) up -d --wait $(INFRA)

# One terminal, flat colored logs, Ctrl-C stops everything (-k)
watch: init dev-infra deps
	@FORCE_COLOR=1 $(CONCURRENTLY) -k -n gateway,auth,club,notif,frontend \
	  -c cyan,cyan,yellow,magenta,blue \
	  "npm --prefix ../backend run start:dev:gateway" \
	  "npm --prefix ../backend run start:dev:auth" \
	  "npm --prefix ../backend run start:dev:club" \
	  "npm --prefix ../backend run start:dev:notification" \
	  "npm --prefix ../frontend run dev"

# Single-side shortcuts for teammates who work on one part
watch-backend: dev-infra deps
	@npm --prefix ../backend run start:dev:all
watch-frontend: deps
	@npm --prefix ../frontend run dev

dev-logs:
	$(COMPOSE) logs -f $(INFRA)
dev-down:
	$(COMPOSE) stop $(INFRA)

.PHONY: all setup init up build down stop start status clean fclean re \
        pull_backend pull_frontend deps dev-infra watch watch-backend \
        watch-frontend dev-logs dev-down