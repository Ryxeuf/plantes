# plantes.ryxeuf.fr — kit de déploiement HortusFox

Kit prêt à donner à une session Claude Code sur le serveur OVH (Docker + Traefik).

## Ce que ça déploie

[HortusFox](https://github.com/danielbrendel/hortusfox-web) — gestionnaire de plantes self-hosted,
MIT, PHP 8.3 + MariaDB, derrière Traefik en HTTPS sur `plantes.ryxeuf.fr`.

## Utilisation

```sh
# sur le serveur
mkdir -p /opt/plantes && cd /opt/plantes
# décompresser ce kit ici
cp .env.example .env && $EDITOR .env     # remplir les secrets
claude
```

Puis dans la session Claude Code :

> Lis CLAUDE.md et PLAN.md, puis déroule le plan étape par étape.
> Arrête-toi et demande-moi avant toute étape marquée [CONFIRMATION].

## Contenu

| Fichier | Rôle |
|---|---|
| `CLAUDE.md` | Briefing de la session : contexte, contraintes, ce qu'il ne faut pas faire |
| `PLAN.md` | Le plan d'exécution, étape par étape, avec critères de vérification |
| `RUNBOOK.md` | Exploitation : sauvegarde, restauration, mise à jour, dépannage |
| `docker-compose.yml` | La stack, labels Traefik inclus |
| `.env.example` | Toutes les variables à renseigner |
| `Makefile` | Raccourcis (`make up`, `make logs`, `make backup`, `make upgrade`) |
| `cron/` | Déclenchement des tâches planifiées HortusFox |
| `scripts/` | Préflight, sauvegarde, restauration |
| `homeassistant/` | Brancher les rappels sur les notifications HA (optionnel) |
| `docs/` | Architecture, DNS/TLS, prise en main, où trouver les données d'entretien |

## Avant de lancer

- [ ] Enregistrement DNS `plantes.ryxeuf.fr` → IP du serveur
- [ ] Traefik déjà en place, avec un réseau Docker externe et un resolver ACME
- [ ] `.env` rempli (mots de passe générés, pas recopiés)
