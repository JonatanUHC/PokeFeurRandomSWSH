#!/usr/bin/env python3
"""Extrait les chaînes de l'interface, en séparant le français de l'anglais.

Sert à deux choses :

1. **Travailler sur le corpus réel.** 370 chaînes réparties dans un fichier de
   19 000 lignes ne se relisent pas à l'œil. On les sort, on les corrige, on
   réinjecte.
2. **Alimenter le contrôle d'accents.** Le générateur n'a jamais eu de BOM
   UTF-8 : PowerShell 5.1 le lisait en ANSI, donc l'auteur avait retiré tous les
   accents (« Reglages », « peche », « Metamorph »). Le BOM est désormais posé,
   les accents sont possibles, et cet outil sert à repérer ce qui reste à
   corriger.

Le français est détecté par mots outils (le, la, les, du, des, pour, avec…),
pas par une liste de chaînes : une nouvelle option est donc prise en compte
sans rien changer ici.

Usage :
    python tools/extract-ui-strings.py            # resume
    python tools/extract-ui-strings.py --dump f   # ecrit le corpus en JSON
    python tools/extract-ui-strings.py --accents  # liste ce qui manque d'accents
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Le generateur a ete decoupe : l'interface vit dans src/Interface.ps1.
# Ne lire que le fichier principal ferait passer le corpus de 635 chaines a
# 160 SANS AUCUNE ERREUR - l'outil dirait simplement qu'il n'y a rien a
# corriger. C'est exactement le mode de panne que ce projet traque.
SOURCES = [ROOT / 'CustomSwShRandomizer.ps1', ROOT / 'src' / 'Interface.ps1']
PS1 = SOURCES[0]

# Mots outils français. Trois suffisent à trancher sans se tromper sur de
# l'anglais : « the », « and » ou « with » n'y figurent pas.
FR_MARKERS = {
    'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et', 'ou', 'pour',
    'avec', 'sur', 'dans', 'qui', 'que', 'ne', 'pas', 'plus', 'sans', 'tous',
    'toutes', 'chaque', 'si', 'tu', 'ton', 'ta', 'tes', 'au', 'aux', 'ce',
    'cette', 'ces', 'son', 'sa', 'ses', 'leur', 'est', 'sont', 'par', 'entre',
    'meme', 'même', 'aucun', 'aucune', 'plutot', 'plutôt', 'quand', 'depuis',
}

# Une chaîne qui contient ça n'est pas du texte d'interface : chemin, clé de
# configuration, identifiant technique.
#
# La première version rejetait TOUTE chaîne contenant « / ». Elle écartait donc
# « tailles d'equipe » à cause du « IV/EV » de la même phrase. Une barre oblique
# ne rend pas une phrase technique ; une barre oblique SANS espace autour, si.
TECHNICAL = re.compile(
    r'\\'                      # chemin Windows
    r'|\.(?:toml|amx|bin|json|dat|ps1|cs|exe)\b'
    r'|::|\$\(|\$\{'
    r'|^\s*$'
)

# Un seul jeton, sans espace : identifiant, clé de config ou chemin. On l'écarte
# quand la langue est devinée — mais PAS dans les zones françaises par
# construction, où vivent les libellés d'un seul mot (« Generation », « Epee »,
# « Francais »), qui sont du texte d'interface tout ce qu'il y a de plus normal.
SINGLE_TOKEN = re.compile(r'^[\w./-]+$')

# Mots dont la forme accentuée est certaine dans ce projet. Les cas ambigus
# (genere/généré vs générer, cache/caché, charge/chargé) sont volontairement
# absents : ils se traitent par phrase, pas par mot.
ACCENTS = {
    'Generation': 'Génération', 'generation': 'génération',
    'Pokemon': 'Pokémon', 'pokemon': 'pokémon',
    'Epee': 'Épée', 'epee': 'épée',
    'espece': 'espèce', 'especes': 'espèces', 'Espece': 'Espèce', 'Especes': 'Espèces',
    'evolution': 'évolution', 'evolutions': 'évolutions',
    'Evolution': 'Évolution', 'Evolutions': 'Évolutions',
    'detaille': 'détaillé', 'detailles': 'détaillés', 'detaillee': 'détaillée',
    'difficulte': 'difficulté', 'Difficulte': 'Difficulté',
    'Verifier': 'Vérifier', 'verifier': 'vérifier', 'verifie': 'vérifie',
    'verifiee': 'vérifiée', 'Verifie': 'Vérifie',
    'numero': 'numéro', 'precise': 'précise', 'precis': 'précis',
    'apres': 'après', 'deja': 'déjà', 'tres': 'très',
    'etre': 'être', 'peche': 'pêche',
    'Metamorph': 'Métamorph',
    'reglages': 'réglages', 'Reglages': 'Réglages', 'reglage': 'réglage',
    'selectionne': 'sélectionne', 'selectionner': 'sélectionner',
    'necessaire': 'nécessaire', 'necessaires': 'nécessaires',
    'NECESSITE': 'NÉCESSITE', 'necessite': 'nécessite',
    'systeme': 'système', 'Systeme': 'Système',
    'parametre': 'paramètre', 'parametres': 'paramètres',
    'element': 'élément', 'elements': 'éléments',
    'derniere': 'dernière', 'premiere': 'première', 'entiere': 'entière',
    'maniere': 'manière', 'particuliere': 'particulière',
    'reference': 'référence', 'references': 'références',
    'experience': 'expérience', 'depart': 'départ',
    'separes': 'séparés', 'separe': 'séparé',
    'serie': 'série', 'series': 'séries',
    'donnee': 'donnée', 'donnees': 'données',
    'probleme': 'problème', 'problemes': 'problèmes',
    'modele': 'modèle', 'interet': 'intérêt',
    'cle': 'clé', 'cles': 'clés',
    'etape': 'étape', 'etapes': 'étapes',
    'echange': 'échange', 'Echange': 'Échange', 'echanges': 'échanges',
    'echoue': 'échoue', 'echouer': 'échouer',
    'equipe': 'équipe', 'equipes': 'équipes',
    'strategique': 'stratégique', 'arenes': 'arènes',
    'decoche': 'décoche', 'decocher': 'décocher',
    'etincelles': 'étincelles', 'reperer': 'repérer',
    'inchange': 'inchangé', 'inchangee': 'inchangée',
    'aleatoire': 'aléatoire', 'aleatoires': 'aléatoires',
    'melange': 'mélange', 'chaine': 'chaîne', 'chaines': 'chaînes',
    'decouverte': 'découverte', 'revele': 'révélé', 'revelee': 'révélée',
    'generations': 'générations', 'legendaires': 'légendaires',
    'legendaire': 'légendaire',
    'fenetre': 'fenêtre', 'prefere': 'préfère',
    'desactive': 'désactivé', 'desactivee': 'désactivée', 'desactiver': 'désactiver',
    'demarrage': 'démarrage', 'entree': 'entrée', 'entrees': 'entrées',
    'resultat': 'résultat', 'resultats': 'résultats',
    'present': 'présent', 'presente': 'présente', 'presents': 'présents',
    'securite': 'sécurité', 'theme': 'thème', 'Theme': 'Thème',
    'francais': 'français', 'Francais': 'Français',
    'emulateur': 'émulateur', 'emulateurs': 'émulateurs',
    'detecte': 'détecté', 'detectee': 'détectée',
    'Resume': 'Résumé', 'resume': 'résumé',
    'ecrit': 'écrit', 'ecrite': 'écrite', 'ecrits': 'écrits', 'ecrites': 'écrites',
    'ecrire': 'écrire', 'reecrit': 'réécrit', 'reecrire': 'réécrire',
    'Generer': 'Générer', 'generer': 'générer',
    'mecanique': 'mécanique', 'complementaire': 'complémentaire',
    'defaut': 'défaut', 'Defaut': 'Défaut',
    'operation': 'opération', 'operations': 'opérations',
    'reussite': 'réussite', 'echec': 'échec', 'Echec': 'Échec',
    'zero': 'zéro', 'penibles': 'pénibles', 'penible': 'pénible',
    'quantite': 'quantité', 'proprietes': 'propriétés', 'propriete': 'propriété',
    'anterieure': 'antérieure', 'ulterieure': 'ultérieure',
    'immediatement': 'immédiatement', 'completement': 'complètement',
    'egalement': 'également', 'generalement': 'généralement',
    'reussi': 'réussi',
    'controle': 'contrôle', 'controles': 'contrôles',
    'arret': 'arrêt', 'arrete': 'arrête',
    'interieur': 'intérieur', 'exterieur': 'extérieur',
    'variete': 'variété', 'varie': 'varié', 'variee': 'variée', 'varies': 'variés',
    'stabilite': 'stabilité', 'compatibilite': 'compatibilité',
    'possibilite': 'possibilité', 'probabilite': 'probabilité',
    'reussir': 'réussir', 'preferee': 'préférée',
}

# --- Deuxieme vague, etablie sur le corpus reel du projet -------------------
# Obtenue en listant les 1 565 tokens non accentues des chaines francaises,
# puis en ne gardant que les formes dont l'accent ne depend PAS du sens.
# Volontairement absents : utilise, applique, charge, cache, change, modifie,
# donne, demande, tire, passe, touche, active, calcule, evolue, cree, gere,
# equilibre, marque, eleve, supprime — leur accent change avec le temps du
# verbe, et se tromper la serait un defaut silencieux de plus.
ACCENTS.update({
    'meme': 'même', 'memes': 'mêmes', 'Meme': 'Même',
    'ete': 'été',
    'debut': 'début', 'Debut': 'Début',
    'priorite': 'priorité', 'priorites': 'priorités',
    'arene': 'arène', 'Arene': 'Arène',
    'generee': 'générée', 'generees': 'générées',
    # 'genere' est volontairement absent : « le mod genere » veut « généré »
    # (participe) alors que « puis genere le mod » veut « génère » (impératif).
    # Le mot seul ne permet pas de trancher ; ces cas se corrigent par phrase.
    'generes': 'générés',
    'activee': 'activée', 'activees': 'activées',
    'demandee': 'demandée', 'demandees': 'demandées',
    'calcules': 'calculés', 'calculee': 'calculée', 'calculees': 'calculées',
    'randomisee': 'randomisée', 'randomisees': 'randomisées',
    'ajoutes': 'ajoutés', 'ajoutee': 'ajoutée', 'ajoutees': 'ajoutées',
    'Strategique': 'Stratégique', 'strategie': 'stratégie', 'Strategie': 'Stratégie',
    'evoluer': 'évoluer',
    'basee': 'basée', 'basees': 'basées',
    'reutilise': 'réutilise', 'reutiliser': 'réutiliser',
    'recupere': 'récupère', 'recuperer': 'récupérer',
    'repartition': 'répartition',
    'regeneration': 'régénération',
    'creer': 'créer', 'creation': 'création',
    'coherent': 'cohérent', 'coherente': 'cohérente', 'coherence': 'cohérence',
    'prealable': 'préalable', 'precedent': 'précédent', 'precedente': 'précédente',
    'specifique': 'spécifique', 'specifiques': 'spécifiques',
    'generique': 'générique', 'numerique': 'numérique',
    'generateur': 'générateur',
    'categorie': 'catégorie', 'categories': 'catégories',
    'critere': 'critère', 'criteres': 'critères',
    'caractere': 'caractère', 'caracteres': 'caractères',
    'arriere': 'arrière', 'lumiere': 'lumière', 'matiere': 'matière',
    'geree': 'gérée', 'gerer': 'gérer', 'gerees': 'gérées',
    'reduction': 'réduction', 'acceleration': 'accélération',
    'selection': 'sélection', 'selections': 'sélections',
    'detection': 'détection',
    'energie': 'énergie', 'periode': 'période',
    'frequence': 'fréquence', 'sequence': 'séquence',
    'consequence': 'conséquence', 'consequences': 'conséquences',
    'difference': 'différence', 'differences': 'différences',
    'different': 'différent', 'differents': 'différents',
    'differente': 'différente', 'differentes': 'différentes',
    'preference': 'préférence', 'preferences': 'préférences',
    'presence': 'présence',
    'etat': 'état', 'etats': 'états', 'Etat': 'État',
    'etoile': 'étoile', 'etoiles': 'étoiles',
    'egal': 'égal', 'egale': 'égale', 'egaux': 'égaux', 'egalite': 'égalité',
    'eviter': 'éviter', 'ecart': 'écart', 'echelle': 'échelle', 'ecran': 'écran',
    'empeche': 'empêche', 'empecher': 'empêcher',
    'enorme': 'énorme', 'etendu': 'étendu', 'etendue': 'étendue',
    'evenement': 'événement', 'evenements': 'événements',
    'extreme': 'extrême', 'extremement': 'extrêmement',
    'foret': 'forêt', 'hesiter': 'hésiter', 'ideal': 'idéal', 'ideale': 'idéale',
    'immediat': 'immédiat', 'immediate': 'immédiate',
    'inferieur': 'inférieur', 'inferieure': 'inférieure',
    'superieur': 'supérieur', 'superieure': 'supérieure',
    'interessant': 'intéressant', 'interessante': 'intéressante',
    'leger': 'léger', 'legere': 'légère', 'legerement': 'légèrement',
    'mediane': 'médiane', 'memoire': 'mémoire', 'moitie': 'moitié',
    'negatif': 'négatif', 'negative': 'négative',
    'penalite': 'pénalité', 'piece': 'pièce', 'pieces': 'pièces',
    'possede': 'possède', 'posseder': 'posséder',
    'preciser': 'préciser',
    'prevu': 'prévu', 'prevue': 'prévue', 'prevoir': 'prévoir',
    'qualite': 'qualité',
    'reel': 'réel', 'reelle': 'réelle', 'reellement': 'réellement',
    'regle': 'règle', 'regles': 'règles', 'Regle': 'Règle', 'Regles': 'Règles',
    'reguliere': 'régulière', 'repere': 'repère',
    'repetition': 'répétition', 'reponse': 'réponse', 'requete': 'requête',
    'resoudre': 'résoudre', 'retablir': 'rétablir',
    'role': 'rôle', 'roles': 'rôles',
    'scenario': 'scénario', 'severe': 'sévère',
    'special': 'spécial', 'speciale': 'spéciale',
    'speciales': 'spéciales', 'speciaux': 'spéciaux',
    'succes': 'succès', 'telecharger': 'télécharger',
    'terminee': 'terminée', 'theorie': 'théorie',
    'unite': 'unité', 'unites': 'unités', 'utilite': 'utilité',
    'veritable': 'véritable',
    'developpe': 'développe', 'developpement': 'développement',
    'interet': 'intérêt', 'interets': 'intérêts',
    'complete': 'complète', 'completer': 'compléter',
    'concrete': 'concrète',
    'celebre': 'célèbre',
    'apparait': 'apparaît', 'apparaitre': 'apparaître',
    'connait': 'connaît', 'connaitre': 'connaître',
    'parait': 'paraît', 'disparait': 'disparaît',
    'plutot': 'plutôt', 'bientot': 'bientôt',
    'cout': 'coût', 'couts': 'coûts',
    'gout': 'goût',
})

# --- Troisieme vague, relevee a l'ecran sur les onglets rendus -------------
ACCENTS.update({
    'appliquee': 'appliquée', 'appliquees': 'appliquées', 'appliques': 'appliqués',
    'reecrivent': 'réécrivent', 'reecrivant': 'réécrivant',
    'camera': 'caméra',
    'detachee': 'détachée', 'detache': 'détaché', 'detaches': 'détachés',
    'forcee': 'forcée', 'forcees': 'forcées',
    'recoit': 'reçoit', 'recois': 'reçois', 'promene': 'promène', 'apparaitront': 'apparaîtront', 'deplace': 'déplacé', 'deplacer': 'déplacer', 'deplacement': 'déplacement',
    'remplacee': 'remplacée', 'remplacees': 'remplacées',
    'associee': 'associée', 'associees': 'associées',
    'conservee': 'conservée', 'conservees': 'conservées',
    'attribuee': 'attribuée', 'attribuees': 'attribuées',
    'limitee': 'limitée', 'limitees': 'limitées',
    'reservee': 'réservée', 'reservees': 'réservées',
    'triee': 'triée', 'triees': 'triées',
    'listee': 'listée', 'listees': 'listées',
    'exportee': 'exportée', 'exportees': 'exportées',
    'importee': 'importée', 'importees': 'importées',
    'installee': 'installée', 'installees': 'installées',
    'melangee': 'mélangée', 'melangees': 'mélangées', 'melanges': 'mélanges',
    'repartie': 'répartie', 'reparties': 'réparties',
    'verrouillee': 'verrouillée', 'deverrouillee': 'déverrouillée',
    'sauvegardee': 'sauvegardée', 'sauvegardees': 'sauvegardées',
    'renseignee': 'renseignée', 'renseignees': 'renseignées',
    'compressee': 'compressée', 'decompressee': 'décompressée',
    'incoherence': 'incohérence', 'incoherent': 'incohérent',
    'irreversible': 'irréversible',
    'deconseille': 'déconseillé', 'deconseillee': 'déconseillée',
    'recommandee': 'recommandée', 'recommandees': 'recommandées',
    'derive': 'dérive', 'derivee': 'dérivée',
    'ordonnee': 'ordonnée', 'ordonnees': 'ordonnées',
    'referencee': 'référencée', 'referencees': 'référencées',
    'numerotee': 'numérotée', 'numerotees': 'numérotées',
    'declaree': 'déclarée', 'declarees': 'déclarées', 'declares': 'déclarés',
    'signalee': 'signalée', 'signalees': 'signalées',
    'ignoree': 'ignorée', 'ignorees': 'ignorées',
    'traitee': 'traitée', 'traitees': 'traitées',
    'creee': 'créée', 'creees': 'créées', 'crees': 'créés',
    'copiee': 'copiée', 'copiees': 'copiées',
    'ecrasee': 'écrasée', 'ecrasees': 'écrasées', 'ecrase': 'écrase', 'restauree': 'restaurée',
    'verifiees': 'vérifiées', 'verifies': 'vérifiés',
    'affichee': 'affichée', 'affichees': 'affichées', })

# Toute entree en minuscules a aussi une forme capitalisee en debut de phrase
# ou de libelle : « Compatibilite », « Camera », « Reglages ». Les generer plutot
# que les ecrire evite d'en oublier la moitie, ce qui etait le cas.
for _k, _v in list(ACCENTS.items()):
    if _k[:1].islower():
        _cap = _k[:1].upper() + _k[1:]
        if _cap not in ACCENTS:
            ACCENTS[_cap] = _v[:1].upper() + _v[1:]

# Une entrée neutre (clé identique à sa valeur) serait signalée à jamais par
# `--check` sans qu'aucune correction ne puisse la faire disparaître. Deux s'y
# étaient glissées — « presque » et « identifiant » — avant ce garde-fou.
_neutres = sorted(k for k, v in ACCENTS.items() if k == v)
assert not _neutres, 'entrées neutres dans ACCENTS : %s' % _neutres

WORD = re.compile(r'\b\w+\b', re.UNICODE)


# Mots anglais courts qui trancheraient a tort. « Theme » existe dans les deux
# langues : on ne veut pas accentuer le libelle anglais en « Theme ».
EN_MARKERS = {
    'the', 'and', 'with', 'from', 'this', 'that', 'your', 'you', 'for',
    'when', 'which', 'they', 'their', 'are', 'is', 'of', 'to', 'in', 'on',
    'it', 'its', 'as', 'be', 'but', 'not', 'all', 'each', 'only', 'also',
}


def is_french(text: str) -> bool:
    words = {w.lower() for w in WORD.findall(text)}
    if words & EN_MARKERS:
        return False
    return len(words & FR_MARKERS) > 0


def strings_of(text: str):
    """Rend (ligne, colonne, valeur) de chaque littéral entre guillemets."""
    for i, line in enumerate(text.split('\n'), start=1):
        stripped = line.lstrip()
        if stripped.startswith('#') or stripped.startswith('//'):
            continue
        for m in re.finditer(r'"([^"\\]*)"', line):
            yield i, m.start(1), m.group(1)


def missing_accents(value: str):
    out = []
    for w in WORD.findall(value):
        if w in ACCENTS:
            out.append((w, ACCENTS[w]))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dump', help='écrire le corpus français en JSON')
    ap.add_argument('--accents', action='store_true',
                    help='lister les chaînes auxquelles il manque des accents')
    ap.add_argument('--check', action='store_true',
                    help='sortir 1 s\'il reste des accents manquants')
    args = ap.parse_args()

    fr, en, tech = [], 0, 0
    presents = [q for q in SOURCES if q.is_file()]
    if not presents:
        print('ECHEC: aucun fichier source trouve.')
        return 1
    for source in presents:
        text = source.read_text(encoding='utf-8-sig')
        for line, col, value in strings_of(text):
            if len(value) < 4:
                continue
            if TECHNICAL.search(value) or SINGLE_TOKEN.match(value):
                tech += 1
                continue
            if is_french(value):
                fr.append({'fichier': source.name, 'line': line, 'col': col,
                           'value': value, 'accents': missing_accents(value)})
            else:
                en += 1

    faulty = [e for e in fr if e['accents']]
    print('Corpus de l\'interface')
    print('  fichiers lus                 : %s' % ', '.join(q.name for q in presents))
    print('  chaines francaises detectees : %d' % len(fr))
    print('  autres (anglais, techniques) : %d + %d' % (en, tech))
    print('  a accentuer                  : %d' % len(faulty))

    if args.dump:
        Path(args.dump).write_text(json.dumps(fr, ensure_ascii=False, indent=2),
                                   encoding='utf-8')
        print('  corpus ecrit dans %s' % args.dump)

    if args.accents:
        print()
        for e in faulty[:400]:
            mots = ', '.join('%s->%s' % (a, b) for a, b in e['accents'])
            print('  %-24s L%-6d %-38s | %s' % (e['fichier'], e['line'], mots[:38], e['value'][:110]))

    if args.check and faulty:
        print()
        print('ECHEC: %d chaine(s) francaise(s) sans accents.' % len(faulty))
        return 1
    if args.check:
        print()
        print('OK  : toutes les chaines francaises sont accentuees.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
