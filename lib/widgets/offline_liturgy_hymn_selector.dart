import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/classes/hymns_class.dart';
import 'package:aelf_flutter/utils/text_management.dart';
import './liturgy_part_title.dart';

class HymnSelectorWithTitle extends StatefulWidget {
  final String title; // Title to display
  final List<String> hymns; // List of the hymn codes

  const HymnSelectorWithTitle({
    Key? key,
    required this.title,
    required this.hymns,
  }) : super(key: key);

  @override
  State<HymnSelectorWithTitle> createState() => _HymnSelectorWithTitleState();
}

class _HymnSelectorWithTitleState extends State<HymnSelectorWithTitle> {
  String? selectedHymnCode;
  Hymns? selectedHymn;

  @override
  void initState() {
    super.initState();
    // Selects the first hymn of the list
    if (widget.hymns.isNotEmpty) {
      selectedHymnCode = widget.hymns.first;
      selectedHymn = hymnsLibraryContent[selectedHymnCode];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        LiturgyPartTitle(widget.title),
        SizedBox(height: 16),

        // Hymn Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrolling list with the given list
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

            // Hymn display
            if (selectedHymn != null) ...[
              // Hymn title
              Text(
                selectedHymn!.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // Author (if exists)
              if (selectedHymn!.author!.isNotEmpty) ...[
                Text(
                  '${selectedHymn!.author}',
                  style: authorNameStyle,
                ),
                SizedBox(height: 16),
              ],

              // Content
              Html(
                data: correctAelfHTML(selectedHymn!.content),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
