# Architecture

```
Internet ──443──▶ Traefik ──▶ réseau "proxy" ──▶ plantes-app  (PHP 8.3 + Apache, port 80)
                  (TLS ACME)                          │
                                                réseau "internal" (internal: true)
                                                      │
                                                 plantes-db  (MariaDB 11.4)
                                                      │
                                            volume plantes_db_data

cron hôte ──▶ docker compose exec app ──▶ POST /cronjob/* (cronpw)
```

## Choix par rapport au docker-compose officiel

| Officiel | Ici | Pourquoi |
|---|---|---|
| `ports: 8080:80` sur l'app | aucun port publié | Traefik est le seul point d'entrée |
| `ports: 3306:3306` sur la db | aucun port publié, réseau `internal: true` | une base ne s'expose pas |
| `image: mariadb` | `mariadb:11.4` | un `latest` de base de données finit toujours par surprendre |
| pas de healthcheck | healthcheck + `depends_on: condition: service_healthy` | l'app plantait au démarrage à froid |
| variables en dur | tout dans `.env` | secrets hors du fichier versionnable |
| `APP_DEBUG` non défini (donc `true`) | `false` | pas de stack trace PHP côté client |

## Où vivent les données

Volumes Docker nommés, préfixés `plantes_` par le `name:` du compose :

- `plantes_db_data` — la base. **Le volume critique.**
- `plantes_app_images`, `plantes_app_attachments` — photos et pièces jointes
- `plantes_app_themes`, `plantes_app_backup`, `plantes_app_logs`, `plantes_app_migrate`

`./scripts/backup.sh` couvre la base + images + pièces jointes + thèmes. Les logs et
les migrations sont reconstruits par l'image, inutile de les sauvegarder.
