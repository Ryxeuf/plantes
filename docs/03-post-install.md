# Prise en main

## Le modèle mental de HortusFox

Tout est **par lieu**. Une plante appartient obligatoirement à un lieu, et c'est le
lieu qui porte le contexte (luminosité, température). Crée donc les lieux d'abord, et
nomme-les avec l'information qui te servira à décider :

```
Salon — fenêtre est
Salon — fond de pièce
Cuisine — fenêtre sud
Chambre — fenêtre nord
Bureau — sous vasistas
Salle de bain
```

L'orientation dans le nom, ce n'est pas de la coquetterie : c'est ce qui te fera
choisir l'intervalle d'arrosage, et ce qui rendra évident, en novembre, quelles
plantes il faut déplacer.

## Pour chaque plante

1. **Nom courant + nom scientifique.** Le nom scientifique est la clé pour retrouver
   les infos ailleurs — voir `04-donnees-plantes.md`.
2. **Photo.** Utile plus qu'on ne croit pour suivre la croissance et repérer un
   dépérissement lent.
3. **Attributs** : diamètre et matière du pot, substrat, date d'acquisition. La
   matière compte : la terre cuite sèche nettement plus vite que le plastique.
4. **Notes** : ce que tu observes. C'est le journal qui te rendra autonome sur ta
   propre collection au bout d'une saison.

## Les tâches récurrentes, le vrai moteur

C'est ce qui déclenche les rappels. Une tâche par plante (ou par groupe de plantes
au même régime) :

| Tâche | Récurrence de départ | À ajuster |
|---|---|---|
| Arroser | 7 j en été, 12-14 j en hiver | selon ce que tu observes au doigt |
| Engrais | toutes les 2-4 semaines de mars à septembre | rien en dormance |
| Dépoussiérer les feuilles | mensuel | les plantes à grandes feuilles surtout |
| Rempoter | annuel ou bisannuel | au printemps |

HortusFox n'ajuste pas tout seul selon la saison : prévois un rendez-vous en octobre
et un en mars pour rallonger puis raccourcir les intervalles. Deux fois par an, dix
minutes. C'est la limite assumée de l'outil — et le point de départ d'une app maison
si l'envie revient.

## Vérifier la chaîne de bout en bout

Crée une tâche d'arrosage avec une échéance d'hier, lance `make cron-test`, et
vérifie que la notification arrive. Tant que ce test n'est pas passé, l'installation
n'est pas terminée.
