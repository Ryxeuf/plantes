#!/usr/bin/env bash
# Déclenche les tâches planifiées de HortusFox.
# L'image Docker n'embarque aucun planificateur : sans ce script, aucun rappel ne part.
#
# L'appel se fait depuis l'intérieur du conteneur, via PHP (toujours présent, à la
# différence de curl) : pas de passage par Traefik, pas de sortie sur Internet,
# le jeton ne quitte pas la machine.
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

VERBOSE="${VERBOSE:-0}"
FAILED=0

run() {
  local route="$1" code
  code=$(docker compose exec -T -e CRONPW="$APP_CRON_PW" -e ROUTE="$route" app php -r '
    $ctx = stream_context_create(["http" => [
      "method"  => "POST",
      "header"  => "Content-Type: application/x-www-form-urlencoded\r\n",
      "content" => http_build_query(["cronpw" => getenv("CRONPW")]),
      "ignore_errors" => true,
      "timeout" => 120,
    ]]);
    @file_get_contents("http://127.0.0.1" . getenv("ROUTE"), false, $ctx);
    $code = "000";
    if (isset($http_response_header[0]) && preg_match("#\s(\d{3})\s#", $http_response_header[0], $m)) {
      $code = $m[1];
    }
    echo $code;
  ' 2>/dev/null | tr -dc '0-9')

  if [ "$code" = "200" ]; then
    [ "$VERBOSE" = "1" ] && echo "✓ $route"
  else
    echo "✗ $route → HTTP ${code:-aucune réponse}"
    FAILED=1
  fi
  return 0
}

run /cronjob/tasks/recurring     # réarme les tâches récurrentes
run /cronjob/tasks/overdue       # signale les tâches en retard
run /cronjob/tasks/tomorrow      # prévient des tâches du lendemain
run /cronjob/calendar/reminder   # rappels d'agenda

# Sauvegarde interne de l'app : une fois par jour suffit (WITH_BACKUP=1)
[ "${WITH_BACKUP:-0}" = "1" ] && run /cronjob/backup/auto

exit $FAILED
