import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';

/// Tab for displaying evangelic canticles (Benedictus, Magnificat, Nunc Dimittis)
class CanticleTab extends StatelessWidget {
  const CanticleTab({
    super.key,
    required this.resolved,
    required this.dataLoader,
    required this.canticleType,
  });

  final ResolvedOffice resolved;
  final DataLoader dataLoader;
  final String canticleType; // 'benedictus', 'magnificat', 'nunc_dimittis'

  @override
  Widget build(BuildContext context) {
    String? antiphon;

    try {
      final evangelicAntiphon = (resolved.officeData as dynamic).evangelicAntiphon;
      antiphon = (evangelicAntiphon as dynamic).common as String?;
    } catch (e) {
      antiphon = null;
    }

    if (antiphon == null || antiphon.isEmpty) {
      return const Center(child: Text('Aucune antienne disponible'));
    }

    return CanticleWidget(
      canticleType: canticleType,
      antiphon1: antiphon,
      dataLoader: dataLoader,
    );
  }
}
