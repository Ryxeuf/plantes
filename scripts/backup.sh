#!/usr/bin/env bash
# Sauvegarde base + volumes de données. Rotation sur BACKUP_KEEP_DAYS.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

DEST="${BACKUP_DIR:-/var/backups/plantes}"
KEEP="${BACKUP_KEEP_DAYS:-30}"
STAMP=$(date +%Y%m%d-%H%M%S)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$DEST"

echo "→ dump MariaDB"
docker compose exec -T db sh -c \
  'mariadb-dump --single-transaction --quick -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
  > "$WORK/database.sql"

echo "→ volumes (images, pièces jointes, thèmes)"
for v in app_images app_attachments app_themes; do
  docker run --rm -v "plantes_${v}:/src:ro" -v "$WORK:/out" alpine \
    tar czf "/out/${v}.tar.gz" -C /src . 2>/dev/null
done

cp .env "$WORK/env.backup"
chmod 600 "$WORK/env.backup"

OUT="$DEST/plantes-$STAMP.tar.gz"
tar czf "$OUT" -C "$WORK" .
chmod 600 "$OUT"
echo "✓ $OUT ($(du -h "$OUT" | cut -f1))"

find "$DEST" -name 'plantes-*.tar.gz' -mtime "+$KEEP" -print -delete
