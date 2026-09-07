# DNS et TLS

## Enregistrement

Chez le registrar / la zone DNS de `ryxeuf.fr` :

```
plantes.ryxeuf.fr.   A     <IP publique du serveur OVH>
```

Un `CNAME` vers l'hôte du serveur marche aussi. TTL court (300 s) le temps de la mise
en place, à remonter ensuite.

Vérification :

```sh
dig +short plantes.ryxeuf.fr
curl -s https://ifconfig.me      # doit correspondre
```

## Certificat

Émis par Traefik via le certresolver ACME déjà configuré sur la machine. Le kit ne
crée pas de resolver : il utilise l'existant, dont le nom se met dans
`TRAEFIK_CERTRESOLVER`.

Le challenge HTTP-01 exige que le port 80 soit joignable depuis Internet et que
l'entrypoint `web` redirige vers `websecure` — c'est la configuration standard, à
vérifier plutôt qu'à recréer.

**Limites Let's Encrypt à connaître avant de boucler sur des tentatives** :
5 échecs de validation par compte, par domaine, par heure ; 50 certificats par
domaine enregistré et par semaine. En cas d'erreur, lire les logs et corriger — pas
relancer.

## Accès restreint (optionnel)

Le service est destiné à la maison. Si tu veux le fermer à l'extérieur, deux options
qui n'exigent aucune modification de l'app :

- middleware Traefik `ipallowlist` sur le routeur `plantes`
- accès uniquement par le VPN / le réseau local

Ne pas coller un basic-auth Traefik par-dessus la page de connexion de l'app : deux
authentifications superposées, personne ne s'en sert au bout de trois jours.
