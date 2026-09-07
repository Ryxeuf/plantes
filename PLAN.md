# Plan d'exécution — plantes.ryxeuf.fr

Déroule les étapes dans l'ordre. Chaque étape a une **vérification** : exécute-la et
montre la sortie réelle avant de passer à la suivante. Les étapes [CONFIRMATION]
s'arrêtent et demandent l'accord de Remy.

---

## Étape 0 — Reconnaissance

Sans rien modifier, établis l'état des lieux :

- `docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'`
- `docker network ls`
- Localise la configuration Traefik (conteneur, fichier statique `traefik.yml`,
  provider file éventuel) et relève : noms d'**entrypoints**, noms de
  **certresolvers**, réseau Docker utilisé.
- Regarde comment un service voisin déjà exposé est étiqueté : c'est la convention
  à reproduire, pas celle du kit.

**Vérification** : tu peux nommer l'entrypoint HTTPS, le certresolver et le réseau
Traefik, et citer le service voisin dont tu t'es inspiré.

**Sortie** : si les valeurs diffèrent de `.env`, corrige `.env` — pas
`docker-compose.yml`.

---

## Étape 1 — Préflight

```sh
cd /opt/plantes
cp -n .env.example .env      # si pas déjà fait
./scripts/preflight.sh
```

Génère les secrets manquants et écris-les dans `.env` :

```sh
openssl rand -base64 24      # APP_ADMIN_PASSWORD, DB_PASSWORD, MARIADB_ROOT_PASSWORD
openssl rand -hex 32         # APP_CRON_PW
```

**Vérification** : `./scripts/preflight.sh` sort en code 0.

**Blocage attendu** : si le DNS ne résout pas, arrête-toi ici. L'enregistrement A
`plantes` sur la zone `ryxeuf.fr` est un prérequis, pas quelque chose à contourner.

---

## Étape 2 — Démarrage [CONFIRMATION]

Montre le `docker compose config` résolu (masque les secrets) et demande validation
avant de lancer.

```sh
docker compose config | sed -E 's/(PASSWORD|CRON_PW|TOKEN)[:=].*/\1: ***/'
docker compose pull
docker compose up -d
docker compose logs -f app     # jusqu'à la fin de l'installation initiale
```

Le premier démarrage crée la base, joue les migrations et crée le compte admin à
partir de `APP_ADMIN_EMAIL` / `APP_ADMIN_PASSWORD`. Ça prend une à deux minutes.

**Vérification** :
- `docker compose ps` → `plantes-db` healthy, `plantes-app` up
- `docker compose exec -T app curl -s -o /dev/null -w '%{http_code}' http://localhost/` → `200`
- Aucun port publié : `docker compose ps --format '{{.Names}} {{.Ports}}'` ne montre
  aucun mapping `0.0.0.0:*`

---

## Étape 3 — Exposition HTTPS

```sh
curl -sI https://plantes.ryxeuf.fr | head -5
echo | openssl s_client -connect plantes.ryxeuf.fr:443 -servername plantes.ryxeuf.fr 2>/dev/null \
  | openssl x509 -noout -issuer -dates
```

**Vérification** : HTTP 200 (ou 302 vers la page de connexion), certificat émis par
Let's Encrypt et valide, redirection HTTP → HTTPS active.

**Si ça échoue** : regarde les logs Traefik (`docker logs <traefik> | grep plantes`)
avant de toucher quoi que ce soit. Les causes habituelles, dans l'ordre : nom de
réseau erroné dans `.env`, entrypoint mal nommé, certresolver mal nommé, rate limit
ACME (attendre, ne pas boucler sur des tentatives).

---

## Étape 4 — Connexion et réglages

Connecte-toi avec `APP_ADMIN_EMAIL`. Puis, dans l'application :

- **Admin** : vérifier le nom de l'espace de travail, la langue (français), le fuseau.
- **Profil** : préférences d'affichage, notifications par e-mail si SMTP configuré.
- Relève le **jeton de cronjob** dans l'admin et compare-le à `APP_CRON_PW` de `.env` :
  ils doivent correspondre. S'ils divergent (installation antérieure), c'est la valeur
  de l'admin qui fait foi — reporte-la dans `.env`.

**Vérification** : capture des réglages appliqués, et confirmation que le jeton
correspond.

---

## Étape 5 — Planification

Sans cette étape, aucun rappel ne part jamais.

```sh
make cron-test          # doit afficher ✓ sur les 4 routes
crontab -l              # état actuel
```

Installe les entrées de `cron/crontab.example` (ou les unités systemd si la machine
utilise déjà des timers — regarde `systemctl list-timers` pour trancher, et suis la
convention existante).

**Vérification** :
- `make cron-test` sort en 0 avec quatre `✓`
- L'entrée est bien dans `crontab -l` ou `systemctl list-timers | grep plantes`
- Attendre le déclenchement suivant et vérifier `/var/log/plantes-cron.log`

---

## Étape 6 — Sauvegardes

```sh
./scripts/backup.sh
ls -lh /var/backups/plantes/
```

Puis vérifie que la restauration fonctionne — une sauvegarde jamais testée n'est pas
une sauvegarde. Si le NAS Synology est accessible depuis ce serveur, propose la
recopie de `$BACKUP_DIR` dessus (rsync ou montage), mais **ne configure rien sur le
NAS sans validation**.

**Vérification** : l'archive existe, `tar tzf` liste `database.sql` et les volumes,
et sa taille est cohérente.

---

## Étape 7 — Prise en main [CONFIRMATION]

Ne saisis pas les plantes à la place de Remy : il faut regarder ses pots.
Prépare le terrain et montre-lui :

- Créer les **lieux** (une pièce = un lieu, l'orientation de la fenêtre dans le nom :
  « Salon — fenêtre est »). Tout part de là dans HortusFox.
- Créer une plante témoin avec une tâche récurrente d'arrosage, pour valider la
  chaîne complète jusqu'à la notification.
- Lui pointer `docs/03-post-install.md` et `docs/04-donnees-plantes.md`.

---

## Étape 8 — Home Assistant (optionnel)

À ne faire qu'après une semaine d'usage réel, et seulement si les notifications par
e-mail ne suffisent pas. Voir `homeassistant/README.md` — le travail de découverte
(schéma ou API) y est décrit, il n'est pas prémâché exprès.

---

## Rapport final

Termine par un récapitulatif court :

- URL, identifiants de connexion (mot de passe affiché une seule fois)
- Ce qui tourne, où sont les données (volumes nommés), où sont les sauvegardes
- La planification installée et son horaire
- Ce qui reste à faire côté Remy
