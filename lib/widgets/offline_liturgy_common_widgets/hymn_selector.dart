import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/hymns_class.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';

/// Hymn selector using pre-hydrated HymnEntry data.
/// No YAML loading needed — hymnData is already resolved.
class HymnSelectorWithTitle extends StatefulWidget {
  final String title;
  final List<HymnEntry> hymns;

  const HymnSelectorWithTitle({
    super.key,
    required this.title,
    required this.hymns,
  });

  @override
  State<HymnSelectorWithTitle> createState() => _HymnSelectorWithTitleState();
}

class _HymnSelectorWithTitleState extends State<HymnSelectorWithTitle> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Select a random hymn if there are multiple, otherwise take the first
    if (widget.hymns.length > 1) {
      selectedIndex = Random().nextInt(widget.hymns.length);
    }
  }

  Hymns? get selectedHymn => widget.hymns[selectedIndex].hymnData;

  @override
  Widget build(BuildContext context) {
    if (widget.hymns.isEmpty) {
      return const Center(child: Text('No hymns available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(widget.title),
        SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show dropdown if there are multiple hymns
            if (widget.hymns.length > 1) ...[
              DropdownButton<int>(
                value: selectedIndex,
                hint: Text('Sélectionner une hymne', style: psalmAntiphonStyle),
                isExpanded: true,
                items: List.generate(widget.hymns.length, (index) {
                  final hymn = widget.hymns[index].hymnData;
                  final code = widget.hymns[index].code;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      hymn?.title ?? 'Hymne introuvable: $code',
                      style: psalmAntiphonStyle,
                    ),
                  );
                }),
                onChanged: (int? newIndex) {
                  if (newIndex != null) {
                    setState(() {
                      selectedIndex = newIndex;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
            ],
            if (selectedHymn != null) ...[
              Text(
                selectedHymn!.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (selectedHymn!.author != null &&
                  selectedHymn!.author!.isNotEmpty) ...[
                Text(
                  '${selectedHymn!.author}',
                  style: authorNameStyle,
                ),
                SizedBox(height: 16),
              ],
              HymnContentDisplay(content: selectedHymn!.content),
            ] else ...[
              Text(
                'Hymne introuvable: ${widget.hymns[selectedIndex].code}',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
