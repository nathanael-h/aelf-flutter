# Fichiers .dart non utilisés dans aelf-flutter

**Date d'analyse** : 2026-01-01
**Méthode** : Analyse de dépendances depuis main.dart

## Statistiques

- **Total de fichiers dans `lib/`** : 82 fichiers
- **Fichiers importés** : 75 fichiers
- **Fichiers non importés** : 8 fichiers

---

## 1. Fichiers spéciaux (normaux)

Ces fichiers ne doivent pas être importés par d'autres fichiers :

### [main.dart](lib/main.dart)
- **Statut** : Point d'entrée de l'application
- **Lignes** : 94
- **Note** : Fichier d'entrée Flutter, ne doit pas être importé

### [generated_plugin_registrant.dart](lib/generated_plugin_registrant.dart)
- **Statut** : Généré automatiquement
- **Lignes** : 20
- **Note** : Généré par Flutter, ne doit pas être édité manuellement

---

## 2. Fichiers de développement (à nettoyer)

### [app_screens/not_dev_screen.dart](lib/app_screens/not_dev_screen.dart)
- **Statut** : Placeholder de développement
- **Lignes** : 21
- **Contenu** : Classe `ToDo` qui affiche des dialogues "Under Development"
- **Recommandation** : ⚠️ À SUPPRIMER (non utilisé)

### [parsers/not_dev_screen.dart](lib/parsers/not_dev_screen.dart)
- **Statut** : Duplicate du précédent
- **Lignes** : 21
- **Contenu** : Identique à `app_screens/not_dev_screen.dart`
- **Recommandation** : ⚠️ À SUPPRIMER (duplicate non utilisé)

---

## 3. Fichiers fonctionnels mais inutilisés

### [parsers/hebrew_psalm_parser.dart](lib/parsers/hebrew_psalm_parser.dart)
- **Statut** : Fonctionnel mais obsolète
- **Lignes** : 295
- **Contenu** :
  - Parser HTML pour psaumes hébreux
  - Classes : `HebrewPsalmConfig`, `HebrewPsalmParser`, `HebrewPsalmFromHtml`
  - Gère les numéros de versets en lettres hébraïques
  - Parse le format HTML avec balises `<p>`, `<br>`, `<span>`
- **Remplacé par** : `hebrew_greek_yaml_parser.dart` (format YAML)
- **Note** : Retiré des dépendances lors de la migration YAML (2026-01-01)
- **Recommandation** : ⚠️ À SUPPRIMER (remplacé par parser YAML)

### [parsers/office_parser.dart](lib/parsers/office_parser.dart)
- **Statut** : Fonctionnel mais non utilisé
- **Lignes** : 290
- **Contenu** : Parser pour données liturgiques d'offices
- **Particularité** : Utilise des imports relatifs (`../models/...`) au lieu du style package
- **Recommandation** : ⚠️ À ÉVALUER (possiblement prévu pour usage futur)

### [widgets/liturgy_info_widget.dart](lib/widgets/liturgy_info_widget.dart)
- **Statut** : Fonctionnel mais non utilisé
- **Lignes** : 73
- **Contenu** :
  - Widget pour afficher les informations liturgiques
  - Affiche : nom de l'octave, temps liturgique, semaine du bréviaire
  - Classe : `LiturgyInfoWidget`
- **Import** : `app_screens/layout_config.dart`
- **Recommandation** : 🔍 À ÉVALUER (pourrait être intégré dans les vues morning/compline)

### [widgets/liturgy_part_antiphon.dart](lib/widgets/liturgy_part_antiphon.dart)
- **Statut** : Fonctionnel mais obsolète
- **Lignes** : 54
- **Contenu** :
  - Widget pour rendre les antiennes avec support HTML
  - Support du zoom (integration avec `CurrentZoomState`)
  - Classe : `LiturgyPartAntiphon`
- **Remplacé par** : `offline_liturgy_common_widgets/antiphon_display.dart`
- **Recommandation** : ⚠️ À SUPPRIMER (remplacé par version plus récente)

---

## Recommandations par priorité

### ✅ HAUTE PRIORITÉ - À supprimer immédiatement

1. **parsers/hebrew_psalm_parser.dart**
   - Remplacé par `hebrew_greek_yaml_parser.dart`
   - Tous les psaumes sont maintenant en YAML

2. **parsers/not_dev_screen.dart** et **app_screens/not_dev_screen.dart**
   - Duplicates inutilisés
   - Placeholders de développement jamais utilisés

3. **widgets/liturgy_part_antiphon.dart**
   - Remplacé par `antiphon_display.dart` dans `offline_liturgy_common_widgets/`

### 🔍 MOYENNE PRIORITÉ - À évaluer

4. **widgets/liturgy_info_widget.dart**
   - Vérifier si ce widget devrait être affiché dans les offices
   - Pourrait ajouter des informations utiles (octave, temps liturgique)
   - Si non nécessaire, supprimer

5. **parsers/office_parser.dart**
   - Vérifier s'il est prévu pour un usage futur
   - Corriger les imports relatifs si conservé
   - Sinon, supprimer

---

## Impact de la suppression

### Fichiers sûrs à supprimer (aucun impact)
- ✅ `parsers/hebrew_psalm_parser.dart` - Déjà remplacé
- ✅ `parsers/not_dev_screen.dart` - Jamais utilisé
- ✅ `app_screens/not_dev_screen.dart` - Jamais utilisé
- ✅ `widgets/liturgy_part_antiphon.dart` - Déjà remplacé

### Fichiers à analyser avant suppression
- ⚠️ `parsers/office_parser.dart` - Vérifier plans futurs
- ⚠️ `widgets/liturgy_info_widget.dart` - Vérifier utilité fonctionnelle

---

## Commandes pour supprimer les fichiers obsolètes

```bash
# Supprimer les fichiers définitivement obsolètes
rm lib/parsers/hebrew_psalm_parser.dart
rm lib/parsers/not_dev_screen.dart
rm lib/app_screens/not_dev_screen.dart
rm lib/widgets/liturgy_part_antiphon.dart

# Optionnel : supprimer les fichiers non utilisés après évaluation
# rm lib/parsers/office_parser.dart
# rm lib/widgets/liturgy_info_widget.dart
```

---

## Historique des changements

**2026-01-01**
- Migration complète vers le format YAML pour tous les psaumes (français, hébreu, grec)
- Suppression de l'import `hebrew_psalm_parser.dart` dans `psalms_display.dart`
- Le parser HTML des psaumes hébreux n'est plus utilisé nulle part dans le projet
