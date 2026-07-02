import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/hymns_class.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';

/// Hymn selector using pre-hydrated HymnEntry data.
/// No YAML loading needed — hymnData is already resolved.
class HymnSelectorWithTitle extends StatefulWidget {
  final String title;
  final List<HymnEntry> hymns;
  final bool shrinkWrap;

  const HymnSelectorWithTitle({
    super.key,
    required this.title,
    required this.hymns,
    this.shrinkWrap = false,
  });

  @override
  State<HymnSelectorWithTitle> createState() => _HymnSelectorWithTitleState();
}

class _HymnSelectorWithTitleState extends State<HymnSelectorWithTitle> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  Hymns? get selectedHymn => widget.hymns[selectedIndex].hymnData;

  @override
  Widget build(BuildContext context) {
    if (widget.hymns.isEmpty) {
      return const Center(child: Text('No hymns available'));
    }

    final zoom = context.watch<CurrentZoom>().value;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final errorColor = Theme.of(context).colorScheme.secondary;
    final titleColor = Theme.of(context).textTheme.titleMedium?.color;
    final hymnTitleStyle = TextStyle(
      fontSize: 16 * zoom / 100,
      fontWeight: FontWeight.bold,
      color: titleColor,
    );

    return ListView(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        LiturgyPartTitle(widget.title, hideVerseIdPlaceholder: false),
        SizedBox(height: 10 * zoom / 100),
        LiturgyRow(
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.hymns.length > 1) ...[
                DropdownButton<int>(
                  value: selectedIndex,
                  hint: Text('Sélectionner une hymne', style: bodyStyle),
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox(),
                  selectedItemBuilder: (context) => List.generate(
                    widget.hymns.length,
                    (index) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.hymns[index].hymnData?.title ??
                            widget.hymns[index].code,
                        style: hymnTitleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  items: List.generate(widget.hymns.length, (index) {
                    final hymn = widget.hymns[index].hymnData;
                    final code = widget.hymns[index].code;
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        hymn?.title ?? 'Hymne introuvable: $code',
                        style: TextStyle(fontSize: 10 * zoom / 100),
                      ),
                    );
                  }),
                  onChanged: (int? newIndex) {
                    if (newIndex != null) {
                      setState(() => selectedIndex = newIndex);
                    }
                  },
                ),
              ],
              if (selectedHymn != null) ...[
                if (widget.hymns.length == 1)
                  Text(selectedHymn!.title, style: hymnTitleStyle),
                if (selectedHymn!.author != null &&
                    selectedHymn!.author!.isNotEmpty) ...[
                  SizedBox(height: 2 * zoom / 100),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      selectedHymn!.author!,
                      style: TextStyle(
                        fontSize: 10 * zoom / 100,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * zoom / 100),
                ] else
                  SizedBox(height: 8 * zoom / 100),
                HymnContentDisplay(content: selectedHymn!.content),
              ] else ...[
                Text(
                  'Hymne introuvable: ${widget.hymns[selectedIndex].code}',
                  style: TextStyle(color: errorColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
