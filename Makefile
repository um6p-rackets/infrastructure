# ==============================================================================
#                                VARIABLES
# ==============================================================================
MKDIR			= mkdir -p
RM				= rm -rf

DATABASE_VOL		= $(HOME)/data/database

COMPOSE			= docker compose -f ./docker-compose.dev.yml

# ==============================================================================
#                                 TARGETS
# ==============================================================================
all: init build

init:
	$(MKDIR) $(DATABASE_VOL)

up: init
	$(COMPOSE) up -d

build: init
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