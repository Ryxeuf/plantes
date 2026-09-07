# Brancher les rappels sur Home Assistant

**À faire seulement après une semaine d'usage réel.** Les notifications par e-mail de
HortusFox suffisent peut-être. Si tu les ignores déjà, alors oui, il faut les faire
arriver là où tu regardes vraiment : l'app companion HA sur ton téléphone.

## Principe

HortusFox n'a pas de webhook sortant. Le pont se fait donc dans l'autre sens : un
script sur le serveur lit les tâches dues et appelle le service `notify` de Home
Assistant.

```
cron ──▶ ha-notify.sh ──▶ [lecture des tâches dues] ──▶ POST /api/services/notify/mobile_app_*
                                                          (HA_TOKEN)
```

## Étape de découverte — à faire, pas à deviner

Deux sources possibles pour « les tâches dues ». Évalue-les dans cet ordre :

1. **L'API REST de HortusFox.** L'application en expose une (jeton à générer depuis
   ton profil). Vérifie ce qu'elle sert réellement : routes disponibles dans
   `app/routes.php` du dépôt, et test avec `curl`. Si une route liste les tâches,
   c'est la bonne voie : contrat stable, aucune connaissance du schéma.
2. **Lecture SQL directe**, en secours. `make db-shell` puis `SHOW TABLES;` pour
   trouver la table des tâches et ses colonnes (échéance, statut, plante, assigné).
   **En lecture seule**, jamais d'écriture : l'app gère son état elle-même.

Complète ensuite `ha-notify.sh` là où c'est marqué.

## Côté Home Assistant

1. Profil → Jetons d'accès longue durée → créer un jeton, le mettre dans `HA_TOKEN`.
2. Vérifier le nom exact du service de notification :
   Outils de développement → Actions → chercher `notify.mobile_app_`.
3. Le serveur OVH doit pouvoir joindre HA. Le Raspberry Pi est chez toi, derrière la
   Freebox : soit tu exposes HA (Nabu Casa ou reverse proxy), soit — plus propre — tu
   inverses le sens et c'est **HA qui interroge** l'app via un `rest` sensor sur
   `https://plantes.ryxeuf.fr`, avec une automatisation qui notifie. Dans ce cas,
   `automation-notify.yaml` est le point de départ et le script serveur ne sert à rien.

Choisis en fonction de ce qui est déjà exposé chez toi — ne monte pas un tunnel pour
un rappel d'arrosage.

## Notifications actionnables

L'intérêt de passer par HA : les boutons. Une notification « Arroser le monstera »
avec « Fait » / « Plus tard » vaut dix rappels passifs. Voir `automation-notify.yaml`
pour la structure `actions` et l'événement `mobile_app_notification_action` qui
permet d'y répondre.
