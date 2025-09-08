import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/classes/hymns_class.dart';
import '../app_screens/liturgy_formatter.dart';

class HymnSelector extends StatefulWidget {
  final List<String> hymns; // Liste des codes d'hymnes à afficher

  const HymnSelector({
    Key? key,
    required this.hymns,
  }) : super(key: key);

  @override
  State<HymnSelector> createState() => _HymnSelectorState();
}

class _HymnSelectorState extends State<HymnSelector> {
  String? selectedHymnCode;
  Hymns? selectedHymn;

  @override
  void initState() {
    super.initState();
    // Sélectionner la première hymne de la liste par défaut
    if (widget.hymns.isNotEmpty) {
      selectedHymnCode = widget.hymns.first;
      selectedHymn = hymnsLibraryContent[selectedHymnCode];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liste déroulante avec les hymnes de la liste fournie
        DropdownButton<String>(
          value: selectedHymnCode,
          hint: Text('Sélectionner une hymne', style: psalmAntiphonStyle),
          isExpanded: true,
          items: widget.hymns.map((String hymnCode) {
            final hymn = hymnsLibraryContent[hymnCode];
            return DropdownMenuItem<String>(
              value: hymnCode,
              child: Text(hymn?.title ?? 'Hymne introuvable: $hymnCode',
                  style: psalmAntiphonStyle),
            );
          }).toList(),
          onChanged: (String? newCode) {
            setState(() {
              selectedHymnCode = newCode;
              selectedHymn = hymnsLibraryContent[newCode];
            });
          },
        ),

        SizedBox(height: 20),

        // Affichage de l'hymne sélectionnée
        if (selectedHymn != null) ...[
          // Titre
          Text(
            selectedHymn!.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          // Auteur (si présent)
          if (selectedHymn!.author!.isNotEmpty) ...[
            Text(
              'Par ${selectedHymn!.author}',
              style: authorNameStyle,
            ),
            SizedBox(height: 16),
          ],

          // Contenu
          Html(
            data: correctAelfHTML(selectedHymn!.content),
          ),
        ],
      ],
    );
  }
}
