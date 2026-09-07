#!/usr/bin/env bash
# Pousse les tâches HortusFox dues vers une notification Home Assistant.
#
# Découverte faite le 2026-09-07 (piste A du README) :
#   - GET/POST /api/tasks/fetch renvoie les tâches non faites (done=0, limit 100)
#     avec id, title, due_date ("YYYY-MM-DD HH:MM:SS", heure locale de l'app).
#   - Auth : paramètre `token` (clé API à créer dans Admin → API), PAS un header
#     Bearer. Envoyé en POST pour ne pas apparaître dans les access logs Apache.
#   - L'appel se fait depuis l'intérieur du conteneur (php, pas de curl embarqué).
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

VERBOSE="${VERBOSE:-0}"

[ -n "${HA_TOKEN:-}" ]        || { echo "HA_TOKEN vide dans .env — voir homeassistant/README.md"; exit 1; }
[ -n "${HORTUSFOX_TOKEN:-}" ] || { echo "HORTUSFOX_TOKEN vide dans .env — créer une clé API dans l'admin HortusFox (Admin → API)"; exit 1; }

# ─── Tâches ouvertes, via l'API REST de l'app ────────────────────────────────
RAW=$(docker compose exec -T -e API_TOKEN="$HORTUSFOX_TOKEN" app php -r '
  $ctx = stream_context_create(["http" => [
    "method"  => "POST",
    "header"  => "Content-Type: application/x-www-form-urlencoded\r\n",
    "content" => http_build_query(["token" => getenv("API_TOKEN")]),
    "ignore_errors" => true,
    "timeout" => 60,
  ]]);
  echo @file_get_contents("http://127.0.0.1/api/tasks/fetch", false, $ctx);
')

# ─── Filtre "dues" + payload HA, en un seul passage ──────────────────────────
PAYLOAD=$(printf '%s' "$RAW" | DOMAIN="$DOMAIN" python3 -c '
import json, os, sys, time
from datetime import datetime

os.environ["TZ"] = "Europe/Paris"; time.tzset()

doc = json.load(sys.stdin)
if doc.get("code") != 200:
    sys.stderr.write("API HortusFox: réponse %s\n" % doc.get("code"))
    sys.exit(2)

now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
due = [t for t in (doc.get("data") or [])
       if not t.get("done") and t.get("due_date") and t["due_date"] <= now]
if not due:
    sys.exit(0)

url = "https://" + os.environ["DOMAIN"]
lines = "\n".join("• " + t["title"] for t in due[:8])
print(json.dumps({
    "title": "%d tâche(s) de jardinage" % len(due),
    "message": lines,
    "data": {
        "tag": "hortusfox-tasks",
        "url": url,
        "notification_icon": "mdi:sprout",
        "actions": [
            {"action": "HORTUSFOX_OPEN", "title": "Ouvrir", "uri": url},
            {"action": "HORTUSFOX_SNOOZE", "title": "Plus tard"},
        ],
    },
}))
') || { echo "échec du filtrage des tâches (voir ci-dessus)"; exit 1; }

if [ -z "${PAYLOAD:-}" ]; then
  [ "$VERBOSE" = "1" ] && echo "aucune tâche due — rien à notifier"
  exit 0
fi

# ─── Notification ────────────────────────────────────────────────────────────
CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 \
  -X POST "$HA_BASE_URL/api/services/$HA_NOTIFY_SERVICE" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ "$CODE" = "200" ]; then
  [ "$VERBOSE" = "1" ] && echo "✓ notification envoyée ($HA_NOTIFY_SERVICE)"
  exit 0
else
  echo "✗ Home Assistant → HTTP $CODE"
  exit 1
fi
