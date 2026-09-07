#!/usr/bin/env bash
# Vérifications avant déploiement. Ne modifie rien.
set -uo pipefail
cd "$(dirname "$0")/.."

ok=0; ko=0
say()  { printf '  %s\n' "$*"; }
pass() { printf '\033[32m  ✓\033[0m %s\n' "$*"; ok=$((ok+1)); }
fail() { printf '\033[31m  ✗\033[0m %s\n' "$*"; ko=$((ko+1)); }
warn() { printf '\033[33m  !\033[0m %s\n' "$*"; }

echo; echo "── Environnement ──"
command -v docker >/dev/null && pass "docker: $(docker --version)" || fail "docker introuvable"
docker compose version >/dev/null 2>&1 && pass "docker compose: $(docker compose version --short)" || fail "plugin docker compose introuvable"

echo; echo "── Fichier .env ──"
if [ -f .env ]; then
  pass ".env présent"
  # shellcheck disable=SC1091
  set -a; . ./.env; set +a
  for v in DOMAIN TRAEFIK_NETWORK TRAEFIK_ENTRYPOINT TRAEFIK_CERTRESOLVER APP_ADMIN_PASSWORD DB_PASSWORD MARIADB_ROOT_PASSWORD APP_CRON_PW; do
    val="${!v:-}"
    if [ -z "$val" ]; then fail "$v vide"
    elif [ "$val" = "CHANGE_ME" ]; then fail "$v laissé à CHANGE_ME"
    else pass "$v renseigné"; fi
  done
else
  fail ".env absent — cp .env.example .env puis remplir"
  exit 1
fi

echo; echo "── DNS ──"
if command -v getent >/dev/null; then
  resolved=$(getent ahostsv4 "$DOMAIN" | awk '{print $1}' | sort -u | tr '\n' ' ')
  if [ -n "$resolved" ]; then
    pass "$DOMAIN résout vers: $resolved"
    public=$(curl -s --max-time 5 https://ifconfig.me || true)
    [ -n "$public" ] && say "IP publique du serveur: $public"
    [ -n "$public" ] && { echo "$resolved" | grep -q "$public" && pass "l'enregistrement pointe bien ici" || warn "l'enregistrement ne pointe pas vers l'IP publique — normal derrière un CDN, bloquant sinon"; }
  else
    fail "$DOMAIN ne résout pas — crée l'enregistrement A avant de continuer"
  fi
fi

echo; echo "── Traefik ──"
if docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
  pass "réseau externe '$TRAEFIK_NETWORK' trouvé"
else
  fail "réseau '$TRAEFIK_NETWORK' introuvable. Réseaux existants:"
  docker network ls --format '    - {{.Name}}'
fi

tcid=$(docker ps --filter "ancestor=traefik" -q | head -1)
[ -z "$tcid" ] && tcid=$(docker ps --format '{{.ID}} {{.Image}}' | grep -i traefik | awk '{print $1}' | head -1)
if [ -n "$tcid" ]; then
  pass "conteneur Traefik: $(docker inspect -f '{{.Name}}' "$tcid" | sed 's|^/||')"
  say "entrypoints déclarés:"
  docker inspect -f '{{range .Config.Cmd}}{{println .}}{{end}}' "$tcid" 2>/dev/null | grep -i 'entrypoints\.' | sed 's/^/    /' || say "    (config en fichier statique, vérifier traefik.yml)"
  say "certresolvers déclarés:"
  docker inspect -f '{{range .Config.Cmd}}{{println .}}{{end}}' "$tcid" 2>/dev/null | grep -i 'certificatesresolvers\.' | sed 's/^/    /' || say "    (config en fichier statique, vérifier traefik.yml)"
  say "→ vérifier que TRAEFIK_ENTRYPOINT='$TRAEFIK_ENTRYPOINT' et TRAEFIK_CERTRESOLVER='$TRAEFIK_CERTRESOLVER' correspondent"
else
  warn "aucun conteneur Traefik détecté — Traefik tourne-t-il ailleurs ?"
fi

echo; echo "── Collisions ──"
if docker ps -a --format '{{.Names}}' | grep -qx 'plantes-app'; then warn "un conteneur 'plantes-app' existe déjà (redéploiement ?)"; else pass "aucun conteneur homonyme"; fi
if docker volume ls --format '{{.Name}}' | grep -q '^plantes_db_data$'; then warn "le volume plantes_db_data existe déjà — données présentes, NE PAS le supprimer"; else pass "pas de volume préexistant"; fi

echo; printf '── Résultat: %d ok, %d bloquant(s) ──\n\n' "$ok" "$ko"
[ "$ko" -eq 0 ]
