import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';

/// Tab for displaying hymns (reuses existing HymnsTabWidget)
class HymnTab extends StatelessWidget {
  const HymnTab({
    super.key,
    required this.resolved,
    required this.dataLoader,
    this.isMarialHymn = false,
  });

  final ResolvedOffice resolved;
  final DataLoader dataLoader;
  final bool isMarialHymn;

  @override
  Widget build(BuildContext context) {
    List<String>? hymns;

    if (isMarialHymn) {
      // For Compline marial hymn
      try {
        hymns = (resolved.officeData as dynamic).marialHymnRef as List<String>?;
      } catch (e) {
        hymns = null;
      }
    } else {
      // Regular hymns
      try {
        hymns = (resolved.officeData as dynamic).hymn as List<String>?;
      } catch (e) {
        try {
          hymns = (resolved.officeData as dynamic).hymns as List<String>?;
        } catch (e) {
          hymns = null;
        }
      }
    }

    return HymnsTabWidget(
      hymns: hymns ?? [],
      dataLoader: dataLoader,
      emptyMessage: isMarialHymn
          ? 'Aucune hymne mariale disponible'
          : 'Aucune hymne disponible',
    );
  }
}
