
COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

all: up

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi local --remove-orphans

.PHONY: all up down stop start restart logs ps clean
