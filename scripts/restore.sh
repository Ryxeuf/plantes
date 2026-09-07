#!/usr/bin/env bash
# Restaure une archive produite par backup.sh. Destructif : demande confirmation.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

ARCHIVE="${1:-}"
[ -f "$ARCHIVE" ] || { echo "Usage: ./scripts/restore.sh /chemin/plantes-YYYYmmdd-HHMMSS.tar.gz"; exit 1; }

echo "Cette opération ÉCRASE la base '$DB_DATABASE' et les fichiers de $DOMAIN."
read -rp "Taper 'restaurer' pour confirmer : " a
[ "$a" = "restaurer" ] || { echo "Annulé."; exit 1; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
tar xzf "$ARCHIVE" -C "$WORK"

echo "→ restauration de la base"
docker compose exec -T db sh -c \
  'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' < "$WORK/database.sql"

for v in app_images app_attachments app_themes; do
  [ -f "$WORK/$v.tar.gz" ] || continue
  echo "→ restauration du volume $v"
  docker run --rm -v "plantes_${v}:/dst" -v "$WORK:/in:ro" alpine \
    sh -c "rm -rf /dst/* && tar xzf /in/$v.tar.gz -C /dst"
done

docker compose restart app
echo "✓ restauré"
