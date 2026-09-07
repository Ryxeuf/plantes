# Briefing — déploiement HortusFox sur plantes.ryxeuf.fr

Tu déploies un service self-hosted sur un serveur de production personnel. Lis ce
fichier en entier avant d'agir, puis suis `PLAN.md`.

## Contexte

- **Serveur** : OVH bare metal (Kimsufi KS-5-B), Docker + Traefik déjà installés et
  utilisés par d'autres services. Tu n'es pas seul sur cette machine.
- **Domaine** : `plantes.ryxeuf.fr`, sous-domaine de `ryxeuf.fr`.
- **Application** : HortusFox (`ghcr.io/danielbrendel/hortusfox-web:latest`), PHP 8.3
  + MariaDB. Dépôt de référence : https://github.com/danielbrendel/hortusfox-web
- **Utilisateur** : Remy, développeur PHP/Symfony expérimenté. Va droit au but,
  pas de pédagogie inutile. Explique tes choix d'infra, pas la syntaxe Docker.
- **Usage** : familial, quelques utilisateurs, une centaine de plantes maximum.
  Pas de contrainte de charge, mais les données ne doivent pas être perdues.

## Règles

1. **Ne touche à rien qui ne t'appartient pas.** La configuration Traefik existante,
   les autres `docker-compose.yml`, les autres conteneurs : lecture seule. Si un
   ajustement Traefik global est nécessaire, propose-le et attends la validation.
2. **Aucun secret en dur.** Tout passe par `.env`, qui n'est jamais commité ni affiché
   en entier dans les logs. Si un mot de passe manque, génère-le
   (`openssl rand -base64 24`) et affiche-le une fois, clairement.
3. **Aucun port publié sur l'hôte.** Ni l'app ni MariaDB. Tout passe par Traefik.
   Le `docker-compose.yml` officiel du projet expose `8080:80` et `3306:3306` —
   celui de ce kit ne le fait pas, c'est volontaire.
4. **Les étapes marquées [CONFIRMATION] dans `PLAN.md` s'arrêtent et demandent.**
5. **Vérifie, n'affirme pas.** Chaque étape a un critère de vérification. Exécute-le
   et montre la sortie réelle. Si ça échoue, dis-le et diagnostique.
6. **Idempotence.** Le plan doit pouvoir être relancé sans casser un déploiement
   existant. Vérifie l'état avant d'agir.

## Pièges connus sur cette stack

- Le nom du **réseau Docker externe de Traefik** et le nom du **certresolver ACME**
  varient d'une installation à l'autre. Détecte-les (`scripts/preflight.sh` le fait),
  ne les devine pas. Ils se renseignent dans `.env`.
- Le conteneur HortusFox **n'embarque pas de cron**. Sans planificateur externe,
  aucun rappel de tâche ne part jamais. C'est l'étape la plus facile à oublier et
  celle qui rend l'outil utile — voir `cron/`.
- `APP_CRON_PW` n'est écrit en base **qu'à la première installation**. Le changer
  ensuite dans `.env` n'a aucun effet : il faut le modifier dans l'admin de l'app.
- L'app tourne sur le port 80 dans le conteneur. Le label
  `traefik.http.services.*.loadbalancer.server.port=80` est obligatoire.
- `APP_TIMEZONE` doit valoir `Europe/Paris`, sinon les échéances de tâches tombent
  à côté.
- Les données vivent dans des volumes Docker nommés (`db_data` et les volumes
  d'images/pièces jointes). Un `docker compose down -v` les détruit. Ne l'utilise
  jamais sans demander.

## Ce qui n'est pas dans le périmètre

- Pas de développement applicatif : on installe et on exploite, on ne code pas.
- Pas d'authentification par proxy (SSO) pour l'instant, l'app gère ses comptes.
- L'intégration Home Assistant est **optionnelle** et se fait après validation du
  fonctionnement de base. Voir `homeassistant/README.md`.
