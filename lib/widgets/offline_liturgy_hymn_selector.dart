import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/classes/hymns_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/utils/text_formatting_helper.dart';

class HymnSelectorWithTitle extends StatefulWidget {
  final String title;
  final List<String> hymns;
  final DataLoader dataLoader;

  const HymnSelectorWithTitle({
    super.key,
    required this.title,
    required this.hymns,
    required this.dataLoader,
  });

  @override
  State<HymnSelectorWithTitle> createState() => _HymnSelectorWithTitleState();
}

class _HymnSelectorWithTitleState extends State<HymnSelectorWithTitle> {
  String? selectedHymnCode;
  Hymns? selectedHymn;
  Map<String, Hymns>? hymnsCache;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHymns();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHymns() async {
    if (widget.hymns.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    final loadedHymns =
        await HymnsLibrary.getHymns(widget.hymns, widget.dataLoader);

    if (mounted) {
      setState(() {
        hymnsCache = loadedHymns;
        selectedHymnCode = widget.hymns.first;
        selectedHymn = hymnsCache![selectedHymnCode];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hymnsCache == null || hymnsCache!.isEmpty) {
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
            DropdownButton<String>(
              value: selectedHymnCode,
              hint: Text('Sélectionner une hymne', style: psalmAntiphonStyle),
              isExpanded: true,
              items: widget.hymns.map((String hymnCode) {
                final hymn = hymnsCache![hymnCode];
                return DropdownMenuItem<String>(
                  value: hymnCode,
                  child: Text(
                    hymn?.title ?? 'Hymne introuvable: $hymnCode',
                    style: psalmAntiphonStyle,
                  ),
                );
              }).toList(),
              onChanged: (String? newCode) {
                setState(() {
                  selectedHymnCode = newCode;
                  selectedHymn = hymnsCache![newCode];
                });
              },
            ),
            SizedBox(height: 20),
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
              buildFormattedText(selectedHymn!.content),
            ],
          ],
        ),
      ],
    );
  }
}
