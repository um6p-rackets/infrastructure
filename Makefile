# ==============================================================================
#                                VARIABLES
# ==============================================================================
MKDIR        = mkdir -p
RM           = rm -rf

FRONTEND_URL = https://github.com/um6p-rackets/frontend.git
BACKEND_URL  = https://github.com/um6p-rackets/backend.git

DATABASE_VOL = $(HOME)/data/database

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
	docker system prune -a --volumes --force

pull_backend: ../backend
	git -C ../backend pull
pull_frontend: ../frontend
	git -C ../frontend pull

re: fclean all

.PHONY: all setup init up build down stop start status clean fclean pull_backend re pull_frontend pull_frontend