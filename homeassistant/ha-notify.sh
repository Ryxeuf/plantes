#!/usr/bin/env bash
# Pousse les tâches HortusFox dues vers une notification Home Assistant.
# ⚠ Squelette : la partie "récupération des tâches" est à compléter après l'étape
#   de découverte décrite dans README.md (API REST de l'app, ou lecture SQL).
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

[ -n "${HA_TOKEN:-}" ] || { echo "HA_TOKEN vide dans .env — voir homeassistant/README.md"; exit 1; }

# ─── À COMPLÉTER ──────────────────────────────────────────────────────────────
# Doit produire une ligne par tâche due, au format :  <id>|<libellé>
#
# Piste A — API REST de HortusFox (préférée) :
#   TASKS=$(curl -s -H "Authorization: Bearer $HORTUSFOX_TOKEN" \
#           "https://$DOMAIN/api/<route à confirmer>" | jq -r '.[] | "\(.id)|\(.title)"')
#
# Piste B — lecture SQL directe (secours ; adapter table et colonnes après SHOW TABLES) :
#   TASKS=$(docker compose exec -T db sh -c \
#     'mariadb -N -B -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" -e "
#        SELECT id, CONCAT(title) FROM <table_taches>
#        WHERE due_date <= NOW() AND done = 0"' | tr "\t" "|")
TASKS=""
# ──────────────────────────────────────────────────────────────────────────────

[ -n "$TASKS" ] || exit 0

COUNT=$(printf '%s\n' "$TASKS" | grep -c . || true)
LIST=$(printf '%s\n' "$TASKS" | cut -d'|' -f2- | sed 's/^/• /' | head -8)

curl -sS -o /dev/null -w '%{http_code}\n' \
  -X POST "$HA_BASE_URL/api/services/$HA_NOTIFY_SERVICE" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg t "$COUNT tâche(s) de jardinage" --arg m "$LIST" --arg url "https://$DOMAIN" '{
        title: $t,
        message: $m,
        data: {
          tag: "hortusfox-tasks",
          url: $url,
          notification_icon: "mdi:sprout",
          actions: [
            { action: "HORTUSFOX_OPEN", title: "Ouvrir", uri: $url },
            { action: "HORTUSFOX_SNOOZE", title: "Plus tard" }
          ]
        }
      }')"
