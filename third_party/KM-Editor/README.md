# KM-Editor — catalogue des cadeaux d'objets des PNJ

`SwShNpcItemGiftDefinitions.cs` est repris **tel quel** du projet
[KM-Editor](https://github.com/KotMatrosk1n/KM-Editor) de KotMatrosk1n,
publié sous **GPL-3.0-only**. Le texte de la licence accompagne le fichier
dans ce dossier, et l'en-tête SPDX d'origine est intact.

## Pourquoi il est ici

`tools/build-npc-gifts.py` a besoin de ce catalogue pour savoir **où chercher** :
quel fichier `.amx`, quelle cellule, quel objet attendu. Le CSV produit, lui, est
dérivé du dump de l'utilisateur — pas de ce fichier. Mais sans ces ancres, le
script ne sait pas par où commencer, et l'option « objets offerts par les PNJ »
du randomizer reste sans effet.

L'alternative aurait été de réextraire ces ancres nous-mêmes pour éviter la GPL.
C'est précisément ce que le droit *sui generis* européen sur les bases de données
sanctionne. Reprendre le fichier sous sa licence est plus honnête, et plus sûr.

## Ce que ça implique

Ce projet est donc distribué sous **GPL-3.0-only** (voir le `LICENSE` à la racine).
Toute redistribution, modifiée ou non, doit rester sous cette licence et fournir
ses sources.

Merci à KotMatrosk1n pour ce travail de rétro-ingénierie.
