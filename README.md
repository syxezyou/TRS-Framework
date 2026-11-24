<div align="center">

<img src="https://raw.githubusercontent.com/syxezyou/syxezyou/main/assets/syx-galaxy.svg" width="100%" alt="SYX Galaxy"/>

# TRS Framework 1.0.0

**Framework RP autonome pour FiveM — SYX**

![Version](https://img.shields.io/badge/Version-1.0.0-9333EA?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000000?style=for-the-badge&logo=lua&logoColor=c084fc)
![Statut](https://img.shields.io/badge/Statut-Expérimental-4c1d95?style=for-the-badge)

</div>

Base RP autonome pour FiveM. ESX, QBCore, ox_lib et RageUI ne sont pas requis.
Seule dépendance externe : oxmysql (et ressources officielles FXServer).

## Installation

1. Installer FXServer avec les ressources de base (mapmanager, chat, spawnmanager, sessionmanager) et OneSync.
2. Télécharger oxmysql depuis https://github.com/overextended/oxmysql/releases et placer la ressource dans resources.
3. Copier resources/trs dans le dossier resources du serveur.
4. Créer une base MariaDB/MySQL et importer sql/trs.sql.
5. Adapter server.cfg.example : clé Cfx.re, identifiants SQL, ports attribués par Pterodactyl, permissions ACE. Ne pas écraser un server.cfg existant : fusionner les lignes.
6. Démarrer le serveur, vérifier que oxmysql et trs démarrent sans erreur.
7. Se connecter, créer son personnage et tester la sauvegarde en se reconnectant.

## Configuration

- resources/trs/shared/Config.lua : version active dérivée de l'original (nom TRS, AppId désactivé, licence de maintenance retirée).
- resources/trs/shared/settings.lua : paramètres du nouveau cœur TRS.
- Les liens et visuels historiques ont été neutralisés dans la configuration distribuée ; renseigner ses propres valeurs.
- Ne jamais inscrire un token Discord ou une clé secrète dans un fichier shared.
- Les coordonnées liées à des MLO personnalisés nécessitent les mappings correspondants.

## Fonctions implémentées

Identité simple, spawn et dernière position, sauvegarde MySQL, comptes cash/banque,
inventaire avec limite et consommation, transferts de proximité, métiers et salaires,
faim/soif, XP, HUD, menus NUI, boutiques, garage et achat de véhicules (un véhicule
par modèle), téléporteurs, ascenseurs, accueil métier, récolte/transformation/vente
d'acier, pêche simplifiée (permis, canne, appâts, tirage pondéré, vente), livraison
simple, météo globale, pile ou face, mort et respawn, permissions ACE et mode
maintenance. Les opérations économiques sont vérifiées côté serveur.

## Commandes

| Commande | Usage |
|---|---|
| F5 | Menu personnel |
| TAB | Inventaire |
| Y | XP |
| E | Interagir près d'un marqueur |
| /trsgive ID ITEM NOMBRE | Donner des objets à proximité |
| /trsbalance deposit 100 | Déposer à la banque |
| /trsbalance withdraw 100 | Retirer à la banque |
| /trsfish douce | Pêcher dans une zone d'eau douce (mer/ocean aussi) |
| /trsrespawn | Réapparaître après 30 secondes |
| /pileouface | Tirage |
| /trsjob ID police | Staff : attribuer un métier |
| /trsmoney ID 100 | Staff : donner du cash |
| /trsrevive ID | Staff : réanimer |

## API serveur pour les autres ressources

```lua
local player = exports.trs:GetPlayer(source)
exports.trs:RegisterItem('radio', 'Radio')
exports.trs:AddItem(source, 'radio', 1)
exports.trs:RemoveItem(source, 'radio', 1)
exports.trs:AddMoney(source, 'cash', 500)
exports.trs:SetJob(source, 'police', 2)
```

## Limites de cette V1

Les paramètres historiques non exploités restent présents dans la configuration pour
les développements suivants. La chasse complète, auto-école (examens), préfecture,
Leboncoin, plaquage, portage, copie d'animation, armes dans le dos, suppression PNJ,
boost Discord, météo par zone, éditeur Rockstar, skin détaillé, interface staff et
métiers spécialisés ne sont pas implémentés. Les callbacks ESX historiques ne
sont pas exécutés ; aucune compatibilité ESX n'est annoncée.
Le système de pêche ne reproduit pas encore le mini-jeu de moulinage.
Le système de garage ne persiste pas les modifications du véhicule.

Cette archive est une première base autonome à tester sur un FXServer de développement,
pas un serveur de production certifié. Les ressources FXServer, mappings et oxmysql
ne sont pas incluses. Tester les événements multijoueur et la sécurité avant ouverture.

## Structure du dépôt

```text
resources/trs/
  fxmanifest.lua
  shared/
  server/
  client/
  html/
sql/trs.sql
server.cfg.example
```

## Support et licence

Signaler les bugs via les issues en précisant les versions et étapes de reproduction. Ne pas publier de secrets. Aucune licence nouvelle n'est attribuée à cette distribution ; vérifier les droits sur les composants et configurations d'origine avant redistribution publique.

---

**Projet SYX — [@syxezyou](https://github.com/syxezyou)**
