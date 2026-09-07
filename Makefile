SHELL := /bin/bash
COMPOSE := docker compose

.PHONY: help preflight up down logs ps shell db-shell backup restore upgrade cron-test

help:
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

preflight: ## Vérifie DNS, Traefik, Docker et le .env avant déploiement
	@./scripts/preflight.sh

up: ## Démarre la stack
	$(COMPOSE) pull && $(COMPOSE) up -d

down: ## Arrête la stack (les volumes sont conservés)
	$(COMPOSE) down

logs: ## Suit les logs applicatifs
	$(COMPOSE) logs -f --tail=100 app

ps: ## État des conteneurs
	$(COMPOSE) ps

shell: ## Shell dans le conteneur applicatif
	$(COMPOSE) exec app bash

db-shell: ## Client MariaDB
	$(COMPOSE) exec db sh -c 'mariadb -u"$$MARIADB_USER" -p"$$MARIADB_PASSWORD" "$$MARIADB_DATABASE"'

backup: ## Dump base + volumes dans $BACKUP_DIR
	@./scripts/backup.sh

restore: ## Restaure une sauvegarde : make restore FILE=/chemin/plantes-YYYYmmdd.tar.gz
	@./scripts/restore.sh $(FILE)

upgrade: backup ## Sauvegarde puis met à jour l'image
	$(COMPOSE) pull && $(COMPOSE) up -d && $(COMPOSE) logs --tail=50 app

cron-test: ## Déclenche les tâches planifiées une fois, en verbeux
	@VERBOSE=1 ./cron/hortusfox-cron.sh
