# Où trouver les données d'entretien

HortusFox ne remplit pas les fiches à ta place : il interroge GBIF pour la taxonomie
et Pl@ntNet pour l'identification photo (clé API gratuite à créer sur
https://my.plantnet.org/ et à renseigner dans l'admin), mais les besoins en eau, en
lumière et en engrais se saisissent à la main.

Pour une collection domestique, une cinquantaine d'espèces couvre presque tout. Voici
où prendre les chiffres, par ordre d'utilité.

## Open Plantbook — https://open.plantbook.io

Le plus directement exploitable : par espèce, des **seuils chiffrés** min/max
d'humidité du sol, de luminosité (lux et DLI), de température, d'hygrométrie et de
conductivité, plus un bloc `care` (substrat, exposition, arrosage, fertilisation).
Gratuit, OAuth2 (client id / secret depuis ton compte), OpenAPI documenté.
C'est la base qui alimente l'intégration Plant Monitor de Home Assistant.

## Perenual — https://perenual.com/docs/api

Fréquence d'arrosage, exposition, sol, pH, températures, toxicité, maladies, et des
guides d'entretien rédigés. Plan gratuit : 100 requêtes/jour, espèces 1 à 3000, usage
personnel. Très orienté jardin et extérieur : complète mal les plantes d'intérieur
tropicales, mais rend service sur les classiques.

## GBIF — https://api.gbif.org

Nom accepté, synonymes, famille. Aucune donnée d'entretien, mais c'est la clé pivot
pour ne pas se retrouver avec trois fiches pour la même plante sous trois noms.
Libre, sans clé.

## Wikipédia FR / Wikidata

Description en français, origine, photo sous licence libre, toxicité pour les
animaux domestiques. Pratique pour donner du corps à une fiche.

## Méthode qui fait gagner du temps

1. Identifie l'espèce (Pl@ntNet dans l'app, ou tu la connais déjà).
2. Cherche le nom scientifique dans Open Plantbook, note les seuils.
3. Traduis-les en un intervalle d'arrosage réaliste **pour ta pièce**, pas dans
   l'absolu : une plante en fenêtre nord en janvier boit deux fois moins que la même
   en fenêtre sud en juillet.
4. Note l'intervalle dans la tâche récurrente, et l'origine du chiffre dans les notes
   de la plante. Dans six mois, tu sauras si tu dois faire confiance au chiffre ou à
   ton doigt.

Au bout d'une saison, tes propres notes valent mieux que n'importe quelle API.
