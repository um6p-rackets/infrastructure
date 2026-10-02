# ==============================================================================
#                                VARIABLES
# ==============================================================================
MKDIR			= mkdir -p
RM				= rm -rf

DATABASE_VOL		= $(HOME)/data/database

MODE 			= dev

ifeq ($(MODE), dev)
	COMPOSE			= docker compose -f ./docker-compose.dev.yml
else ifeq ($(MODE), prod)
	COMPOSE			= docker compose -f ./docker-compose.yml
else
	$(error "Invalid MODE specified. Please use 'dev' or 'prod'.")
endif

# ==============================================================================
#                                 TARGETS
# ==============================================================================
all: setup build

setup: init
	@./setup.sh

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

re: fclean all

.PHONY: all init up build down clean fclean re