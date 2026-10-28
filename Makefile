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
  COMPOSE = docker compose -f ./docker-compose.dev.yml --profile dev
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

# build: setup
# 	$(COMPOSE) up -d --build
	
build: setup
	for s in database rabbitmq api_gateway auth club notification frontend nginx; do \
		$(COMPOSE) build $$s || $(COMPOSE) build --no-cache $$s || exit 1; done
	$(COMPOSE) up -d
	
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
	docker builder prune -af
	docker system prune -a --volumes --force
	@sudo systemctl restart docker
	@until docker info >/dev/null 2>&1; do sleep 1; done

	@sudo systemctl restart docker
	@sleep 2

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
BACKEND_NPM  = npm --prefix ../backend
FRONTEND_NPM = npm --prefix ../frontend

# Install deps only when the lockfile changes (or node_modules is missing)
../backend/node_modules: ../backend/package-lock.json
	cd ../backend && npm install
	@touch $@
../frontend/node_modules: ../frontend/package-lock.json
	cd ../frontend && npm install
	@touch $@

deps: setup ../backend/node_modules ../frontend/node_modules	

# --wait blocks until the containers are healthy
dev-up: init
	$(COMPOSE) up -d --wait $(INFRA)

# Generate clients + apply committed migrations (safe to run every time)
db-sync: dev-up deps
	@FORCE_COLOR=1 $(CONCURRENTLY) -s all -n "generate,migrate,seed" -c "magentaBright,bold.cyan,bold.yellow" \
		"$(BACKEND_NPM) run db:generate" \
		"$(BACKEND_NPM) run db:migrate" \
		"$(BACKEND_NPM) run db:seed"

# One terminal, colored logs, Ctrl-C stops everything
watch: db-sync
	@FORCE_COLOR=1 $(CONCURRENTLY) -k -n gateway,auth,club,notif,frontend \
	  -c cyan,green,yellow,magenta,blue \
	  "$(BACKEND_NPM) run start:dev:gateway" \
	  "$(BACKEND_NPM) run start:dev:auth" \
	  "$(BACKEND_NPM) run start:dev:club" \
	  "$(BACKEND_NPM) run start:dev:notification" \
	  "$(FRONTEND_NPM) run dev"

# !!!! [Be careful] Build from scratch and rewatch (It destroys all data in the database and rabbitmq !!!!)
rewatch: clean-deps dev-down
	$(COMPOSE) down --volumes --remove-orphans
	@sudo $(RM) $(DATABASE_VOL) $(RABBITMQ_VOL)
	@$(MAKE) watch

watch-backend: db-sync
	@$(BACKEND_NPM) run start:dev:all
watch-frontend: deps
	@$(FRONTEND_NPM) run dev


dev-logs:
	$(COMPOSE) logs -f $(INFRA)
clean-deps:
	@sudo $(RM) ../backend/node_modules ../frontend/node_modules
	@sudo $(RM) ../backend/dist ../frontend/.next
dev-down:
	$(COMPOSE) stop $(INFRA)

.PHONY: all setup init up build down stop start status clean fclean re \
        pull_backend pull_frontend deps dev-up db-sync \
        watch rewatch watch-backend watch-frontend clean-deps dev-logs dev-down
