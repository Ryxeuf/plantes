# Runbook — plantes.ryxeuf.fr

## Au quotidien

| Besoin | Commande |
|---|---|
| État | `make ps` |
| Logs | `make logs` |
| Redémarrer | `docker compose restart app` |
| Console MariaDB | `make db-shell` |
| Forcer les rappels | `make cron-test` |

## Mise à jour

```sh
cd /opt/plantes
make upgrade        # sauvegarde, pull de l'image, redémarrage
make logs           # surveiller les migrations
```

L'image `:latest` applique ses migrations au démarrage. La sauvegarde préalable est
faite par la cible `upgrade` — ne saute pas cette étape, les migrations ne sont pas
réversibles.

Pour épingler une version plutôt que suivre `latest`, remplacer le tag de l'image
dans `docker-compose.yml` par un tag publié sur `ghcr.io/danielbrendel/hortusfox-web`.

## Sauvegarde et restauration

- Automatique : cron à 4 h, rotation à `BACKUP_KEEP_DAYS` jours dans `$BACKUP_DIR`.
- Manuelle : `./scripts/backup.sh`
- Restauration : `make restore FILE=/var/backups/plantes/plantes-20260906-040000.tar.gz`

Une archive contient `database.sql`, les volumes images/pièces jointes/thèmes, et une
copie du `.env` du moment. **Elle contient donc des secrets** : `chmod 600`, et si tu
la recopies sur le NAS, dans un dossier non partagé.

L'application a aussi sa propre sauvegarde interne (`/cronjob/backup/auto`, visible
dans l'admin). Elle ne remplace pas la sauvegarde externe : elle vit dans le même
volume que ce qu'elle sauvegarde.

## Dépannage

**502 Bad Gateway par Traefik**
Le conteneur app n'écoute pas encore, ou le label `loadbalancer.server.port=80` manque.
`docker compose exec -T app curl -sI http://localhost/` pour trancher : si ça répond,
le problème est côté routage Traefik ; sinon, côté app.

**Certificat non émis**
`docker logs <traefik> | grep -i acme`. Causes classiques : DNS pas encore propagé,
mauvais nom de certresolver, rate limit Let's Encrypt (5 échecs/heure, 50 certs/semaine
par domaine racine — attendre, ne pas relancer en boucle).

**L'app démarre puis s'arrête**
Presque toujours la base : `docker compose logs db`. Vérifier que `DB_USERNAME`/
`DB_PASSWORD` de `app` correspondent à `MARIADB_USER`/`MARIADB_PASSWORD` de `db`.
Attention : si le volume `plantes_db_data` existe déjà, MariaDB **ignore** les
variables d'environnement et garde les identifiants d'origine. Dans ce cas, corriger
le mot de passe en base plutôt que dans `.env`.

**Aucun rappel ne part**
Dans l'ordre : le cron tourne-t-il (`crontab -l`, `/var/log/plantes-cron.log`) ; le
jeton `cronpw` correspond-il à celui de l'admin ; les tâches sont-elles bien
récurrentes et assignées ; le SMTP est-il configuré (ou les notifications HA en place).

**Mot de passe admin perdu**
`APP_ADMIN_PASSWORD` n'est utilisé qu'à la première installation. Ensuite, passer par
la réinitialisation de l'app (nécessite le SMTP) ou modifier le hash en base via
`make db-shell`.

## Ce qu'il ne faut jamais faire

- `docker compose down -v` — détruit les volumes, donc toutes les données.
- Publier le port 3306 sur l'hôte.
- Remettre `APP_DEBUG=true` sur une instance exposée : la stack trace PHP part au client.
- Modifier la configuration Traefik globale pour ce seul service.
